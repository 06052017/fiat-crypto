Require Import Coq.ZArith.ZArith.
Require Import Crypto.Util.ZRange.
Require Import Crypto.Util.ZUtil.Definitions.

Require Import Crypto.Util.Notations.

Module ZRange.
  Local Open Scope Z_scope.
  Local Open Scope zrange_scope.

  Local Notation eta v := r[ lower v ~> upper v ].

  Definition flip (v : zrange) : zrange
    := r[ upper v ~> lower v ].

  Definition union (x y : zrange) : zrange
    := let (lx, ux) := eta x in
       let (ly, uy) := eta y in
       r[ Z.min lx ly ~> Z.max ux uy ].

  Definition intersection (x y : zrange) : zrange
    := let (lx, ux) := eta x in
       let (ly, uy) := eta y in
       r[ Z.max lx ly ~> Z.min ux uy ].

  Definition normalize (v : zrange) : zrange
    := r[ Z.min (lower v) (upper v) ~> Z.max (upper v) (lower v) ].

  Definition normalize' (v : zrange) : zrange
    := union v (flip v).

  Lemma normalize'_eq : normalize = normalize'. Proof. reflexivity. Defined.

  Definition abs (v : zrange) : zrange
    := let (l, u) := eta v in
       r[ 0 ~> Z.max (Z.abs l) (Z.abs u) ].

  Definition opp (v : zrange) : zrange
    := let (l, u) := eta v in
       r[ -u ~> -l ].

  Definition map (f : Z -> Z) (v : zrange) : zrange
    := let (l, u) := eta v in
       r[ f l ~> f u ].

  Definition split_range_at_0 (x : zrange) : option zrange (* < 0 *) * option zrange (* >= 0 *)
    := let (l, u) := eta x in
       (if (0 <=? l)%Z
        then None
        else Some r[l ~> Z.min u (-1)],
        if (0 <=? u)%Z
        then Some r[Z.max 0 l ~> u]
        else None).

  Definition apply_to_split_range (f : zrange -> zrange) (v : zrange) : zrange
    := match split_range_at_0 v with
       | (Some n, Some p) => union (f n) (f p)
       | (Some v, None) | (None, Some v) => f v
       | (None, None) => f v
       end.

  Definition apply_to_range (f : BinInt.Z -> zrange) (v : zrange) : zrange
    := let (l, u) := eta v in
       union (f l) (f u).

  Definition apply_to_each_split_range (f : BinInt.Z -> zrange) (v : zrange) : zrange
    := apply_to_split_range (apply_to_range f) v.

  Definition constant (v : Z) : zrange := r[v ~> v].

  Definition two_corners (f : Z -> Z) (v : zrange) : zrange
    := apply_to_range (fun x => constant (f x)) v.
  Definition four_corners (f : Z -> Z -> Z) (x y : zrange) : zrange
    := apply_to_range (fun x => two_corners (f x) y) x.
  Definition eight_corners (f : Z -> Z -> Z -> Z) (x y z : zrange) : zrange
    := apply_to_range (fun x => four_corners (f x) y z) x.

  Definition two_corners_and_zero (f : Z -> Z) (v : zrange) : zrange
    := apply_to_each_split_range (fun x => constant (f x)) v.
  Definition four_corners_and_zero (f : Z -> Z -> Z) (x y : zrange) : zrange
    := apply_to_split_range (apply_to_range (fun x => two_corners_and_zero (f x) y)) x.
  Definition eight_corners_and_zero (f : Z -> Z -> Z -> Z) (x y z : zrange) : zrange
    := apply_to_split_range (apply_to_range (fun x => four_corners_and_zero (f x) y z)) x.

  Definition two_corners' (f : Z -> Z) (v : zrange) : zrange
    := normalize' (map f v).

  Lemma two_corners'_eq x y : two_corners x y = two_corners' x y.
  Proof.
    cbv [two_corners two_corners' normalize' map union apply_to_range constant flip].
    cbn [lower upper].
    rewrite Z.max_comm; reflexivity.
  Qed.

  (** if positive, round up to 2^k-1 (0b11111....); if negative, round down to -2^k (0b...111000000...) *)
  Definition round_lor_land_bound (x : BinInt.Z) : BinInt.Z
    := if (0 <=? x)%Z
       then 2^(Z.log2_up (x+1))-1
       else -2^(Z.log2_up (-x)).
  Definition land_lor_bounds (f : BinInt.Z -> BinInt.Z -> BinInt.Z) (x y : zrange) : zrange
    := four_corners_and_zero (fun x y => f (round_lor_land_bound x) (round_lor_land_bound y)) x y.
  Definition land_bounds : zrange -> zrange -> zrange := land_lor_bounds Z.land.
  Definition lor_bounds : zrange -> zrange -> zrange := land_lor_bounds Z.lor.

  Definition split_bounds (r : zrange) (split_at : BinInt.Z) : zrange * zrange :=
    if upper r <? split_at
    then if (0 <=? lower r)%Z
         then (r, {| lower := 0; upper := 0 |})
         else ( {| lower := 0; upper := split_at - 1 |},
                {| lower := lower r / split_at; upper := (upper r / split_at) |} )
    else ( {| lower := 0; upper := split_at - 1 |},
           {| lower := lower r / split_at; upper := (upper r / split_at) |} ).

  Definition good (r : zrange) : Prop
    := lower r <= upper r.
  Definition goodb (r : zrange) : bool
    := (lower r <=? upper r)%Z.
End ZRange.
