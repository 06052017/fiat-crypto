Require Export QhasmCommon QhasmUtil State.
Require Export ZArith Sumbool.
Require Export Bedrock.Word.

Import State.
Import Util.

Definition evalTest {n} (o: TestOp) (a b: word n): bool :=
  let c := (N.compare (wordToN a) (wordToN b)) in

  let eqBit := match c with | Eq => true | _ => false end in
  let ltBit := match c with | Lt => true | _ => false end in
  let gtBit := match c with | Gt => true | _ => false end in

  match o with
  | TEq => eqBit
  | TLt => ltBit
  | TLe => orb (eqBit) (ltBit)
  | TGt => gtBit
  | TGe => orb (eqBit) (gtBit)
  end.

Definition evalCond (c: Conditional) (state: State): option bool.
  refine match c with
  | TestTrue => Some true
  | TestFalse => Some false
  | TestInt n t a b => 
    match (getIntReg a state) with
    | Some va =>
      match (getIntReg b state) with
      | Some vb => Some (evalTest t va vb)
      | _ => None
      end
    | _ => None
    end

  | TestFloat n t a b =>
    let aOpt := (getFloatReg a state) in
    let bOpt := convert (getFloatReg a state) _ in

    match aOpt with
    | Some va =>
      match bOpt with
      | Some vb => Some (evalTest t va vb)
      | _ => None
      end
    | _ => None
    end
  end; abstract (
    inversion a; inversion b;
    unfold aOpt, getFractionalBits;
    simpl; intuition).
Defined.

Definition evalOperation (o: Operation) (state: State): option State.
  refine (
  let evalIOp := fun (io: IntOp) (x y: word 32) =>
    match io with
    | IPlus => wplus x y
    | IMinus => wminus x y
    | IXor => wxor x y
    | IAnd => wand x y
    | IOr => wor x y
    end in

  let evalFOp := fun {b} (fo: FloatOp) (x y: word b) =>
    match fo with
    | FAnd => wand x y
    | FPlus => wplus x y
    | FMult => wmult x y
    end in

  let evalRotOp := fun (ro: RotOp) (x: word 32) (n: nat) =>
    match ro with
    | Shl => NToWord 32 (N.shiftl_nat (wordToN x) n)
    | Shr => NToWord 32 (N.shiftr_nat (wordToN x) n)
    end in

  let liftOpt := fun {A B C} (f: A -> B -> option C) (xo: option A) (yo: option B) =>
    match (xo, yo) with
    | (Some x, Some y) => f x y
    | _ => None
    end in

  match o with
  | IOpConst o r c =>
    liftOpt (fun x y => setIntReg r (evalIOp o x y) state)
      (getIntReg r state) (match c with | constInt32 v => Some v end)

  | IOpReg o a b =>
    liftOpt (fun x y => setIntReg a (evalIOp o x y) state)
      (getIntReg a state) (getIntReg b state)

  | FOpConst32 o r c =>
    liftOpt (fun x y => setFloatReg r (evalFOp o x y) state) (getFloatReg r state)
      (convert (match c with | constFloat32 v => Some v | _ => None end) _)

  | FOpReg32 o a b =>
    liftOpt (fun x y => setFloatReg a (evalFOp o x y) state)
      (getFloatReg a state) (convert (getFloatReg b state) _)

  | FOpConst64 o r c =>
    liftOpt (fun x y => setFloatReg r (evalFOp o x y) state)
      (getFloatReg r state) (match c with | constFloat64 v => Some v | _ => None end)

  | FOpReg64 o a b =>
    liftOpt (fun x y => setFloatReg a (evalFOp o x y) state)
      (getFloatReg a state) (convert (getFloatReg b state) _)

  | OpRot o r i =>
   match (getIntReg r state) with
    | Some va => setIntReg r (evalRotOp o va i) state
    | None => None
    end
  end); unfold evalIOp, evalFOp, evalRotOp, getFractionalBits.

  elim r.
  destruct r.

    try destruct r; try destruct c; try destruct a; try destruct b; simpl;
    intuition.
  (* TODO *)
Defined.

Definition evalAssignment (a: Assignment) (state: State): option State :=
  match a with
  | Assign32Stack32 r s =>
    match (getReg r state) with
    | Some v0 =>
      match (getStack s state) with
      | Some v1 => setReg r v1 state
      | _ => None
      end
    | None => None
    end

  | Assign32Stack16 r s i =>
    match (getReg r state) with
    | Some v0 =>
      match (getStack s state) with
      | Some v1 => setReg r (trunc 32 (getIndex v1 16 i)) state
      | _ => None
      end
    | None => None
    end
  | Assign32Stack8 r s i =>
    match (getReg r state) with
    | Some v0 =>
      match (getStack s state) with
      | Some v1 => setReg r (trunc 32 (getIndex v1 8 i)) state
      | _ => None
      end
    | None => None
    end
  | Assign32Stack64 r s i =>
    match (getReg r state) with
    | Some v0 =>
      match (getStack s state) with
      | Some v1 => setReg r (getIndex v1 32 i) state
      | _ => None
      end
    | None => None
    end
  | Assign32Stack128 r s i =>
    match (getReg r state) with
    | Some v0 =>
      match (getStack s state) with
      | Some v1 => setReg r (getIndex v1 32 i) state
      | _ => None
      end
    | None => None
    end

  | Assign32Reg32 r0 r1 =>
    match (getReg r0 state) with
    | Some v0 =>
      match (getReg r1 state) with
      | Some v1 => setReg r0 v1 state
      | _ => None
      end
    | None => None
    end
  | Assign32Reg16 r0 r1 i =>
    match (getReg r0 state) with
    | Some v0 =>
      match (getReg r1 state) with
      | Some v1 => setReg r0 (trunc 32 (getIndex v1 16 i)) state
      | _ => None
      end
    | None => None
    end
  | Assign32Reg8 r0 r1 i =>
    match (getReg r0 state) with
    | Some v0 =>
      match (getReg r1 state) with
      | Some v1 => setReg r0 (trunc 32 (getIndex v1 8 i)) state
      | _ => None
      end
    | None => None
    end
  | Assign32Reg64 r0 r1 i =>
    match (getReg r0 state) with
    | Some v0 =>
      match (getReg r1 state) with
      | Some v1 => setReg r0 (getIndex v1 32 i) state
      | _ => None
      end
    | None => None
    end
  | Assign32Reg128 r0 r1 i =>
    match (getReg r0 state) with
    | Some v0 =>
      match (getReg r1 state) with
      | Some v1 => setReg r0 (getIndex v1 32 i) state
      | _ => None
      end
    | None => None
    end

  | Assign3232Stack32 r0 i s =>
    match (getReg r0 state) with
    | Some v0 =>
      match (getStack s state) with
      | Some v1 => setReg r0 (setInPlace v0 v1 i) state
      | _ => None
      end
    | None => None
    end

  | Assign3232Stack64 r s =>
    match (getReg r state) with
    | Some v0 =>
      match (getStack s state) with
      | Some v1 => setReg r v1 state
      | _ => None
      end
    | None => None
    end

  | Assign3232Stack128 r s i =>
    match (getReg r state) with
    | Some v0 =>
      match (getStack s state) with
      | Some v1 => setReg r (getIndex v1 64 i) state
      | _ => None
      end
    | None => None
    end

  | Assign3232Reg32 r0 i r1 =>
    match (getReg r0 state) with
    | Some v0 =>
      match (getReg r1 state) with
      | Some v1 => setReg r0 (setInPlace v0 v1 i) state
      | _ => None
      end
    | None => None
    end

  | Assign3232Reg64 r0 r1 =>
    match (getReg r0 state) with
    | Some v0 =>
      match (getReg r1 state) with
      | Some v1 => setReg r0 v1 state
      | _ => None
      end
    | None => None
    end

  | Assign3232Reg128 r0 r1 i =>
    match (getReg r0 state) with
    | Some v0 =>
      match (getReg r1 state) with
      | Some v1 => setReg r0 (getIndex v1 64 i) state
      | _ => None
      end
    | None => None
    end

  | Assign6464Reg32 r0 i r1 =>
    match (getReg r0 state) with
    | Some v0 =>
      match (getReg r1 state) with
      | Some v1 => setReg r0 (setInPlace v0 v1 i) state
      | _ => None
      end
    | None => None
    end

  | Assign6464Reg64 r0 i r1 =>
    match (getReg r0 state) with
    | Some v0 =>
      match (getReg r1 state) with
      | Some v1 => setReg r0 (setInPlace v0 v1 i) state
      | _ => None
      end
    | None => None
    end

  | Assign6464Reg128 r0 r1 =>
    match (getReg r0 state) with
    | Some v0 =>
      match (getReg r1 state) with
      | Some v1 => setReg r0 v1 state
      | _ => None
      end
    | None => None
    end

  | AssignConstant r c =>
    match (getReg r state) with
    | Some v0 =>
      match c with
      | const32 v1 => setReg r v1 state
      end
    | None => None
    end
  end.

