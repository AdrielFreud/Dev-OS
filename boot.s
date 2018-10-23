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

.code16
.intel_syntax noprefix
.text
.org 0x0                                        

LOAD_SEGMENT = 0x1000                     # load the 2nd stage loader to segment 1000h
FAT_SEGMENT  = 0x0ee0                     # load FAT to segment 0x0ee0 (9*512 bytes under 2nd stage loader)

.global main

main:
    jmp short start                       # jump to beginning of code
    nop

.include "bootsector.s"
.include "macros.s"

start:
  mInitSegments  
  mResetDiskSystem
  mWriteString loadmsg
  mFindFile filename, LOAD_SEGMENT
  mReadFAT FAT_SEGMENT
  mReadFile LOAD_SEGMENT, FAT_SEGMENT
  mStartSecondStage

# 
# Booting has failed because of a disk error. 
# Inform the user and reboot.
# 
bootFailure:
  mWriteString diskerror
  mReboot

.include "functions.s"
    
# PROGRAM DATA
filename:         .asciz "[Freud-OS] 2NDSTAGEBIN"
rebootmsg:        .asciz "Press any key to reboot.\r\n"
diskerror:        .asciz "Disk error. \r\n"
loadmsg:          .asciz "Loading [Freud-OS]...\r\n"

root_strt:   .byte 0,0      # hold offset of root directory on disk
root_scts:   .byte 0,0      # holds # sectors in root directory
file_strt:   .byte 0,0      # holds offset of bootloader on disk

.fill (510-(.-main)), 1, 0  # Pad with nulls up to 510 bytes (excl. boot magic)
BootMagic:  .int 0xAA55     # magic word for BIOS
