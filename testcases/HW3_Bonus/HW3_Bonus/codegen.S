.global ext_dsp_codegen
ext_dsp_codegen:
  addi  sp, sp, -32       # Allocate stack space
  sw    s0, 28(sp)        # Save s0 on the stack
  addi  s0, sp, 32        # Set s0 to the new stack frame
  sw    a0, -20(s0)       # Save a0 in the stack frame
  sw    a1, -24(s0)       # Save a1 in the stack frame
  lw    a4, -20(s0)       # Load a0 (saved value) into a4
  lw    a5, -24(s0)       # Load a1 (saved value) into a5
  ukadd8   a5, a4, a5     # UKADD8 a4 and a5, store the result in a5
  mv    a0, a5            # Move the result to a0 (return value)
  lw    s0, 28(sp)        # Restore s0 from the stack
  addi  sp, sp, 32        # Deallocate stack space
  jr    ra                # Return to the caller