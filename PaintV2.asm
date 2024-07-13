; Prajwal Nautiyal
; This is an updated version of the simple paint application
; I wanted to see how to handle mouse input in 8086



; -------------------------
; Macros declared below
; -------------------------
; the macro to fill a pixel
; assuming 'cx' and 'dx' will already have the relevant coordinates
fillPixel macro clr
    mov al, clr
    mov ah, 0ch     ; syscall for changing the colour of a single pixel
    int 10h
    endm

; macro to draw a box, row by row filled with the specified colour
box macro bclr
    add ax, sqSide
    mov boxClr, bclr
    call fillBox 
    endm  

; starting address of the program
org 100h

; the entry point of the program
jmp .text

; -----------------------------------------
; the data section of the program
; the variables used are declared below
; -----------------------------------------
.data:
    help db 0xD, 0xA, "Usage Instructions", 0xD, 0xA, "Left Click: Draw with chosen colour", 0xD, 0xA, "Right Click: Erase", 0xD, 0xA, "Both Together: Exit Program", 0xD, 0xA, "Click any Button to Continue.", 0xD, 0xA, "Please be patient while the colour choice boxes are being drawn.",0
    helpLen equ $-help

    ; list of accepted inputs
    inputs db 0x31, 0x32, 0x33, 0

    ; user choice for colour, default is red
    userChoice db 0xC

    ; box colour
    boxClr db 0x0

    ; bounds for colour boxes
    sqSide dw 0x10
    max dw 0x70


; -------------------
; the actual code
; -------------------
.text:
    ; set screen initially to text mode
    mov al, 03h
    mov ah, 0
    int 10h

    ; setting the cursor position to 0,0
    mov dx, 0
    mov ah, 02h
    int 10h

    ; print usage instructions and wait for user confirmation
    mov ax, offset help
    mov bx, helpLen
    call printSTR

    mov ah, 0x0
    int 16h

    ; set screen to Graphical Mode.
    mov al, 13h
    mov ah, 0 
    int 10h

    mov ax, 0
    mov dx, 0
    ; draw the colour boxes
    box 0xF ; white

    box 0xC ; red

    box 0x9 ; blue

    box 0xA ; green

    box 0xD ; magenta

    box 0xB ; cyan

    box 0xE ; yellow

    ; hide text cursor
    mov ch, 32
    mov ah, 1
    int 10h

    ; initialise mouse and get its status
    mov ax, 0
    int 33h

    ; display mouse cursor
    mov ax, 1
    int 33h

    repeat:
        ; get mouse position
        mov ax, 3
        int 33h

        ; shift right on cx by 1, basically diving by 2 but in binary
        ; done because in graphical mode the value of 'cx' received from mouse driver
        ; is doubled due to pixel density
        shr cx, 1

        ; if both mouse buttons are pressed, end the program         
        cmp bx, 3
        je endProg

        ; check if the cursor is over the colour choices
        ; first check the lower max bound of the choice
        cmp dx, max
        jge notChoice
        ; then the right max, since the left and top would be zero in cx & dx respectively
        cmp cx, sqSide
        jge notChoice
        ; check for left click
        cmp bx, 1
        jne noClr
        ; get colour from pixel to set as user choice
        mov ah, 0x0D
        int 10h
        mov userChoice, al
        jmp repeat

        ; if not over the colour choices, fill/erase the pixel or skip
        notChoice:
            ; if right mouse button is pressed,
            ; fill with black to erase
            cmp bx, 2
            je erase

            ; if left mouse button is not pressed skipping filling colour
            cmp bx, 1
            jne noClr

            fillPixel userChoice

    noClr:
        jmp repeat
    
    erase:
        fillPixel 0x0
        jmp noClr   
         
endProg:
    ret


; -----------------------------    
; procedures declared below
; -----------------------------
; procedure to print a sentence
    printSTR proc
        mov bp, ax      ; move ax to bp
        mov cx, bx      ; move bx to cx
        mov al, 01b     ; to increment the cursor position after printing
        mov bh, 0       ; set page number to 0
        mov bl, 0x0A
        ; High 4 bits are the background color, Low 4 bits are the foreground color
        ; 0000/0x00 - Black, 1010/0xA - Bright Green
        push cs         ; push cs to top of stack
        pop es          ; pop top of stack into es
        mov ah, 0x13    ; syscall to print string
        int 10h
        ret             ; return to the calling procedure
        endp            ; end procedure

; procedure to fill a box with a specified colour
    fillBox proc
        ; save the current value of ax which has the lower bound of the box & reset cx
        start:
            push ax
            mov cx, 0
        ; loop to fill the row, if cx is equal to the side of the box, jump to next row
        row:
            cmp cx, sqSide
            je nxt
            fillPixel boxClr
            inc cx
            jmp row
        ; if dx is equal to the max bound of the box, return    
        nxt:
            pop ax
            inc dx
            cmp dx, ax
            jl start
        
        ret
        endp