;	define memory model for library assembly code

FALSE	equ	0	;for small model
TRUE	equ	1	;for big model

; small model:= 	@bigmodel and @medmodel are false
; medium model:=	@bigmodel is false, @medmodel is true
; big model:=		@bigmodel is true, @medmodel is false

@BIGMODEL EQU FALSE	; select this for model desired
@MEDMODEL EQU FALSE	; medium model switch

if1
if	@bigmodel
%out	BIG MODEL ASSEMBLY
else
if	@medmodel
%out	MEDIUM MODEL ASSEMBLY
else
%out	SMALL MODEL ASSEMBLY
endif
endif
endif

;	@BIGCODE means far procedures
;	@BIGDATA means 4 byte data pointers

@bigcode	equ	(@bigmodel or @medmodel)
@bigdata	equ	@bigmodel

