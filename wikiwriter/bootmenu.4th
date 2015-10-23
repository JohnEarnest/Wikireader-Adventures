\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\  
\  Inspire-o-tron
\ 
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

decimal lcd-cls

: inc  dup @ 1+ swap ! ; ( addr -- )
: dec  dup @ 1- swap ! ; ( addr -- )

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\  
\  Random number generator
\
\  A simple linear congruential generator
\  with a seed persisted to a file.
\ 
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

variable seed

: seed-file s" DATA/SEED.TXT" ; ( -- addr len )

: load-seed ( -- )
    seed-file r/o open-file 0= if
        >r seed 1 cells r> dup >r read-file 2drop
        r> close-file drop
    else
        drop 8675309 seed !
    then
;

load-seed

: save-seed ( -- )
    seed-file delete-file drop
    seed-file w/o create-file 0= if
        >r seed 1 cells r> dup >r write-file drop
        r> close-file drop
    else
        drop
    then
;

: random ( max -- n )
    seed @ 1664525 * 1013904223 + dup seed ! over mod
    dup 0< if over + then nip
    save-seed
;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\  
\  Random tables
\
\  `rtable` loads lines from a text file
\  into memory, and then the `any`
\  helper word can retrieve a random
\  entry from this table as a string.
\ 
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

128 constant entry-size

variable file-handle
variable entry-count
variable entry-head

: rtable ( addr len -- )
    r/o open-file
    create
    0= if
        file-handle !
        here entry-count ! 0 ,
        
        begin
            here entry-head ! 0 ,   \ reserve str len slot
            entry-size allot        \ reserve str storage
            
            entry-head @ 1 cells +  \ storage addr
            entry-size              \ storage size
            file-handle @ read-line
            drop 0= if
                drop                          \ discard bogus line data
                file-handle @ close-file drop \ close file handle
                exit
            then
                
            entry-head  @ !    \ copy the length into place
            entry-count @ inc  \ increment entry no.
        again
    else
        drop ." Unable to load rtable data." cr
    then
;

: any ( rtable -- addr len )
    dup @ random           ( base random-index )
    entry-size 1 cells + * ( base random-offset )
    + 1 cells +            ( entry-base )
    dup 1 cells + swap @
;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\  
\ Wrapped text display
\ 
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

variable text-addr
variable text-len
variable word-addr
variable word-len

: lcd-column  lcd-x @ font-width / ; ( -- n )

: next-word ( -- word-addr word-len )
    text-addr @ word-addr !
    0           word-len  !
    begin
        \ if we've reached whitespace or eos, break.
        text-addr @ c@ 32 = text-len @ 1 < or if
            text-addr inc
            text-len  dec
            word-addr @
            word-len  @
            exit
        then
        text-addr inc
        text-len  dec
        word-len  inc
    again
;

: text-wrap ( addr len -- )
    text-len  !
    text-addr !
    begin
        text-len @ 1 < if exit then
        next-word
        dup 1+ lcd-column + lcd-text-columns 1- > if lcd-cr then
        8 0 lcd-move-rel
        lcd-type
    again
;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\  
\  Static data:
\ 
\  the word s" works somewhat strangely
\  on the wikireader; it doesn't appear
\  to function as an immediate word.
\  as a result, we have to resort to
\  a slightly hacky workaround to
\  provide filenames for our rtable
\  declarations.
\ 
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: jobs     s" DATA/JOBS.TXT"     ; jobs     rtable job
: wants    s" DATA/WANTS.TXT"    ; wants    rtable want
: issues   s" DATA/ISSUES.TXT"   ; issues   rtable issue

: forms    s" DATA/FORMS.TXT"    ; forms    rtable form
: themes   s" DATA/THEMES.TXT"   ; themes   rtable theme
: features s" DATA/FEATURES.TXT" ; features rtable feature

: descs    s" DATA/DESC.TXT"     ; descs    rtable desc
: locs     s" DATA/LOCS.TXT"     ; locs     rtable loc
: places   s" DATA/PLACES.TXT"   ; places   rtable place

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\  
\  Image blitting:
\
\  Read a packed 1-bit bitmap
\  directly into the framebuffer
\  from a file.
\ 
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: blit-image ( addr len -- )
    r/o open-file 0= if
        file-handle !
        
        lcd-vram-size 0 do
            lcd-vram i + 32 file-handle @ read-file
            drop drop \ I don't care about the return value.
        32 +loop
        
        file-handle @ close-file drop
    else
        drop ." Unable to load image data." cr
    then
;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\  
\  The main program:
\ 
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: draw-common ( addr len -- )
    lcd-clear-all
    lcd-white
    1 1 lcd-at-xy
    lcd-type
    lcd-black
    1 3 lcd-at-xy
;

: draw-who ( -- )
    s"  Character...               "
    draw-common
    
    job any text-wrap
    s" who wants " text-wrap
    want any text-wrap
    s" but is impeded by " text-wrap
    issue any text-wrap
;

: draw-what ( -- )
    s"  Writing prompt...          "
    draw-common
    
    s" write " text-wrap
    form any text-wrap
    s" exploring " text-wrap
    theme any text-wrap
    s" and incorporating " text-wrap
    feature any text-wrap
;

: draw-where ( -- )
    s"  Setting...                 "
    draw-common
    
    desc any text-wrap
    loc any text-wrap
    place any text-wrap
;

: handle-buttons ( -- updated )
    button case
        button-none   of                                 endof
        button-power  of s" DATA/SPLASH1.IMG" blit-image endof
        button-left   of draw-who                        endof
        button-centre of draw-what                       endof
        button-right  of draw-where                      endof
    endcase
;

: main ( -- )
    ctp-flush
    key-flush
    button-flush
    s" DATA/SPLASH2.IMG" blit-image
    begin
        key?     if                key-flush    then
        ctp-pos? if                ctp-flush    then
        button?  if handle-buttons button-flush then
        wait-for-event
    again
; main
