section .text

global filter_x86
global _filter_x86

filter_x86:
_filter_x86:
	push	ebp
	mov		ebp,	esp
	;reserve space for all variables
	sub		esp,	64

	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi

	;init x_f, y_f
	mov	DWORD[EBP-36],	0
	mov	DWORD[EBP-40],	0

	;calculate and store next_row_B
	mov		eax,	[EBP+20]
	mov		ecx,	3
	mul		ecx
	add		eax,	[EBP+28]
	mov	[EBP-48],	eax

	;calculate box_next_row
	mov		eax,	[ebp+16]
	mul		ecx
	add		eax,	[ebp+28]
	mov [ebp-52],	eax

	;calculate box_ret_to_row
	mov		eax,	[ebp+20]
	sub		eax,	[ebp+16]
	mul		ecx
	mov	[ebp-44],	eax

	;initialize filtered pixel and destination pixel
	mov		esi,	[ebp+8]
	mov		edi,	[ebp+12]

	;initialize addr_box
	mov [ebp-60],	esi

	;height-box
	mov		eax,	[ebp+24]
	sub		eax,	[ebp+16]
	mov [ebp-64],	eax

	;width-box
	mov		eax,	[ebp+20]
	sub		eax,	[ebp+16]
	mov	[ebp-24],	eax

while_y_f:
	;calculate iter_row
	mov		eax,	1			;eax == iter_row
	mov 	ecx,	[ebp-40]	;ecx == y_f
	mov		ebx,	[ebp+16]	;ebx == box
	cmp		ecx,	ebx
	jl		yf_is_less_1
	add		eax,	ebx
	jmp	endif_yf_1
yf_is_less_1:
	add		eax,	ecx		
endif_yf_1:
	cmp		ecx,	[ebp-64]
	jl		yf_is_less_2
	add		eax,	[ebp+24]
	sub		eax,	ecx
	sub		eax,	1
	jmp endif_yf_2
yf_is_less_2:
	add		eax,	ebx
endif_yf_2:
	mov	[ebp-28],	eax
while_x_f:
;move the current address and the address of the box's line beginning to the beginning of the box 
	mov			esi,	[ebp-60]
	mov		[ebp-56],	esi
	
;init max colors for the next filtered pixel
	mov	BYTE[ebp-4],	0
	mov	BYTE[ebp-8],	0
	mov	BYTE[ebp-12],	0

;calculate iter_pxl
	mov		eax,	1			;eax == iter_pix
	mov 	ecx,	[ebp-36]	;ecx == x_f
	mov		ebx,	[ebp+16]	;ebx == box
	cmp		ecx,	ebx			;;adding pixels to the left of the filtered pix
	jl	xf_is_less_1
	add		eax,	ebx		;else : iter_pix+=box
	jmp	endif_xf_1
xf_is_less_1:
	add		eax,	ecx		;less: iter_pix+=xf
endif_xf_1:

	cmp		ecx,	[ebp-24]	; to the right
	jl	xf_is_less_2
	add		eax,	[ebp+20]	; iter_pix += width - xf -1
	sub		eax,	ecx
	sub		eax,	1
	jmp endif_xf_2
xf_is_less_2:
	add		eax,	ebx
endif_xf_2:
	mov	[ebp-32],	eax

;init while_i loop
	mov		eax,	[ebp-28]	; i = iter_row
	mov	[ebp-16],	eax

while_i:
	mov		eax,	[ebp-32]	; j = iter_pix
	mov	[ebp-20],	eax
while_j:		
	mov		dl,	[esi]			;color of current byte
	cmp		dl,	BYTE[ebp-4]		;if greater store under max
	jbe channel_2
	mov	BYTE[ebp-4],	dl
channel_2:
	add 	esi,	1			;move on to the next byte of the checked pixel
	mov		dl,	[esi]
	mov	dh,0
	cmp		dl,	BYTE[ebp-8]
	jbe channel_3
	mov	BYTE[ebp-8],	dl
channel_3:
	add 	esi,	1			;move on to the next byte of the checked pixel
	mov		dl,	[esi]
	mov	dh,0
	cmp		dl,	BYTE[ebp-12]
	jbe checked_chs
	mov	BYTE[ebp-12],	dl
checked_chs:
	add 	esi,	1
;while_j loop condition
	sub	DWORD[ebp-20],	1		;j--
	cmp DWORD[ebp-20],	0		;j==0?
	jg	while_j					;if >0 -> next while_j iteration

	mov		esi,	[ebp-56]	; once its gone through the whole row addr_first += next_row_B
	add		esi,	[ebp-48]	; esi = addr_first (in the next row of the box that is)
	mov	[ebp-56],	esi
;while_i loop condition
	sub	DWORD[ebp-16],	1		;i--
	cmp DWORD[ebp-16],	0		;i==0?
	jg	while_i					;if >0 -> next while_i iteration
;save channels into dest pixel
	mov		dl,	BYTE[ebp-4]
	mov		[edi],	dl
	add		edi,	1
	mov		dl,	BYTE[ebp-8]
	mov		[edi],	dl
	add		edi,	1
	mov		dl,	BYTE[ebp-12]
	mov		[edi],	dl
	add		edi,	1
	
	add	DWORD[ebp-36],	1		;xf++
	mov		eax,	[ebp-36]	
	cmp		eax,	[ebp+16]	;xf > box ?
	jle		endif_xf_3			;
	add	DWORD[ebp-60],	3		;if so add 3 to addrbox	
endif_xf_3:

;while_x_f loop condiiton
	mov		eax,	[ebp+20]
	cmp	[ebp-36],	eax			;xf < width -> filter next pixel in the filtered row
	jl	while_x_f
;new row to filter:
	add		edi,	[ebp+28]	;add padding in bytes to the address of the destination byte 
	add	DWORD[ebp-40],	1		;yf++
	mov	DWORD[ebp-36],	0		;xf=0
	
	mov		eax,	[ebp-40]	;calculate box address - now it points to the width-box'th pixel in the yf-1 row
	cmp		eax,	[ebp+16]	;if new yf is >box the beginning of the box moves to the next row : box_addr+=3width + padd
	jg	greater_yf_3
	mov		ebx,	[ebp-44]	;if it's not - return to the beginning of the row
	sub	[ebp-60],	ebx
	jmp	endif_yf_3
	greater_yf_3:
	mov		ebx,	[ebp-52]
	add	[ebp-60],	ebx
	endif_yf_3:

;while_y_f loop condition
	mov		eax,	[ebp+24]	
	cmp	[ebp-40],	eax			;yf<height -> filter through next row
	jl	while_y_f

quit:	
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	add 	esp,	64
	pop		ebp
	jl		quit
	ret