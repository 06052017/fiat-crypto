Require Export Language Conversion.
Require Import QhasmCommon QhasmEvalCommon QhasmUtil Qhasm.
Require Export String Ascii.
Require Import NArith NPeano.
Require Export Bedrock.Word.

Module QhasmString <: Language.
  Definition Program := string.
  Definition State := unit.

  Definition evaluatesTo (p: Program) (i o: State): Prop := True.
End QhasmString.

Module StringConversion <: Conversion Qhasm QhasmString.
  Import Qhasm ListNotations.

  (* The easy one *)
  Definition convertState (st: QhasmString.State): option Qhasm.State := None.

  (* Hexadecimal Primitives *)

  Section Hex.
    Local Open Scope string_scope.

    Definition natToDigit (n : nat) : string :=
      match n with
        | 0  => "0"  | 1  => "1"  | 2  => "2"  | 3  => "3"
        | 4  => "4"  | 5  => "5"  | 6  => "6"  | 7  => "7"
        | 8  => "8"  | 9  => "9"  | 10 => "A"  | 11 => "B"
        | 12 => "C"  | 13 => "D"  | 14 => "E"  | _  => "F"
      end.

    Fixpoint nToHex' (n: N) (digitsLeft: nat): string :=
        match digitsLeft with
        | O => ""
        | S nextLeft =>
            match n with
            | N0 => "0"
            | _ => (nToHex' (N.shiftr_nat n 4) nextLeft) ++
                (natToDigit (N.to_nat (N.land n 15%N)))
            end
        end.

    Definition nToHex (n: N): string :=
      let size := (N.size n) in
      let div4 := fun x => (N.shiftr x 2%N) in
      let size' := (size + 4 - (N.land size 3))%N in
      nToHex' n (N.to_nat (div4 size')).

  End Hex.

  (* Conversion of elements *)

  Section Elements.
    Local Open Scope string_scope.
    Import Util.

    Definition nameSuffix (n: nat): string := 
      (nToHex (N.of_nat n)).

    Coercion wordToString {n} (w: word n): string := 
      "0x" ++ (nToHex (wordToN w)).

    Coercion intConstToString {n} (c: IConst n): string :=
      match c with
      | constInt32 w => "0x" ++ w
      end.

    Coercion floatConstToString {n} (c: FConst n): string :=
      match c with
      | constFloat32 w => "0x" ++ w
      | constFloat64 w => "0x" ++ w
      end.

    Coercion intRegToString {n} (r: IReg n): string :=
      match r with
      | regInt32 n => "w" ++ (nameSuffix n)
      end.

    Coercion floatRegToString {n} (r: FReg n): string :=
      match r with
      | regFloat32 n => "sf" ++ (nameSuffix n)
      | regFloat64 n => "lf" ++ (nameSuffix n)
      end.

    Coercion natToString (n: nat): string :=
      "0x" ++ (nToHex (N.of_nat n)).

    Coercion stackToString {n} (s: Stack n): string :=
      match s with
      | stack32 n => "ss" ++ (nameSuffix n)
      | stack64 n => "ls" ++ (nameSuffix n)
      | stack128 n => "qs" ++ (nameSuffix n)
      end.

    Coercion stringToSome (x: string): option string := Some x.

    Definition stackLocation {n} (s: Stack n): word 32 :=
      combine (natToWord 8 n) (natToWord 24 n).

    Definition assignmentToString (a: Assignment): option string :=
      match a with
      | ARegStackInt n r s => r ++ " = *(int" ++ n ++ " *)" ++ s
      | ARegStackFloat n r s => r ++ " = *(float" ++ n ++ " *)" ++ s
      | AStackRegInt n s r => "*(int" ++ n ++ " *) " ++ s ++ " = " ++ r
      | AStackRegFloat n s r => "*(float" ++ n ++ " *) " ++ s ++ " = " ++ r
      | ARegRegInt n a b => a ++ " = " ++ b
      | ARegRegFloat n a b => a ++ " = " ++ b
      | AConstInt n r c => r ++ " = " ++ c
      | AConstFloat n r c => r ++ " = " ++ c
      | AIndex n m a b i =>
        a ++ " = *(int" ++ n ++ " *) (" ++ b ++ " + " ++ (m/n) ++ ")"
      | APtr n r s => r ++ " = " ++ s
      end.

    Coercion intOpToString (b: IntOp): string :=
      match b with
      | IPlus => "+"
      | IMinus => "-"
      | IXor => "^"
      | IAnd => "&"
      | IOr => "|"
      end.

    Coercion floatOpToString (b: FloatOp): string :=
      match b with
      | FPlus => "+"
      | FMult => "*"
      | FAnd => "&"
      end.

    Coercion rotOpToString (r: RotOp): string :=
      match r with
      | Shl => "<<"
      | Shr => ">>"
      end.
 
    Definition operationToString (op: Operation): option string :=
      match op with
      | IOpConst o r c => 
        r ++ " " ++ o ++ "= " ++ c
      | IOpReg o a b =>
        a ++ " " ++ o ++ "= " ++ b
      | FOpConst32 o r c =>
        r ++ " " ++ o ++ "= " ++ c
      | FOpReg32 o a b =>
        a ++ " " ++ o ++ "= " ++ b
      | FOpConst64 o r c =>
        r ++ " " ++ o ++ "= " ++ c
      | FOpReg64 o a b =>
        a ++ " " ++ o ++ "= " ++ b
      | OpRot o r i =>
        r ++ " " ++ o ++ "= " ++ i
      end.

    Definition testOpToString (t: TestOp): bool * string :=
      match t with
      | TEq => (true, "=")
      | TLt => (true, "<")
      | TGt => (true, ">")
      | TLe => (false, ">")
      | TGe => (false, "<")
      end.

    Definition conditionalToString (c: Conditional): string * string :=
      match c with
      | TestTrue => ("=? 0", ">") (* these will be elided later on*)
      | TestFalse => (">? 0", ">")
      | TestInt n o a b =>
        match (testOpToString o) with
        | (true, s) =>
          (s ++ "? " ++ a ++ " - " ++ b, s)
        | (false, s) =>
          ("!" ++ s ++ "? " ++ a ++ " - " ++ b, "!" ++ s)
        end
      | TestFloat n o a b =>
        match (testOpToString o) with
        | (true, s) =>
          (s ++ "? " ++ a ++ " - " ++ b, s)
        | (false, s) =>
          ("!" ++ s ++ "? " ++ a ++ " - " ++ b, "!" ++ s)
        end
      end.

  End Elements.

  Section Parsing.
    Inductive Entry :=
      | intEntry: forall n, IReg n -> Entry
      | floatEntry: forall n, FReg n -> Entry
      | stackEntry: forall n, Stack n -> Entry.

    Definition entryId (x: Entry): nat * nat * nat :=
      match x with
      | intEntry n (regInt32 v) => (0, n, v)
      | floatEntry n (regFloat32 v) => (1, n, v)
      | floatEntry n (regFloat64 v) => (2, n, v)
      | stackEntry n (stack32 v) => (3, n, v)
      | stackEntry n (stack64 v) => (4, n, v)
      | stackEntry n (stack128 v) => (5, n, v)
      end.

    Lemma id_equal: forall {x y}, x = y <-> entryId x = entryId y.
    Proof.
      intros; split; intros;
        destruct x as [nx x | nx x | nx x];
        destruct y as [ny y | ny y | ny y];
        try rewrite H;

        destruct x, y; subst;
        destruct (Nat.eq_dec n n0); subst;

        simpl in H; inversion H; intuition.
    Qed.

    Lemma triple_conv: forall {x0 x1 x2 y0 y1 y2: nat},
      (x0 = y0 /\ x1 = y1 /\ x2 = y2) <-> (x0, x1, x2) = (y0, y1, y2).
    Proof.
      intros; split; intros.

      - destruct H; destruct H0; subst; intuition.

      - inversion_clear H; intuition.
    Qed.

    Definition triple_dec (x y: nat * nat * nat): {x = y} + {x <> y}.
      refine (match x as x' return x' = _ -> _ with
      | (x0, x1, x2) => fun _ =>
        match y as y' return y' = _ -> _ with
        | (y0, y1, y2) => fun _ =>
           _ (Nat.eq_dec x0 y0) (Nat.eq_dec x1 y1) (Nat.eq_dec x2 y2)
        end (eq_refl y)
      end (eq_refl x));
        rewrite <- _H, <- _H0;
        clear _H _H0 x y p p0;
        intros.

      intros; destruct x6, x7, x8; first [
        left; abstract (subst; intuition)
      | right; abstract (intro;
          apply triple_conv in H;
          destruct H; destruct H0; intuition)
      ].
    Defined.

    Definition entry_dec (x y: Entry): {x = y} + {x <> y}.
      refine (_ (triple_dec (entryId x) (entryId y))).
      intros; destruct x0.

      - left; abstract (apply id_equal in e; intuition).
      - right; abstract (intro; apply id_equal in H; intuition).
    Defined.

    Fixpoint entries (prog: Program): list Entry :=
      match prog with
      | cons s next =>
        match s with
        | QAssign a =>
          match a with
          | ARegStackInt n r s => [intEntry n r; stackEntry n s]
          | ARegStackFloat n r s => [floatEntry n r; stackEntry n s]
          | AStackRegInt n s r => [intEntry n r; stackEntry n s]
          | AStackRegFloat n s r => [floatEntry n r; stackEntry n s]
          | ARegRegInt n a b => [intEntry n a; intEntry n b]
          | ARegRegFloat n a b => [floatEntry n a; floatEntry n b]
          | AConstInt n r c => [intEntry n r]
          | AConstFloat n r c => [floatEntry n r]
          | AIndex n m a b i => [intEntry n a; intEntry m b]
          | APtr n r s => [intEntry 32 r; stackEntry n s]
          end
        | QOp o =>
          match o with
          | IOpConst o r c => [intEntry 32 r]
          | IOpReg o a b => [intEntry 32 a; intEntry 32 b]
          | FOpConst32 o r c => [floatEntry 32 r]
          | FOpReg32 o a b => [floatEntry 32 a; floatEntry 32 b]
          | FOpConst64 o r c => [floatEntry 64 r]
          | FOpReg64 o a b => [floatEntry 64 a; floatEntry 64 b]
          | OpRot o r i => [intEntry 32 r]
          end
        | QJmp c _ =>
          match c with
          | TestInt n o a b => [intEntry n a; intEntry n b]
          | TestFloat n o a b => [floatEntry n a; floatEntry n b]
          | _ => []
          end
        | QLabel _ => []
        end ++ (entries next)
      | nil => nil
      end.

    Definition flatMap {A B} (lst: list A) (f: A -> option B): list B :=
      fold_left
        (fun lst a => match (f a) with | Some x => cons x lst | _ => lst end)
        lst [].

    Fixpoint dedup (l : list Entry) : list Entry :=
      match l with
      | [] => []
      | x::xs =>
        if in_dec entry_dec x xs
        then dedup xs
        else x::(dedup xs)
      end.

    Definition everyIReg32 (lst: list Entry): list (IReg 32) :=
      flatMap (dedup lst) (fun e =>
        match e with | intEntry 32 r => Some r | _ => None end).

    Definition everyFReg32 (lst: list Entry): list (FReg 32) :=
      flatMap (dedup lst) (fun e =>
        match e with | floatEntry 32 r => Some r | _ => None end).

    Definition everyFReg64 (lst: list Entry): list (FReg 64) :=
      flatMap (dedup lst) (fun e =>
        match e with | floatEntry 64 r => Some r | _ => None end).

    Definition everyStack (n: nat) (lst: list Entry): list (Stack n).
      refine (flatMap (dedup lst) (fun e =>
        match e with
        | stackEntry n' r =>
          if (Nat.eq_dec n n') then Some (convert r _) else None
        | _ => None
        end)); subst; abstract intuition.
    Defined.
  End Parsing.

  (* Macroscopic Conversion Methods *)
  Definition optionToList {A} (o: option A): list A :=
    match o with
    | Some a => [a]
    | None => []
    end.

  Definition convertStatement (statement: Qhasm.QhasmStatement): list string :=
    match statement with
    | QAssign a => optionToList (assignmentToString a)
    | QOp o => optionToList (operationToString o)
    | QJmp c l =>
      match (conditionalToString c) with
      | (s1, s2) =>
        let s' := ("goto lbl" ++ l ++ " if " ++ s2)%string in
        [s1; s']
      end
    | QLabel l => [("lbl" ++ l ++ ": ")%string]
    end.

  Definition convertProgramPrologue (prog: Qhasm.Program): list string :=
    [EmptyString].

  Definition convertProgramEpilogue (prog: Qhasm.Program): list string :=
    [EmptyString].

  Definition convertProgram (prog: Qhasm.Program): option string :=
    None.

  Lemma convert_spec: forall a a' b b' prog prog',
    convertProgram prog = Some prog' ->
    convertState a = Some a' -> convertState b = Some b' ->
    QhasmString.evaluatesTo prog' a b <-> Qhasm.evaluatesTo prog a' b'.
  Admitted.

End StringConversion.
