global _start

; TAKE NOTICE: You can set the program to a million (1.000.000) iterations or any other value you whish by changing NUM_ITERS value like this.
; NUM_ITERS 	equ 1000000

NUM_ITERS 	equ 1000000000

SYS_READ	equ 0
SYS_WRITE   equ 1
STDIN      	equ 0
STDOUT      equ 1
SYS_EXIT    equ 60

SECTION .data
lutmask db 0x01,0x00,0x00,0x00,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF
lutmasq db 0x01,0x00,0x00,0x00,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF
andmask times 32 db 0x03
highroll db "Highest Ones Roll: ",
highroll_num db "   ",0x0A
rollsessions db "Number of Roll Sessions: 100000000",
rollsessionslen equ $-rollsessions


SECTION .text

;for sanity check, this should yield 231 as result
teststack256:
	pop rbx

	xor rax, rax
	push rax
	push rax
	push rax
	push rax

jmp rbx

randstack256:
	pop rbx

	rdrand rax
	push rax
	rdrand rdx
	push rdx
	rdrand rax
	push rax
	rdrand rdx
	push rdx

jmp rbx


simhigh: ; function clutters all ymm regs and rax, rdx
	;Setup lut and mask in vmx registers
	mov rax, andmask
	mov rdx, lutmask
	vmovdqa ymm15, [rax]
	vmovdqa ymm14, [rdx]

	; The lowest power of 2 aligned number that can caontian 231 is 256 we go for that
	;  so we generate 256 random number from 0-4

	call randstack256
	call randstack256
	;256-231 = 25 rolls = 50  bits should not be rolled, since we only count good rolls we just make sure those rolls fail 
	;by those 2 bits being non 0 (any 2 bits number thats not 0)
	;ergo: let sjust fil them with high bits
	mov rax, -1
	shr rax, 64-50 ;64 bits register with all 1's 50 bits need to remian high
	or [rsp], rax; now the correct amount of bits on stack is set to high, so they will count as a failed roll as 2 bits number


	;load random numbers in vmx registers
	vmovdqu ymm10, [rsp]
	add rsp, 0x20
	vmovdqu ymm11, [rsp]
	add rsp, 0x20

	;shift right al quad words, so we can access the proper 2 bits in the next step
	vpsrlq ymm0, ymm10, 0
	vpsrlq ymm1, ymm10, 2
	vpsrlq ymm2, ymm10, 4
	vpsrlq ymm3, ymm10, 6

	vpsrlq ymm4, ymm11, 0
	vpsrlq ymm5, ymm11, 2
	vpsrlq ymm6, ymm11, 4
	vpsrlq ymm7, ymm11, 6

	; and all bytes with 0x03 so we just get the correct bits
	vpand ymm0, ymm0, ymm15
	vpand ymm1, ymm1, ymm15
	vpand ymm2, ymm2, ymm15
	vpand ymm3, ymm3, ymm15

	vpand ymm4, ymm4, ymm15
	vpand ymm5, ymm5, ymm15
	vpand ymm6, ymm7, ymm15
	vpand ymm7, ymm7, ymm15

	;apply lut [0 -> 1, 1 -> 0, 2->0, 3-> 0, rest  -> 0xff (which shoudl not happen)]
	vpshufb ymm0, ymm14, ymm0
	vpshufb ymm1, ymm14, ymm1
	vpshufb ymm2, ymm14, ymm2
	vpshufb ymm3, ymm14, ymm3

	vpshufb ymm4, ymm14, ymm4
	vpshufb ymm5, ymm14, ymm5
	vpshufb ymm6, ymm14, ymm6
	vpshufb ymm7, ymm14, ymm7

	;Now add everything togheter still using the avx registers 
	; NOte: Avx512 has a dedicted instruction for popcount, but we have to sum our stuff ourselves, since AVX512 is only supported on handfull of cpu's atm.
	vpxor ymm15, ymm15; so we know that is 0

	vpsadbw ymm0, ymm15, ymm0
	vpsadbw ymm1, ymm15, ymm1
	vpsadbw ymm2, ymm15, ymm2
	vpsadbw ymm3, ymm15, ymm3
	vpsadbw ymm4, ymm15, ymm4
	vpsadbw ymm5, ymm15, ymm5
	vpsadbw ymm6, ymm15, ymm6
	vpsadbw ymm7, ymm15, ymm7

	vpaddb ymm8, ymm0, ymm1
	vpaddb ymm9, ymm2, ymm3
	vpaddb ymm10, ymm4, ymm5
	vpaddb ymm11, ymm6, ymm7

	vpaddb ymm12, ymm8, ymm9
	vpaddb ymm13, ymm10, ymm11

	vpaddb ymm14, ymm12, ymm13
	vphaddw ymm14, ymm14, ymm15
	vphaddw ymm14, ymm14, ymm15
	vphaddw ymm14, ymm14, ymm15

	;now everythong is in 2 words

	xor rax, rax
	movd edx, xmm14
	vextracti128 xmm14, ymm14, 1
	movd eax, xmm14
	add eax, edx

ret


_start:

;Since this runs as fast as it does, I never break the loop, thereby preventing branching which really can impact performance
;(Since we are not realistically gonna hit the target of 177 anyways)

mov rcx, NUM_ITERS

xor r15, r15 ; this will remmeber the max amount, (set to 0 now)

simloop:

call simhigh
cmp rax,r15
cmovg r15,rax

loop simloop

;Now we need to write r15 to highroll_num in redable ascii chars
;We just need 3 chars max so thas doable
lea rbx, [highroll_num]
mov r10, 100
mov r11, 10

;r15 has number
xor rdx, rdx
mov rax, r15
div r10
add al, 0x30
mov [rbx], al

;move reiminder and go again
mov r15, rdx 

xor rdx, rdx
mov rax, r15
div r11
add al, 0x30
mov [rbx+1], al
add dl, 0x30 ;move final remainder (dingle digits)
mov [rbx+2], dl 


mov rax, SYS_WRITE
xor rdi, rdi
mov rsi, highroll
mov rdx, rollsessions-highroll
syscall

mov rax, SYS_WRITE
xor rdi, rdi
mov rsi, rollsessions
mov rdx, rollsessionslen
syscall

mov rax, SYS_EXIT
xor rdi, rdi
syscall