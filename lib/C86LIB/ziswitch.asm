;+ARCHIVE+ ziswitch.asm   732  5/21/1985 16:14:34

	include	model.h

;	code to process an integer switch statement

	include	prologue.h

;	entry	1, value to compare

	public	$iswitch

if	@BIGCODE 
$iswitch	proc	far
else
$iswitch	proc	near
endif

	pop	di			; get data offset
if	@BIGCODE
	pop	es
else
	mov	ax,cs
	mov	es,ax
endif
	pop	ax		; and value to check
	db	026h		; es:
	mov	cx,[di]		; number of entries
	mov	bx,cx		; for exit
	sal	bx,1
	add	di,bx		; the last shall be first
	inc	cx		; for the default
	std			; set the direction flag
	repne scasw		; compare it
	add	di,4
	add	di,bx
if	@BIGCODE
	push	es
endif
	db	026h		; es:
	push	[di]
	cld			;more DOS bugs
	mov	ax,ds
	mov	es,ax
	ret

$iswitch	endp

	include	epilogue.h

	end
        