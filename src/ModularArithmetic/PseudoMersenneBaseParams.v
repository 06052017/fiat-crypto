Require Import ZArith.
Require Import List.
Require Crypto.BaseSystem.
Local Open Scope Z_scope.

Definition sum_firstn l n := fold_right Z.add 0 (firstn n l).

Class PseudoMersenneBaseParams (modulus : Z) := {
  limb_widths : list Z;
  limb_widths_nonneg : forall w, In w limb_widths -> 0 <= w;
  limb_widths_nonnil : limb_widths <> nil;
  limb_widths_good : forall i j, (i + j < length limb_widths)%nat ->
    sum_firstn limb_widths (i + j) <=
    sum_firstn limb_widths i + sum_firstn limb_widths j;
  k : Z;
  c : Z;
  k_matches_limb_widths : sum_firstn limb_widths (length limb_widths) = k;
  modulus_pseudomersenne : modulus = 2^k - c;
  prime_modulus : Znumtheory.prime modulus;
  limb_widths_match_modulus : forall i j,
    (i < length limb_widths)%nat ->
    (j < length limb_widths)%nat ->
    (i + j >= length limb_widths)%nat ->
    let w_sum := sum_firstn limb_widths in
    k + w_sum (i + j - length limb_widths)%nat <= w_sum i + w_sum j
}.
