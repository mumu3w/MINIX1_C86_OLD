;+ARCHIVE+ zfloatpp.asm 23386 11/15/1985 12:45:52

;
;
;	The auto-detect feature of the run-time has not been
;	completed!!!!!!!!!!!! It is working somewhat, but
;	is too dangerous to use at this time. We hope to get it
;	straightened out in the future, but CI makes no promises
;	on this.
;
;	If you want to mess with this, set auto8087 to non-zero
;	here and in zmain.asm in base.arc and reassemble/link
;	this and zmain to test it out.
;
auto8087	equ	0
;
	include	model.h

;	floating point routines

	include	prologue.h

@code	ends


@datac	segment 
if	auto8087
	extrn	_sys8087:word		; non-zero if 8087 present
endif
@datac	ends

@code	segment

if	@BIGCODE 
a1	equ	@ab+16
a2	equ	a1+8
else
a1	equ	@ab+14
a2	equ	a1+8
endif

	public	$dneg,$lcvtd,$icvtd,$drsub,$dsub,$dadd,$dcvtl,$dcvti
	public	$dcvtul,$dcvtui,$dmul,$ddiv
	public	$dceq,$dcne,$dcls,$dcle,$dcgr,$dcge

savreg:
if	@BIGCODE 
	push	es
endif
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	mov	bp,sp
if	@BIGCODE 
	jmp	word ptr 16[bp]
else
	jmp	word ptr 14[bp]
endif

resreg:
if	@BIGCODE 
	pop	16[bp]
else
	pop	14[bp]		;get the return address
endif
	mov	sp,bp
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
if	@BIGCODE 
	pop	es
endif
	ret

;	subroutine to move a string of words
;	entry	cx, number of words to move
;		si, source address relative to ss
;		di, dest address rel to ss

msw:
	cld			;set the direction flag
	mov	ax,ss
	mov	es,ax		;set the es register
if	@BIGCODE 
	push	ds
	mov	ds,ax
endif
	rep movsw
if	@BIGCODE 
	pop	ds
endif
	ret


;	subroutine to unpack a double
;	entry	si, address of double
;		di, where to unpack it

unpack:
	push	di
	mov	cx,4		;number of words to move
	add	di,cx		;correct offset
	call	msw
	pop	di		;thats the data copied
if	@BIGDATA 
	db	36h		;an ss: override
endif
	mov	ax,10[di]	;get most significant word
	mov	bx,ax		;copy it
	and	ax,07ff0h	;get exponent
if	@BIGDATA 
	db	36h		;an ss: override
endif
	mov	2[di],ax	;save it
	mov	ax,bx
	and	ax,08000h	;get sign
if	@BIGDATA 
	db	36h		;an ss: override
endif
	mov	[di],ax		;save it too
	and	bx,0fh
	or	bx,010h		;set significant bit of mantissa
if	@BIGDATA 
	db	36h		;an ss: override
endif
	mov	10[di],bx
	ret


;	subroutine to repack a double
;	entry	si, source of data
;		di, destination address

repack:

	push	si
	push	di
	mov	cx,4
	add	si,cx
	call	msw
	pop	di
	pop	si
if	@BIGDATA 
	db	36h		;an ss: override
endif
	mov	ax,10[si]
	and	ax,0fh
if	@BIGDATA 
	db	36h		;an ss: override
endif
	or	ax,[si]
if	@BIGDATA 
	db	36h		;an ss: override
endif
	or	ax,2[si]
if	@BIGDATA 
	db	36h		;an ss: override
endif
	mov	6[di],ax
	ret


;	normalize an unpacked double

;	entry	di, address of unpacked number to be normalised


normalize:

if	@BIGDATA 
	db	36h		;an ss: override
endif
	mov	ax,4[di]	;see if zero
if	@BIGDATA 
	db	36h		;an ss: override
endif
	or	ax,6[di]
if	@BIGDATA 
	db	36h		;an ss: override
endif
	or	ax,8[di]
if	@BIGDATA 
	db	36h		;an ss: override
endif
	or	ax,10[di]
	jnz	norf10
if	@BIGDATA 
	db	36h		;an ss: override
endif
	mov	[di],ax		;set it all to zero
if	@BIGDATA 
	db	36h		;an ss: override
endif
	mov	2[di],ax
	jmp	norf99		;all done
norf10:
	mov	bx,010h		;adjust exponent constant
	mov	ax,0ffe0h	;see if too large
norf11:
if	@BIGDATA 
	db	36h		;an ss: override
endif
	test	ax,10[di]	;get the most significant word
	jz	norf20		;nope
if	@BIGDATA 
	db	36h		;an ss: override
endif
	shr	word ptr 10[di],1	;shift it right
if	@BIGDATA 
	db	36h		;an ss: override
endif
	rcr	word ptr 8[di],1
if	@BIGDATA 
	db	36h		;an ss: override
endif
	rcr	word ptr 6[di],1
if	@BIGDATA 
	db	36h		;an ss: override
endif
	rcr	word ptr 4[di],1
if	@BIGDATA 
	db	36h		;an ss: override
endif
	add	word ptr 2[di],bx
	jmp	norf11
norf20:
	mov	ax,010h
norf21:
if	@BIGDATA 
	db	36h		;an ss: override
endif
	test	ax,10[di]
	jnz	norf99		;all done
if	@BIGDATA 
	db	36h		;an ss: override
endif
	shl	word ptr 4[di],1
if	@BIGDATA 
	db	36h		;an ss: override
endif
	rcl	word ptr 6[di],1
if	@BIGDATA 
	db	36h		;an ss: override
endif
	rcl	word ptr 8[di],1
if	@BIGDATA 
	db	36h		;an ss: override
endif
	rcl	word ptr 10[di],1
if	@BIGDATA 
	db	36h		;an ss: override
endif
	sub	2[di],bx		;adjust exponent
	jmp	norf21
norf99:
	ret


;	negate a number
;	don't bother with 8087

if	@BIGCODE 
$dneg	proc	far
else
$dneg	proc	near
endif
	push	bp
	mov	bp,sp
	test	word ptr @ab+6[bp],07ff0h	;is number zero ?
	jz	dneg01				;yes, don't negate
	xor	byte ptr @ab+7[bp],080h		;and negate it
dneg01:
	pop	bp
	ret
$dneg	endp

;	convert a double to an int
;	leaving the int on the stack
;	does not make use of 8087

if	@BIGCODE 
$icvtd	proc	far
else
$icvtd	proc	near
endif
	call	savreg
	sub	sp,10		;working space
	mov	cx,4		;words
	lea	si,a1[bp]	;source
	mov	di,sp		;destination
	call	msw		;perform move string words
	mov	ax,-4[bp]	;get sign of number
	and	ax,8000h
	xor	-4[bp],ax	;make number positive
	mov	-2[bp],ax	;and save for exit
	mov	ax,4330h	;unnormalise number
	push	ax
	xor	ax,ax
	push	ax
	push	ax
	push	ax
if	@BIGCODE 
	call	far ptr $dadd		;do it
else
	call	$dadd		;do it
endif
	mov	ax,-10[bp]
	mov	bx,-2[bp]	;was it negative
	or	bx,bx
	jz	icd01		;nope
	neg	ax
icd01:
	mov	a1+6[bp],ax
	call	resreg
	ret	6		;all done
$icvtd	endp

;	convert a double to long
;	leaving the long on the stack
;	does not use 8087

if	@BIGCODE 
$lcvtd	proc	far
else
$lcvtd	proc	near
endif
	call	savreg
	sub	sp,10		;working space
	mov	cx,4		;words
	lea	si,a1[bp]	;source
	mov	di,sp		;destination
	call	msw		;perform move string words
	mov	ax,-4[bp]	;get sign of number
	and	ax,8000h
	xor	-4[bp],ax	;make number positive
	mov	-2[bp],ax	;and save for exit
	mov	ax,4330h	;unnormalise number
	push	ax
	xor	ax,ax
	push	ax
	push	ax
	push	ax
if	@BIGCODE 
	call	far ptr $dadd		;do it
else
	call	$dadd		;do it
endif
	mov	ax,-10[bp]
	mov	dx,-8[bp]
	mov	bx,-2[bp]	;was it negative
	or	bx,bx
	jz	lcd01		;nope
	neg	dx
	neg	ax
	sbb	dx,0
lcd01:
	mov	a1+4[bp],ax
	mov	a1+6[bp],dx
	call	resreg
	ret	4		;all done
$lcvtd	endp

;	subtract the double float on top of stack from next double (reversed)

;	entry	two doubles on stack
;	exit	difference on stack

if	@BIGCODE 
$drsub	proc	far
else
$drsub	proc	near
endif
if	auto8087
	cmp	_sys8087,0
	jz	do$drsub
	fninit				; don't wait
	push	bp
	mov	bp,sp
	fld	qword ptr @ab[bp]  
	fsub	qword ptr @ab+8[bp]
	fstp	qword ptr @ab+8[bp]
	mov	sp,bp
	pop	bp
	fwait
	ret	8
do$drsub:
endif
	call	savreg
	xor	byte ptr a1+15[bp],80h	;invert sign to subtract
	jmp	short $dsub01
$drsub	endp

;	subtract the double float on top of stack from next double

;	entry	two doubles on stack
;	exit	difference on stack

if	@BIGCODE 
$dsub	proc	far
else
$dsub	proc	near
endif
if	auto8087
	cmp	_sys8087,0
	jz	do_$dsub
	fninit				; don't wait
	push	bp
	mov	bp,sp
	fld	qword ptr @ab[bp]  
	fsubr	qword ptr @ab+8[bp]
	fstp	qword ptr @ab+8[bp]
	mov	sp,bp
	pop	bp
	fwait
	ret	8
do_$dsub:
endif
	call	savreg
	xor	byte ptr a1+7[bp],80h	;invert sign to subtract
	jmp	short $dsub01
$dsub	endp

;	add two double float numbers and return result on stack

;	entry	two doubles on stack
;	exit 	the sum is on the stack
;	must preserv si

if	@BIGCODE 
$dadd	proc	far
else
$dadd	proc	near
endif
if	auto8087
	cmp	_sys8087,0
	jz	do_$dadd		; do 8087 add
	fninit				; don't wait
	push	bp
	mov	bp,sp
	fld	qword ptr @ab[bp]  
	fadd	qword ptr @ab+8[bp]
	fstp	qword ptr @ab+8[bp]
	mov	sp,bp
	pop	bp
	fwait
	ret	8
do_$dadd:
endif
	call	savreg
$dsub01:
	mov	ax,07ff0h
	test	ax,a1+6[bp]	;top operand zero ?
	jz	das00		;yes, just exit
	test	ax,a2+6[bp]	;or the other
	jnz	das01		;nope

	mov	cx,4		;words
	lea	si,a1[bp]	;source
	lea	di,a2[bp]
	call	msw		;perform move string words
das00:
	jmp	das99		;all done
das01:
	sub	sp,24		;room for temps
	lea	si,a1[bp]	;unpack the top operand
	mov	di,sp
	call	unpack
	lea	si,a2[bp]
	lea	di,-12[bp]
	call	unpack		;second operand

	mov	si,sp		;prepare to scale
	lea	di,-12[bp]
if	@BIGDATA 
	db	36h		;an ss: override
endif
	mov	ax,2[si]
if	@BIGDATA 
	db	36h		;an ss: override
endif
	sub	ax,2[di]
	jz	das10		;no scaling required
	jns	das02		;no reverse reqd
	xchg	di,si		;exchange registers
	neg	ax		;restore exponent in register
das02:
if	@BIGDATA 
	db	36h		;an ss: override
endif
	add	2[di],ax	;adjust exponent
	mov	cl,4		;make exponent an integer
	shr	ax,cl
	mov	cx,ax		;get the shift count
das03:
	mov	bx,6		;offset and count
	clc
das04:
if	@BIGDATA 
	db	36h		;an ss: override
endif
	rcr	word ptr 4[bx+di],1
	dec	bx
	dec	bx
	jns	das04		;shift it down
	loop	das03		;for all bits
das10:
	mov	cx,4		;loop count
	mov	bx,cx		;initialise offset
if	@BIGDATA 
	db	36h		;an ss: override
endif
	mov	ax,[di]		;add or subtract ?
if	@BIGDATA 
	db	36h		;an ss: override
endif
	xor	ax,[si]
	js	das12		;it is subtract
	clc
das11:
if	@BIGDATA 
	db	36h		;an ss: override
endif
	mov	ax,[bx+si]	;get a word
if	@BIGDATA 
	db	36h		;an ss: override
endif
	adc	[bx+di],ax
	inc	bx		;add 2 without changing carry
	inc	bx
	loop	das11
	jmp	das20
das12:
	clc
das13:
if	@BIGDATA 
	db	36h		;an ss: override
endif
	mov	ax,[bx+si]	;get a word
if	@BIGDATA 
	db	36h		;an ss: override
endif
	sbb	[bx+di],ax	;do subtract
	inc	bx		;add 2 without changing carry
	inc	bx
	loop	das13

if	@BIGDATA 
	db	36h		;an ss: override
endif
	mov	ax,10[di]	;is result negative ?
	or	ax,ax
	jns	das20		;nope
	xor	ax,ax
	mov	cx,4
	mov	bx,cx
	stc			;set carry
das14:
if	@BIGDATA 
	db	36h		;an ss: override
endif
	not	word ptr [bx+di];negate word 
if	@BIGDATA 
	db	36h		;an ss: override
endif
	adc	[bx+di],ax	;the hard way
	inc	bx
	inc	bx
	loop	das14
	mov	ah,080h
if	@BIGDATA 
	db	36h		;an ss: override
endif
	xor	[di],ax		;and reverse sign
das20:				;pack the result
	push	di
	call	normalize	;normalize the result
	pop	si
	lea	di,a2[bp]	;destination address
	call	repack		;pack the result

das99:
	test	word ptr a2+6[bp],07ff0h	;is result zero
	jnz	das999		;nope
	mov	word ptr a2+6[bp],0	;set result to zero
das999:
	call	resreg
	ret	8		;all done

$dadd	endp

;	convert an unsigned long to double
;	entry	number on the stack
;	don't bother with ndp

if	@BIGCODE 
$dcvtul	proc	far
else
$dcvtul	proc	near
endif
	sub	sp,4
	call	savreg
if	@BIGCODE 
	les	si,dword ptr a1[bp]
else
	mov	si,a1+2[bp]
endif
	mov	ax,a1+4[bp]
	mov	dx,a1+6[bp]
	jmp	short dcvtui00		;do the rest
$dcvtul	endp

;	convert unsigned integer to double
;	entry	integer on stack
;	don't bother with ndp

if	@BIGCODE 
$dcvtui	proc	far
else
$dcvtui	proc	near
endif
	sub	sp,6
	call	savreg
if	@BIGCODE 
	les	si,dword ptr a1+2[bp]
else
	mov	si,a1+4[bp]		;get return address
endif
	mov	ax,a1+6[bp]		;get integer
	xor	dx,dx
dcvtui00:
	xor	bx,bx
	push	bx
	push	bx
	jmp	short dcvti01
$dcvtui	endp

;	convert signed long to double
;	entry	long on stack
;	don't bother with ndp

if	@BIGCODE 
$dcvtl	proc	far
else
$dcvtl	proc	near
endif
	sub	sp,4
	call	savreg
if	@BIGCODE 
	les	si,dword ptr a1[bp]
else
	mov	si,a1+2[bp]
endif
	mov	ax,a1+4[bp]
	mov	dx,a1+6[bp]
	jmp	short dcvti00		;do the rest
$dcvtl	endp

;	convert signed integer to double
;	entry	integer on stack
;	don't bother with ndp

if	@BIGCODE 
$dcvti	proc	far
else
$dcvti	proc	near
endif
	sub	sp,6
	call	savreg
if	@BIGCODE 
	les	si,dword ptr a1+2[bp]
else
	mov	si,a1+4[bp]		;get return address
endif
	mov	ax,a1+6[bp]		;get integer
	cwd				;sign extend it
dcvti00:
	xor	bx,bx
	push	bx
	push	bx
	or	dx,dx		;is it negative
	jns	dcvti01		;nope
	neg	dx
	neg	ax
	sbb	dx,0
	or	bh,080h		;set sign
dcvti01:
if	@BIGCODE 
	mov	a1-4[bp],si
	mov	a1-2[bp],es
else
	mov	a1-2[bp],si	;set return address
endif
	push	dx
	push	ax
	mov	ax,04330h	;basic exponent
	push	ax
	push	bx		;sign
	mov	di,sp
	call	normalize	;check this code $$$
	mov	si,sp
	lea	di,a1[bp]
	call	repack
	call	resreg
	ret
$dcvti	endp


;	multiply two double float numbers and return result on stack

;	entry	two doubles on stack
;	exit 	the product is on the stack

if	@BIGCODE 
$dmul	proc	far
else
$dmul	proc	near
endif
if	auto8087
	cmp	_sys8087,0
	jz	do_$dmul
	fninit				; don't wait
	push	bp
	mov	bp,sp
	fld	qword ptr @ab[bp]  
	fmul	qword ptr @ab+8[bp]
	fstp	qword ptr @ab+8[bp]
	mov	sp,bp
	pop	bp
	fwait
	ret	8
do_$dmul:
endif
	call	savreg
	mov	ax,07ff0h
	test	ax,a2+6[bp]	;second operand zero ?
	jz	mul00		;yes, just exit
	test	ax,a1+6[bp]	;or the other
	jnz	mul01		;nope

	mov	cx,4		;words
	lea	si,a1[bp]	;source
	lea	di,a2[bp]
	call	msw		;perform move string words
mul00:
	jmp	mul99		;all done
mul01:
	sub	sp,24		;room for temps
	lea	si,a1[bp]	;unpack the top operand
	mov	di,sp
	call	unpack
	lea	si,a2[bp]
	lea	di,-12[bp]
	call	unpack		;second operand

	xor	bx,bx		;set up working area for multiply
	push	bx
	push	bx
	push	bx
	push	bx
	push	bx
	push	bx
	mov	si,sp		;create base for operation
	call	mulxx		;calc reloaction address
mulxx:
	pop	di
;WARNING--FOLLOWING TWO INSTRUCTIONS CANNOT BE COMBINED-BUG
	add	di,offset multab
	sub	di,offset mulxx	;address of mult table
;WARNING--SEE ABOVE
	mov	cx,13		;number of entries in table
mul02:
	mov	bl,cs:[di]	;get offset of operand 1
if	@BIGDATA 
	db	36h		;an ss: override
endif
	mov	ax,[bx+si]	;get it
	or	ax,ax		;if zero, fast continue
	jz	mul04
	mov	bl,cs:1[di]	;get offset of other operand
if	@BIGDATA 
	db	36h		;an ss: override
endif
	mul	word ptr [bx+si]	;unsigned multiply
	mov	bl,cs:2[di]	;get result address
if	@BIGDATA 
	db	36h		;an ss: override
endif
	add	[bx+si],ax	;add in result
	inc	bx
	inc	bx
if	@BIGDATA 
	db	36h		;an ss: override
endif
	adc	[bx+si],dx	;upper half
	jae	mul04		;all carry done (carry == 0)
mul03:
	inc	bx
	inc	bx
if	@BIGDATA 
	db	36h		;an ss: override
endif
	inc	word ptr [bx+si]	;do the carry
	jz	mul03		;still more carry
mul04:
	add	di,3		;to next frame
	loop	mul02		;do all words
	mov	ax,-10[bp]	;calc the result exponent
	sub	ax,04030h	;adjust for exponent and shift in mult routine
	add	ax,-22[bp]
	mov	-34[bp],ax	;and store it
	mov	ax,-12[bp]	;get sign of result
	xor	ax,-24[bp]
	mov	-36[bp],ax

	mov	di,sp
	call	normalize	;normalize the result
	mov	si,sp
	lea	di,a2[bp]	;destination address
	call	repack		;pack the result

mul99:
	call	resreg
	ret	8		;all done


;	multiplication table required above

multab:
	db	+24+10,+12+10,+10
	db	+24+8,+12+10,+8
	db	+24+10,+12+8,+8
	db	+24+8,+12+8,+6
	db	+24+6,+12+10,+6
	db	+24+6,+12+8,+4
	db	+24+6,+12+6,+2
	db	+24+10,+12+6,+6
	db	+24+8,+12+6,+4
	db	+24+4,+12+10,+4
	db	+24+4,+12+8,+2
	db	+24+10,+12+4,+4
	db	+24+8,+12+4,+2

$dmul	endp

;	divide two double float numbers and return result on stack

;	entry	two doubles on stack
;	exit 	the result is on the stack


if	@BIGCODE 
$ddiv	proc	far
else
$ddiv	proc	near
endif
if	auto8087
	cmp	_sys8087,0
	jz	do_$ddiv
	fninit				; don't wait
	push	bp
	mov	bp,sp
	fld	qword ptr @ab[bp]  
	fdiv	qword ptr @ab+8[bp]
	fstp	qword ptr @ab+8[bp]
	mov	sp,bp
	pop	bp
	fwait
	ret	8
do_$ddiv:
endif
	call	savreg
	mov	ax,07ff0h
	test	ax,a1+6[bp]	;second operand zero ?
	jnz	div000		;nope, test other operand
	mov	cx,4
	lea	si,a1[bp]
	lea	di,a2[bp]
	call	msw
	jmp	short div00
div000:
	test	ax,a2+6[bp]	;or the other
	jnz	div01		;nope

	mov	ax,0ffffh	;set overflow with large number
	mov	a2[bp],ax
	mov	a2+2[bp],ax
	mov	a2+4[bp],ax
	and	ah,07fh
	or	a2+6[bp],ax	;preserve sign
div00:
	jmp	div99		;all done
div01:
	sub	sp,12
	lea	si,a1[bp]	;get operand
	mov	di,sp
	call	unpack
	pop	bx		;save sign
	pop	cx		;and exponent
	xor	ax,ax		;some scratch space
	push	ax
	push	ax
	push	ax
	push	ax
	push	cx
	push	bx		;put it back

	sub	sp,12		;room for other temp
	lea	si,a2[bp]	;unpack the top operand
	mov	di,sp
	call	unpack

	mov	cx,53		;number of bits to divide
div02:
	push	cx		;save bit count
	mov	cx,4		;number of words to compare
	lea	si,-22[bp]
	lea	di,-2[bp]
div03:
if	@BIGDATA 
	db	36h		;an ss: override
endif
	mov	ax,[si]		;get divisor word
if	@BIGDATA 
	db	36h		;an ss: override
endif
	cmp	ax,[di]		;compare to dividend
	jb	div04		;yes it divides
	ja	div06		;no it does not
	dec	si		;a solid maybe
	dec	si
	dec	di
	dec	di
	loop	div03
div04:				;yes it does
	mov	cx,4
	lea	si,-28[bp]
	lea	di,-8[bp]
	clc
div05:
if	@BIGDATA 
	db	36h		;an ss: override
endif
	mov	ax,[si]
if	@BIGDATA 
	db	36h		;an ss: override
endif
	sbb	[di],ax
	inc	si
	inc	si
	inc	di
	inc	di
	loop	div05
	stc
div06:
	mov	cx,8		;number of words to shift
	lea	si,-16[bp]
div07:
if	@BIGDATA 
	db	36h		;an ss: override
endif
	rcl	word ptr [si],1
	inc	si
	inc	si
	loop	div07

	pop	cx
	loop	div02		;next bit

	mov	ax,-30[bp]	;calc the result exponent
	sub	ax,03ff0h	;adjust for exponent and shift in div routine
	sub	-18[bp],ax	;store adjusted exponent

	mov	ax,-32[bp]	;get sign of result
	xor	-20[bp],ax	;and save it

	lea	di,-20[bp]
	call	normalize	;normalize the result
	lea	si,-20[bp]
	lea	di,a2[bp]	;destination address
	call	repack		;pack the result

div99:
	call	resreg
	ret	8		;all done
$ddiv	endp

;	double precision floating point comparison routines
;	don't bother with ndp

if	@BIGCODE 
$dceq	proc	far			;return true if equal
else
$dceq	proc	near			;return true if equal
endif
	call	savreg
	mov	ax,202H
	jmp	short dcomp		;do internal comparison routine
$dceq	endp

if	@BIGCODE 
$dcne	proc	far			;return true if not equal
else
$dcne	proc	near			;return true if not equal
endif
	call	savreg
	mov	ax,505H
	jmp	short dcomp		;do internal comparison routine
$dcne	endp

if	@BIGCODE 
$dcls	proc	far			;return true if less
else
$dcls	proc	near			;return true if less
endif
	call	savreg
	mov	ax,104H
;	mov	ax,401H
	jmp	short dcomp		;do internal comparison routine
$dcls	endp

if	@BIGCODE 
$dcle	proc	far			;return true if less or equal
else
$dcle	proc	near			;return true if less or equal
endif
	call	savreg
	mov	ax,306H
;	mov	ax,603H
	jmp	short dcomp		;do internal comparison routine
$dcle	endp

if	@BIGCODE 
$dcgr	proc	far			;return true if greater
else
$dcgr	proc	near			;return true if greater
endif
	call	savreg
	mov	ax,401H
;	mov	ax,104H
	jmp	short dcomp		;do internal comparison routine
$dcgr	endp

if	@BIGCODE 
$dcge	proc	far			;return true if greater or equal
else
$dcge	proc	near			;return true if greater or equal
endif
	call	savreg
	mov	ax,603H
;	mov	ax,306H
;	jmp	short dcomp		;do internal comparison routine


;	actual routine to do comparison of two doubles on stack


dcomp:
	mov	ch,a1+7[bp]
	mov	dh,a2+7[bp]
	mov	cl,ch
	or	cl,dh
	jns	dcomp00		;both positive, continue
	mov	cl,ch
	xor	cl,dh
	jns	dcomp000	;both negative
	cmp	dh,ch
	jge	dcomp031
	jmp	short dcomp04
dcomp000:
	mov	al,ah		;invert test conditions
dcomp00:
	mov	cx,4
	mov	si,a1+6
dcomp01:
	mov	dx,8[si+bp]
	cmp	[si+bp],dx
	jnz	dcomp03
	dec	si
	dec	si
	loop	dcomp01

dcomp02:			;numbers are equal, set result
	and	al,2
	jz	dcomp99		;false
	jmp	short dcomp98		;true
dcomp03:			;numbers are not equal
	ja	dcomp04		;greater
dcomp031:
	and	al,1
	jz	dcomp99
	jmp	short dcomp98		;true
dcomp04:
	and	al,4
	jz	dcomp99
;	jmp	short dcomp98

dcomp98:			;set true
	mov	al,1
dcomp99:
	xor	ah,ah		;clear the top byte
	or	ax,ax		;set the flags
	mov	a2+6[bp],ax	;result to stack
	call	resreg
	ret	14		;dump the rest
$dcge	endp

	public	$dstore

;	store a double from the stack

;	entry	di, addres to store double
;	exit	stored and also on the stack

if	@BIGCODE 
$dstore	proc	far
else
$dstore	proc	near
endif
	call	savreg
if	@BIGDATA
	les	di,dword ptr a1[bp]
	mov	ax,a1+4[bp]
	mov	es:[di],ax
	mov	ax,a1+6[bp]
	mov	es:2[di],ax
	mov	ax,a1+8[bp]
	mov	es:4[di],ax
	mov	ax,a1+10[bp]
	mov	es:6[di],ax
	call	resreg
	ret	4
else
	mov	di,a1[bp]
	mov	ax,a1+2[bp]
	mov	[di],ax
	mov	ax,a1+4[bp]
	mov	2[di],ax
	mov	ax,a1+6[bp]
	mov	4[di],ax
	mov	ax,a1+8[bp]
	mov	6[di],ax
	call	resreg
	ret	2
endif
$dstore	endp

;	load a real to the stack

;	entry	address of real on stack
;	exit	double on stack

	public	$fload,$fstore

if	@BIGCODE 
$fload	proc	far
else
$fload	proc	near
endif

if	@BIGDATA
	sub	sp,4
else
	sub	sp,6
endif

	call	savreg
if	@BIGDATA
	;	big model
	les	ax,dword ptr a1[bp]
	mov	a1-4[bp],ax
	mov	a1-2[bp],es
	les	si,dword ptr a1+4[bp]	;get the data address
	mov	ax,es:2[si]		;get exponent
	mov	dx,es:[si]		;low word
else
if	@BIGCODE
	;	medium model
	les	ax,dword ptr a1+2[bp]   ;get return address
	mov	a1-4[bp],ax
	mov	a1-2[bp],es
	mov	si,a1+6[bp]		;get the data address
	mov	ax,2[si]		;get exponent
	mov	dx,[si]			;low word
else
	;	small model
	mov	ax,a1+4[bp]		;save the return address
	mov	a1-2[bp],ax
	mov	si,a1+6[bp]		;get the data address
	mov	ax,2[si]		;get exponent
	mov	dx,[si]			;low word
endif
endif
	xor	bx,bx			;zero it
	mov	cx,3			;number of bits to shift
ldr01:	sar	ax,1
	rcr	dx,1
	rcr	bx,1
	loop	ldr01			;three times
	and	ax,08fffh		;clear exponent bits
	jnz	ldr02			;it's real
	mov	bx,ax
	mov	dx,ax
	jmp	short ldr03		;final and return
ldr02:
	add	ax,3800h		;(3ffh-7fh) shl 4;adjust exponent
ldr03:
	mov	a1+6[bp],ax
	mov	a1+4[bp],dx
	mov	a1+2[bp],bx
	mov	word ptr a1[bp],0
	call	resreg
	ret
$fload	endp

;	store a float from the stack

;	entry	address to store float on stack
;	exit	float stored and still on stack (as a double)


if	@BIGCODE 
$fstore	proc	far
else
$fstore	proc	near
endif

if	@BIGDATA
av	equ	a1+4
else
av	equ	a1+2
endif

	call	savreg

	mov	di,av+6[bp]		;do rounding

	mov	ax,07ff0h
	and	ax,di
	cmp	ax,07ff0h		
	jz	fst10			; too big

	and	di,0fh			;keep the mantissa bits
	add	word ptr av+2[bp],1000h	;round it
	adc	word ptr av+4[bp],0
	adc	di,0
	test	di,16			;any carry ?
	jz	fstr50			;nope
	sub	di,16
	shr	di,1
	rcr	word ptr av+4[bp],1
	rcr	word ptr av+2[bp],1
	add	word ptr av+6[bp],16	;adjust exponent
fstr50:
	and	word ptr av+6[bp],0fff0h
	or	av+6[bp],di		;end of rounding 

	mov	ax,av+6[bp]		;get exponent part
	and	ax,07ff0h		;only
	sub	ax,3ff0h		;remove bias
	cmp	ax,07f0h
	jge	fst10			;too large to save
	cmp	ax,-07f0h
	jle	fst20			;too small to save
	mov	ax,av+6[bp]		;get exponent part
	sub	ax,3ff0h-7f0h		;reduce exponent range
	jns	fst01			;not negative
	or	ah,10h			;set new sign bit
fst01:
	mov	dx,av+4[bp]
	mov	bx,av+2[bp]
	mov	cx,3			;shift it left
fst02:
	shl	bx,1
	rcl	dx,1
	rcl	ax,1
	loop	fst02
	jmp	short fst99		;and out we go
fst10:
	mov	ax,av+6[bp]		;keep sign
	or	ax,7fffh
	mov	dx,0ffffh		;largest possable number
	jmp	short fst99
fst20:
	xor	ax,ax			;result is zero (really underflow)
	cwd
fst99:
if	@BIGDATA 
	les	di,dword ptr a1[bp]
	mov	es:[di],dx
	mov	es:2[di],ax
else
	mov	di,a1[bp]
	mov	[di],dx			;low order word
	mov	2[di],ax		;high order word
endif
	call	resreg
if	@BIGDATA 
	ret	4
else
	ret	2
endif
$fstore	endp

	include	epilogue.h
	end
        