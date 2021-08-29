import os, llvm

var err = allocCStringArray(["a"])

proc parse(path: string, module: ptr ModuleRef) =
  var
    ctx = GetModuleContext(module[])
    memBuf: MemoryBufferRef
  if CreateMemoryBufferWithContentsOfFile(path, addr memBuf, err):
    quit "Error reading IR file: " & cstringArrayToSeq(err)[0]

  if ParseIRInContext(ctx, memBuf, module, err):
    quit "Error parsing IR file: " & cstringArrayToSeq(err)[0]

proc find_store(user: ValueRef, target: string): ValueRef =
  var previous_instruction = GetPreviousInstruction(user)
  while previous_instruction != nil:
    if GetInstructionOpcode(previous_instruction) == Store:
      let
        target_operand = GetOperand(previous_instruction, 1)
        operand_name = GetValueName(target_operand)
      if $operand_name == target:
        return previous_instruction
    previous_instruction = GetPreviousInstruction(previous_instruction)

proc process(module: ModuleRef, builder: BuilderRef) =
  let
    function_call = GetNamedFunction(module, "function_call")
    printf = GetNamedFunction(module, "printf")
    dlsym_fmt = GetNamedGlobal(module, "dlsym_fmt")
    print_checked = GetNamedFunction(module, "print_checked")

  var use = GetFirstUse(function_call)
  while use != nil:
    let user = GetUser(use)
    if GetInstructionOpcode(user) == Call:
      let store_inst = find_store(user, "rsi")
      if store_inst != nil:
        PositionBuilderBefore(builder, GetPreviousInstruction(user))
        let
          rsi = GetOperand(store_inst, 1)
          loaded = BuildLoad(builder, rsi, "address")
          args = [dlsym_fmt, loaded]
        discard BuildCall(builder, printf, unsafeAddr args[0], 2, "")
        discard BuildCall(builder, print_checked, unsafeAddr loaded, 1, "")
    use = GetNextUse(use)

proc create_printf(module: ModuleRef) =
  var
    ctx = GetModuleContext(module)
    i64 = Int64TypeInContext(ctx)
    args = [GetNamedGlobal(module, "dlsym_fmt").TypeOf(), i64]
    function_type = FunctionType(i64, addr args[0], 2, false)
  discard AddFunction(module, "printf", function_type)

proc create_print_checked(module: ModuleRef) =
  var
    ctx = GetModuleContext(module)
    arg0 = Int64TypeInContext(GetModuleContext(module))
    function_type = FunctionType(VoidTypeInContext(ctx), addr arg0, 1, false)
  discard AddFunction(module, "print_checked", function_type)

proc dump(path: string, module: ModuleRef) =
  if PrintModuleToFile(module, path, err):
    quit "Error writing file: " & cstringArrayToSeq(err)[0]
  echo "Ouput: ", path

proc main() =
  var
    ctx = ContextCreate()
    module = ModuleCreateWithNameInContext("dlsym_hook", ctx)
    builder = CreateBuilderInContext(ctx)
    size: csize_t

  if module == nil:
    quit "Error creating module"

  if builder == nil:
    quit "Error creating builder"

  parse($paramStr(1), addr module)
  echo "Loaded IR: ", GetModuleIdentifier(module, addr size)

  let bb = GetEntryBasicBlock(GetNamedFunction(module, "function_call"))
  PositionBuilderAtEnd(builder, bb)
  discard BuildGlobalStringPtr(builder, "dlsym => %p\n", "dlsym_fmt")

  create_printf(module)
  create_print_checked(module)
  process(module, builder)

  let verify = VerifyModule(module, AbortProcessAction, err)
  echo "Verification: ", verify
  if verify:
    quit "Error: " & cstringArrayToSeq(err)[0]

  dump(paramStr(2), module)
  deallocCStringArray(err)
main()