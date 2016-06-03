
Require Import QhasmCommon QhasmEvalCommon.
Require Import Pseudo Qhasm AlmostQhasm Medial Conversion Language.
Require Import PseudoMedialConversion AlmostConversion StringConversion.

Extraction Language Ocaml.
Require Import ExtrOcamlString ExtrOcamlBasic.
Require Import Coq.Strings.String.

Module Progs.
  Module Arch := PseudoUnary32.
  Module C32 := PseudoMedialConversion Arch.

  Import C32.P.

  Definition omap {A B} (f: A -> option B) (x: option A): option B :=
    match x with
    | Some v => f v
    | None => None
    end.

  Definition prog0: C32.P.Program.
    refine
      (PBin _ Add (PComb _ _ _
        (PVar 1 (exist _ 0 _))
        (PConst _ (natToWord _ 1)))); abstract intuition.
  Defined.

  Definition prog1: option C32.M.Program :=
    C32.PseudoConversion.convertProgram prog0.

  Definition prog2: option AlmostQhasm.Program :=
    omap C32.MedialConversion.convertProgram prog1.

  Definition prog3: option Qhasm.Program :=
    omap AlmostConversion.convertProgram prog2.

  Definition prog4: option string :=
    omap StringConversion.convertProgram prog3.
End Progs.

Definition Result: string.
  let res := eval vm_compute in (
    match Progs.prog4 with
    | Some x => x
    | None => EmptyString
    end) in exact res.
Defined.

Open Scope string_scope.
Print Result.

Extraction "Result.ml" Result.
