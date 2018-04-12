;+ARCHIVE+ zlmul.asm      718 12/11/1984 13:03:24

	include	model.h

;	multiply two longs

	include	prologue.h

;	entry	1,two longs on the stack
;	exit	1,result on stack, other long popped from stack

a1	equ	@ab[bp]
a2	equ	@ab+4[bp]

	public	$lmul

if	@BIGCODE 
$lmul	proc	far
else
$lmul	proc	near
endif

	push	bp
	mov	bp,sp
	push	ax
	push	dx
	mov	ax,a2+2		;get high
	mul	word ptr a1	;* low
	mov	a2+2,ax		;partial result
	mov	ax,a1+2		;other high
	mul	word ptr a2	;other low
	add	a2+2,ax		;more partial result
	mov	ax,a1		;low
	mul	word ptr a2	;other low
	mov	a2,ax		;result
	add	a2+2,dx		;finish partial result
	pop	dx
	pop	ax
	pop	bp		;get back frame pointer
	ret	4		;dump one long

$lmul	endp

	include	epilogue.h

	end
        