; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

org 100h


 .data
    ID_table    dw  0123h, 1234h, 2345h, 3456h, 4567h, 5678h, 6789h, 7890h, 0987h, 9876h, 8765h, 7654h, 6543h, 5432h, 4321h, 98ach, 8a2ch, 9cb1h, 6f43h, 8abch 
    PW_table    db  00h,    01h,    02h,   03h,   04h,   05h,   06h,   07h,   08h,   09h,   0ah,   0bh,   0ch,   0dh,   0eh,   0fh,   05h,   0bh,   03h,   06h
    StartTxt    db  "Security Lock.",10,13,"$" ; string $  control cursor position   
    SuccessTxt  dw  10,13,"Access allowed!  ",10,13,"$"
    FailTxt     dw  10,13,"Access denied!  ",10,13,"$"
    EnterID     db  10,13,"Enter ID (4 hexa digits)",10,13,">> $"
    EnterPW     db  10,13,"Enter Password (1 hexa digit)",10,13,">> $"
    ID          dw  ?
    PW          db  ?
    sixteen     dw  10h
    size        dw  14h   ; for the 20 IDs in database 
    temp        dw  ?

.code
    mov     ax,@data        ; @data is a variable that holds the value of the location in memory where the data segment is.
    mov     ds,ax           ; cant directly place in ds  

    mov     ax,offset StartTxt   ;starting message at the begining of code 
    mov     si,ax
    mov     bl, 05h              ;starting message color
    call    Print
    
    call    ScanID
    call    ScanPW
    call    Output  
    ; wait for any key press...
     mov     ah, 0 ;
     int     16h
    ret
    
    Print     proc    near ; prints char by char
        mov     dl, 0      ; current column.   to start from 0, beginning of line 
        mov     dh, 0      ; current row.
        mov     cx,1    
        LP:
        mov     ah, 02h    ;set cursor position 
        int     10h
        cmp     [si],'$'   ;$ marks the end of string
        je      done  
        mov     al,[si]    
        inc     si    
        inc     dl       
        mov     ah,09h     ;print character at cursor position
        int     10h
        jmp     LP
                
        done: 
        ret
    endp
    
  

    ScanID  proc    near      ; near , same cs, reads ID as input from user
        mov     dx,offset EnterID     
        mov     ah,9    ; display whole message 
        int     21h

        mov     cx,4    ; as Id is 4 hexadecinmal 
        mov     bx,0   
        L:
        call    scancharacter
        call    ATH
        call    store
        loop    L
        mov     ID,bx
        ret
    endp

    ScanPW  proc    near      ;reads PW as input from user   
        mov     dx,offset EnterPW
        mov     ah,9       ;print string
        int     21h

       ; mov     cx,1    ; as pw is 4 bits  so 1 hexacharacter only 
        call    scancharacter   ; no loop as one character 
        call    ATH
        mov     PW,al
        ret
    endp

    scancharacter  proc    near 
        mov     ah,1
        int     21h         ;read one character from input, result is stored in AL
        ret
    endp

    ATH     proc    near    ; coverts ascii to hexa
        cmp al, '0'         ;makes sure eno number 
        jae  LP1

        LP1:
        cmp al, '9' 
        ja LP2       ; jumps only if not '0' to '9'.

        sub al, 30h ; convert char '0' to '9' to numeric value.
        jmp finish

        LP2:
        ; gets here if it's 'a' to 'f' 
        or al, 00100000b   ; remove upper case if character entered is upper case.
        sub al, 57h        ; convert chars from 'a' to 'f' to numeric value.

        finish:

        ret
    endp

    store   proc    near   
        mov     temp,cx
        dec     cx
        mov     ah,0     ; add value during interrupt to reset 
        cmp     cx,0
        je      jump
        L3:
        mul     sixteen  ;to shift one cell to the left
        loop    L3       ;cx automatically decrements loop ends when cx=0
        jump:
        mov     cx,temp
        add     bx,ax    ; to save in bx 
        ret
    endp    
    ret  
    
    
        
    Output   proc    near      ;login function
                                                                    
        cld              ; sets to increment index registers  (SI or DI)
        mov     cx,size  ; set counter to data size:20 IDs
        mov     ax,cs    ; load address into es:di
        mov     es,ax    
        lea     di,ID_table
        mov     ax,ID
        repne   scasw    ; compare content of ax to di  and increments di and decrements cx, repeat until compared words are equal (ZF = 1) or until CX = 0 
        jz      F
        NF:
        mov     dx,offset FailTxt
        mov     ah,9h  
        int     21h
        jmp     exit
        F:      ;found
        mov     si,size
        sub     si,cx   
        dec     si                     ; offset of id entered in table 
        mov     bx,offset PW_table
        mov     al,byte ptr([bx+si])   ; al carries password that coresponds to ID entered   
        cmp     al,PW                  ; password scanned as input is in PW
        jne     NF
        mov     dx,offset SuccessTxt
        mov     ah,9    
        int     21h
        exit:
        ret
    endp                                 

ret


