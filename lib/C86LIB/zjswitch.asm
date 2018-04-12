;+ARCHIVE+ zjswitch.asm   617 12/11/1984 13:04:00

	include	model.h

;	code to process a jump table switch statement

	include	prologue.h

;	entry	1, value to compare

	public	$jswitch

if	@BIGCODE 
$jswitch	proc	far
else
$jswitch	proc	near
endif

if	@BIGCODE 
	pop	di			; pop offset
	pop	es			; pop segment
else
	pop	di			; pop offset
	mov	ax,cs			; es <- cs
	mov	es,ax
endif		   
	pop	bx			; get check value
	sub	bx,es:[di]
	cmp	bx,es:02[di]		; in range ?
	jb	do_switch
	mov	bx,-1
do_switch:
	shl	bx,1
if	@BIGCODE 
	push	es
	push	es:06[bx+di]
	ret
else
	jmp	es:06[bx+di]	
endif
$jswitch	endp

	include	epilogue.h

	end
