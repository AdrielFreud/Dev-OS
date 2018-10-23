# ***********************************************************
#
# DevOS 2012
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF
# ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
# TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT
# SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
# AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
# THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
# ***********************************************************
# ***********************************************************

# 
# Writes string at DS:SI to screen.
# String must be NULL-terminated.
# 
# This function uses in 10h/ah=0xe (video - teletype output).
# 
.func WriteString
 WriteString:
  lodsb                   # load byte at ds:si into al (advancing si)
  or     al, al           # test if character is 0 (end)
  jz     WriteString_done # jump to end if 0.
  
  mov    ah, 0xe          # Subfunction 0xe of int 10h (video teletype output).
  mov    bx, 9            # Set bh (page number) to 0, and bl (attribute) to white (9).
  int    0x10             # call BIOS interrupt.
  
  jmp    WriteString      # Repeat for next character.
 
 WriteString_done:
  retw
.endfunc

# 
# Displays 'press any key', waits for key, then causes BIOS to reboot
# This function uses BIOS interrupt 16h, subfunction 0 for reading a
# keypress.
# 
.func Reboot
 Reboot:
  lea    si, rebootmsg    # Load address of reboot message into si
  call   WriteString      # print the string
  xor    ax, ax           # subfuction 0
  int    0x16             # call bios to wait for key

  .byte  0xEA             # machine language to jump to FFFF:0000 (reboot)
  .word  0x0000
  .word  0xFFFF
.endfunc

# Read sector with logical address (LBA) AX into data 
# buffer at ES:BX. 
# This function uses interrupt 13h, subfunction ah=2.
.func ReadSector
ReadSector:
  xor     cx, cx                      # Set try count = 0

 readsect:
  push    ax                          # Store logical block
  push    cx                          # Store try number
  push    bx                          # Store data buffer offset
   
  # Calculate cylinder, head and sector:
  # Cylinder = (LBA / SectorsPerTrack) / NumHeads
  # Sector   = (LBA mod SectorsPerTrack) + 1
  # Head     = (LBA / SectorsPerTrack) mod NumHeads
    
  mov     bx, iTrackSect              # Get sectors per track
  xor     dx, dx
  div     bx                          # Divide (dx:ax/bx to ax,dx)
                                      # Quotient (ax) =  LBA / SectorsPerTrack
                                      # Remainder (dx) = LBA mod SectorsPerTrack
  inc     dx                          # Add 1 to remainder, since sector 
  mov     cl, dl                      # Store result in cl for int 13h call.
  
  mov     bx, iHeadCnt                # Get number of heads
  xor     dx, dx
  div     bx                          # Divide (dx:ax/bx to ax,dx)
                                      # Quotient (ax) = Cylinder
                                      # Remainder (dx) = head
  mov     ch, al                      # ch = cylinder                      
  xchg    dl, dh                      # dh = head number
  
  # Call interrupt 0x13, subfunction 2 to actually
  # read the sector.
  # al = number of sectors
  # ah = subfunction 2
  # cx = sector number
  # dh = head number
  # dl = drive number
  # es:bx = data buffer
  # If it fails, the carry flag will be set.
  mov     ax, 0x0201                  # Subfunction 2, read 1 sector
  mov     dl, iBootDrive              # from this drive
  pop     bx                          # Restore data buffer offset.
  int     0x13
  jc      readfail
  
  # On success, return to caller.
  pop     cx                          # Discard try number
  pop     ax                          # Get logical block from stack
  ret

  # The read has failed. 
  # We will retry four times total, then jump to boot failure.
 readfail:   
  pop     cx                          # Get try number             
  inc     cx                          # Next try
  cmp     cx, word ptr 4              # Stop at 4 tries
  je      bootFailure

  # Reset the disk system:
  xor     ax, ax
  int     0x13
  
  # Get logical block from stack and retry.
  pop     ax
  jmp     readsect
.endfunc
