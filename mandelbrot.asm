.286
CODE SEGMENT
ASSUME CS:code, DS:code
ORG 0100h

; *****************************************************************************
start:
  ; Mandlebrot coordinates
  zr   = DWORD PTR [SI+0]
  zi   = DWORD PTR [SI+4]
  cr   = DWORD PTR [SI+8]
  ci   = DWORD PTR [SI+12]
  zrsq = DWORD PTR [SI+16]
  zisq = DWORD PTR [SI+20]

  ; Temp int
  Temp = WORD PTR  [SI+28]

  ; ===========================================================================
  ; Initialize

  ; Initialize the FPU
  FNINIT

  ; SI points to our memory
  mov si, 0A000h ; So we can push it

  ; Shave off some bytes by reusing 100
  mov dx, 100

  ; Switch to MCGA
  mov ax, 013h
  int 010h

  ; ES:DI is the end of our drawing area
  push si
  pop es
  mov di, 63879
  std ; We're using stosb backwards

  ; Initialize our X and Y
  mov bp, 199
  mov cx, bp


  ; ===========================================================================
  ; Main draw loop

MainLoop:
  ; Get our next mandelbrot value
  call GMV

  ; Store it
  mov al, bl
  stosb

  ; Decrement our X
  dec cx
  jns MainLoop

  ; Decrement our Y
  mov cx, 199
  sub di, 120
  dec bp
  jns MainLoop


  ; ===========================================================================
  ; Done

  ; Wait for a key press
  xor ax, ax
  int 016h

  ; Change back to text mode
  mov ax, 3
  int 010h

  ; Exit to DOS
  int 020h



; *****************************************************************************
; GMV: Get Mandelbrot Value
; Gets the value for the next Mandelbrot pixel
; Returns:
;   BL - The color to use
GMV:
  ; ===========================================================================
  ; Initialize

  ; cr = (x - 100) / 50;
  mov ax, cx
  sub ax, dx                  ; \
  mov Temp, ax                ;  > ST0 = Current X - 100
  FILD Temp                   ; /
  FILD Divisor                ; ST0 = 50, ST1 = Current X - 100
  FDIVP                       ; ST0 = (Current X - 100) / 50
  FSTP cr                     ; Store the result in cr

  ; ci = (y - 100) / 50;
  mov ax, bp
  sub ax, dx                  ; \
  mov Temp, ax                ;  > ST0 = Current Y - 100
  FILD Temp                   ; /
  FILD Divisor                ; ST0 = 50, ST1 = Current Y - 100
  FDIVP                       ; ST0 = (Current Y - 100) / 50
  FSTP ci                     ; Store the result in ci

  ; zr = zi = zrsq = zisq = 0;
  FLDZ
  FST zr
  FST zi
  FST zrsq
  FSTP zisq

  ; numiteration = 1;
  mov bl, 1

  ; ===========================================================================
  ; Our main loop

  ; do {
GMVLoop:

  ; zi = 2 * zr * zi + ci;
  FLD zr
  FMUL zi
  FIMUL TwoValue
  FADD ci
  FST zi ; Reusing this later

  ; zr = zrsq - zisq + cr;
  FLD zrsq
  FSUB zisq
  FADD cr
  FST zr ; Reusing this since it already is zr

  ; zrsq = zr * zr;
  ;FLD zr ; Reused from above
  FMUL zr
  FSTP zrsq

  ; zisq = zi * zi;
  ;FLD zi ; Reused from above
  FMUL zi
  FST zisq ; Reusing this for our comparison

  ; if ((zrsq + zisq) < 4)
  ;   return numiteration;
  FADD zrsq
  FILD FourValue
  FCOMPP
  FSTSW ax
  FWAIT
  sahf
  jb GMVDone

  ;} while (numiteration++ < 200);
  inc bx
  cmp bl, dl
  jb GMVLoop

  ;return 0;
  xor bl, bl

GMVDone:  
  ret
;GMV



; *****************************************************************************
; Data

; Divisor
Divisor DW 50
; Two Value
TwoValue DW 2
; 4 Value
FourValue DW 4

CODE ENDS
END start
