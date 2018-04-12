;+ARCHIVE+ zlrushft.asm   739 12/11/1984 13:03:28

	include	model.h

;	long right unsigned shift

	include	prologue.h

;	entry	1, number of bits to shift (as a long for now)
;		2, long to shift

;	exit	shifted value on stack

a1	equ	@ab
a2	equ	@ab+4

	public	$lrushift

if	@BIGCODE 
$lrushift	proc	far
else
$lrushift	proc	near
endif

	push	bp
	mov	bp,sp
	push	cx
	push	dx
	push	ax
	mov	cx,a1[bp]
	jcxz	lru09			;don't shift anything
	cmp	cx,32			;max number of bits
	jbe	lru01			;valid
	mov	cx,32			;set to maximum
lru01:
	mov	ax,a2[bp]
	mov	dx,a2+2[bp]
lru02:
	shr	dx,1
	rcr	ax,1
	loop	lru02			;do it for all bits
	mov	a2[bp],ax
	mov	a2+2[bp],dx
lru09:
	pop	ax
	pop	dx
	pop	cx
	pop	bp
	ret	4

$lrushift	endp

	include	epilogue.h

	end
        