Require Import Crypto.Reflection.Syntax.
Require Import Crypto.Reflection.Wf.
Require Import Crypto.Reflection.ExprInversion.
Require Import Crypto.Util.Sigma.
Require Import Crypto.Util.Option.
Require Import Crypto.Util.Equality.
Require Import Crypto.Util.Tactics.
Require Import Crypto.Util.Notations.

Section language.
  Context {base_type_code : Type}
          {op : flat_type base_type_code -> flat_type base_type_code -> Type}.

  Local Notation flat_type := (flat_type base_type_code).
  Local Notation type := (type base_type_code).
  Local Notation exprf := (@exprf base_type_code op).
  Local Notation expr := (@expr base_type_code op).
  Local Notation Expr := (@Expr base_type_code op).
  Local Notation wff := (@wff base_type_code op).
  Local Notation wf := (@wf base_type_code op).
  Local Notation Wf := (@Wf base_type_code op).

  Section with_var.
    Context {var1 var2 : base_type_code -> Type}.

    Local Notation eP := (fun t => var1 t * var2 t)%type (only parsing).
    Local Notation "x == y" := (existT eP _ (x, y)).

    Definition wff_code (G : list (sigT eP)) {t} (e1 : @exprf var1 t) : forall (e2 : @exprf var2 t), Prop
      := match e1 in Syntax.exprf _ _ t return exprf t -> Prop with
         | TT
           => fun e2
              => TT = e2
         | Var t v1
           => fun e2
              => match invert_Var e2 with
                 | Some v2 => List.In (v1 == v2) G
                 | None => False
                 end
         | Op t1 tR opc1 args1
           => fun e2
              => match invert_Op e2 with
                 | Some (existT t2 (opc2, args2))
                   => { pf : t1 = t2
                      | eq_rect _ (fun t => op t tR) opc1 _ pf = opc2
                        /\ wff G (eq_rect _ exprf args1 _ pf) args2 }
                 | None => False
                 end
         | LetIn tx1 ex1 tC1 eC1
           => fun e2
              => match invert_LetIn e2 with
                 | Some (existT tx2 (ex2, eC2))
                   => { pf : tx1 = tx2
                      | wff G (eq_rect _ exprf ex1 _ pf) ex2
                        /\ (forall x1 x2,
                               wff (flatten_binding_list x1 x2 ++ G)%list
                                   (eC1 x1) (eC2 (eq_rect _ _ x2 _ pf))) }
                 | None => False
                 end
         | Pair tx1 ex1 ty1 ey1
           => fun e2
              => match invert_Pair e2 with
                 | Some (ex2, ey2) => wff G ex1 ex2 /\ wff G ey1 ey2
                 | None => False
                 end
         end.

    Local Ltac t :=
      repeat match goal with
             | _ => progress simpl in *
             | _ => progress subst
             | _ => progress inversion_option
             | _ => progress invert_expr_subst
             | [ H : Some _ = _ |- _ ] => symmetry in H
             | _ => assumption
             | _ => reflexivity
             | _ => constructor
             | _ => progress destruct_head False
             | _ => progress destruct_head and
             | _ => progress destruct_head sig
             | _ => progress break_match_hyps
             | _ => progress break_match
             | [ |- and _ _ ] => split
             | _ => exists eq_refl
             | _ => intro
             | [ e : expr (Arrow _ _) |- _ ]
               => let H := fresh in
                  let f := fresh in
                  remember (invert_Abs e) as f eqn:H;
                  symmetry in H;
                  apply invert_Abs_Some in H
             end.

    Definition wff_encode {G t e1 e2} (v : @wff var1 var2 G t e1 e2) : @wff_code G t e1 e2.
    Proof.
      destruct v; t.
    Defined.

    Definition wff_decode {G t e1 e2} (v : @wff_code G t e1 e2) : @wff var1 var2 G t e1 e2.
    Proof.
      destruct e1; t.
    Defined.

    Definition wff_endecode {G t e1 e2} v : @wff_decode G t e1 e2 (@wff_encode G t e1 e2 v) = v.
    Proof.
      destruct v; reflexivity.
    Qed.

    Definition wff_deencode {G t e1 e2} v : @wff_encode G t e1 e2 (@wff_decode G t e1 e2 v) = v.
    Proof.
      destruct e1; simpl in *;
        move e2 at top;
        lazymatch type of e2 with
        | exprf Unit
          => subst; reflexivity
        | exprf (Tbase ?t)
          => revert dependent t;
               intros ? e2
        | exprf (Prod ?A ?B)
          => revert dependent A;
               intros ? e2;
               move e2 at top;
               revert dependent B;
               intros ? e2
        | exprf ?t
          => revert dependent t;
               intros ? e2
        end;
        refine match e2 with
               | TT => _
               | _ => _
               end;
        t.
    Qed.
  End with_var.
End language.

Ltac inversion_wff_step :=
  let postprocess H :=
      (cbv [wff_code] in H;
       simpl in H;
       try match type of H with
           | True => clear H
           | False => exfalso; exact H
           end) in
  match goal with
  | [ H : wff _ ?x ?y |- _ ]
    => first [ is_var x; is_var y; fail 1
             | idtac ];
       apply wff_encode in H; postprocess H
  end.
Ltac inversion_wff := repeat inversion_wff_step.
