(** * Interpretation of PHOAS syntax for expression trees on ℤ *)
Require Import Coq.ZArith.ZArith.
Require Import Crypto.Reflection.Z.Syntax.
Require Import Crypto.Reflection.Syntax.
Require Import Crypto.ModularArithmetic.ModularBaseSystemListZOperations.
Require Import Crypto.Util.Equality.
Require Import Crypto.Util.ZUtil.
Require Import Crypto.Util.Option.
Require Import Crypto.Util.Bool.
Require Import Crypto.Util.Tactics.
Require Import Bedrock.Word.
Require Import Crypto.Util.WordUtil.
Export Reflection.Syntax.Notations.

Local Notation eta x := (fst x, snd x).
Local Notation eta3 x := (eta (fst x), snd x).
Local Notation eta4 x := (eta3 (fst x), snd x).

Module Z.
  Definition interp_base_type (t : base_type) : Type := interp_base_type t.
  Definition interp_op {src dst} (f : op src dst) : interp_flat_type interp_base_type src -> interp_flat_type interp_base_type dst
    := interp_op src dst f.
End Z.

Module Word64.
  Definition bit_width : nat := 64.
  Definition word64 := word bit_width.
  Delimit Scope word64_scope with word64.
  Bind Scope word64_scope with word64.

  Definition word64ToZ (x : word64) : Z
    := Z.of_N (wordToN x).
  Definition ZToWord64 (x : Z) : word64
    := NToWord _ (Z.to_N x).

  Ltac fold_Word64_Z :=
    repeat match goal with
           | [ |- context G[NToWord bit_width (Z.to_N ?x)] ]
             => let G' := context G [ZToWord64 x] in change G'
           | [ |- context G[Z.of_N (wordToN ?x)] ]
             => let G' := context G [word64ToZ x] in change G'
           | [ H : context G[NToWord bit_width (Z.to_N ?x)] |- _ ]
             => let G' := context G [ZToWord64 x] in change G' in H
           | [ H : context G[Z.of_N (wordToN ?x)] |- _ ]
             => let G' := context G [word64ToZ x] in change G' in H
           end.

  Create HintDb push_word64ToZ discriminated.
  Hint Extern 1 => progress autorewrite with push_word64ToZ in * : push_word64ToZ.

  Lemma bit_width_pos : (0 < Z.of_nat bit_width)%Z.
  Proof. simpl; omega. Qed.

  Ltac arith := solve [ omega | auto using bit_width_pos with zarith ].

  Lemma word64ToZ_bound w : (0 <= word64ToZ w < 2^Z.of_nat bit_width)%Z.
  Proof.
    pose proof (wordToNat_bound w) as H.
    apply Nat2Z.inj_lt in H.
    rewrite Zpow_pow2, Z2Nat.id in H by (apply Z.pow_nonneg; omega).
    unfold word64ToZ.
    rewrite wordToN_nat, nat_N_Z; omega.
  Qed.

  Lemma word64ToZ_log_bound w : (0 <= word64ToZ w /\ Z.log2 (word64ToZ w) < Z.of_nat bit_width)%Z.
  Proof.
    pose proof (word64ToZ_bound w) as H.
    destruct (Z_zerop (word64ToZ w)) as [H'|H'].
    { rewrite H'; simpl; omega. }
    { split; [ | apply Z.log2_lt_pow2 ]; try omega. }
  Qed.

  Lemma ZToWord64_word64ToZ (x : word64) : ZToWord64 (word64ToZ x) = x.
  Proof.
    unfold ZToWord64, word64ToZ.
    rewrite N2Z.id, NToWord_wordToN.
    reflexivity.
  Qed.
  Hint Rewrite ZToWord64_word64ToZ : push_word64ToZ.

  Lemma word64ToZ_ZToWord64 (x : Z) : (0 <= x < 2^Z.of_nat bit_width)%Z -> word64ToZ (ZToWord64 x) = x.
  Proof.
    unfold ZToWord64, word64ToZ; intros [H0 H1].
    pose proof H1 as H1'; apply Z2Nat.inj_lt in H1'; [ | omega.. ].
    rewrite <- Z.pow_Z2N_Zpow in H1' by omega.
    replace (Z.to_nat 2) with 2%nat in H1' by reflexivity.
    rewrite wordToN_NToWord_idempotent, Z2N.id by (omega || auto using bound_check_nat_N).
    reflexivity.
  Qed.
  Hint Rewrite word64ToZ_ZToWord64 using arith : push_word64ToZ.

  Definition add : word64 -> word64 -> word64 := @wplus _.
  Definition sub : word64 -> word64 -> word64 := @wminus _.
  Definition mul : word64 -> word64 -> word64 := @wmult _.
  Definition shl : word64 -> word64 -> word64 := @wordBin N.shiftl _.
  Definition shr : word64 -> word64 -> word64 := @wordBin N.shiftr _.
  Definition land : word64 -> word64 -> word64 := @wand _.
  Definition lor : word64 -> word64 -> word64 := @wor _.
  Definition neg : word64 -> word64 -> word64 (* TODO: FIXME? *)
    := fun x y => NToWord _ (Z.to_N (ModularBaseSystemListZOperations.neg (Z.of_N (wordToN x)) (Z.of_N (wordToN y)))).
  Definition cmovne : word64 -> word64 -> word64 -> word64 -> word64 (* TODO: FIXME? *)
    := fun x y z w => NToWord _ (Z.to_N (ModularBaseSystemListZOperations.cmovne (Z.of_N (wordToN x)) (Z.of_N (wordToN x)) (Z.of_N (wordToN z)) (Z.of_N (wordToN w)))).
  Definition cmovle : word64 -> word64 -> word64 -> word64 -> word64 (* TODO: FIXME? *)
    := fun x y z w => NToWord _ (Z.to_N (ModularBaseSystemListZOperations.cmovl (Z.of_N (wordToN x)) (Z.of_N (wordToN x)) (Z.of_N (wordToN z)) (Z.of_N (wordToN w)))).
  Infix "+" := add : word64_scope.
  Infix "-" := sub : word64_scope.
  Infix "*" := mul : word64_scope.
  Infix "<<" := shl : word64_scope.
  Infix ">>" := shr : word64_scope.
  Infix "&'" := land : word64_scope.

  Local Ltac w64ToZ_t :=
    intros;
    try match goal with
        | [ |- ?wordToZ (?op ?x ?y) = _ ]
          => cbv [wordToZ op] in *
        end;
    autorewrite with push_Zto_N push_Zof_N push_wordToN; try reflexivity.

  Local Notation bounds_2statement wop Zop
    := (forall x y,
           (0 <= Zop (word64ToZ x) (word64ToZ y)
            -> Z.log2 (Zop (word64ToZ x) (word64ToZ y)) < Z.of_nat bit_width
            -> word64ToZ (wop x y) = (Zop (word64ToZ x) (word64ToZ y)))%Z).

  Lemma word64ToZ_add : bounds_2statement add Z.add. Proof. w64ToZ_t. Qed.
  Lemma word64ToZ_sub : bounds_2statement sub Z.sub. Proof. w64ToZ_t. Qed.
  Lemma word64ToZ_mul : bounds_2statement mul Z.mul. Proof. w64ToZ_t. Qed.
  Lemma word64ToZ_shl : bounds_2statement shl Z.shiftl.
  Proof. w64ToZ_t. admit. Admitted.
  Lemma word64ToZ_shr : bounds_2statement shr Z.shiftr.
  Proof. admit. Admitted.
  Lemma word64ToZ_land : bounds_2statement land Z.land.
  Proof. w64ToZ_t. Qed.
  Lemma word64ToZ_lor : bounds_2statement lor Z.lor.
  Proof. w64ToZ_t. Qed.

  Definition interp_base_type (t : base_type) : Type
    := match t with
       | TZ => word64
       end.
  Definition interp_op {src dst} (f : op src dst) : interp_flat_type interp_base_type src -> interp_flat_type interp_base_type dst
    := match f in op src dst return interp_flat_type interp_base_type src -> interp_flat_type interp_base_type dst with
       | Add => fun xy => fst xy + snd xy
       | Sub => fun xy => fst xy - snd xy
       | Mul => fun xy => fst xy * snd xy
       | Shl => fun xy => fst xy << snd xy
       | Shr => fun xy => fst xy >> snd xy
       | Land => fun xy => land (fst xy) (snd xy)
       | Lor => fun xy => lor (fst xy) (snd xy)
       | Neg => fun xy => neg (fst xy) (snd xy)
       | Cmovne => fun xyzw => let '(x, y, z, w) := eta4 xyzw in cmovne x y z w
       | Cmovle => fun xyzw => let '(x, y, z, w) := eta4 xyzw in cmovle x y z w
       end%word64.

  Definition of_Z ty : Z.interp_base_type ty -> interp_base_type ty
    := match ty return Z.interp_base_type ty -> interp_base_type ty with
       | TZ => ZToWord64
       end.
  Definition to_Z ty : interp_base_type ty -> Z.interp_base_type ty
    := match ty return interp_base_type ty -> Z.interp_base_type ty with
       | TZ => word64ToZ
       end.

  Module Export Rewrites.
    Ltac word64_util_arith := omega.

    Hint Rewrite word64ToZ_add using word64_util_arith : push_word64ToZ.
    Hint Rewrite <- word64ToZ_add using word64_util_arith : pull_word64ToZ.
    Hint Rewrite word64ToZ_sub using word64_util_arith : push_word64ToZ.
    Hint Rewrite <- word64ToZ_sub using word64_util_arith : pull_word64ToZ.
    Hint Rewrite word64ToZ_mul using word64_util_arith : push_word64ToZ.
    Hint Rewrite <- word64ToZ_mul using word64_util_arith : pull_word64ToZ.
    Hint Rewrite word64ToZ_shl using word64_util_arith : push_word64ToZ.
    Hint Rewrite <- word64ToZ_shl using word64_util_arith : pull_word64ToZ.
    Hint Rewrite word64ToZ_shr using word64_util_arith : push_word64ToZ.
    Hint Rewrite <- word64ToZ_shr using word64_util_arith : pull_word64ToZ.
    Hint Rewrite word64ToZ_land using word64_util_arith : push_word64ToZ.
    Hint Rewrite <- word64ToZ_land using word64_util_arith : pull_word64ToZ.
    Hint Rewrite word64ToZ_lor using word64_util_arith : push_word64ToZ.
    Hint Rewrite <- word64ToZ_lor using word64_util_arith : pull_word64ToZ.
  End Rewrites.
End Word64.

Module ZBounds.
  Record bounds := { lower : Z ; upper : Z }.
  Bind Scope bounds_scope with bounds.
  Definition t := option bounds. (* TODO?: Separate out the bounds computation from the overflow computation? e.g., have [safety := in_bounds | overflow] and [t := bounds * safety]? *)
  Bind Scope bounds_scope with t.
  Local Coercion Z.of_nat : nat >-> Z.
  Definition word64ToBounds (x : Word64.word64) : t
    := let v := Word64.word64ToZ x in Some {| lower := v ; upper := v |}.
  Definition SmartBuildBounds (l u : Z)
    := if ((0 <=? l) && (Z.log2 u <? Word64.bit_width))%Z%bool
       then Some {| lower := l ; upper := u |}
       else None.
  Definition t_map2 (f : Z -> Z -> Z -> Z -> bounds) (x y : t)
    := match x, y with
       | Some (Build_bounds lx ux), Some (Build_bounds ly uy)
         => match f lx ly ux uy with
            | Build_bounds l u
              => SmartBuildBounds l u
            end
       | _, _ => None
       end%Z.

  Definition add : t -> t -> t
    := t_map2 (fun lx ly ux uy => {| lower := lx + ly ; upper := ux + uy |}).
  Definition sub : t -> t -> t
    := t_map2 (fun lx ly ux uy => {| lower := lx - uy ; upper := ux - ly |}).
  Definition mul : t -> t -> t
    := t_map2 (fun lx ly ux uy => {| lower := lx * ly ; upper := ux * uy |}).
  Definition shl : t -> t -> t
    := t_map2 (fun lx ly ux uy => {| lower := lx << ly ; upper := ux << uy |}).
  Definition shr : t -> t -> t
    := t_map2 (fun lx ly ux uy => {| lower := lx >> uy ; upper := ux >> ly |}).
  Definition land : t -> t -> t
    := t_map2 (fun lx ly ux uy => {| lower := 0 ; upper := Z.min ux uy |}).
  Definition lor : t -> t -> t
    := t_map2 (fun lx ly ux uy => {| lower := Z.max lx ly;
                                     upper := 2^(Z.max (Z.log2 (ux+1)) (Z.log2 (uy+1))) - 1 |}).
  Definition neg : t -> t -> t
    := fun int_width v
       => match int_width, v with
          | Some (Build_bounds lint_width uint_width), Some (Build_bounds lb ub)
            => if ((0 <=? lint_width) && (uint_width <=? Word64.bit_width))%Z%bool
               then Some (let might_be_one := ((lb <=? 1) && (1 <=? ub))%Z%bool in
                          let must_be_one := ((lb =? 1) && (ub =? 1))%Z%bool in
                          if must_be_one
                          then {| lower := Z.ones lint_width ; upper := Z.ones uint_width |}
                          else if might_be_one
                               then {| lower := 0 ; upper := Z.ones uint_width |}
                               else {| lower := 0 ; upper := 0 |})
               else None
          | _, _ => None
          end.
  Definition cmovne (x y r1 r2 : t) : t
    := t_map2 (fun lr1 lr2 ur1 ur2 => {| lower := Z.min lr1 lr2 ; upper := Z.max ur1 ur2 |}) r1 r2.
  Definition cmovle (x y r1 r2 : t) : t
    := t_map2 (fun lr1 lr2 ur1 ur2 => {| lower := Z.min lr1 lr2 ; upper := Z.max ur1 ur2 |}) r1 r2.

  Module Export Notations.
    Delimit Scope bounds_scope with bounds.
    Notation "b[ l ~> u ]" := {| lower := l ; upper := u |} : bounds_scope.
    Infix "+" := add : bounds_scope.
    Infix "-" := sub : bounds_scope.
    Infix "*" := mul : bounds_scope.
    Infix "<<" := shl : bounds_scope.
    Infix ">>" := shr : bounds_scope.
    Infix "&'" := land : bounds_scope.
  End Notations.

  Definition interp_base_type (ty : base_type) : Type
    := match ty with
       | TZ => t
       end.
  Definition interp_op {src dst} (f : op src dst) : interp_flat_type interp_base_type src -> interp_flat_type interp_base_type dst
    := match f in op src dst return interp_flat_type interp_base_type src -> interp_flat_type interp_base_type dst with
       | Add => fun xy => fst xy + snd xy
       | Sub => fun xy => fst xy - snd xy
       | Mul => fun xy => fst xy * snd xy
       | Shl => fun xy => fst xy << snd xy
       | Shr => fun xy => fst xy >> snd xy
       | Land => fun xy => land (fst xy) (snd xy)
       | Lor => fun xy => lor (fst xy) (snd xy)
       | Neg => fun xy => neg (fst xy) (snd xy)
       | Cmovne => fun xyzw => let '(x, y, z, w) := eta4 xyzw in cmovne x y z w
       | Cmovle => fun xyzw => let '(x, y, z, w) := eta4 xyzw in cmovle x y z w
       end%bounds.

  Definition of_word64 ty : Word64.interp_base_type ty -> interp_base_type ty
    := match ty return Word64.interp_base_type ty -> interp_base_type ty with
       | TZ => word64ToBounds
       end.

  Ltac inversion_bounds :=
    let lower := (eval cbv [lower] in (fun x => lower x)) in
    let upper := (eval cbv [upper] in (fun y => upper y)) in
    repeat match goal with
           | [ H : _ = _ :> bounds |- _ ]
             => pose proof (f_equal lower H); pose proof (f_equal upper H); clear H;
                cbv beta iota in *
           | [ H : _ = _ :> t |- _ ]
             => unfold t in H; inversion_option
           end.
End ZBounds.

Module BoundedWord64.
  Record BoundedWord :=
    { lower : Z ; value : Word64.word64 ; upper : Z ;
      in_bounds : (0 <= lower /\ lower <= Word64.word64ToZ value <= upper /\ Z.log2 upper < Z.of_nat Word64.bit_width)%Z }.
  Bind Scope bounded_word_scope with BoundedWord.
  Definition t := option BoundedWord.
  Bind Scope bounded_word_scope with t.
  Local Coercion Z.of_nat : nat >-> Z.

  Definition interp_base_type (ty : base_type) : Type
    := match ty with
       | TZ => t
       end.

  Definition word64ToBoundedWord (x : Word64.word64) : t.
  Proof.
    refine (let v := Word64.word64ToZ x in
            match Sumbool.sumbool_of_bool (0 <=? v)%Z, Sumbool.sumbool_of_bool (Z.log2 v <? Z.of_nat Word64.bit_width)%Z with
            | left Hl, left Hu
              => Some {| lower := Word64.word64ToZ x ; value := x ; upper := Word64.word64ToZ x |}
            | _, _ => None
            end).
    subst v.
    abstract (Z.ltb_to_lt; repeat split; (assumption || reflexivity)).
  Defined.

  Definition boundedWordToWord64 (x : t) : Word64.word64
    := match x with
       | Some x' => value x'
       | None => Word64.ZToWord64 0
       end.

  Definition of_word64 ty : Word64.interp_base_type ty -> interp_base_type ty
    := match ty return Word64.interp_base_type ty -> interp_base_type ty with
       | TZ => word64ToBoundedWord
       end.
  Definition to_word64 ty : interp_base_type ty -> Word64.interp_base_type ty
    := match ty return interp_base_type ty -> Word64.interp_base_type ty with
       | TZ => boundedWordToWord64
       end.

  Definition of_Z ty : Z.interp_base_type ty -> interp_base_type ty
    := fun x => of_word64 _ (Word64.of_Z _ x).
  Definition to_Z ty : interp_base_type ty -> Z.interp_base_type ty
    := fun x => Word64.to_Z _ (to_word64 _ x).

  Definition BoundedWordToBounds (x : BoundedWord) : ZBounds.bounds
    := {| ZBounds.lower := lower x ; ZBounds.upper := upper x |}.

  Definition to_bounds ty : interp_base_type ty -> ZBounds.interp_base_type ty
    := match ty return interp_base_type ty -> ZBounds.interp_base_type ty with
       | TZ => option_map BoundedWordToBounds
       end.

  Local Ltac build_binop word_op bounds_op :=
    refine (fun x y : t
            => match x, y with
               | Some x, Some y
                 => match bounds_op (Some (BoundedWordToBounds x)) (Some (BoundedWordToBounds y))
                          as bop return bounds_op (Some (BoundedWordToBounds x)) (Some (BoundedWordToBounds y)) = bop -> t
                    with
                    | Some (ZBounds.Build_bounds l u)
                      => let pff := _ in
                         fun pf => Some {| lower := l ; value := word_op (value x) (value y) ; upper := u;
                                           in_bounds := pff pf |}
                    | None => fun _ => None
                    end eq_refl
               | _, _ => None
               end);
    try unfold bounds_op; try unfold word_op;
    cbv [ZBounds.t_map2 BoundedWordToBounds ZBounds.SmartBuildBounds ModularBaseSystemListZOperations.neg].

  Local Ltac build_4op word_op bounds_op :=
    refine (fun x y z w : t
            => match x, y, z, w with
               | Some x, Some y, Some z, Some w
                 => match bounds_op (Some (BoundedWordToBounds x)) (Some (BoundedWordToBounds y))
                                    (Some (BoundedWordToBounds z)) (Some (BoundedWordToBounds w))
                          as bop return bounds_op (Some (BoundedWordToBounds x)) (Some (BoundedWordToBounds y))
                                                  (Some (BoundedWordToBounds z)) (Some (BoundedWordToBounds w))
                                        = bop -> t
                    with
                    | Some (ZBounds.Build_bounds l u)
                      => let pff := _ in
                         fun pf => Some {| lower := l ; value := word_op (value x) (value y) (value z) (value w) ; upper := u;
                                           in_bounds := pff pf |}
                    | None => fun _ => None
                    end eq_refl
               | _, _, _, _ => None
               end);
    try unfold bounds_op; try unfold word_op;
    cbv [ZBounds.t_map2 BoundedWordToBounds ZBounds.SmartBuildBounds cmovne cmovl].

  Axiom proof_admitted : False.
  Local Opaque Word64.bit_width.
  Hint Resolve Z.ones_nonneg : zarith.
  Local Ltac t_start :=
    repeat first [ progress break_match
                 | progress intros
                 | progress subst
                 | progress ZBounds.inversion_bounds
                 | progress inversion_option
                 | progress Word64.fold_Word64_Z
                 | progress autorewrite with bool_congr_setoid in *
                 | progress destruct_head' and
                 | progress Z.ltb_to_lt
                 | assumption
                 | progress destruct_head' BoundedWord; simpl in *
                 | progress autorewrite with push_word64ToZ
                 | progress repeat apply conj
                 | solve [ Word64.arith ]
                 | match goal with
                   | [ |- appcontext[Z.min ?x ?y] ]
                     => apply (Z.min_case_strong x y)
                   | [ |- appcontext[Z.max ?x ?y] ]
                     => apply (Z.max_case_strong x y)
                   end
                 | progress destruct_head' or ].

  Tactic Notation "admit" := abstract case proof_admitted.

  Definition add : t -> t -> t.
  Proof.
    build_binop Word64.add ZBounds.add; t_start;
      admit.
  Defined.

  Definition sub : t -> t -> t.
  Proof.
    build_binop Word64.sub ZBounds.sub; t_start;
      admit.
  Defined.

  Definition mul : t -> t -> t.
  Proof.
    build_binop Word64.mul ZBounds.mul; t_start;
      admit.
  Defined.

  Definition shl : t -> t -> t.
  Proof.
    build_binop Word64.shl ZBounds.shl; t_start;
      admit.
  Defined.

  Definition shr : t -> t -> t.
  Proof.
    build_binop Word64.shr ZBounds.shr; t_start;
      admit.
  Defined.

  Definition land : t -> t -> t.
  Proof.
    build_binop Word64.land ZBounds.land; t_start;
      admit.
  Defined.

  Definition lor : t -> t -> t.
  Proof.
    build_binop Word64.lor ZBounds.lor; t_start;
      admit.
  Defined.

  Definition neg : t -> t -> t.
  Proof. build_binop Word64.neg ZBounds.neg; abstract t_start. Defined.

  Definition cmovne : t -> t -> t -> t -> t.
  Proof. build_4op Word64.cmovne ZBounds.cmovne; abstract t_start. Defined.

  Definition cmovle : t -> t -> t -> t -> t.
  Proof. build_4op Word64.cmovle ZBounds.cmovle; abstract t_start. Defined.

  Local Notation value_binop_correct op opW :=
    (forall x y v, op (Some x) (Some y) = Some v -> value v = opW (value x) (value y))
      (only parsing).

  Definition value_add : value_binop_correct add Word64.add.
  Proof.
  Admitted.

  Module Export Notations.
    Delimit Scope bounded_word_scope with bounded_word.
    Notation "b[ l ~> u ]" := {| lower := l ; upper := u |} : bounded_word_scope.
    Infix "+" := add : bounded_word_scope.
    Infix "-" := sub : bounded_word_scope.
    Infix "*" := mul : bounded_word_scope.
    Infix "<<" := shl : bounded_word_scope.
    Infix ">>" := shr : bounded_word_scope.
    Infix "&'" := land : bounded_word_scope.
  End Notations.

  Definition interp_op {src dst} (f : op src dst) : interp_flat_type interp_base_type src -> interp_flat_type interp_base_type dst
    := match f in op src dst return interp_flat_type interp_base_type src -> interp_flat_type interp_base_type dst with
       | Add => fun xy => fst xy + snd xy
       | Sub => fun xy => fst xy - snd xy
       | Mul => fun xy => fst xy * snd xy
       | Shl => fun xy => fst xy << snd xy
       | Shr => fun xy => fst xy >> snd xy
       | Land => fun xy => land (fst xy) (snd xy)
       | Lor => fun xy => lor (fst xy) (snd xy)
       | Neg => fun xy => neg (fst xy) (snd xy)
       | Cmovne => fun xyzw => let '(x, y, z, w) := eta4 xyzw in cmovne x y z w
       | Cmovle => fun xyzw => let '(x, y, z, w) := eta4 xyzw in cmovle x y z w
       end%bounded_word.
End BoundedWord64.

Module LiftOption.
  Section lift_option.
    Context (T : Type).

    Definition interp_flat_type (t : flat_type base_type)
      := option (interp_flat_type (fun _ => T) t).

    Definition interp_base_type' (t : base_type)
      := match t with
         | TZ => option T
         end.

    Definition of' {ty} : Syntax.interp_flat_type interp_base_type' ty -> interp_flat_type ty
      := @smart_interp_flat_map
           base_type
           interp_base_type' interp_flat_type
           (fun t => match t with TZ => fun x => x end)
           (fun _ _ x y => match x, y with
                           | Some x', Some y' => Some (x', y')
                           | _, _ => None
                           end)
           ty.

    Fixpoint to' {ty} : interp_flat_type ty -> Syntax.interp_flat_type interp_base_type' ty
      := match ty return interp_flat_type ty -> Syntax.interp_flat_type interp_base_type' ty with
         | Tbase TZ => fun x => x
         | Prod A B => fun x => (@to' A (option_map (@fst _ _) x),
                                 @to' B (option_map (@snd _ _) x))
         end.
  End lift_option.
End LiftOption.

Module ZBoundsTuple.
  Definition interp_flat_type (t : flat_type base_type)
    := LiftOption.interp_flat_type ZBounds.bounds t.

  Definition of_ZBounds {ty} : Syntax.interp_flat_type ZBounds.interp_base_type ty -> interp_flat_type ty
    := @LiftOption.of' ZBounds.bounds ty.
  Definition to_ZBounds {ty} : interp_flat_type ty -> Syntax.interp_flat_type ZBounds.interp_base_type ty
    := @LiftOption.to' ZBounds.bounds ty.
End ZBoundsTuple.

Module BoundedWord64Tuple.
  Definition interp_flat_type (t : flat_type base_type)
    := LiftOption.interp_flat_type BoundedWord64.BoundedWord t.

  Definition of_BoundedWord64 {ty} : Syntax.interp_flat_type BoundedWord64.interp_base_type ty -> interp_flat_type ty
    := @LiftOption.of' BoundedWord64.BoundedWord ty.
  Definition to_BoundedWord64 {ty} : interp_flat_type ty -> Syntax.interp_flat_type BoundedWord64.interp_base_type ty
    := @LiftOption.to' BoundedWord64.BoundedWord ty.
End BoundedWord64Tuple.

Module Relations.
  Definition lift_relation {T} (R : BoundedWord64.BoundedWord -> T -> Prop) : BoundedWord64.t -> T -> Prop
    := fun x y => match x with
                  | Some _ => True
                  | None => False
                  end -> match x with
                         | Some x' => R x' y
                         | None => True
                         end.

  Definition related'_Z (x : BoundedWord64.BoundedWord) (y : Z) : Prop
    := Word64.word64ToZ (BoundedWord64.value x) = y.
  Definition related_Z : BoundedWord64.t -> Z -> Prop := lift_relation related'_Z.
  Definition related_Zi t : BoundedWord64.interp_base_type t -> Z.interp_base_type t -> Prop
    := match t with TZ => related_Z end.
  Definition related'_word64 (x : BoundedWord64.BoundedWord) (y : Word64.word64) : Prop
    := BoundedWord64.value x = y.
  Definition related_word64 : BoundedWord64.t -> Word64.word64 -> Prop := lift_relation related'_word64.
  Definition related_word64i t : BoundedWord64.interp_base_type t -> Word64.interp_base_type t -> Prop
    := match t with TZ => related_word64 end.
  Definition related_bounds (x : BoundedWord64.t) (y : ZBounds.t) : Prop
    := match x, y with
       | Some x, Some y
         => BoundedWord64.lower x = ZBounds.lower y /\ BoundedWord64.upper x = ZBounds.upper y
       | Some _, _
         => False
       | None, None => True
       | None, _ => False
       end.
  Definition related_boundsi t : BoundedWord64.interp_base_type t -> ZBounds.interp_base_type t -> Prop
    := match t with TZ => related_bounds end.

  Local Notation related_op R interp_op1 interp_op2
    := (forall (src dst : flat_type base_type) (op : op src dst)
               (sv1 : interp_flat_type _ src) (sv2 : interp_flat_type _ src),
           interp_flat_type_rel_pointwise2 R sv1 sv2 ->
           interp_flat_type_rel_pointwise2 R (interp_op1 _ _ op sv1) (interp_op2 _ _ op sv2))
         (only parsing).
  Local Notation related_const R interp f g
    := (forall (t : base_type) (v : interp t), R t (f t v) (g t v))
         (only parsing).

  Local Ltac related_const_t :=
    let v := fresh in
    let t := fresh in
    intros t v; destruct t; intros; simpl in *; hnf; simpl;
    cbv [BoundedWord64.word64ToBoundedWord related'_Z related'_word64] in *;
    break_innermost_match; simpl;
    first [ tauto
          | Z.ltb_to_lt;
            pose proof (Word64.word64ToZ_log_bound v);
            try omega ].

  Lemma related_Z_const : related_const related_Zi Word64.interp_base_type BoundedWord64.of_word64 Word64.to_Z.
  Proof. related_const_t. Qed.
  Lemma related_bounds_const : related_const related_boundsi Word64.interp_base_type BoundedWord64.of_word64 ZBounds.of_word64.
  Proof. related_const_t. Qed.
  Lemma related_word64_const : related_const related_word64i Word64.interp_base_type BoundedWord64.of_word64 (fun _ x => x).
  Proof. related_const_t. Qed.

  Lemma related_Z_op : related_op related_Zi (@BoundedWord64.interp_op) (@Z.interp_op).
  Proof.
    let op := fresh in intros ?? op; destruct op; simpl.
    repeat first [ progress cbv [related_Z lift_relation related'_Z BoundedWord64.value]
                 | progress intros
                 | progress destruct_head' prod
                 | progress destruct_head' and
                 | progress specialize_by (exact I)
                 | progress subst
                 | progress break_match
                 | progress break_match_hyps
                 | progress simpl @fst in *
                 | progress simpl @snd in *
                 | destruct_head' BoundedWord64.BoundedWord ].
    { cbv [related_Z lift_relation related'_Z].
      intros; break_match.
      unfold related_Z, BoundedWord64.t, lift_relation, related'_Z, BoundedWord64.value.
      match goal with
      | [ H : _ = Some _ |- _ ] => apply BoundedWord64.value_add in H; simpl in H
      end.
      subst.
      apply Word64.word64ToZ_add; auto;
        admit. }
  Admitted.

  Lemma related_bounds_op : related_op related_boundsi (@BoundedWord64.interp_op) (@ZBounds.interp_op).
  Proof. admit. Admitted.
  Lemma related_word64_op : related_op related_word64i (@BoundedWord64.interp_op) (@Word64.interp_op).
  Proof. admit. Admitted.

  Create HintDb interp_related discriminated.
  Hint Resolve related_Z_op related_bounds_op related_word64_op related_Z_const related_bounds_const related_word64_const : interp_related.
End Relations.
