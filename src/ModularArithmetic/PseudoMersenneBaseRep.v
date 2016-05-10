Require Import ZArith.
Require Crypto.BaseSystem.
Require Import Crypto.ModularArithmetic.PrimeFieldTheorems.
Require Import Crypto.ModularArithmetic.ModularBaseSystemProofs Crypto.ModularArithmetic.PseudoMersenneBaseParams.
Local Open Scope Z_scope.

Class RepZMod (modulus : Z) := {
  T : Type;
  encode : F modulus -> T;
  decode : T -> F modulus;

  rep : T -> F modulus -> Prop;
  encode_rep : forall x, rep (encode x) x;
  rep_decode : forall u x, rep u x -> decode u = x;

  add : T -> T -> T;
  add_rep : forall u v x y, rep u x -> rep v y -> rep (add u v) (x+y)%F;

  sub : T -> T -> T;
  sub_rep : forall u v x y, rep u x -> rep v y -> rep (sub u v) (x-y)%F;

  mul : T -> T -> T;
  mul_rep : forall u v x y, rep u x -> rep v y -> rep (mul u v) (x*y)%F
}.

Class SubtractionCoefficient (m : Z) (prm : PseudoMersenneBaseParams m) := {
  coeff : BaseSystem.digits;
  coeff_length : (length coeff <= length PseudoMersenneBaseParamProofs.base)%nat;
  coeff_mod: (BaseSystem.decode PseudoMersenneBaseParamProofs.base coeff) mod m = 0
}.

Instance PseudoMersenneBase m (prm : PseudoMersenneBaseParams m) (sc : SubtractionCoefficient m prm)
: RepZMod m := {
  T := list Z;
  encode := ModularBaseSystem.encode;
  decode := ModularBaseSystem.decode;

  rep := ModularBaseSystem.rep;
  encode_rep := ModularBaseSystemProofs.encode_rep;
  rep_decode := ModularBaseSystemProofs.rep_decode;

  add := BaseSystem.add;
  add_rep := ModularBaseSystemProofs.add_rep;

  sub := ModularBaseSystem.sub coeff coeff_mod;
  sub_rep := ModularBaseSystemProofs.sub_rep coeff coeff_mod coeff_length;

  mul := ModularBaseSystem.mul;
  mul_rep := ModularBaseSystemProofs.mul_rep
}.
