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

.include "macros.s"

.global main

main:
  xchg bx, bx
  mWriteString msg
hang:
  jmp hang

# 
# Booting has failed because of a disk error. 
# Inform the user and reboot.
# 
bootFailure:
  mWriteString diskerror
  mReboot
  
.include "functions.s"

# PROGRAM DATA
msg:          .asciz "2nd stage bootloader...\r\n"
rebootmsg:    .asciz "Press any key to reboot.\r\n"
diskerror:    .asciz "Disk error. "

.include "bootsector.s"

.fill 1024, 1, 1              # Pad 1K with 1-bytes to test file larger than 1 sector
