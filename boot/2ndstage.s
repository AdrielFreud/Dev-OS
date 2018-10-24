# ***********************************************************
#
# DevOS 2011
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

.code16
.intel_syntax noprefix
.text
.org 0x0                                        

LOAD_SEGMENT = 0x2000                   # load the kernel to segment 2000h
FAT_SEGMENT  = 0x0ee0

.global main

main:
    jmp short start                     # jump to beginning of code
    nop
    
# INCLUDES
.include "bootsector.s"
.include "functions.s"
.include "macros.s"
.include "a20.s"
.include "descriptors.s"

# PROGRAM DATA
filename:    .asciz "KERNEL  BIN"
rebootmsg:   .asciz "Press any key to reboot.\r\n"
diskerror:   .asciz "Disk error. "
a20error:    .asciz "A20 unavailable. "
root_strt:   .byte 0,0      # hold offset of root directory on disk
root_scts:   .byte 0,0      # holds # sectors in root directory
file_strt:   .byte 0,0      # holds offset of bootloader on disk
idt:
  .word  2048  # Size of IDT (256 entries of 8 bytes)
  .int   0x0   # Linear address of IDT
gdt:
  .word  24    # Size of GDT: 3 entries of 8 bytes.
  .int   2048  # Linear address of GDT

start:
  # Copy the boot sector to our code:
	mCopyBootSector
	# Find the kernel file:
  mFindFile filename, LOAD_SEGMENT
  # Load the kernel file into memory:
  mReadFile LOAD_SEGMENT, FAT_SEGMENT
  # Reset the disk system:
  mResetDiskSystem
  # Enable the A20 line:
  mEnableA20
  # Setup the interrupt descriptor table:
  mSetupIDT
  # Setup the global descriptor table:
  mSetupGDT  
  # Actually load the IDT and GDT:
  mLoadDescriptorTables
  # Switch to protected mode:
  mGoProtected
  # Clear the prefetch queue:
  mClearPrefetchQueue
  # Point all data segments to GDT 2:
  mSetup386Segments
  # Jump to kernel code:
  mJumpToKernel
  # shouldn't get here...
  
# 
# Booting has failed because of a disk error. 
# Inform the user and reboot.
# 
bootFailure:
  mWriteString diskerror
  mReboot
