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

# Initialize various segments:
# - The boot sector is loaded by BIOS at 0:7C00 (CS = 0)
# - CS, DS and ES are set to zero.
# - Stack point is set to 0x7C00 and will grow down from there.
# - Interrupts may not act now, so they are disabled.
.macro mInitSegments
  cli                        
  mov  iBootDrive, dl    # save what drive we booted from (should be 0x0)
  mov  ax, cs            # CS is set to 0x0, because that is where boot sector is loaded (0:07c00)
  mov  ds, ax            # DS = CS = 0x0 
  mov  es, ax            # ES = CS = 0x0
  mov  ss, ax            # SS = CS = 0x0
  mov  sp, 0x7C00        # Stack grows down from offset 0x7C00 toward 0x0000.
  sti
.endm
 
# Reset disk system.
# This is done through interrupt 0x13, subfunction 0.
# If reset fails, carry is set and we jump to reboot.
.macro mResetDiskSystem
  mov  dl, iBootDrive    # drive to reset
  xor  ax, ax            # subfunction 0
  int  0x13              # call interrupt 13h
  jc   bootFailure       # display error message if carry set (error)  
.endm

# Write a string to stdout.
# str = string to write
.macro mWriteString str
  lea    si,    \str
  call   WriteString
.endm

# Show a disk error message, wait for keystroke,
# then reboot.
.macro mReboot
  call   Reboot
.endm

# places first sector of bootloader in file_strt
# places # sectors in bootloader in file_scts
# jumps to bootFailure if bootloader not found in root dir
.macro mFindFile filename, loadsegment

  # The root directory will be loaded in a higher segment.
  # Set ES to this segment.
  mov     ax, \loadsegment
  mov     es, ax
  
  # The number of sectors that the root directory occupies
  # is equal to its max number of entries, times 32 bytes per
  # entry, divided by sector size. 
  # E.g. (32 * rootsize) / 512
  # This normally yields 14 sectors on a FAT12 disk.
  # We calculate this total, then store it in cx for later use in a loop.
  mov     ax, 32
  xor     dx, dx
  mul     word ptr iRootSize
  div     word ptr iSectSize          # Divide (dx:ax,sectsize) -> (ax,dx)
  mov     cx, ax                      
  mov     root_scts, cx
  # root_scts is now the number of sectors in root directory.
  
  # Calculate start sector root directory:
  # root_strt = number of FAT tables * sectors per FAT
  #           + number of hidden sectors
  #           + number of reserved sectors
  xor   ax, ax                      # find the root directory
  mov   al, byte ptr iFatCnt        # ax = number of FAT tables
  mov   bx, word ptr iFatSize       # bx = sectors per FAT
  mul   bx                          # ax = #FATS * sectors per FAT
  add   ax, word ptr iHiddenSect    # Add hidden sectors to ax
  adc   ax, word ptr iHiddenSect+2
  add   ax, word ptr iResSect       # Add reserved sectors to ax
  mov   root_strt, ax
  # root_strt is now the number of the first root sector 
  
  # Load a sector from the root directory.
  # If sector reading fails, a reboot will occur.
  read_next_sector:
    push   cx
    push   ax
    xor    bx, bx
    call   ReadSector
    
  check_entry:
    mov    cx, 11                      # Directory entries filenames are 11 bytes.
    mov    di, bx                      # es:di = Directory entry address
    lea    si, \filename               # ds:si = Address of filename we are looking for.
    repz   cmpsb                       # Compare filename to memory.
    je     found_file                  # If found, jump away.
    add    bx, word ptr 32             # Move to next entry. Complete entries are 32 bytes.
    cmp    bx, word ptr iSectSize      # Have we moved out of the sector yet?
    jne    check_entry                 # If not, try next directory entry.
    
    pop    ax
    inc    ax                          # check next sector when we loop again
    pop    cx
    loopnz read_next_sector            # loop until either found or not
    jmp    bootFailure                 # could not find file: abort
    
  found_file:
    # The directory entry stores the first cluster number of the file
    # at byte 26 (0x1a). BX is still pointing to the address of the start
    # of the directory entry, so we will go from there.
    # Read cluster number from memory:
    mov    ax, es:[bx+0x1a]
    mov    file_strt, ax
.endm

.macro mReadFAT fatsegment
    # The FAT will be loaded in a special segment.
    # Set ES to this segment.
    mov   ax, \fatsegment
    mov   es, ax
  
    # Calculate offset of FAT:
    mov   ax, word ptr iResSect       # Add reserved sectors to ax  
    add   ax, word ptr iHiddenSect    # Add hidden sectors to ax
    adc   ax, word ptr iHiddenSect+2
  
    # Read all FAT sectors into memory:
    mov   cx, word ptr iFatSize       # Number of sectors in FAT
    xor   bx, bx                      # Memory offset to read into (es:bx)
  read_next_fat_sector:
    push  cx
    push  ax
    call  ReadSector
    pop   ax
    pop   cx
    inc   ax
    add   bx, word ptr iSectSize
    loopnz read_next_fat_sector       # continue with next sector
.endm

# Load a file into memory at the specified segment.
# - The logical sector number of the file_start must be in file_strt
# - The size of the file in sectors must be in file_scts
.macro mReadFile loadsegment, fatsegment
    # Set memory segment that will receive the file:
    mov     ax, \loadsegment
    mov     es, ax
    # Set memory offset for loading to 0.
    xor     bx, bx
        
    # Set memory segment for FAT:
    mov     cx, file_strt             # CX now points to file's first FAT entry
    
  read_file_next_sector:
    # Locate sector:
    mov     ax, cx                    # Sector to read is equal to current FAT entry
    add     ax, root_strt             # Plus the start of the root directory
    add     ax, root_scts             # Plus the size of the root directory
    sub     ax, 2                     # ... but minus 2
    
    # Read sector:
    push    cx                        # Read a sector from disk, but save CX
    call    ReadSector                # as it contains our FAT entry
    pop     cx
    add     bx, iSectSize             # Move memory pointer to next section
    
    # Get next sector from FAT:
    push    ds                        # Make DS:SI point to FAT table
    mov     dx, \fatsegment           # in memory.
    mov     ds, dx
    
    mov     si, cx                    # Make SI point to the current FAT entry
    mov     dx, cx                    # (offset is entry value * 1.5 bytes)
    shr     dx
    add     si, dx
    
    mov     dx, ds:[si]               # Read the FAT entry from memory
    test    dx, 1                     # See which way to shift
    jz      read_next_file_even
    and     dx, 0x0fff
    jmp     read_next_file_cluster_done
read_next_file_even:    
    shr     dx, 4
read_next_file_cluster_done:    
    pop     ds                        # Restore DS to the normal data segment
    mov     cx, dx                    # Store the new FAT entry in CX
    cmp     cx, 0xff8                 # If the FAT entry is greater or equal
    jl      read_file_next_sector     # to 0xff8, then we've reached end-of-file
.endm

.macro mStartSecondStage
    # Make es and ds point to segment where 2nd stage was loaded.
    mov     ax, word ptr LOAD_SEGMENT
    mov     es, ax
    mov     ds, ax
    # Jump to second stage start of code:    
    jmp     LOAD_SEGMENT:0
.endm
 
