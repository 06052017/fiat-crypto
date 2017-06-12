Require Import Coq.ZArith.ZArith.
Require Import Coq.Lists.List.
Local Open Scope Z_scope.

Require Import Crypto.Arithmetic.Core.
Require Import Crypto.Util.FixedWordSizes.
Require Import Crypto.Specific.Karatsuba.
Require Import Crypto.Arithmetic.PrimeFieldTheorems.
Require Import Crypto.Util.Tuple Crypto.Util.Sigma Crypto.Util.Sigma.MapProjections Crypto.Util.Sigma.Lift Crypto.Util.Notations Crypto.Util.ZRange Crypto.Util.BoundedWord.
Require Import Crypto.Util.Tactics.Head.
Require Import Crypto.Util.Tactics.MoveLetIn.
Import ListNotations.

Require Import Crypto.Specific.IntegrationTestTemporaryMiscCommon.

Require Import Crypto.Compilers.Z.Bounds.Pipeline.

Section BoundedField25p5.
  Local Coercion Z.of_nat : nat >-> Z.

  Let limb_widths := Eval vm_compute in (List.map (fun i => Z.log2 (wt (S i) / wt i)) (seq 0 sz)).
  Let length_lw := Eval compute in List.length limb_widths.

  Local Notation b_of exp := {| lower := 0 ; upper := 2^exp + 2^(exp-3) |}%Z (only parsing). (* max is [(0, 2^(exp+2) + 2^exp + 2^(exp-1) + 2^(exp-3) + 2^(exp-4) + 2^(exp-5) + 2^(exp-6) + 2^(exp-10) + 2^(exp-12) + 2^(exp-13) + 2^(exp-14) + 2^(exp-15) + 2^(exp-17) + 2^(exp-23) + 2^(exp-24))%Z] *)
  (* The definition [bounds_exp] is a tuple-version of the
     limb-widths, which are the [exp] argument in [b_of] above, i.e.,
     the approximate base-2 exponent of the bounds on the limb in that
     position. *)
  Let bounds_exp : Tuple.tuple Z length_lw
    := Eval compute in
        Tuple.from_list length_lw limb_widths eq_refl.
  Let bounds : Tuple.tuple zrange length_lw
    := Eval compute in
        Tuple.map (fun e => b_of e) bounds_exp.

  Let lgbitwidth := Eval compute in (Z.to_nat (Z.log2_up (List.fold_right Z.max 0 limb_widths))).
  Let bitwidth := Eval compute in (2^lgbitwidth)%nat.
  Let feZ : Type := tuple Z sz.
  Let feW : Type := tuple (wordT lgbitwidth) sz.
  Let feBW : Type := BoundedWord sz bitwidth bounds.
  Let phi : feBW -> F m :=
    fun x => B.Positional.Fdecode wt (BoundedWordToZ _ _ _ x).

  (* TODO : change this to field once field isomorphism happens *)
  Definition mul :
    { mul : feBW -> feBW -> feBW
    | forall a b, phi (mul a b) = F.mul (phi a) (phi b) }.
  Proof.
    lazymatch goal with
    | [ |- { f | forall a b, ?phi (f a b) = @?rhs a b } ]
      => apply lift2_sig with (P:=fun a b f => phi f = rhs a b)
    end.
    intros a b.
    eexists_sig_etransitivity. all:cbv [phi].
    rewrite <- (proj2_sig mul_sig).
    symmetry; rewrite <- (proj2_sig carry_sig); symmetry.
    set (carry_mulZ := fun a b => proj1_sig carry_sig (proj1_sig mul_sig a b)).
    change (proj1_sig carry_sig (proj1_sig mul_sig ?a ?b)) with (carry_mulZ a b).
    context_to_dlet_in_rhs carry_mulZ.
    cbv beta iota delta [carry_mulZ proj1_sig mul_sig carry_sig fst snd runtime_add runtime_and runtime_mul runtime_opp runtime_shr sz].
    reflexivity.
    sig_dlet_in_rhs_to_context.
    apply (fun f => proj2_sig_map (fun THIS_NAME_MUST_NOT_BE_UNDERSCORE_TO_WORK_AROUND_CONSTR_MATCHING_ANAOMLIES___BUT_NOTE_THAT_IF_THIS_NAME_IS_LOWERCASE_A___THEN_REIFICATION_STACK_OVERFLOWS___AND_I_HAVE_NO_IDEA_WHATS_GOING_ON p => f_equal f p)).
    (* jgross start here! *)
    (*Set Ltac Profiling.*)
    (*Open Scope zrange_scope.
    assert (Interpretation.Bounds.is_tighter_thanb
              (T:=Syntax.tuple (Syntax.Tbase Syntax.TZ) 8)
              (r[0 ~> 72057594037927935]%zrange, r[0 ~> 72057594037927935]%zrange, r[0 ~> 72057594037927935]%zrange,
               r[0 ~> 102363547501837588311535505879802992345435751778060049012811372691468]%zrange, r[0 ~> 72057594037927935]%zrange,
               r[0 ~> 19714502134749424271321677013450763]%zrange, r[0 ~> 72057594037927935]%zrange, r[0 ~> 72057594037927935]%zrange)
              (r[0 ~> 81064793292668928]%zrange, r[0 ~> 81064793292668928]%zrange, r[0 ~> 81064793292668928]%zrange,
               r[0 ~> 81064793292668928]%zrange, r[0 ~> 81064793292668928]%zrange, r[0 ~> 81064793292668928]%zrange,
               r[0 ~> 81064793292668928]%zrange, r[0 ~> 81064793292668928]%zrange) = true).
    cbv [Interpretation.Bounds.is_tighter_thanb Relations.interp_flat_type_relb_pointwise Relations.interp_flat_type_rel_pointwise_gen_Prop Syntax.tuple Syntax.tuple' fst snd].*)
    Ltac ReflectiveTactics.solve_side_conditions ::= idtac.
    Time refine_reflectively.
    Import ReflectiveTactics.
    { Time do_reify. }
    Import Compilers.Syntax.
    Require Import CNotations.
    Require Import Crypto.Util.Tactics.SubstLet.
    Require Import Crypto.Util.Tactics.UnifyAbstractReflexivity.
    { Time unify_abstract_vm_compute_rhs_reflexivity. }
    { Time unify_abstract_vm_compute_rhs_reflexivity. }
    { Time unify_abstract_vm_compute_rhs_reflexivity. }
    { Time unify_abstract_vm_compute_rhs_reflexivity. }
    { Time unify_abstract_vm_compute_rhs_reflexivity. }
    { Time unify_abstract_rhs_reflexivity. }
    { Show. Time unify_abstract_renamify_rhs_reflexivity. }
    { Time shelve; subst_let; clear; abstract vm_cast_no_check (eq_refl true). }
    { Time shelve; subst_let; clear; vm_compute; reflexivity. }
    { Time shelve; unify_abstract_compute_rhs_reflexivity. }
    { Time shelve; unify_abstract_cbv_interp_rhs_reflexivity. }
    { Time abstract handle_bounds_from_hyps. }
    { Time handle_boundedness_side_condition. }
    Unshelve.
    all:shelve_unifiable.
    cbv [Interpretation.Bounds.is_tighter_thanb Relations.interp_flat_type_relb_pointwise Relations.interp_flat_type_rel_pointwise_gen_Prop Syntax.tuple Syntax.tuple' fst snd codomain bounds Interpretation.Bounds.is_tighter_thanb'].
    (*Show Ltac Profile.*)
  Time Admitted.

End BoundedField25p5.
