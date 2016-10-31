(** * PHOAS Syntax for expression trees on ℤ *)
Require Import Coq.ZArith.ZArith.
Require Import Crypto.Reflection.Syntax.
Require Import Crypto.ModularArithmetic.ModularBaseSystemListZOperations.
Require Import Crypto.Util.Equality.
Require Import Crypto.Util.ZUtil.
Require Import Crypto.Util.PartiallyReifiedProp.
Export Syntax.Notations.

Local Set Boolean Equality Schemes.
Local Set Decidable Equality Schemes.
Scheme Equality for Z.
Inductive base_type := TZ.
Definition interp_base_type (v : base_type) : Type :=
  match v with
  | TZ => Z
  end.

Local Notation tZ := (Tbase TZ).
Local Notation eta x := (fst x, snd x).
Local Notation eta3 x := (eta (fst x), snd x).
Local Notation eta4 x := (eta3 (fst x), snd x).

Inductive op : flat_type base_type -> flat_type base_type -> Type :=
| Add : op (tZ * tZ) tZ
| Sub : op (tZ * tZ) tZ
| Mul : op (tZ * tZ) tZ
| Shl : op (tZ * tZ) tZ
| Shr : op (tZ * tZ) tZ
| Land : op (tZ * tZ) tZ
| Lor : op (tZ * tZ) tZ
| Neg : op (tZ * tZ) tZ
| Cmovne : op (tZ * tZ * tZ * tZ) tZ
| Cmovle : op (tZ * tZ * tZ * tZ) tZ.

Definition interp_op src dst (f : op src dst) : interp_flat_type interp_base_type src -> interp_flat_type interp_base_type dst
  := match f in op src dst return interp_flat_type interp_base_type src -> interp_flat_type interp_base_type dst with
     | Add => fun xy => fst xy + snd xy
     | Sub => fun xy => fst xy - snd xy
     | Mul => fun xy => fst xy * snd xy
     | Shl => fun xy => fst xy << snd xy
     | Shr => fun xy => fst xy >> snd xy
     | Land => fun xy => Z.land (fst xy) (snd xy)
     | Lor => fun xy => Z.lor (fst xy) (snd xy)
     | Neg => fun xy => ModularBaseSystemListZOperations.neg (fst xy) (snd xy)
     | Cmovne => fun xyzw => let '(x, y, z, w) := eta4 xyzw in cmovne x y z w
     | Cmovle => fun xyzw => let '(x, y, z, w) := eta4 xyzw in cmovl x y z w
     end%Z.

Definition base_type_eq_semidec_transparent (t1 t2 : base_type)
  : option (t1 = t2)
  := Some (match t1, t2 return t1 = t2 with
           | TZ, TZ => eq_refl
           end).
Lemma base_type_eq_semidec_is_dec t1 t2 : base_type_eq_semidec_transparent t1 t2 = None -> t1 <> t2.
Proof.
  unfold base_type_eq_semidec_transparent; congruence.
Qed.

Definition op_beq t1 tR (f g : op t1 tR) : reified_Prop
  := match f, g return bool with
     | Add, Add => true
     | Add, _ => false
     | Sub, Sub => true
     | Sub, _ => false
     | Mul, Mul => true
     | Mul, _ => false
     | Shl, Shl => true
     | Shl, _ => false
     | Shr, Shr => true
     | Shr, _ => false
     | Land, Land => true
     | Land, _ => false
     | Lor, Lor => true
     | Lor, _ => false
     | Neg, Neg => true
     | Neg, _ => false
     | Cmovne, Cmovne => true
     | Cmovne, _ => false
     | Cmovle, Cmovle => true
     | Cmovle, _ => false
     end.

Lemma op_beq_bl : forall t1 tR x y, to_prop (op_beq t1 tR x y) -> x = y.
Proof.
  intros ?? x; destruct x;
    intro y;
    refine match y with
           | Add => _
           | _ => _
           end;
    compute; try (reflexivity || trivial || (intros; exfalso; assumption)).
Qed.
