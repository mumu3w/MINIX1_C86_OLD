;+ARCHIVE+ zldivmod.asm  1855 12/11/1984 13:03:22

	include	model.h

;	does division of two signed longs

	include	prologue.h

a1	equ	@ab+10
a2	equ	@ab+14

	public	$lsdiv,$ludiv,$lsmod,$lumod

if	@BIGCODE 
$lsdiv	proc	far
else
$lsdiv	proc	near
endif
	push	ax
	xor	al,al			;signed div
	jmp	short dm01
$lsdiv	endp

if	@BIGCODE 
$ludiv	proc	far
else
$ludiv	proc	near
endif
	push	ax
	mov	al,1			;unsigned div
	jmp	short dm01
$ludiv	endp

if	@BIGCODE 
$lsmod	proc	far
else
$lsmod	proc	near
endif
	push	ax
	mov	al,2			;signed mod
	jmp	short dm01
$lsmod	endp

if	@BIGCODE 
$lumod	proc	far
else
$lumod	proc	near
endif
	push	ax
	mov	al,3

dm01:

	push	bx
	push	cx
	push	dx
	push	si
	push	bp
	mov	bp,sp
	push	di			;save for caller
	cbw				;zero top byte
	xchg	ax,bx			;save flags

	mov	ax,a1[bp]
	mov	dx,a1+2[bp]
	mov	si,a2[bp]
	mov	di,a2+2[bp]

	test	bl,1			;signed ?
	jnz	dm03			;nope
	or	dx,dx
	jns	dm02
	neg	dx
	neg	ax
	sbb	dx,0
	inc	bh
dm02:
	or	di,di
	jns	dm03
	neg	di
	neg	si
	sbb	di,0
	xor	bh,3
dm03:
	push	bx
	mov	cx,32		;loop counter
	xor	bx,bx		;set to zero
	push	bx
dm04:
	xchg	cx,-6[bp]	;get back dividend
	sal	ax,1		;left 1 bit
	rcl	dx,1
	rcl	bx,1
	rcl	cx,1
	cmp	di,cx		;will it go
	ja	dm06		;nope
	jb	dm05		;yes
	cmp	si,bx		;maybe
	ja	dm06
dm05:
	sub	bx,si
	sbb	cx,di
	inc	ax		;bit to result
dm06:
	xchg	cx,-6[bp]	;check loop counter
	loop	dm04
	pop	si		;get remainder
	pop	cx		;get control
	test	cl,2		;if mod, result to ax,dx
	jz	dm07
	xchg	ax,bx
	mov	dx,si
	test	ch,2
	jz	dm07
	xor	ch,1		;invert bit
dm07:
	test	cl,1		;signed ?
	jnz	dm08		;nope
	test	ch,1		;reverse sign ?
	jz	dm08		;nope
	neg	dx
	neg	ax
	sbb	dx,0
dm08:
	mov	a2[bp],ax
	mov	a2+2[bp],dx

	pop	di
	pop	bp
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret	4

$lumod	endp

	include	epilogue.h

	end
        