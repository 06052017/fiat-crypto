
Require Import Bedrock.Word Bedrock.Nomega.
Require Import NArith PArith Ndigits Compare_dec Arith.
Require Import ProofIrrelevance.
Require Import Ring.
Require Import Wordize.

Section BoundedWord.

  Local Open Scope wordize_scope.

  Context {n: nat}.

  (* Word Operations *)

  Definition shiftr (w: word n) (bits: nat): word n.
    destruct (le_dec bits n).

    - replace n with (bits + (n - bits)) in * by (abstract intuition).
      refine (zext (split1 bits (n - bits) w) (n - bits)).

    - exact (wzero n).
  Defined.

  Lemma shiftr_spec: forall (w : word n) (bits: nat),
      wordToN (shiftr w bits) = N.shiftr (wordToN w) (N.of_nat bits).
    intros; unfold shiftr; destruct (le_dec bits n).

    - admit.

    - replace (wordToN (wzero n)) with 0%N by admit.
      unfold N.shiftr.
      induction bits.

      + replace (N.of_nat 0) with 0%N by intuition.
        assert (n = 0) by intuition; clear n0; subst.
        replace w with WO; intuition.

      + induction bits; admit.
  Qed.

  Definition mask (m: nat) (w: word n): word n.
    destruct (le_dec m n).

    - replace n with (m + (n - m)) in * by (abstract intuition).
      refine (w ^& (zext (wones m) (n - m))).

    - exact w.
  Defined.

  (* Definitions of Inequality and simple bounds. *)

  Lemma le_ge : forall n m, (n <= m -> m >= n)%nat.
  Proof.
    intros; omega.
  Qed.

  Lemma ge_le : forall n m, (n >= m -> m <= n)%nat.
  Proof.
    intros; omega.
  Qed.

  Ltac ge_to_le :=
    try apply N.ge_le;
    repeat match goal with
           | [ H : _ |- _ ] => apply N.le_ge in H
           end.

  Ltac ge_to_le_nat :=
    try apply le_ge;
    repeat match goal with
           | [ H : _ |- _ ] => apply ge_le in H
           end.

  Ltac preomega := unfold wordLeN; intros; ge_to_le; pre_nomega.

  Hint Rewrite wordToN_nat Nat2N.inj_add N2Nat.inj_add Nat2N.inj_mul N2Nat.inj_mul Npow2_nat : N.

  Theorem word_size_bound : forall (w: word n),
    w <= Npow2 n - 1.
  Proof.
    intros; unfold wordLeN; rewrite wordToN_nat.

    assert (B := wordToNat_bound w);
      rewrite <- Npow2_nat in B;
      apply nat_compare_lt in B.

    unfold N.le; intuition;
      rewrite N2Nat.inj_compare in H;
      rewrite Nat2N.id in H.

    apply nat_compare_lt in B.
    apply nat_compare_gt in H.

    replace (N.to_nat (Npow2 n)) with (S (N.to_nat (Npow2 n - 1))) in * by admit.
    intuition.
  Qed.

  Theorem constant_bound_N : forall k,
    NToWord n k <= k.
  Proof.
    preomega.
    rewrite NToWord_nat.
    destruct (le_lt_dec (pow2 n) (N.to_nat k)).

    specialize (wordToNat_bound (natToWord n (N.to_nat k))); nomega.

    rewrite wordToNat_natToWord_idempotent; nomega.
  Qed.

  Theorem constant_bound_nat : forall k,
    natToWord n k <= N.of_nat k.
  Proof.
    preomega.
    destruct (le_lt_dec (pow2 n) k).

    specialize (wordToNat_bound (natToWord n k)); nomega.

    rewrite wordToNat_natToWord_idempotent; nomega.
  Qed.

  Lemma let_bound : forall (x: word n) (f: word n -> word n) xb fb, x <= xb
    -> (forall x', x' <= xb -> f x' <= fb)
    -> (let k := x in f k) <= fb.
    eauto.
  Qed.

  Theorem wplus_bound : forall (w1 w2 : word n) b1 b2,
    w1 <= b1
    -> w2 <= b2
    -> w1 ^+ w2 <= b1 + b2.
  Proof.
    preomega.
    destruct (le_lt_dec (pow2 n) (N.to_nat b1 + N.to_nat b2)).

    specialize (wordToNat_bound (w1 ^+ w2)); nomega.

    rewrite wplus_alt.
    unfold wplusN, wordBinN.
    rewrite wordToNat_natToWord_idempotent; nomega.
  Qed.

  Theorem wmult_bound : forall (w1 w2 : word n) b1 b2,
    w1 <= b1
    -> w2 <= b2
    -> w1 ^* w2 <= b1 * b2.
  Proof.
    preomega.
    destruct (le_lt_dec (pow2 n) (N.to_nat b1 * N.to_nat b2)).

    specialize (wordToNat_bound (w1 ^* w2)); nomega.

    rewrite wmult_alt.
    unfold wmultN, wordBinN.
    rewrite wordToNat_natToWord_idempotent.
    ge_to_le_nat.

    apply Mult.mult_le_compat; nomega.
    pre_nomega.
    apply Lt.le_lt_trans with (N.to_nat b1 * N.to_nat b2); auto.
    apply Mult.mult_le_compat; nomega.
  Qed.

  Theorem shiftr_bound : forall (w : word n) b bits,
    w <= b
    -> shiftr w bits <= N.shiftr b (N.of_nat bits).
  Proof.
    admit.
  Qed.

  Theorem mask_bound : forall (w : word n) m,
    mask m w <= Npow2 m - 1.
  Proof.
    admit.
  Qed.

  Theorem mask_update_bound : forall (w : word n) b m,
    w <= b
    -> mask m w <= (N.min b (Npow2 m - 1)).
  Proof.
    admit.
  Qed.


  Ltac word_bound :=
    repeat (
       eassumption
       || apply wplus_bound
       || apply wmult_bound
       || apply mask_update_bound
       || apply mask_bound
       || apply shiftr_bound
       || apply constant_bound_N
       || apply constant_bound_nat
       || apply word_size_bound
      ).

  Notation "$" := (natToWord _).

  Lemma example1 : forall (w1 w2 w3 w4 : word n) b1 b2 b3 b4,
    w1 <= b1
    -> w2 <= b2
    -> w3 <= b3
    -> w4 <= b4
    -> { b | w1 ^+ (w2 ^* w3) ^* w4 <= b }.    
  Proof.
    eexists.
    word_bound.
  Defined.

  (* Eval simpl in fun (w1 w2 w3 w4 : word n) (b1 b2 b3 b4 : N)
                    (H1 : w1 <= b1) (H2 : w2 <= b2) (H3 : w3 <= b3) (H4 : w4 <= b4) =>
                  projT1 (example1 H1 H2 H3 H4). *)

  Lemma example2 : forall (w1 w2 w3 w4 : word n) b1 b2 b3 b4,
    w1 <= b1
    -> w2 <= b2
    -> w3 <= b3
    -> w4 <= b4
    -> { b | w1 ^+ (w2 ^* $7 ^* w3) ^* w4 ^+ $8 ^+ w2 <= b }.
  Proof.
    eexists.
    word_bound.
  Defined.

  (*Eval simpl in fun (w1 w2 w3 w4 : word n) (b1 b2 b3 b4 : N)
                    (H1 : w1 <= b1) (H2 : w2 <= b2) (H3 : w3 <= b3) (H4 : w4 <= b4) =>
                  projT1 (example2 H1 H2 H3 H4). *)

  Lemma example3 : forall (w1 w2 w3 w4 : word n),
    w1 <= Npow2 3
    -> w2 <= Npow2 4
    -> w3 <= Npow2 8
    -> w4 <= Npow2 16
    -> { b | w1 ^+ (w2 ^* $7 ^* w3) ^* w4 ^+ $8 ^+ w2 <= b }.
  Proof.
    eexists.
    word_bound.
  Defined.

  (* Eval simpl in fun (w1 w2 w3 w4 : word n)
                    (H1 : w1 <= _) (H2 : w2 <= _) (H3 : w3 <= _) (H4 : w4 <= _) =>
                  projT1 (example3 H1 H2 H3 H4). *)

End BoundedWord.

Section MulmodExamples.

  Notation "A <= B" := (wordLeN A B) (at level 70).
  Notation "$" := (natToWord _).

  Lemma mask_wand : forall (n: nat) (x: word n) m b,
    mask (N.to_nat m) x <= b
    -> x ^& (@NToWord n (N.ones m)) <= b.
  Proof.
  Admitted.

  Ltac word_bound_step :=
    idtac; match goal with
    | [ H: ?x <= _ |- ?x <= _] => eexact H
    | [|- (let x := ?y in @?z x) <= ?b ] => refine (@let_bound _ y z _ b _ _); [ | intros ? ? ]
    | [|- (let x := ?y in (?a <= ?b)) ] => change ((let x := y in a) <= b)
    | [|- (let x := ?y in (?a <= @?b x)) ] => change ((let x := y in a) <= b y); cbv beta
    | [|- mask _ _ <= _] => apply mask_bound
    | [|- _ ^+ _ <= _] => apply wplus_bound
    | [|- _ ^* _ <= _] => apply wmult_bound
    | [|- shiftr _ _ <= _] => apply shiftr_bound
    | [|- $ _ <= _] => apply constant_bound_nat
    | [|- NToWord _ _ <= _] => apply constant_bound_N
    | [|- _ <= Npow2 _ - 1] => apply word_size_bound 
    | [|- _ ^& (@NToWord _ (N.ones _)) <= _] => apply mask_wand
    end.

  Ltac simpl_hyps :=
    match goal with
    | [ H: ?x <= _ |- context[?x]] =>
      unfold Npow, Pos.pow, Npow2, N.shiftr in H;
      simpl in H
    | [ H: _ |- _ ] => clear H
    | _ => idtac
    end.

  Ltac word_bound := repeat (word_bound_step; simpl_hyps).

  Ltac word_bound_danger :=
    word_bound; try eassumption; try apply word_size_bound.
 
  Lemma example_and : forall x : word 32,
      wand x (NToWord 32 (N.ones 10)) <= 1023.
    intros.
    replace (wand x (NToWord 32 (N.ones 10))) with (mask 10 x) by admit.
    word_bound.
  Qed.
 
  Lemma example_shiftr : forall x : word 32, shiftr x 30 <= 3.
    intros.
    replace 3%N with (N.shiftr (Npow2 32 - 1) (N.of_nat 30)) by (simpl; intuition).
    word_bound.
  Qed.

  Lemma example_shiftr2 : forall x : word 32, x <= 1023 -> shiftr x 5 <= 31.
    intros.
    replace 31%N with (N.shiftr 1023%N 5%N) by (simpl; intuition).
    word_bound.
  Qed.
    
  Variable f0 f1 f2 f3 f4 f5 f6 f7 f8 f9 : word 32.
  Variable g0 g1 g2 g3 g4 g5 g6 g7 g8 g9 : word 32.
  Hypothesis Hf0 : f0 <= 2^26.
  Hypothesis Hf1 : f1 <= 2^25.
  Hypothesis Hf2 : f2 <= 2^26.
  Hypothesis Hf3 : f3 <= 2^25.
  Hypothesis Hf4 : f4 <= 2^26.
  Hypothesis Hf5 : f5 <= 2^25.
  Hypothesis Hf6 : f6 <= 2^26.
  Hypothesis Hf7 : f7 <= 2^25.
  Hypothesis Hf8 : f8 <= 2^26.
  Hypothesis Hf9 : f9 <= 2^25.
  Hypothesis Hg0 : g0 <= 2^26.
  Hypothesis Hg1 : g1 <= 2^25.
  Hypothesis Hg2 : g2 <= 2^26.
  Hypothesis Hg3 : g3 <= 2^25.
  Hypothesis Hg4 : g4 <= 2^26.
  Hypothesis Hg5 : g5 <= 2^25.
  Hypothesis Hg6 : g6 <= 2^26.
  Hypothesis Hg7 : g7 <= 2^25.

  Hypothesis Hg8 : g8 <= 2^26.
  Hypothesis Hg9 : g9 <= 2^25.
    
  Lemma example_mulmod_s_ppt : { b | f0 ^* g0  <= b}.
    eexists.
    word_bound.
  Defined.

  Lemma example_mulmod_s_pp :  { b | f0 ^* g0 ^+ $19 ^* (f9 ^* g1 ^* $2 ^+ f8 ^* g2 ^+ f7 ^* g3 ^* $2 ^+ f6 ^* g4 ^+ f5 ^* g5 ^* $2 ^+ f4 ^* g6 ^+ f3 ^* g7 ^* $2 ^+ f2 ^* g8 ^+  f1 ^* g9 ^* $2) <= b}.
    eexists.
    word_bound.
  Defined.

  Lemma example_mulmod_s_pp_shiftr :
      { b | shiftr (f0 ^* g0 ^+  $19 ^* (f9 ^* g1 ^* $2 ^+ f8 ^* g2 ^+ f7 ^* g3 ^* $2 ^+ f6 ^* g4 ^+ f5 ^* g5 ^* $2 ^+ f4 ^* g6 ^+ f3 ^* g7 ^* $2 ^+ f2 ^* g8 ^+  f1 ^* g9 ^* $2)) 26 <= b}.
    eexists.
    word_bound.
  Defined.

  Lemma example_mulmod_u_fg1 :  { b |
        (let y : word 32 := (* the type declarations on the let-s make type inference not take forever *)
           (f0 ^* g0 ^+
            $19 ^*
            (f9 ^* g1 ^* $2 ^+ f8 ^* g2 ^+ f7 ^* g3 ^* $2 ^+ f6 ^* g4 ^+ f5 ^* g5 ^* $2 ^+ f4 ^* g6 ^+ f3 ^* g7 ^* $2 ^+ f2 ^* g8 ^+
             f1 ^* g9 ^* $2)) in
         let y0 : word 32 :=
           (shiftr y 26 ^+
            (f1 ^* g0 ^+ f0 ^* g1 ^+
             $19 ^* (f9 ^* g2 ^+ f8 ^* g3 ^+ f7 ^* g4 ^+ f6 ^* g5 ^+ f5 ^* g6 ^+ f4 ^* g7 ^+ f3 ^* g8 ^+ f2 ^* g9))) in
         let y1 : word 32 :=
           (shiftr y0 25 ^+
            (f2 ^* g0 ^+ f1 ^* g1 ^* $2 ^+ f0 ^* g2 ^+
             $19 ^* (f9 ^* g3 ^* $2 ^+ f8 ^* g4 ^+ f7 ^* g5 ^* $2 ^+ f6 ^* g6 ^+ f5 ^* g7 ^* $2 ^+ f4 ^* g8 ^+ f3 ^* g9 ^* $2))) in
         let y2 : word 32 :=
           (shiftr y1 26 ^+
            (f3 ^* g0 ^+ f2 ^* g1 ^+ f1 ^* g2 ^+ f0 ^* g3 ^+
             $19 ^* (f9 ^* g4 ^+ f8 ^* g5 ^+ f7 ^* g6 ^+ f6 ^* g7 ^+ f5 ^* g8 ^+ f4 ^* g9))) in
         let y3 : word 32 :=
           (shiftr y2 25 ^+
            (f4 ^* g0 ^+ f3 ^* g1 ^* $2 ^+ f2 ^* g2 ^+ f1 ^* g3 ^* $2 ^+ f0 ^* g4 ^+
             $19 ^* (f9 ^* g5 ^* $2 ^+ f8 ^* g6 ^+ f7 ^* g7 ^* $2 ^+ f6 ^* g8 ^+ f5 ^* g9 ^* $2))) in
         let y4 : word 32 :=
           (shiftr y3 26 ^+
            (f5 ^* g0 ^+ f4 ^* g1 ^+ f3 ^* g2 ^+ f2 ^* g3 ^+ f1 ^* g4 ^+ f0 ^* g5 ^+
             $19 ^* (f9 ^* g6 ^+ f8 ^* g7 ^+ f7 ^* g8 ^+ f6 ^* g9))) in
         let y5 : word 32 :=
           (shiftr y4 25 ^+
            (f6 ^* g0 ^+ f5 ^* g1 ^* $2 ^+ f4 ^* g2 ^+ f3 ^* g3 ^* $2 ^+ f2 ^* g4 ^+ f1 ^* g5 ^* $2 ^+ f0 ^* g6 ^+
             $19 ^* (f9 ^* g7 ^* $2 ^+ f8 ^* g8 ^+ f7 ^* g9 ^* $2))) in
         let y6 : word 32 :=
           (shiftr y5 26 ^+
            (f7 ^* g0 ^+ f6 ^* g1 ^+ f5 ^* g2 ^+ f4 ^* g3 ^+ f3 ^* g4 ^+ f2 ^* g5 ^+ f1 ^* g6 ^+ f0 ^* g7 ^+
             $19 ^* (f9 ^* g8 ^+ f8 ^* g9))) in
         let y7 : word 32 :=
           (shiftr y6 25 ^+
            (f8 ^* g0 ^+ f7 ^* g1 ^* $2 ^+ f6 ^* g2 ^+ f5 ^* g3 ^* $2 ^+ f4 ^* g4 ^+ f3 ^* g5 ^* $2 ^+ f2 ^* g6 ^+ f1 ^* g7 ^* $2 ^+
             f0 ^* g8 ^+ $19 ^* f9 ^* g9 ^* $2)) in
         let y8 : word 32 :=
           (shiftr y7 26 ^+
            (f9 ^* g0 ^+ f8 ^* g1 ^+ f7 ^* g2 ^+ f6 ^* g3 ^+ f5 ^* g4 ^+ f4 ^* g5 ^+ f3 ^* g6 ^+ f2 ^* g7 ^+ f1 ^* g8 ^+
             f0 ^* g9)) in
         let y9 : word 32 :=
           ($19 ^* shiftr y8 25 ^+
            wand
              (f0 ^* g0 ^+
               $19 ^*
               (f9 ^* g1 ^* $2 ^+ f8 ^* g2 ^+ f7 ^* g3 ^* $2 ^+ f6 ^* g4 ^+ f5 ^* g5 ^* $2 ^+ f4 ^* g6 ^+ f3 ^* g7 ^* $2 ^+
                f2 ^* g8 ^+ f1 ^* g9 ^* $2)) (@NToWord 32 (N.ones 26%N))) in
         let fg1 : word 32 := (shiftr y9 26 ^+
          wand
            (shiftr y 26 ^+
             (f1 ^* g0 ^+ f0 ^* g1 ^+
              $19 ^* (f9 ^* g2 ^+ f8 ^* g3 ^+ f7 ^* g4 ^+ f6 ^* g5 ^+ f5 ^* g6 ^+ f4 ^* g7 ^+ f3 ^* g8 ^+ f2 ^* g9)))
            (@NToWord 32 (N.ones 26%N))) in
         fg1) <= b }.
  Proof.
    eexists.
    (* Time word_bound. *) (* <- It works, but don't do this in the build! *)
  Abort.

  Require Import ZArith.
  Variable shiftra : forall {l}, word l -> nat -> word l. (* "arithmetic" aka "signed" bitshift *)
  Hypothesis shiftra_spec : forall {l} (w : word l) (n:nat), wordToZ (shiftra l w n) = Z.shiftr (wordToZ w) (Z.of_nat n).

  Lemma example_shiftra : forall x : word 4, shiftra 4 x 2 <= 15.
  Abort.

  Lemma example_shiftra : forall x : word 4, x <= 7 -> shiftra 4 x 2 <= 1.
  Abort.

  Lemma example_mulmod_s_pp_shiftra :
      { b | shiftra 32 (f0 ^* g0 ^+  $19 ^* (f9 ^* g1 ^* $2 ^+ f8 ^* g2 ^+ f7 ^* g3 ^* $2 ^+ f6 ^* g4 ^+ f5 ^* g5 ^* $2 ^+ f4 ^* g6 ^+ f3 ^* g7 ^* $2 ^+ f2 ^* g8 ^+  f1 ^* g9 ^* $2)) 26 <= b}.
  Abort.
End MulmodExamples.
