Require Crypto.CompleteEdwardsCurve.Pre.

Module E.
  Section TwistedEdwardsCurves.
    (* Twisted Edwards curves with complete addition laws. References:
    * <https://eprint.iacr.org/2008/013.pdf>
    * <http://ed25519.cr.yp.to/ed25519-20110926.pdf>
    * <https://eprint.iacr.org/2015/677.pdf>
    *)

    Context {F eq Fzero one opp Fadd sub Fmul inv div} `{Algebra.field F eq Fzero one opp Fadd sub Fmul inv div}.
    Local Infix "=" := eq : type_scope. Local Notation "a <> b" := (not (a = b)) : type_scope.
    Local Notation "0" := Fzero.  Local Notation "1" := one.
    Local Infix "+" := Fadd. Local Infix "*" := Fmul.
    Local Infix "-" := sub. Local Infix "/" := div.
    Local Notation "x ^2" := (x*x) (at level 30).

    Context {a d: F}.
    Class twisted_edwards_params :=
      {
        char_gt_2 : 1 + 1 <> 0;
        nonzero_a : a <> 0;
        square_a : exists sqrt_a, sqrt_a^2 = a;
        nonsquare_d : forall x, x^2 <> d
      }.
    Context `{twisted_edwards_params}.
  
    Definition point := { P | let '(x,y) := P in a*x^2 + y^2 = 1 + d*x^2*y^2 }.
    Definition coordinates (P:point) : (F*F) := proj1_sig P.

    Program Definition zero : point := (0, 1).
    
    Program Definition add (P1 P2:point) : point := exist _ (
      let (x1, y1) := coordinates P1 in
      let (x2, y2) := coordinates P2 in
        (((x1*y2  +  y1*x2)/(1 + d*x1*x2*y1*y2)) , ((y1*y2 - a*x1*x2)/(1 - d*x1*x2*y1*y2)))) _.

    (** The described points are indeed on the curve -- see [CompleteEdwardsCurve.Pre] for proof *)
    Solve All Obligations using intros; exact Pre.zeroOnCurve
      || exact (Pre.unifiedAdd'_onCurve (char_gt_2:=char_gt_2) (d_nonsquare:=nonsquare_d)
         (a_nonzero:=nonzero_a) (a_square:=square_a) _ _ (proj2_sig _) (proj2_sig _)).

    Fixpoint mul (n:nat) (P : point) : point :=
      match n with
      | O => zero
      | S n' => add P (mul n' P)
      end.
  End TwistedEdwardsCurves.
End E.
  
Delimit Scope E_scope with E.
Infix "+" := E.add : E_scope.
Infix "*" := E.mul : E_scope.