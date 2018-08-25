Require Import Coq.ZArith.ZArith.
Require Import Crypto.Util.Tactics.BreakMatch.
Require Import Crypto.Util.ZUtil.ZSimplify.
Require Import Crypto.Util.ZUtil.ZSimplify.Core.
Require Import Crypto.Util.ZUtil.ZSimplify.Simple.
Require Import Crypto.Util.ZUtil.Definitions.
Require Import Crypto.Util.ZUtil.Tactics.LtbToLt.
Require Import Crypto.Util.ZUtil.Hints.PullPush.
Local Open Scope Z_scope.

Module Z.
  Lemma rshi_correct_full : forall s a b n,
    Z.rshi s a b n = if (0 <=? n)
                     then ((b + a * s) / 2 ^ n) mod s
                     else ((b + a * s) * 2 ^ (-n)) mod s.
  Proof.
    cbv [Z.rshi]; intros. pose proof (Z.log2_nonneg s).
    destruct (Decidable.dec (0 <= n)), (Z_zerop s); subst;
      break_match;
      repeat match goal with
             | H : _ = s |- _ => rewrite H
             | _ => rewrite Z.land_ones by auto with zarith
             | _ => progress Z.ltb_to_lt
             | _ => progress autorewrite with Zshift_to_pow push_Zpow zsimplify_const
             | _ => reflexivity
             | _ => omega
             end.
  Qed.
  Lemma rshi_correct : forall s a b n, 0 <= n -> s <> 0 ->
                                  Z.rshi s a b n = ((b + a * s) / 2 ^ n) mod s.
  Proof. intros; rewrite rshi_correct_full; break_match; Z.ltb_to_lt; omega. Qed.
End Z.
