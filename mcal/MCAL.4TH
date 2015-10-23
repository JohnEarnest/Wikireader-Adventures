\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\
\  MCal
\
\  A page-a-day calendar written
\  in Ficl-Forth for the WikiReader.
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

decimal lcd-cls 1 1 lcd-at-xy 76 lcd-emit

: inc  dup @ 1+ swap ! ;
: dec  dup @ 1- swap ! ;

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\
\  Higher-Level graphics routines:
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: lcd-column ( -- n ) lcd-x @ font-width / ;
: lcd-back   ( -- )   -8 0 lcd-move-rel ;

: fillbox ( w h -- )
    lcd-x @ swap
    ( w x h )
    0 do
        over 1- 0 lcd-line-rel
        dup lcd-x !
        lcd-y inc
    loop
    2drop
;

79 lcd-emit

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\
\  Persistence:
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

variable date-buffer
: date-file s" DATE.TXT" ;

: save-date ( n -- )
    date-buffer !
    date-file delete-file drop
    date-file w/o create-file 0= if
        \ we successfully opened the file
        >r date-buffer 1 cells r> dup >r write-file

        \ if the write fails, just give up
        drop r> close-file drop
    else
        drop
    then
;

: load-date ( -- n )
    date-file r/o open-file 0= if
        \ we successfully opened the file
        >r date-buffer 1 cells r> dup >r read-file

        \ return what's in our buffer even if read fails
        2drop date-buffer @ r> close-file drop
    else
        drop 0
    then
;

65 lcd-emit

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\
\  Calendar Logic:
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

variable selected  2 selected !
variable date      0 date     !

variable thisYear
variable thisMonth
variable thisDay
variable thisFirst
variable thisMonthDays

create monthDays 31 , 28 , 31 , 30 , 31 , 30 , 31 , 31 , 30 , 31 , 30 , 31 ,

: leapyear? ( year -- flag )
    dup 400 mod 0= if drop true exit then
    dup 4 mod 0= swap 100 mod 0<> and
;

: days-in-month ( -- days )
    thisYear @ thisMonth @
    12 mod dup cells monthDays + @
    swap 1 = if over leapyear? if 1+ then then
    nip
;

: reset-date ( -- )
    2014 thisYear  !
       0 thisMonth !
       0 thisDay   !
       2 thisFirst !
    days-in-month thisMonthDays !
;

: step-date ( -- )
    thisDay inc
    thisDay @ thisMonthDays @ < if exit then

    thisFirst @ thisMonthDays @ + 7 mod thisFirst !
    0 thisDay ! thisMonth inc days-in-month thisMonthDays !
    thisMonth @ 12 < if exit then

    0 thisMonth ! thisYear inc
;

: set-date ( n -- )
    date ! reset-date
    date @ 0 ?do step-date loop
;

68 lcd-emit

: step-to ( day year month -- )
    \ sanity check month and carry years as needed:
    dup 11 > if drop 1+  0 then
    dup  0 < if drop 1- 11 then
    \ sanity check year and clamp as needed:
    over 2014 < if 2drop 2014 0 then
    begin
        over thisYear  @ =
        over thisMonth @ =
        and if
            2drop
            \ sanity check day, clamping as needed:
            dup days-in-month > if drop days-in-month then
            0 ?do date inc step-date loop

            date @ save-date exit
        then
        date inc step-date
    again
;

: set-day ( day -- )
    \ keep year and month
    thisYear @ thisMonth @
    0 date ! reset-date
    step-to
;

: next-date ( -- )
    selected @ 0= if
        thisDay   @
        thisYear  @ 1+
        thisMonth @
        step-to exit
    then
    selected @ 1 = if
        thisDay   @
        thisYear  @
        thisMonth @ 1+
        step-to exit
    then
    date inc step-date date @ save-date 
;

: prev-date ( -- )
    \ the universe begins on january 1st 2014:
    date @ 0= if exit then

    selected @ 0= if
        thisDay   @
        thisYear  @ 1-
        thisMonth @
        reset-date 0 date ! step-to exit
    then
    selected @ 1 = if
        thisDay   @
        thisYear  @
        thisMonth @ 1-
        reset-date 0 date ! step-to exit
    then
    date @ 1- set-date date @ save-date
;

73 lcd-emit

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\
\  Fact Storage:
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

create fact-buffer  1024 allot
create fact-data    366 1024 * allot
create fact-entries 366 2 * cells allot
variable fact-count  0 fact-count !
variable fact-head   fact-data fact-head !

: load-fact ( addr len -- )
    fact-count @ 366 = if
        2drop ." Fact capacity exceeded." cr exit
    then
    2dup >r fact-head @ r> cmove
    nip fact-head @
    over fact-head @ + fact-head !
    fact-count @ 2 * cells fact-entries +
    swap over ! 1 cells + ! fact-count inc
;

: load-facts ( -- )
    s" FACTS.TXT" r/o open-file 0= if
        >r
        begin
            fact-buffer 1024 r> dup >r read-line
            0= if
                0= if drop r> close-file drop exit then
                fact-buffer swap load-fact
            else
                drop drop r> close-file drop exit
            then
        again
    else
        drop ." Unable to load fact database!" cr
    then
;

: get-fact ( index -- addr len )
    fact-count @ mod
    2 * cells fact-entries +
    dup @ swap 1 cells + @
;

78 lcd-emit

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\
\  Fact Display:
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

variable text-addr
variable text-len
variable word-addr
variable word-len

: next-word ( -- word-addr word-len )
    text-addr @ word-addr !
    0           word-len  !
    begin
        \ if we've reached a whitespace or eos, break.
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
    1 5 lcd-at-xy lcd-black
    text-len  !
    text-addr !
    begin
        text-len @ 1 < if exit then
        next-word
        dup 1 + lcd-column + lcd-text-columns 1 - > if lcd-cr then
        8 0 lcd-move-rel
        lcd-type
    again
;

: draw-fact ( index -- )
    lcd-white
    1 3 lcd-at-xy s"  Did you know...?           " lcd-type
    get-fact text-wrap
;

71 lcd-emit

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\
\  Calendar Display:
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: .year ( n -- )
    selected @ 0 = if lcd-white else lcd-black then
    lcd-space lcd-u.
;

: .month ( n -- )
    selected @ 1 = if lcd-white else lcd-black then
    s" JanFebMarAprMayJunJulAugSepOctNovDec"
    drop swap 12 mod 3 * + 3 lcd-space lcd-type lcd-space
;

: .day ( n -- )
    dup 10 mod 1 = over 11 <> and if lcd-u. lcd-back s" st " lcd-type exit then
    dup 10 mod 2 = over 12 <> and if lcd-u. lcd-back s" nd " lcd-type exit then
    dup 10 mod 3 = over 13 <> and if lcd-u. lcd-back s" rd " lcd-type exit then
    lcd-u. lcd-back s" th " lcd-type
;

: box>day ( pos -- label )
    dup thisFirst @ < if drop -1 exit then
    thisFirst @ -
    dup days-in-month > if drop -1 exit then
;

: daybox-outline ( label pos -- )
    dup  7 mod 32 *  7 + \ x
    swap 7 /   26 * 34 + \ y
    lcd-move-to lcd-black
    thisDay @ 1+ = >r
    33 27 r> if fillbox else lcd-box then
;

46 lcd-emit

: daybox-label ( label pos -- )
    dup  7 mod 4 * 2 + \ x
    swap 7 /   2 * 3 + \ y
    lcd-at-xy
    dup thisDay @ 1+ = if lcd-white else lcd-black then
    dup 10 < if lcd-space then lcd-u.
;

: daybox ( label pos -- )
    2dup
    over thisDay @ 1+ = if
    daybox-outline daybox-label else
    daybox-label daybox-outline then
;

: xy>box ( x y -- pos )
    over 7 < over 34 < or if 2drop -1 exit then
    34 - 26 / dup 5 > if 2drop -1 exit then swap \ y
     7 - 32 / dup 6 > if 2drop -1 exit then swap \ x
    7 * +
;

: draw-calendar ( -- )
    lcd-clear-all
    1 1 lcd-at-xy
    thisMonth @ .month
    selected @ 2 = if
        thisDay @ 1+ .day
    then
    23 1 lcd-at-xy
    thisYear @ .year

    selected @ 2 = if
        date @ draw-fact
    else
        42 0 do
            i box>day
            dup 0 > if i daybox else drop then
        loop
    then
;

46 lcd-emit

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\
\  The main program:
\
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: handle-buttons ( -- updated )
    false
    button case
        button-power  of endof
        button-left   of prev-date true or endof
        button-right  of next-date true or endof
        button-centre of selected @ 1 + 3 mod selected ! true or endof
    endcase
;

: handle-touch ( -- updated )
    ctp-pos
    over -1 = over -1 = and if
        2drop false exit
    then

    selected @ 2 = if
        \ tapping on fact view returns to calendar view:
        1 selected !
        2drop true exit
    then

    dup 34 < if
        drop
        selected @ 1 = if
            160 > dup if 0 selected ! then exit
        then
        selected @ 0 = if
            80 < dup if 1 selected ! then exit
        then
        drop false exit
    then

    xy>box     dup 0 < if drop false exit then
    box>day 1- dup 0 < if drop false exit then
    
    dup thisDay @ = if
        2 selected !
        drop true exit
    then

    set-day true
;

46 lcd-emit

: main ( -- )
    load-facts
    load-date set-date
    ctp-flush
    key-flush
    draw-calendar
    begin
        false
        key?     if key-flush then
        ctp-pos? if handle-touch   or ctp-flush    then
        button?  if handle-buttons or button-flush then
        if draw-calendar then
        wait-for-event
    again
;

main