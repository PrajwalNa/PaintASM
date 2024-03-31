; Prajwal Nautiyal
; This is a simple paint application
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

; macro to print a given string by calling the printSTR procedure
print macro text, textLen
    call incROW
    mov ax, offset text
    mov bx, textLen
    call printSTR
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
    prompt db "Choose the colour of ink you would like to use", 0
    promptLen equ $-prompt
    
    ; the appended 0xD, 0xA are for Carriage Return and Line Feed respectively,
    ; to print the text on separate lines
    colours db "1: Red", 0xD, 0xA, "2: Blue", 0xD, 0xA, "3: Green", 0xD, 0xA,"Enter the number: ", 0
    coloursLen equ $-colours
    
    error db "Error! Please choose a number on the list: ", 0
    errorLen equ $-error
    
    help db 0xD, 0xA, "Usage Instructions", 0xD, 0xA, "Left Click: Draw with chosen colour", 0xD, 0xA, "Right Click: Erase", 0xD, 0xA, "Both Together: Exit Program", 0xD, 0xA, "Click any Button to Continue.", 0
    helpLen equ $-help
    
    ; list of accepted inputs
    inputs db 0x31, 0x32, 0x33, 0
    
    ; user choice for colour, default is red
    userChoice db 0xC 


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
    
    ; print prompt for user to choose a colour
    print prompt, promptLen
    print colours, coloursLen
    
    userIN:
        ; get user input and validate it 
        call getINP
        cmp cx, 1
        jne Good
        
        print error, errorLen
        jmp userIN
        
    Good:
        ; check which colour did user choose and route accordingly
        ; since Red is default I just send them to mouse initialisation
        cmp al, 0x31
        je initM
        cmp al, 0x32
        je Blue
        ; if its not Red or Blue, set it to Green
        mov userChoice, 0xA
        jmp initM
        
    Blue:
        mov userChoice, 0x9
        
    initM:
        ; print usage instructions and wait for user confirmation
        print help, helpLen
        
        mov ah, 0x0
        int 16h
        
        ; set screen to Graphical Mode.
        mov al, 13h
        mov ah, 0 
        int 10h
        
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

; procedure to get user input, and validate it
    getINP proc
        mov ah, 00h     ; syscall to get input
        int 16h         ; interrupt 16h
        call printCHAR  ; call proc to print the entered character
        mov bx, 0
        mov cx, 0       
        ; check if the input is on the list of accepted inputs
        checkINP:
            cmp [inputs+bx], 0
            je  Bad 
            cmp al, [inputs+bx]
            je  done
            inc bx
            jmp checkINP
        ; if the loop went through without getting even one match
        ; set bx to 1 to indicate error
        Bad:
            mov cx, 1    
        ; else if there was a match bx would be set to 0
        done:                  
            ret         ; return to the calling procedure
            endp        ; end procedure

; procedure to print one character in teletype mode
    printCHAR proc
        mov ah, 0x0E    ; syscall to print character in al using teletype output
        int 10h
        cmp al, 0x8     ; comparing the input to the backspace key
        jne noBack      ; if the input is not the backspace key, jump to noBack
        mov al, 0x20    ; else move space to al
        mov ah, 0x0Eh   ; print space
        int 10h
        mov al, 0x8     ; move backspace to al
        mov ah, 0x0E    ; print backspace, basically moving the cursor back one column
        int 10h
        ; abcd<backspace> -> abc<space replaced 'd'>[cursor after space] -> abc[cursor on space]
        noBack:
        ret
        endp
            
; procedure to increase the row position of the cursor
    incROW proc
        ; get current cursor position
        mov bh, 0
        mov ah, 0x03
        int 10h
        
        inc dh          ; increment the row number
        mov dl, 0       ; set the column number to 0
        mov ah, 0x2     ; set the cursor position
        int 10h
        ret
        endp