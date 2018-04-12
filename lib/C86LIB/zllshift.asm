;+ARCHIVE+ zllshift.asm   703 12/11/1984 13:03:24

	include	model.h

;	long left shift

	include	prologue.h

;	entry	1, shift count
;		2, the value to be shifted

;	exit	shifted value on stack

a1	equ	@ab
a2	equ	@ab+4

	public	$llshift

if	@BIGCODE 
$llshift	proc	far
else
$llshift	proc	near
endif

	push	bp
	mov	bp,sp
	push	cx
	push	dx
	push	ax
	mov	cx,a1[bp]
	jcxz	lls09			;don't shift anything
	cmp	cx,32			;max number of bits
	jbe	lls01			;valid
	mov	cx,32			;set to maximum
lls01:
	mov	ax,a2[bp]
	mov	dx,a2+2[bp]
lls02:
	shl	ax,1
	rcl	dx,1
	loop	lls02			;do it for all bits
	mov	a2[bp],ax
	mov	a2+2[bp],dx
lls09:
	pop	ax
	pop	dx
	pop	cx
	pop	bp
	ret	4

$llshift	endp

	include	epilogue.h

	end
  