# 
# A20 enabling
# 
# This file provides the mEnableA20 macro, which attempt to enable the A20 line. 
# This in done in the following sequence:
# * Test if A20 is already enabled/disabled (and exit if it's already in the right state)
# * Try the BIOS function
# * Test if A20 is became enabled/disabled (and exit if the BIOS function worked)
# * Try the keyboard controller method
# * Test if A20 is became enabled/disabled (and exit if the keyboard controller method worked)
# * Try the "fast A20" method
# * Test if A20 is became enabled/disabled (and exit if the "fast A20" method worked)
# * Display a "A20 unavailable" error message and reboot.
# 
# 


# 
# Checks the status of the a20 line.
#
# Returns: 0 in ax if the a20 line is disabled (memory wraps around)
#          1 in ax if the a20 line is enabled (memory does not wrap around)
# 
.func CheckA20
  CheckA20:
    pushf
    push ds
    push es
    push di
    push si
 
    cli
 
    xor ax, ax                         # Set es:di = 0000:0500
    mov es, ax
    mov di, 0x0500
    
    not ax                             # Set ds:si = ffff:0510
    mov ds, ax             
    mov si, 0x0510 
 
    mov al, byte ptr es:[di]           # Save byte at es:di on stack.
    push ax
 
    mov al, byte ptr ds:[si]           # Save byte at ds:si on stack.
    push ax
 
    mov byte ptr es:[di], 0x00         # [es:di] = 0x00
    mov byte ptr ds:[si], 0xFF         # [ds:si] = 0xff
 
    cmp byte ptr es:[di], 0xFF         # Did memory wrap around?
 
    pop ax
    mov byte ptr ds:[si], al           # Restore byte at ds:si
 
    pop ax
    mov byte ptr es:[di], al           # Restore byte at es:di
 
    mov ax, 0
    je check_a20__exit                 # If memory wrapped around, return 0.
 
    mov ax, 1                          # else return 1.
 
check_a20__exit:
    pop si
    pop di
    pop es
    pop ds
    popf
 
    ret
.endfunc

.func Wait_8042_command
  Wait_8042_command:
    in      al,0x64
    test    al,2
    jnz     Wait_8042_command
    ret
.endfunc

.func Wait_8042_data
  Wait_8042_data:
    in      al,0x64
    test    al,1
    jz      Wait_8042_data
    ret
.endfunc

# 
# Attempt to enable A20 line through BIOS function.
# 
.macro mSetA20BIOS
    mov ax, 0x2401
    int 0x15
.endm

# 
# Attempt to enable A20 line through keyboard controller.
#
.macro mSetA20Keyboard
    cli                        # Disable interrupts

    call    Wait_8042_command  # When controller ready for command
    mov     al,0xAD            # Send command 0xad (disable keyboard).
    out     0x64,al

    call    Wait_8042_command  # When controller ready for command
    mov     al,0xD0            # Send command 0xd0 (read from input)
    out     0x64,al

    call    Wait_8042_data     # When controller has data ready
    in      al,0x60            # Read input from keyboard
    push    eax                # ... and save it

    call    Wait_8042_command  # When controller is ready for command
    mov     al,0xD1            # Set command 0xd1 (write to output)
    out     0x64,al            

    call    Wait_8042_command  # When controller is ready for command
    pop     eax                # Write input back, with bit #2 set
    or      al,2
    out     0x60,al

    call    Wait_8042_command  # When controller is ready for command
    mov     al,0xAE            # Write command 0xae (enable keyboard)
    out     0x64,al

    call    Wait_8042_command  # Wait until controller is ready for command
    
    sti                        # Enable interrupts
.endm

# 
# Attempt to enable A20 through Fast A20 option
# 
.macro mSetA20FastGate
    in al, 0x92
    or al, 2
    out 0x92, al
.endm

.macro mEnableA20
    call CheckA20
    cmp  ax, 0
    jne  enable_A20__done
    mSetA20BIOS
    call CheckA20
    cmp  ax, 0
    jne  enable_A20__done
    mSetA20Keyboard
    call CheckA20
    cmp  ax, 0
    jne  enable_A20__done
    mSetA20FastGate
    call CheckA20
    xchg bx, bx
    cmp  ax, 0
    jne  enable_A20__done
  enable_A20__fail:
    mWriteString a20error
    mReboot
  enable_A20__done:
.endm
