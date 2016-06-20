Require Export Bedrock.Word Bedrock.Nomega.
Require Import NArith NPeano List Sumbool.
Require Import QhasmCommon QhasmEvalCommon QhasmUtil Pseudo State.
Require Export Wordize Vectorize.

Module Conversion.
  Import Pseudo ListNotations StateCommon EvalUtil ListState.

  Hint Unfold setList getList getVar setCarry setCarryOpt getCarry
       getMem setMem overflows.

  Lemma pseudo_var: forall {w s n} x k v b p m c,
      nth_error x k = Some v
    -> pseudoEval (@PVar w s n b (exist _ k p)) (x, m, c) = Some ([v], m, c).
  Proof.
    intros; simpl; autounfold; simpl.
    destruct (nth_error x k); simpl; try inversion H; intuition.
  Qed.

  Lemma pseudo_mem: forall {w s} n v m c x name len index p0 p1,
      TripleM.find (w, name mod n, index mod len)%nat m = Some (@wordToN w v)
    -> pseudoEval (@PMem w s n len (indexize _ p0 name) (indexize _ p1 index)) (x, m, c) = Some ([v], m, c).
  Proof.
    intros; autounfold; simpl.
    unfold getMem; simpl.
    rewrite H; autounfold; simpl.
    rewrite NToWord_wordToN; intuition.
  Qed.

  Lemma pseudo_const: forall {w s n} x v m c,
      pseudoEval (@PConst w s n v) (x, m, c) = Some ([v], m, c).
  Proof. intros; simpl; intuition. Qed.

  Lemma pseudo_plus:
    forall {w s n} (p: @Pseudo w s n 2) x out0 out1 m0 m1 c0 c1,
      pseudoEval p (x, m0, c0) = Some ([out0; out1], m1, c1)
    -> pseudoEval (PBin n Add p) (x, m0, c0) =
        Some ([out0 ^+ out1], m1,
          Some (proj1_sig (bool_of_sumbool
               (overflows w (&out0 + &out1)%N)%w))).
  Proof.
    intros; simpl; rewrite H; simpl.

    pose proof (wordize_plus out0 out1).
    destruct (overflows w _); autounfold; simpl; try rewrite H0;
      try rewrite <- (@Npow2_ignore w (out0 ^+ out1));
      try rewrite NToWord_wordToN; intuition.
  Qed.

  Lemma pseudo_bin:
    forall {w s n} (p: @Pseudo w s n 2) x out0 out1 m0 m1 c0 c1 op,
      op <> Add
    -> pseudoEval p (x, m0, c0) = Some ([out0; out1], m1, c1)
    -> pseudoEval (PBin n op p) (x, m0, c0) =
        Some ([fst (evalIntOp op out0 out1)], m1, c1).
  Proof.
    intros; simpl; rewrite H0; simpl.

    induction op;
      try (contradict H; reflexivity);
      unfold evalIntOp; autounfold; simpl;
      reflexivity.
  Qed.

  Lemma pseudo_and:
    forall {w s n} (p: @Pseudo w s n 2) x out0 out1 m0 m1 c0 c1,
      pseudoEval p (x, m0, c0) = Some ([out0; out1], m1, c1)
    -> pseudoEval (PBin n And p) (x, m0, c0) =
        Some ([out0 ^& out1], m1, c1).
  Proof.
    intros.
    replace (out0 ^& out1) with (fst (evalIntOp And out0 out1)).
    - apply pseudo_bin; intuition; inversion H0.
    - unfold evalIntOp; simpl; intuition.
  Qed.

  Lemma pseudo_awc:
    forall {w s n} (p: @Pseudo w s n 2) x out0 out1 m0 m1 c0 c,
      pseudoEval p (x, m0, c0) = Some ([out0; out1], m1, Some c)
    -> pseudoEval (PCarry n AddWithCarry p) (x, m0, c0) =
        Some ([addWithCarry out0 out1 c], m1,
          Some (proj1_sig (bool_of_sumbool (overflows w
          (&out0 + &out1 + (if c then 1 else 0))%N)%w))).
  Proof.
    intros; simpl; rewrite H; simpl.

    pose proof (wordize_awc out0 out1); unfold evalCarryOp.
    destruct (overflows w ((& out0)%w + (& out1)%w +
                           (if c then 1%N else 0%N)));
      autounfold; simpl; try rewrite H0; intuition.
  Qed.

  Lemma pseudo_shiftr:
    forall {w s n} (p: @Pseudo w s n 1) x out m0 m1 c0 c1 k,
      pseudoEval p (x, m0, c0) = Some ([out], m1, c1)
    -> pseudoEval (PShift n Shr k p) (x, m0, c0) =
        Some ([shiftr out k], m1, c1).
  Proof.
    intros; simpl; rewrite H; autounfold; simpl.
    rewrite wordize_shiftr; rewrite NToWord_wordToN; intuition.
  Qed.

  Lemma pseudo_dual:
    forall {w s n} (p: @Pseudo w s n 1) x out0 out1 m0 m1 c0 c1 k,
      pseudoEval p (x, m0, c0) = Some ([out0; out1], m1, c1)
    -> pseudoEval (PDual n Mult p) (x, m0, c0) =
      Some ([x ^* y; (highBits (n/2) x) ^* (highBits (n/2) y)], m1, c1).
  Proof.
    intros; simpl; rewrite H; autounfold; simpl.
    rewrite wordize_shiftr; rewrite NToWord_wordToN; intuition.
  Qed.

  Lemma pseudo_comb:
    forall {w s n a b} (p0: @Pseudo w s n a) (p1: @Pseudo w s n b)
      input out0 out1 m0 m1 m2 c0 c1 c2,
      pseudoEval p0 (input, m0, c0) = Some (out0, m1, c1)
    -> pseudoEval p1 (input, m1, c1) = Some (out1, m2, c2)
    -> pseudoEval (@PComb w s n _ _ p0 p1) (input, m0, c0) =
        Some (out0 ++ out1, m2, c2).
  Proof.
    intros; autounfold; simpl.
    rewrite H; autounfold; simpl.
    rewrite H0; autounfold; simpl; intuition.
  Qed.

  Lemma pseudo_cons:
    forall {w s n b} (p0: @Pseudo w s n 1) (p1: @Pseudo w s n b)
        (p2: @Pseudo w s n (S b)) input x xs m0 m1 m2 c0 c1 c2,
      pseudoEval p0 (input, m0, c0) = Some ([x], m1, c1)
    -> pseudoEval p1 (input, m1, c1) = Some (xs, m2, c2)
    -> p2 = (@PComb w s n _ _ p0 p1)
    -> pseudoEval p2 (input, m0, c0) = Some (x :: xs, m2, c2).
  Proof.
    intros.
    replace (x :: xs) with ([x] ++ xs) by (simpl; intuition).
    rewrite H1.
    apply (pseudo_comb p0 p1 input _ _ m0 m1 m2 c0 c1 c2); intuition.
  Qed.

  Definition pseudeq {w s} (n m: nat) (f: list (word w) -> list (word w)) : Type := 
    {p: @Pseudo w s n m | forall x: (list (word w)),
      List.length x = n -> exists m' c',
      pseudoEval p (x, TripleM.empty N, None) = Some (f x, m', c')}.

  Definition example (v: list (word 32)) : list (word 32) :=
      [(natToWord _ 1) ^& (nth 0 v (wzero _))].

  Ltac autodestruct :=
    repeat match goal with
    | [H: context[Datatypes.length (cons _ _)] |- _] => simpl in H
    | [H: context[Datatypes.length nil] |- _] => simpl in H
    | [H: S ?a = S ?b |- _] => inversion H; clear H
    | [H: (S ?a) = 0 |- _] => contradict H; intuition
    | [H: 0 = (S ?a) |- _] => contradict H; intuition
    | [H: 0 = 0 |- _] => clear H
    | [x: list ?T |- _] =>
      match goal with
      | [H: context[Datatypes.length x] |- _] => destruct x
      end
    end.

  Definition convert_example: @pseudeq 32 W32 1 1 example.
    repeat eexists; unfold example; autounfold; autodestruct.

    eapply pseudo_and.
    eapply pseudo_cons.
    eapply pseudo_const.
    eapply pseudo_var.

    (* leftovers *)

    instantiate (1 := 0); simpl; intuition.
    reflexivity.

    Grab Existential Variables.

    abstract (simpl; intuition).
    exact None.
  Defined.

  Eval simpl in (proj1_sig convert_example).

End Conversion.

