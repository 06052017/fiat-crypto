Require Import Crypto.Util.Equality.
Require Import Crypto.Util.GlobalSettings.

Section sigT.
  Definition pr1_path {A} {P : A -> Type} {u v : sigT P} (p : u = v)
  : projT1 u = projT1 v
    := f_equal (@projT1 _ _) p.

  Definition pr2_path {A} {P : A -> Type} {u v : sigT P} (p : u = v)
  : eq_rect _ _ (projT2 u) _ (pr1_path p) = projT2 v.
  Proof.
    destruct p; reflexivity.
  Defined.

  Definition path_sigT_uncurried {A : Type} {P : A -> Type} (u v : sigT P)
             (pq : sigT (fun p : projT1 u = projT1 v => eq_rect _ _ (projT2 u) _ p = projT2 v))
  : u = v.
  Proof.
    destruct u as [u1 u2], v as [v1 v2]; simpl in *.
    destruct pq as [p q].
    destruct q; simpl in *.
    destruct p; reflexivity.
  Defined.

  Definition path_sigT {A : Type} {P : A -> Type} (u v : sigT P)
             (p : projT1 u = projT1 v) (q : eq_rect _ _ (projT2 u) _ p = projT2 v)
  : u = v
    := path_sigT_uncurried u v (existT _ p q).

  Definition path_sigT_nondep {A B : Type} (u v : @sigT A (fun _ => B))
             (p : projT1 u = projT1 v) (q : projT2 u = projT2 v)
  : u = v
    := @path_sigT _ _ u v p (eq_trans (transport_const _ _) q).

  Lemma eq_rect_sigT {A x} {P : A -> Type} (Q : forall a, P a -> Prop) (u : sigT (Q x)) {y} (H : x = y)
  : eq_rect x (fun a => sigT (Q a)) u y H
    = existT
        (Q y)
        (eq_rect x P (projT1 u) y H)
        match H in (_ = y) return Q y (eq_rect x P (projT1 u) y H) with
          | eq_refl => projT2 u
        end.
  Proof.
    destruct H, u; reflexivity.
  Defined.
End sigT.

Section sig.
  Definition proj1_sig_path {A} {P : A -> Prop} {u v : sig P} (p : u = v)
  : proj1_sig u = proj1_sig v
    := f_equal (@proj1_sig _ _) p.

  Definition proj2_sig_path {A} {P : A -> Prop} {u v : sig P} (p : u = v)
  : eq_rect _ _ (proj2_sig u) _ (proj1_sig_path p) = proj2_sig v.
  Proof.
    destruct p; reflexivity.
  Defined.

  Definition path_sig_uncurried {A : Type} {P : A -> Prop} (u v : sig P)
             (pq : {p : proj1_sig u = proj1_sig v | eq_rect _ _ (proj2_sig u) _ p = proj2_sig v})
  : u = v.
  Proof.
    destruct u as [u1 u2], v as [v1 v2]; simpl in *.
    destruct pq as [p q].
    destruct q; simpl in *.
    destruct p; reflexivity.
  Defined.

  Definition path_sig {A : Type} (P : A -> Prop) (u v : sig P)
             (p : proj1_sig u = proj1_sig v) (q : eq_rect _ _ (proj2_sig u) _ p = proj2_sig v)
  : u = v
    := path_sig_uncurried u v (exist _ p q).

  Lemma eq_rect_sig {A x} {P : A -> Type} (Q : forall a, P a -> Prop) (u : sig (Q x)) {y} (H : x = y)
  : eq_rect x (fun a => sig (Q a)) u y H
    = exist
        (Q y)
        (eq_rect x P (proj1_sig u) y H)
        match H in (_ = y) return Q y (eq_rect x P (proj1_sig u) y H) with
          | eq_refl => proj2_sig u
        end.
  Proof.
    destruct H, u; reflexivity.
  Defined.
End sig.

Section ex.
  Definition path_ex_uncurried' {A : Type} (P : A -> Prop) {u1 v1 : A} {u2 : P u1} {v2 : P v1}
             (pq : exists p : u1 = v1, eq_rect _ _ u2 _ p = v2)
  : ex_intro P u1 u2 = ex_intro P v1 v2.
  Proof.
    destruct pq as [p q].
    destruct q; simpl in *.
    destruct p; reflexivity.
  Defined.

  Definition path_ex' {A : Type} (P : A -> Prop) (u1 v1 : A) (u2 : P u1) (v2 : P v1)
             (p : u1 = v1) (q : eq_rect _ _ u2 _ p = v2)
  : ex_intro P u1 u2 = ex_intro P v1 v2
    := path_ex_uncurried' P (ex_intro _ p q).

  Lemma eq_rect_ex {A x} {P : A -> Type} (Q : forall a, P a -> Prop) (u : ex (Q x)) {y} (H : x = y)
  : eq_rect x (fun a => ex (Q a)) u y H
    = match u with
        | ex_intro u1 u2
          => ex_intro
               (Q y)
               (eq_rect x P u1 y H)
               match H in (_ = y) return Q y (eq_rect x P u1 y H) with
                 | eq_refl => u2
               end
      end.
  Proof.
    destruct H, u; reflexivity.
  Defined.
End ex.
