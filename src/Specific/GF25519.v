Require Import Crypto.ModularArithmetic.ModularBaseSystem.
Require Import Crypto.ModularArithmetic.ModularBaseSystemOpt.
Require Import Crypto.ModularArithmetic.PseudoMersenneBaseParams.
Require Import Crypto.ModularArithmetic.PseudoMersenneBaseParamProofs.
Require Import Coq.Lists.List Crypto.Util.ListUtil.
Require Import Crypto.ModularArithmetic.PrimeFieldTheorems.
Require Import Crypto.Tactics.VerdiTactics.
Require Import Crypto.BaseSystem.
Import ListNotations.
Require Import Coq.ZArith.ZArith Coq.ZArith.Zpower Coq.ZArith.ZArith Coq.ZArith.Znumtheory.
Local Open Scope Z.

(* BEGIN PseudoMersenneBaseParams instance construction. *)

Definition modulus : Z := 2^255 - 19.
Lemma prime_modulus : prime modulus. Admitted.

Instance params25519 : PseudoMersenneBaseParams modulus.
  construct_params prime_modulus 10%nat 255.
Defined.

(* END PseudoMersenneBaseParams instance construction. *)

(* Precompute k and c *)
Definition k_ := Eval compute in k.
Definition c_ := Eval compute in c.

(* Makes Qed not take forever *)
Opaque Z.shiftr Pos.iter Z.div2 Pos.div2 Pos.div2_up Pos.succ Z.land
  Z.of_N Pos.land N.ldiff Pos.pred_N Pos.pred_double Z.opp Z.mul Pos.mul
  Let_In digits Z.add Pos.add Z.pos_sub.

Local Open Scope nat_scope.
Lemma GF25519Base25Point5_mul_reduce_formula :
  forall f0 f1 f2 f3 f4 f5 f6 f7 f8 f9
    g0 g1 g2 g3 g4 g5 g6 g7 g8 g9,
    {ls | forall f g, rep [f0;f1;f2;f3;f4;f5;f6;f7;f8;f9] f
                      -> rep [g0;g1;g2;g3;g4;g5;g6;g7;g8;g9] g
                      -> rep ls (f*g)%F}.
Proof.
  eexists; intros ? ? Hf Hg.
  pose proof (carry_mul_opt_correct k_ c_ (eq_refl k_) (eq_refl c_) [0;9;8;7;6;5;4;3;2;1;0]_ _ _ _ Hf Hg) as Hfg.
  compute_formula.
Time Defined.

Extraction "/tmp/test.ml" GF25519Base25Point5_mul_reduce_formula.
(* It's easy enough to use extraction to get the proper nice-looking formula.
 * More Ltac acrobatics will be needed to get out that formula for further use in Coq.
 * The easiest fix will be to make the proof script above fully automated,
 * using [abstract] to contain the proof part. *)


Lemma GF25519Base25Point5_add_formula :
  forall f0 f1 f2 f3 f4 f5 f6 f7 f8 f9
    g0 g1 g2 g3 g4 g5 g6 g7 g8 g9,
    {ls | forall f g, rep [f0;f1;f2;f3;f4;f5;f6;f7;f8;f9] f
                   -> rep [g0;g1;g2;g3;g4;g5;g6;g7;g8;g9] g
                   -> rep ls (f + g)%F}.
Proof.
  eexists.
  intros f g Hf Hg.
  pose proof (add_opt_rep _ _ _ _ Hf Hg) as Hfg.
  compute_formula.
Defined.