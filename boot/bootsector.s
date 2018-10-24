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

bootsector:
 iOEM:        .ascii "DevOS   "    # OEM String
 iSectSize:   .word  0x200         # Bytes per sector
 iClustSize:  .byte  1             # Sectors per cluster
 iResSect:    .word  1             # #of reserved sectors
 iFatCnt:     .byte  2             # #of fat copies
 iRootSize:   .word  224           # size of root directory
 iTotalSect:  .word  2880          # total # of sectors if below 32 MB
 iMedia:      .byte  0xF0          # Media Descriptor
 iFatSize:    .word  9             # Size of each FAT
 iTrackSect:  .word  9             # Sectors per track
 iHeadCnt:    .word  2             # number of read-write heads
 iHiddenSect: .int   0             # number of hidden sectors
 iSect32:     .int   0             # # sectors if over 32 MB
 iBootDrive:  .byte  0             # holds drive that the boot sector came from
 iReserved:   .byte  0             # reserved, empty
 iBootSign:   .byte  0x29          # extended boot sector signature
 iVolID:      .ascii "seri"        # disk serial
 acVolLabel:  .ascii "MYVOLUME   " # just placeholder. We don't yet use volume labels.
 acFSType:    .ascii "FAT16   "    # file system type
/* end boot sector */
