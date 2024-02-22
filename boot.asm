
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


          ; Unpublished kernel vector points

d_ideread:  equ   0447h
d_idewrite: equ   044ah


          ; Executable header block

            org   1ffah
            dw    begin
            dw    end-begin
            dw    begin

begin:      br    start

            db    8+80h
            db    14
            dw    2023
            dw    start

            db    'See github/dmadole/Elfos-zx1 for more information',0


          ; Parse over command line arguments to capture the option and the
          ; two filenames, which will be left in RF and RA.

start:      ldi   f_boot.1
            phi   r0
            ldi   f_boot.0
            plo   r0

skipspc:    lda   ra                    ; skip any leading whitespace
            lbz   reboot
            sdi   ' '
            lbdf  skipspc

            ghi   ra
            phi   rf
            glo   ra
            plo   rf

            dec   rf

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


          ; Open the input file and seek to end to get the length of it.

endargs:    ldi   fildes.1              ; pointer to file descriptor
            phi   rd
            ldi   fildes.0
            plo   rd

            ldi   0                     ; no open options
            plo   r7

            sep   scall                 ; open file and check if failed
            dw    o_open
            lbdf  inpfail

            ldi   end.1
            phi   rf
            ldi   end.0
            plo   rf

            ldi   255                   ; read maximum size
            phi   rc
            plo   rc

            sep   scall                 ; get as much as there is
            dw    o_read
            lbdf  readerr

            sep   scall                 ; pointless but close file
            dw    o_close

            ldi   (end+100h).1
            phi   r9
            ldi   (end+100h).0
            plo   r9

            ldi   string1.1
            phi   rf
            ldi   string1.0
            plo   rf

            ldi   3
            plo   rb

            lbr   skipdot

version:    ldi   '.'
            str   rf
            inc   rf

skipdot:    lda   r9
            plo   rd
            ldi   0
            phi   rd

            sep   scall
            dw    f_intout

            dec   rb
            glo   rb
            lbnz  version

            str   rf

            ldi   message1.1
            phi   rf
            ldi   message1.0
            plo   rf

            sep   scall
            dw    o_msg

            ldi   string2.1
            phi   rf
            ldi   string2.0
            plo   rf

            lda   r9
            phi   rd
            lda   r9
            plo   rd

            sep   scall
            dw    f_intout

            ldi   0
            str   rf

            ldi   message2.1
            phi   rf
            ldi   message2.0
            plo   rf

            sep   scall
            dw    o_msg

            ldi   message3.1
            phi   rf
            ldi   message3.0
            plo   rf

            sep   scall
            dw    o_msg

            
            ldi   end.1
            phi   rf
            ldi   end.0
            plo   rf
            
            ldi   0300h.1
            phi   rd
            phi   r0
            ldi   0300h.0
            plo   rd
            plo   r0

            sep   scall
            dw    f_memcpy

            sex   r0
            sep   r0
            
reboot:     sep   scall
            dw    o_inmsg
            db    'Booting default kernel...',13,10,13,10,0

            sex   r0
            sep   r0


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


          ; File descriptor used for both intput and output files.

fildes:     db    0,0,0,0
            dw    dta
            db    0,0,0,0,0,0,0,0,0,0,0,0,0


          ; Data transfer area that is included in executable header size
          ; but not actually included in executable.

dta:        ds    512

end:        end    begin
