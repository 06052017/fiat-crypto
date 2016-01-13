
Require Import BinInt BinNat ZArith Znumtheory.
Require Import Eqdep_dec.
Require Import Tactics.VerdiTactics.

Section GaloisPreliminaries.
  Definition Prime := {x: Z | prime x}.

  Definition primeToZ(x: Prime) := proj1_sig x.
  Coercion primeToZ: Prime >-> Z.
End GaloisPreliminaries.

Module Type Modulus.
  Parameter modulus: Prime.
End Modulus.

Module Galois (M: Modulus).
  Import M.

  Definition GF := {x: Z | x = x mod modulus}.
  Definition GFToZ(x: GF) := proj1_sig x.
  Coercion GFToZ: GF >-> Z.

  Definition ZToGF (x: Z) : if ((0 <=? x) && (x <? modulus))%bool then GF else True.
    break_if; [|trivial].
    exists x.
    destruct (Bool.andb_true_eq _ _ (eq_sym Heqb)); clear Heqb.
    erewrite Zmod_small; [trivial|].
    intuition.
    - rewrite <- Z.leb_le; auto.
    - rewrite <- Z.ltb_lt; auto.
  Defined.

  Theorem gf_eq: forall (x y: GF), x = y <-> GFToZ x = GFToZ y.
  Proof.
    destruct x, y; intuition; simpl in *; try congruence.
    subst x.
    f_equal.
    apply UIP_dec.
    apply Z.eq_dec.
  Qed.

  (* Elementary operations *)
  Definition GFzero: GF.
    exists 0.
    abstract trivial.
  Defined.

  Definition GFone: GF.
    exists 1.
    abstract( symmetry; apply Zmod_small; intuition;
              destruct modulus; simpl;
              apply prime_ge_2 in p; intuition).
  Defined.

  Lemma GFone_nonzero : GFone <> GFzero.
  Proof.
    unfold GFone, GFzero.
    intuition; solve_by_inversion.
  Qed.
  Hint Resolve GFone_nonzero.

  Definition GFplus(x y: GF): GF.
    exists ((x + y) mod modulus);
    abstract (rewrite Zmod_mod; trivial).
  Defined.

  Definition GFminus(x y: GF): GF.
    exists ((x - y) mod modulus).
    abstract (rewrite Zmod_mod; trivial).
  Defined.

  Definition GFmult(x y: GF): GF.
    exists ((x * y) mod modulus).
    abstract (rewrite Zmod_mod; trivial).
  Defined.

  Definition GFopp(x: GF): GF := GFminus GFzero x.

  (* Totient Preliminaries *)
  Fixpoint GFexp' (x: GF) (power: positive) :=
    match power with
    | xH => x
    | xO power' => GFexp' (GFmult x x) power'
    | xI power' => GFmult x (GFexp' (GFmult x x) power')
    end.

  Definition GFexp (x: GF) (power: N): GF :=
    match power with
    | N0 => GFone
    | Npos power' => GFexp' x power'
    end.

  (* Inverses + division derived from the existence of a totient *)
  Definition isTotient(e: N) := N.gt e 0 /\ forall g: GF, g <> GFzero ->
    GFexp g e = GFone.

  Definition Totient := {e: N | isTotient e}.

  Theorem fermat_little_theorem: isTotient (N.pred (Z.to_N modulus)).
  Admitted.

  Definition totient : Totient.
    exists (N.pred (Z.to_N modulus)).
    exact fermat_little_theorem.
  Defined.

  Definition totientToN(x: Totient) := proj1_sig x.
  Coercion totientToN: Totient >-> N.

  Definition GFinv(x: GF): GF := GFexp x (N.pred totient).

  Definition GFdiv(x y: GF): GF := GFmult x (GFinv y).

End Galois.
