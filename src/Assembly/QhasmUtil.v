
Require Import ZArith NArith NPeano.
Require Import QhasmCommon.
Require Export Bedrock.Word.

Module Util.
  (* Magical Bitwise Manipulations *)

  (* Force w to be m bits long, by truncation or zero-extension *)
  Definition trunc {n} (m: nat) (w: word n): word m.
    destruct (lt_eq_lt_dec n m) as [s|s]; try destruct s as [s|s].

  - replace m with (n + (m - n)) by abstract intuition.
    refine (zext w (m - n)).

  - rewrite <- s; assumption.

  - replace n with (m + (n - m)) in w by abstract intuition.
    refine (split1 m (n-m) w).
  Defined.

  (* Get the index-th m-bit block of w *)
  Definition getIndex {n} (w: word n) (m index: nat): word m.
    replace n with
      ((min n (m * index)) + (n - (min n (m * index))))%nat
      in w by abstract (
      assert ((min n (m * index)) <= n)%nat
          by apply Nat.le_min_l;
      intuition).

    refine
      (trunc m
      (split2 (min n (m * index)) (n - min n (m * index)) w)).
  Defined.

  (* set the index-th m-bit block of w to s *)
  Definition setInPlace {n m} (w: word n) (s: word m) (index: nat): word n :=
    (w ^& (wnot (trunc n (combine (wones m) (wzero (index * m)%nat)))))
       ^| (trunc n (combine s (wzero (index * m)%nat))).

  (* Option utilities *)
  Definition omap {A B} (x: option A) (f: A -> option B) :=
    match x with | Some y => f y | _ => None end.

  Notation "A <- X ; B" := (omap X (fun A => B)) (at level 70, right associativity).
End Util.
