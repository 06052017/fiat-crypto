Require Import Coq.ZArith.ZArith Coq.ZArith.Znumtheory.
Require Import Coq.Numbers.Natural.Peano.NPeano.
Require Import Crypto.CompleteEdwardsCurve.CompleteEdwardsCurveTheorems.
Require Import Crypto.ModularArithmetic.PrimeFieldTheorems Crypto.ModularArithmetic.ModularArithmeticTheorems.
Require Import Bedrock.Word.
Require Import Crypto.Tactics.VerdiTactics.
Require Import Crypto.Spec.Encoding.
Require Import Crypto.Util.ZUtil.
Require Import Crypto.Spec.ModularWordEncoding.


Local Open Scope F_scope.

Section SignBit.
  Context {m : Z} {prime_m : prime m} {two_lt_m : (2 < m)%Z} {sz : nat} {bound_check : (Z.to_nat m < 2 ^ sz)%nat}.
  Lemma m_pos : (0 < m)%Z.
  Proof.
    apply prime_ge_2 in prime_m; omega.
  Qed.

  Arguments modular_word_encoding {m} {sz} m_pos bound_check.
  Let Fm_encoding := modular_word_encoding m_pos bound_check.

  Definition sign_bit (x : F m) :=
  match (@enc _ _ Fm_encoding x) with
    | Word.WO => false
    | Word.WS b _ w' => b
  end.

  Lemma sign_bit_parity : forall x, sign_bit x = Z.odd x.
  Proof.
    unfold sign_bit; intros.
    unfold Fm_encoding, enc, modular_word_encoding, Fm_enc.
    pose proof (shatter_word (NToWord sz (Z.to_N x))) as shatter.
    case_eq sz; intros; subst; rewrite shatter.
    + pose proof (prime_ge_2 m prime_m).
      simpl in bound_check.
      assert (m < 1)%Z by (apply Z2Nat.inj_lt; try omega; assumption).
      omega.
    + pose proof (FieldToZ_range x m_pos).  
      destruct (FieldToZ x); auto.
      - destruct p; auto.
      - pose proof (Pos2Z.neg_is_neg p); omega.
   Qed.

  Lemma sign_bit_zero : sign_bit 0 = false.
  Proof.
    rewrite sign_bit_parity; auto.
  Qed.

  Lemma sign_bit_opp : forall (x : F m), x <> 0 -> negb (sign_bit x) = sign_bit (opp x).
  Proof.
    intros.
    pose proof sign_bit_zero as sign_zero.
    rewrite !sign_bit_parity in *.
    pose proof (F_opp_spec x) as opp_spec_x.
    apply F_eq in opp_spec_x.
    rewrite FieldToZ_add in opp_spec_x.
    rewrite <-opp_spec_x, Z_odd_mod in sign_zero by omega.
    replace (Z.odd m) with true in sign_zero by (destruct (ZUtil.prime_odd_or_2 m prime_m); auto || omega).
    rewrite Z.odd_add, F_FieldToZ_add_opp, Z.div_same, Bool.xorb_true_r in sign_zero by assumption || omega.
    apply Bool.xorb_eq.
    rewrite <-Bool.negb_xorb_l.
    assumption.
  Qed.

End SignBit.