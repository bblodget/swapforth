\ File: hello.fs
\ Prints out "hello" after each key press.
\ Also toggles a variable between 0 and 1
\ each iteration.

: 1+        d# 1 + ;
: negate    invert 1+ ;
: 1-        d# -1 + ;
: 0=        d# 0 = ;

: <>        = invert ; 
: 0<>       d# 0 <> ;
: >         swap < ; 
: 0<        d# 0 < ; 
: 0>        d# 0 > ;

: 1ms 
	d# 0 
	begin
		dup d# 6552 < while 
			d# 1 +
	repeat
	drop
;

: ms
	begin
		dup 0> while
			1ms
			1-
	repeat
	drop
;


: leds  d# 4 io! ;


: uart-stat ( mask -- f ) \ is bit in UART status register on?
    h# 2000 io@ and
;

header key?
: key?
    d# 2 uart-stat 0<>
;

header key
: key
    begin
        key?
    until
;fallthru
: key>
    h# 1000 io@
;

header emit
: emit
    begin
        d# 1 uart-stat 
    until
    h# 1000 io!
;

: emit
    begin
        d# 1 uart-stat 
    until
    h# 1000 io!
;

header space
: space
    d# 32 emit
;

header cr
: cr
    d# 10
    d# 13
;fallthru
: 2emit
    emit emit
;

: hello
	[char] H emit
	[char] E emit
	[char] L emit
	[char] L emit
	[char] O emit
	cr
;

create my_var1 	1 ,

: main
	begin
		hello
		key drop
		my_var1 @i 0= if
			[char] 0 emit cr
			d# 1 my_var1 !
		else	
			[char] 1 emit cr
			d# 0 my_var1 !
		then
	again
;

