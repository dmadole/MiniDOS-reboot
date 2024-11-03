
;  Copyright 2023, David S. Madole <david@madole.net>
;
;  This program is free software: you can redistribute it and/or modify
;  it under the terms of the GNU General Public License as published by
;  the Free Software Foundation, either version 3 of the License, or
;  (at your option) any later version.
;
;  This program is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  GNU General Public License for more details.
;
;  You should have received a copy of the GNU General Public License
;  along with this program.  If not, see <https://www.gnu.org/licenses/>.


          ; Definition files

          #include include/bios.inc
          #include include/kernel.inc


          ; Executable header block

            org   1ffah
            dw    begin
            dw    end-begin
            dw    begin

begin:      br    start

            db    11+80h
            db    2
            dw    2024
            dw    start

            db    'See github/dmadole/MiniDOS-reboot for more information',0


          ; Parse over command line arguments to capture the option and the
          ; two filenames, which will be left in RF and RA.

start:      lda   ra                    ; skip any leading whitespace
            lbz   reboot
            sdi   ' '
            lbdf  start

            ghi   ra                    ; remember start of filename
            phi   rf
            glo   ra
            plo   rf

            dec   rf                    ; back up to valid character

skipinp:    lda   ra                    ; skip over filename
            lbz   endargs
            sdi   ' '
            lbnf  skipinp

            dec   ra                    ; zero terminate filename
            ldi   0
            str   ra
            inc   ra

skipsp2:    lda   ra                    ; skip over whitespace after name
            lbz   endargs
            sdi   ' '
            lbdf  skipsp2

            lbr    dousage


          ; If a kernel filename argument was supplied, open it and load to
          ; memory, then copy it over the existing kernel as the boot loader
          ; would do, then jump to it to start.

endargs:    ldi   fildes.1              ; pointer to file descriptor
            phi   rd
            ldi   fildes.0
            plo   rd

            ldi   0                     ; no open options
            plo   r7

            sep   scall                 ; open file and check if failed
            dw    o_open
            lbdf  inpfail

            ldi   end.1                 ; pointer to memory after program
            phi   rf
            ldi   end.0
            plo   rf

            ldi   255                   ; read maximum data size
            phi   rc
            plo   rc

            sep   scall                 ; load as much as there is
            dw    o_read
            lbdf  readerr

            sep   scall                 ; pointless close it anyway
            dw    o_close


          ; Display the version number of the kernel being booted.

            ldi   (end+100h).1          ; pointer to version info
            phi   r9
            ldi   (end+100h).0
            plo   r9

            ldi   string1.1             ; pointer to string buffer
            phi   rf
            ldi   string1.0
            plo   rf

            ldi   3                     ; count of dotted numbers
            plo   rb

            lbr   skipdot               ; skip the first dot

version:    ldi   '.'                   ; output dot to buffer
            str   rf
            inc   rf

skipdot:    lda   r9                    ; get element of version
            plo   rd
            ldi   0
            phi   rd

            sep   scall                 ; convert to decimal
            dw    f_intout

            dec   rb                    ; loop until three elements
            glo   rb
            lbnz  version

            str   rf                    ; zero terminate string

            ldi   message1.1            ; point back to beginning
            phi   rf
            ldi   message1.0
            plo   rf

            sep   scall                 ; and display version
            dw    o_msg

            ldi   string2.1             ; pointer to build string
            phi   rf
            ldi   string2.0
            plo   rf

            lda   r9                    ; get build number info
            phi   rd
            lda   r9
            plo   rd

            sep   scall                 ; convert to decimal
            dw    f_intout

            ldi   0                     ; zero terminate
            str   rf

            ldi   message2.1            ; pointer back to start
            phi   rf
            ldi   message2.0
            plo   rf

            sep   scall                 ; display build info
            dw    o_msg

            ldi   message3.1            ; pointer to end of message
            phi   rf
            ldi   message3.0
            plo   rf

            sep   scall                 ; output end of message
            dw    o_msg


          ; Now copy the kernel image over kernel memory at 0300h and then
          ; cold start it.
            
            ldi   end.1                 ; pointer to image in memory
            phi   rf
            ldi   end.0
            plo   rf
            
            ldi   0300h.1               ; pointer to kernel memory
            phi   rd
            phi   r0
            ldi   0300h.0
            plo   rd
            plo   r0

            sep   scall                 ; copy using bios routine
            dw    f_memcpy

            sex   r0                    ; jump as if from boot loader
            sep   r0


          ; If no argument was supplied, reboot the system via BIOS as
          ; after a hardware reset, reloading the default kernel.
            
reboot:     sep   scall                 ; confirm bios reboot action
            dw    o_inmsg
            db    'Rebooting via BI','OS...',13,10,13,10,0

            ldi   f_boot.1              ; setup bios boot vector
            phi   r0
            ldi   f_boot.0
            plo   r0

            sex   r0                    ; jump to it as if cold start
            sep   r0


          ; Message to display info of kernel being booted

message1:   db    'Booting kernel '
string1:    ds    12

message2:   db    ' build '
string2:    ds    6

message3:   db    '...',13,10,13,10,0


          ; Help message output when argument syntax is incorrect.

dousage:    sep   scall
            dw    o_inmsg
            db    'USAGE: boot [kernel]',13,1,0

            sep   sret


          ; Failure message output when input file can't be opened.

inpfail:    sep   scall
            dw    o_inmsg
            db    'ERROR: Can not open input file.',13,1,0

            sep   sret


          ; Failure message output when input file can't be opened.

readerr:    sep   scall
            dw    o_inmsg
            db    'ERROR: Can not read input file.',13,1,0

            sep   sret


          ; File descriptor used for reading in kernel

fildes:     db    0,0,0,0
            dw    dta
            db    0,0,0,0,0,0,0,0,0,0,0,0,0


          ; Data transfer area that is included in executable header size
          ; but not actually included in executable.

dta:        ds    512

end:        end    begin
