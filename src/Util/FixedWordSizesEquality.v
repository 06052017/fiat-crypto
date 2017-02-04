Require Import Coq.ZArith.ZArith.
Require Import Coq.NArith.BinNat.
Require Import Coq.Arith.Arith.
Require Import Bedrock.Word.
Require Import Crypto.Util.FixedWordSizes.
Require Import Crypto.Util.WordUtil.
Require Import Crypto.Util.Tactics.BreakMatch.

Definition wordT_beq_hetero {logsz1 logsz2} : wordT logsz1 -> wordT logsz2 -> bool
  := match logsz1 return wordT logsz1 -> wordT logsz2 -> bool with
     | 5 as logsz1' | 6 as logsz1' | 7 as logsz1'
     | _ as logsz1'
       => match logsz2 return wordT logsz1' -> wordT logsz2 -> bool with
          | 5 as logsz2' | 6 as logsz2' | 7 as logsz2'
          | _ as logsz2'
            => @Word.weqb_hetero (2^logsz1') (2^logsz2')
          end
     end.

(* transparent so the equality proof can compute away *)
Lemma pow2_inj_helper x y : 2^x = 2^y -> x = y.
Proof.
  destruct (NatUtil.nat_eq_dec x y) as [pf|pf]; [ intros; assumption | ].
  intro H; exfalso.
  abstract (apply pf; eapply NPeano.Nat.pow_inj_r; [ | eassumption ]; omega).
Defined.
Lemma pow2_inj_helper_refl x p : pow2_inj_helper x x p = eq_refl.
Proof.
  induction x; simpl; [ reflexivity | ].
  etransitivity; [ | exact (f_equal (fun p => f_equal S p) (IHx eq_refl)) ]; clear IHx.
  unfold pow2_inj_helper in *; simpl.
  pose proof (NatUtil.nat_eq_dec_S x x).
  do 2 edestruct NatUtil.nat_eq_dec; try assumption; try (exfalso; assumption).
  match goal with
  | [ H : ?x <> ?x |- _ ] => exfalso; clear -H; exact (H eq_refl)
  end.
Defined.
Lemma pow2_inj_helper_eq_rect x y P v v'
  : (exists pf : 2^x = 2^y, eq_rect _ P v _ pf = v')
    -> (exists pf : x = y, eq_rect _ (fun e => P (2^e)) v _ pf = v').
Proof.
  intros [pf H]; exists (pow2_inj_helper x y pf); subst v'.
  destruct (NatUtil.nat_eq_dec x y) as [H|H];
    [ | exfalso; clear -pf H;
        abstract (apply pow2_inj_helper in pf; omega) ].
  subst; rewrite pow2_inj_helper_refl; simpl.
  pose proof (NatUtil.UIP_nat_transparent _ _ pf eq_refl); subst pf.
  reflexivity.
Defined.

Definition wordT_beq_lb logsz1
  : forall x y : wordT logsz1, x = y -> wordT_beq_hetero x y = true
  := match logsz1 return forall x y : wordT logsz1, x = y -> wordT_beq_hetero x y = true with
     | 5 as logsz1' | 6 as logsz1' | 7 as logsz1'
     | _ as logsz1'
       => fun x y pf => proj2 (@Word.weqb_hetero_true_iff (2^logsz1') x (2^logsz1') y) (ex_intro _ eq_refl pf)
     end.
Definition wordT_beq_hetero_lb {logsz1 logsz2}
  : forall x y, (exists pf : logsz1 = logsz2, eq_rect _ wordT x _ pf = y) -> wordT_beq_hetero x y = true.
Proof.
  intros x y [pf H]; subst logsz2; revert x y H; simpl.
  apply wordT_beq_lb.
Defined.

Definition wordT_beq_bl logsz
  : forall x y : wordT logsz, wordT_beq_hetero x y = true -> x = y
  := match logsz return forall x y : wordT logsz, wordT_beq_hetero x y = true -> x = y with
     | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7
     | _
       => fun x y pf => proj1 (Word.weqb_hetero_homo_true_iff _ x y) pf
     end.

Lemma wordT_beq_hetero_type_lb_false logsz1 logsz2 x y : logsz1 <> logsz2 -> @wordT_beq_hetero logsz1 logsz2 x y = false.
Proof.
  destruct (wordT_beq_hetero x y) eqn:H; [ | reflexivity ].
  revert H.
  repeat (try destruct logsz1 as [|logsz1];
          try destruct logsz2 as [|logsz2];
          try (intros; omega);
          try (intro H'; apply Word.weqb_hetero_true_iff in H'; destruct H' as [pf H']; pose proof (pow2_inj_helper _ _ pf); try omega)).
Qed.

Definition wordT_beq_hetero_bl {logsz1 logsz2}
  : forall x y, wordT_beq_hetero x y = true -> (exists pf : logsz1 = logsz2, eq_rect _ wordT x _ pf = y).
Proof.
  refine match logsz1, logsz2 return forall x y, wordT_beq_hetero x y = true -> (exists pf : logsz1 = logsz2, eq_rect _ wordT x _ pf = y) with
         | 0, 0 | 1, 1 | 2, 2 | 3, 3 | 4, 4 | 5, 5 | 6, 6
         | 7, 7
           => fun x y pf => ex_intro _ eq_refl (@wordT_beq_bl _ x y pf)
         | S (S (S (S (S (S (S (S a))))))), S (S (S (S (S (S (S (S b)))))))
           => match NatUtil.nat_eq_dec a b with
              | left pf
                => match pf with
                   | eq_refl => fun x y pf => ex_intro _ eq_refl (@wordT_beq_bl _ x y pf)
                   end
              | right n => fun x y pf => match _ : False with end
              end
         | _, _
           => fun x y pf => match _ : False with end
         end;
    try abstract (rewrite wordT_beq_hetero_type_lb_false in pf by omega; clear -pf; congruence).
Defined.

Lemma ZToWord_gen_wordToZ_gen : forall {sz} v, ZToWord_gen (@wordToZ_gen sz v) = v.
Proof.
  unfold ZToWord_gen, wordToZ_gen.
  intros.
  rewrite N2Z.id, NToWord_wordToN; reflexivity.
Qed.

Lemma wordToZ_gen_ZToWord_gen : forall {sz} v, (0 <= v < 2^(Z.of_nat sz))%Z -> @wordToZ_gen sz (ZToWord_gen v) = v.
Proof.
  unfold ZToWord_gen, wordToZ_gen.
  intros ?? [H0 H1].
  rewrite wordToN_NToWord_idempotent, Z2N.id; try omega.
  rewrite Npow2_N.
  apply Z2N.inj_lt in H1; [ | omega.. ].
  rewrite Z2N.inj_pow, <- nat_N_Z, N2Z.id in H1 by omega.
  assumption.
Qed.

Lemma ZToWord_gen_wordToZ_gen_ZToWord_gen : forall {sz1 sz2} v,
    (sz2 <= sz1)%nat -> @ZToWord_gen sz2 (wordToZ_gen (@ZToWord_gen sz1 v)) = ZToWord_gen v.
Proof.
  unfold ZToWord_gen, wordToZ_gen.
  intros sz1 sz2 v H.
  rewrite N2Z.id, NToWord_wordToN_NToWord by omega.
  reflexivity.
Qed.

Lemma wordToZ_gen_ZToWord_gen_wordToZ_gen sz1 sz2 w
  : (sz1 <= sz2)%nat -> wordToZ_gen (@ZToWord_gen sz2 (@wordToZ_gen sz1 w)) = wordToZ_gen w.
Proof.
  unfold ZToWord_gen, wordToZ_gen; intro H.
  rewrite N2Z.id, wordToN_NToWord_wordToN by omega.
  reflexivity.
Qed.

Lemma ZToWord_wordToZ : forall {sz} v, ZToWord (@wordToZ sz v) = v.
Proof.
  unfold wordT, word_case in *.
  intro sz; break_match; simpl; apply ZToWord_gen_wordToZ_gen.
Qed.

Lemma wordToZ_ZToWord : forall {sz} v, (0 <= v < 2^(Z.of_nat (2^sz)))%Z -> @wordToZ sz (ZToWord v) = v.
Proof.
  unfold wordToZ, ZToWord, word_case_dep.
  intros; break_match; apply wordToZ_gen_ZToWord_gen;
    assumption.
Qed.

Local Ltac handle_le :=
  repeat match goal with
         | [ |- (S ?a <= 2^?b)%nat ]
           => change (2^(Nat.log2 (S a)) <= 2^b)%nat
         | [ |- (2^_ <= 2^_)%nat ]
           => apply Nat.pow_le_mono_r
         | [ |- _ <> _ ] => intro; omega
         | _ => assumption
         | [ |- (_ <= S _)%nat ]
           => apply Nat.leb_le; vm_compute; reflexivity
         | _ => exfalso; omega
         end.

Lemma ZToWord_wordToZ_ZToWord : forall {sz1 sz2} v,
    (sz2 <= sz1)%nat -> @ZToWord sz2 (wordToZ (@ZToWord sz1 v)) = ZToWord v.
Proof.
  unfold wordToZ, ZToWord, word_case_dep.
  intros sz1 sz2; break_match; intros; apply ZToWord_gen_wordToZ_gen_ZToWord_gen;
    handle_le.
Qed.

Lemma wordToZ_ZToWord_wordToZ : forall sz1 sz2 w, (sz1 <= sz2)%nat -> wordToZ (@ZToWord sz2 (@wordToZ sz1 w)) = wordToZ w.
Proof.
  unfold wordToZ, ZToWord, word_case_dep.
  intros sz1 sz2; break_match; intros; apply wordToZ_gen_ZToWord_gen_wordToZ_gen;
    handle_le.
Qed.

Local Ltac wordToZ_word_case_dep_t :=
  let H := fresh in
  intro H;
  intros; unfold wordToZ, word_case_dep, wordT, word_case, word32, word64, word128, word32ToZ, word64ToZ, word128ToZ in *;
  break_innermost_match;
  change 128%nat with (2^7)%nat in *;
  change 64%nat with (2^6)%nat in *;
  change 32%nat with (2^5)%nat in *;
  apply H.

Lemma wordToZ_word_case_dep_1op (wop : forall sz, word sz -> word sz)
      (P : nat -> Z -> Z -> Type)
  : (forall logsz (x : word (2^logsz)), P logsz (wordToZ_gen x) (wordToZ_gen (wop (2^logsz) x)))
    -> forall logsz (x : wordT logsz), P logsz (wordToZ x) (wordToZ (word_case_dep (T:=fun _ W => W -> W) logsz (wop 32) (wop 64) (wop 128) (fun _ => wop _) x)).
Proof. wordToZ_word_case_dep_t. Qed.

Lemma wordToZ_word_case_dep_11op {T} (wop : forall sz, T -> word sz -> word sz)
      (P : nat -> Z -> Z -> Type)
      {v}
  : (forall logsz (x : word (2^logsz)), P logsz (wordToZ_gen x) (wordToZ_gen (wop (2^logsz) v x)))
    -> forall logsz (x : wordT logsz), P logsz (wordToZ x) (wordToZ (word_case_dep (T:=fun _ W => T -> W -> W) logsz (wop 32) (wop 64) (wop 128) (fun _ => wop _) v x)).
Proof. wordToZ_word_case_dep_t. Qed.

Lemma wordToZ_word_case_dep_binop (wop : forall sz, word sz -> word sz -> word sz)
      (P : nat -> Z -> Z -> Z -> Type)
  : (forall logsz (x y : word (2^logsz)), P logsz (wordToZ_gen x) (wordToZ_gen y) (wordToZ_gen (wop (2^logsz) x y)))
    -> forall logsz (x y : wordT logsz), P logsz (wordToZ x) (wordToZ y) (wordToZ (word_case_dep (T:=fun _ W => W -> W -> W) logsz (wop 32) (wop 64) (wop 128) (fun _ => wop _) x y)).
Proof. wordToZ_word_case_dep_t. Qed.

Lemma wordToZ_word_case_dep_quadop (wop : forall sz, word sz -> word sz -> word sz -> word sz -> word sz)
      (P : nat -> Z -> Z -> Z -> Z -> Z -> Type)
  : (forall logsz (x y z w : word (2^logsz)), P logsz (wordToZ_gen x) (wordToZ_gen y) (wordToZ_gen z) (wordToZ_gen w) (wordToZ_gen (wop (2^logsz) x y z w)))
    -> forall logsz (x y z w : wordT logsz), P logsz (wordToZ x) (wordToZ y) (wordToZ z) (wordToZ w) (wordToZ (word_case_dep (T:=fun _ W => W -> W -> W -> W -> W) logsz (wop 32) (wop 64) (wop 128) (fun _ => wop _) x y z w)).
Proof. wordToZ_word_case_dep_t. Qed.

(** This converts goals involving (currently only binary) [wordT]
    operations to the corresponding goals involving [word]
    operations. *)
Ltac fixed_size_op_to_word :=
  repeat autounfold with fixed_size_constants in *;
  lazymatch goal with
  | [ |- context[wordToZ (word_case_dep (T:=?T) ?logsz (?wop 32) (?wop 64) (?wop 128) ?f ?x)] ]
    => move x at top;
       revert dependent logsz; intros logsz x;
       pattern (wordToZ x), (wordToZ (word_case_dep (T:=T) logsz (wop 32) (wop 64) (wop 128) f x));
       let P := lazymatch goal with |- ?P _ _ => P end in
       let P := lazymatch (eval pattern logsz in P) with ?P _ => P end in
       revert logsz x;
       refine (@wordToZ_word_case_dep_unop wop P _);
       intros logsz x; unfold wordToZ_gen; intros
  | [ |- context[wordToZ (word_case_dep (T:=?T) ?logsz (?wop 32) (?wop 64) (?wop 128) ?f ?x ?y)] ]
    => lazymatch type of x with
       | context[logsz]
         => move y at top; move x at top;
            revert dependent logsz; intros logsz x y;
            pattern (wordToZ x), (wordToZ y), (wordToZ (word_case_dep (T:=T) logsz (wop 32) (wop 64) (wop 128) f x y));
            let P := lazymatch goal with |- ?P _ _ _ => P end in
            let P := lazymatch (eval pattern logsz in P) with ?P _ => P end in
            revert logsz x y;
            refine (@wordToZ_word_case_dep_binop wop P _);
            intros logsz x y; unfold wordToZ_gen; intros
       | _
         => move y at top;
            revert dependent logsz; intros logsz y;
            pattern (wordToZ y), (wordToZ (word_case_dep (T:=T) logsz (wop 32) (wop 64) (wop 128) f x y));
            let P := lazymatch goal with |- ?P _ _ => P end in
            let P := lazymatch (eval pattern logsz in P) with ?P _ => P end in
            revert logsz y;
            refine (@wordToZ_word_case_dep_11op wop P x _);
            intros logsz y; unfold wordToZ_gen; intros
       end
  | [ |- context[wordToZ (word_case_dep (T:=?T) ?logsz (?wop 32) (?wop 64) (?wop 128) ?f ?x ?y ?z ?w)] ]
    => move w at top; move z at top; move y at top; move x at top;
       revert dependent logsz; intros logsz x y z w;
       pattern (wordToZ x), (wordToZ y), (wordToZ z), (wordToZ w), (wordToZ (word_case_dep (T:=T) logsz (wop 32) (wop 64) (wop 128) f x y z w));
       let P := lazymatch goal with |- ?P _ _ _ _ _ => P end in
       let P := lazymatch (eval pattern logsz in P) with ?P _ => P end in
       revert logsz x y z w;
       refine (@wordToZ_word_case_dep_quadop wop P _);
       intros logsz x y z w; unfold wordToZ_gen; intros
  end.
