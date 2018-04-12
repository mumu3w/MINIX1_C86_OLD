;+ARCHIVE+ zentry.asm     781 12/11/1984 13:03:18
	include	model.h

;	stack check function
;	used for debugging by setting the '-t' switch in cc3

	extrn	_heaptop:word

	include	prologue.h

@code	ends
@datai	segment
fullmess	db	'NO CORE$'
@datai	ends
@code	segment

	public	$entry

if	@BIGCODE 
	extrn	_exit:far
$entry	proc	far
	mov	ax,_heaptop
	mov	cl,4
	shr	ax,cl
        add     ax,dgroup:_heaptop+2
	mov	dx,sp
	mov	cl,4
	shr	dx,cl
	mov	cx,ss
	add	dx,cx
	sub	dx,8			;result is 80h bytes
	cmp	dx,ax
	jbe	full	
else
	extrn	_exit:near
$entry	proc	near
	mov	ax,sp
	cmp	ax,80h
	jbe	full
	sub	ax,80h
	cmp	ax,_heaptop
	jbe	full
endif

	ret
full:
	mov	ah,9
	mov	dx,offset DGROUP:fullmess
	int	21h
	mov	ax,80f0h
	push	ax
	call	_exit
	jmp	full

$entry	endp
	include	epilogue.h
	end
        