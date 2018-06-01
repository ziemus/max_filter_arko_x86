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
	;add		eax,	1
	mul		ecx
	add		eax,	[ebp+28]
	mov [ebp-52],	eax

	;calculate box_ret_to_row
	mov		eax,	[ebp+20]
	sub		eax,	[ebp+16]
	;sub		eax,	1
	mul		ecx					;by 3
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
jl	yf_is_less_1
	add		eax,	ebx
	jmp	endif_yf_1
yf_is_less_1:
	add		eax,	ecx		
endif_yf_1:
	cmp		ecx,	[ebp-64]
	jl	yf_is_less_2
	add		eax,	[ebp+24]
	sub		eax,	ecx
	sub		eax,	1
	jmp endif_yf_2
yf_is_less_2:
	add		eax,	ebx
endif_yf_2:
	mov	[ebp-28],	eax

while_x_f:
	mov		esi,	[ebp-60]
	mov	[ebp-56],	esi
;init max colors for the next filtered pixel
	mov	BYTE[ebp-13],	0
	mov	BYTE[ebp-14],	0
	mov	BYTE[ebp-15],	0

;calculate iter_pxl
	mov		eax,	1			;eax == iter_pix
	mov 	ecx,	[ebp-36]	;ecx == x_f
	mov		ebx,	[ebp+16]	;ebx == box
	cmp		ecx,	ebx
	jl	xf_is_less_1
	add		eax,	ebx
	jmp	endif_xf_1
xf_is_less_1:
	add		eax,	ecx		
endif_xf_1:

	cmp		ecx,	[ebp-24]
	jl	xf_is_less_2
	add		eax,	[ebp+20]
	sub		eax,	ecx
	sub		eax,	1
	jmp endif_xf_2
xf_is_less_2:
	add		eax,	ebx
endif_xf_2:
	mov	[ebp-32],	eax

;init while_i loop
	mov		eax,	[ebp-28]	
	mov	[ebp-16],	eax

while_i:
	mov		eax,	[ebp-32]
	mov	[ebp-20],	eax
while_j:		
	mov		al,	[esi]
	cmp		al,	BYTE[ebp-4]
	jle channel_2
	mov	BYTE[ebp-4],	al
channel_2:
	add 	esi,	1
	mov		al,	[esi]
	cmp		al,	BYTE[ebp-8]
	jle channel_3
	mov	BYTE[ebp-8],	al
channel_3:
	add 	esi,	1
	mov		al,	[esi]
	cmp		al,	BYTE[ebp-12]
	jle checked_chs
	mov	BYTE[ebp-12],	al
checked_chs:
	add 	esi,	1
					
;while_j loop condition
	sub	DWORD[ebp-20],	1
	cmp DWORD[ebp-20],	0
	jne	while_j

	mov		esi,	[ebp-56]
	add		esi,	[ebp-48]
	mov	[ebp-56],	esi
;while_i loop condition
	sub	DWORD[ebp-16],	1
	cmp DWORD[ebp-16],	0
	jne	while_i
;save channels into dest pixel
	add edx, 1
	mov		al,	BYTE[ebp-4]
	mov		[edi],	al
	add		edi,	1
	mov		al,	BYTE[ebp-8]
	mov		[edi],	al
	add		edi,	1
	mov		al,	BYTE[ebp-12]
	mov		[edi],	al
	add		edi,	1
			
	add	DWORD[ebp-36],	1		;xf++
	mov		eax,	[ebp-36]	
	cmp		eax,	[ebp+16]	;xf > box ?
	jle		endif_xf_3			;
	add	DWORD[ebp-60],	3	
	;if so add 3 to addrbox	
endif_xf_3:					;else do nothing

;while_x_f loop condiiton
	mov		eax,	[ebp+20]
	cmp	[ebp-36],	eax
	jne	while_x_f

	add		edi,	[ebp+28]
	add	DWORD[ebp-40],	1
	mov	DWORD[ebp-36],	0
		
	mov		eax,	[ebp-40] ;calculate box address
	cmp		eax,	[ebp+16]
	jg	greater_yf_3
	mov		ebx,	[ebp-44]
	sub	[ebp-60],	ebx
	jmp	endif_yf_3
	greater_yf_3:
	mov		ebx,	[ebp-52]
	add	[ebp-60],	ebx
	endif_yf_3:

;while_y_f loop condition
	mov		eax,	[ebp+24]
	cmp	[ebp-40],	eax
	jne	while_y_f

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