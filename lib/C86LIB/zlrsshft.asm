;+ARCHIVE+ zlrsshft.asm   705 12/11/1984 13:03:26

	include	model.h

;	long right signed shift

;	entry	2, value to be shifted
;		1, shift count

;	exit	shifted value in stack, shift count destroyed

	include	prologue.h

	public	$lrsshift

if	@BIGCODE 
$lrsshift	proc	far
else
$lrsshift	proc	near
endif
	push	bp
	mov	bp,sp
	push	ax
	push	dx
	push	cx
	mov	ax,@ab+4[bp]
	mov	dx,@ab+6[bp]
	mov	cx,@ab[bp]
	jcxz	lrs09			;don't shift anything
	cmp	cx,32			;max number of bits
	jbe	lrs01			;valid
	mov	cx,32			;set to maximum
lrs01:
	sar	dx,1
	rcr	ax,1
	loop	lrs01			;do it for all bits
lrs09:
	mov	@ab+4[bp],ax
	mov	@ab+6[bp],dx
	pop	cx
	pop	dx
	pop	ax
	pop	bp
	ret	4

$lrsshift	endp

	include	epilogue.h

	end
        