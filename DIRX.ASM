; DIRX.ASM
; DIRX Fast Directory Listing
; Mark Earnest
; Latest Revision: 6/3/95

CSeg            Segment Byte Public 'Prog'
                Assume CS:Cseg, DS:Cseg, ES:Cseg
                Org            100h

Set_DTA         Macro                           ; Set Data Transfer Access 
                push dx                         ; Save DX Register
                mov ah, 1ah                     ; DOS Set DTA
                mov dx, offset #1               ; Move pointer to file list
                int 21h                         ; Call DOS
                pop dx                          ; Restore DX Register
#EM                                             ; End Macro

Print           Macro                           ; Print String
                push dx                         ; Save DX Register
                mov dx, offset #1               ; Load String
                call write_str                  ; Print String
                pop dx                          ; Restore DX Register
#EM                                             ; End Macro


MAIN:                    
                call Vid_Ini                    ; Start Machine Video 
                call Hide_Cursor                ; hide cursor        
                call Prog_Ini                   ; Initalize Program
                call Print_Intro                ; Print introduction
                call Get_First2Files            ; Run Get_FirstFile    
                call Get_NextFiles              ; Run Get_NextFile
                call Show_Cursor                ; show cursor
                mov ah,4ch                      ; DOS End Program
                int 21h                         ; Call DOS

Prog_Ini:
                xor cx,cx                       ; clear cx
                mov si, 0080h                   ; load command tail
                mov cl, [si]b                   ; load command tail length
                cmp cl, 0                       ; no command tail?
                je >L20                         ; then make one
                inc si                          ; next byte
                inc si                          ; next byte
                mov di, offset File_Name        ; load destination string
                dec cl                          ; decrease length 
                call Dup_Left                   ; copy command tail over
                jmp >L21                        ; Skip Default FileName
L20:            mov cx, 4                       ; Copy 4 Characters
                mov si, offset Any_File         ; Load *.*
                mov di, offset File_Name        ; Load FileName
                call dup_left                   ; Copy *.* Into FileName
L21:            mov al, 0f                      ; BWhite on Black
                call change_color               ; Set Color
                ret                             ; Return

Print_Intro:              
                call send_crlf                  ; GoTo Next Line
                Print Intro                     ; Print Program Information
                ret                             ; Return

SplitFName:   
                mov di, offset FName            ; Load FileName
                mov si, offset FileSep          ; Load Period (.)
                call find_str                   ; Find Period in FileName
                cmp al,0                        ; find it?
                if ne jmp >L10                  ; If no Period, GoTo Handeler
                jmp >L11                        ; Otherwise Split FileName
L10:            cmp cx, 1                       ; Is FileName 1 Character?
                je >L13                         ; If so, Goto Handeler
                cmp cx, 2                       ; Is FileName 2 Characters?
                je >L14                         ; If So, Goto Handeler
                mov cx, ax                      ; load position
                mov si, offset FName            ; Load FileName
                mov di, offset FExt             ; Load File Extention Buffer
                call dup_right                  ; Move Extention to FExt
                mov cx, ax                      ; load position
                sub cx, 1                       ; Sub 1 From CX (Remove (.))
                jmp >L12                        ; Skip Erase FExt
L11:            mov si, offset FName            ; Load FExt
                mov offset FExt b, 00           ; Erase FExt
L12:            mov si, offset FName            ; load filename
                mov di, offset FBase            ; Load File Base Buffer
                call dup_left                   ; Move Base into FBase
                jmp >L16                        ; Skip . or .. Handelers
L13:            mov cx, 1                       ; 1 Repeat
                jmp >L15                        ; Goto String Dupe
L14:            mov cx, 2                       ; 2 Repeats
L15:            mov al, 46                      ; ASCII For .
                mov offset FExt b, 00           ; Erase FExt
                mov di, offset FBase            ; Load FBase
                call dup_str                    ; Dupe The String
L16:            ret                             ; Return


Get_First2Files:
                Set_DTA Reserved                ; Run Set_DTA Macro
                mov cx, 23                      ; All Files
                mov dx, offset file_name        ; Load File Mask
                mov ah, 4eh                     ; DOS Find First File
                int 21h                         ; Call DOS
                if c jmp L4                     ; Jump If No Files Left    
                call Main_Get_Files             ; Call Get Files
                mov cx, 0                       ; Wipe Counter
                mov cx, 6                       ; Set Counter to 6
                call send_crlf                  ; GoTo Next Line
                ret                             ; Return

Get_NextFiles:
                Set_DTA Reserved                ; Run Set_DTA Macro
                mov ah, 4fh                     ; DOS Find Next File
                int 21h                         ; Call DOS
                if c jmp L3                     ; Jump If No Files Left    
                call Main_Get_Files             ; Call Get Files
                inc cl                          ; Add 1 to cl
                cmp cl, 23                      ; Compare cl to 23
                ja >L1                          ; Jump if cl is Above 24
                call send_crlf                  ; Goto Next Line
                jmp Get_NextFiles               ; Loop Again
L1:             mov screen_x b,15               ; Column 15
                call update_real_cursor         ; Set Cursor
                mov al,8eh                      ; Flashing Yellow on Black
                call change_color               ; Set Color
                call send_crlf                  ; GoTo Next Line
                Print PK_Message                ; Print Message
                mov al, 0f                      ; BWhite on Black
                call change_color               ; Set Color
                mov ah, 07h                     ; DOS Wait For Key
                int 21h                         ; Call DOS
                mov screen_x b, 0               ; Column 0
                call update_real_cursor         ; Move Cursor
                call clear_to_end_of_line       ; Clear Line
                xor cx, cx                      ; Clear CX
                jmp Get_NextFiles               ; Loop Again
L2:             call update_virtual_cursor      ; Get Current Cursor Position
                mov screen_x b,41               ; Column 41
                call update_real_cursor         ; Move Cursor
                print line                      ; Print A Line
                mov screen_x b, 54              ; Move to Column 54
                call update_real_cursor         ; Move Cursor
                print line                      ; Print A Line
                mov screen_x b, 77              ; Column 77
                call update_real_cursor         ; Move Cursor
                print line                      ; Print A Line
                call send_crlf                  ; GoTo Next Line
L4:             pop dx                          ; Restore DX
L3:             print End_Line                  ; Print End Line
                ret                             ; Return

Main_Get_Files:
                mov si, offset FName            ; Load FileName
                push cx                         ; Save Count
                call length_str                 ; Get FileName Length
                call SplitFName                 ; Split the File Name
                pop cx                          ; Restore Count
                print line                      ; Print A Line
                Print FBase                     ; Print the Base
                call update_virtual_cursor      ; Get Cursor Location
                mov screen_x b,11               ; Set Column to 11     
                call update_real_cursor         ; Move Cursor
                print FExt                      ; Print File Extention
                mov screen_x b,14               ; Move to Column 14
                call update_real_cursor         ; Move Cursor
                print line                      ; Print A Line
                Call Get_Attr                   ; Report File Attributes
                Set_DTA Reserved                ; Run Set_DTA Macro
                mov ah, 4fh                     ; DOS Find Next File
                int 21h                         ; Call DOS
                if c jmp L2                     ; Jump If No Files Left    
                mov si, offset FName            ; Load FileName
                push cx                         ; Save Count
                call length_str                 ; Get FileName Length
                call SplitFName                 ; Split the File Name
                pop cx                          ; Restore Count
                mov screen_x b, 41              ; Move Cursor to Column 41
                call update_real_cursor         ; Move Cursor
                print line                      ; Print A Line
                Print FBase                     ; Print the Base
                call update_virtual_cursor      ; Get Cursor Location
                mov screen_x b, 51              ; Set Column to 51     
                call update_real_cursor         ; Move Cursor
                print FExt                      ; Print File Extention
                mov screen_x b, 54              ; Move to Column 54
                call update_real_cursor         ; Move Cursor
                print line                      ; Print A Line
                Call Get_Attr                   ; Report File Attributes
                mov screen_x b, 77              ; Column 77
                call update_real_cursor         ; Move Cursor
                print line                      ; Print A Line
                ret                             ; Return

Get_Attr:
                push ax                         ; Save AX
                mov ah, byte ptr Attrib         ; Load Attribute Byte
                mov al, ah                      ; Copy Attribute to AL
                test al, 1                      ; Test if Attribute Contains 1
                if ne print Read_Only           ; If So, Print R-O
                mov al, ah                      ; Copy Attribute to AL 
                test al, 2                      ; Test if Attribute Contains 2
                if ne print Hidden              ; If So, Print Hid
                mov al, ah                      ; Copy Attribute to AL 
                test al, 4                      ; Test if Attribute Contains 4
                if ne print System              ; If So, Print Sys
                mov al, ah                      ; Copy Attribute to AL 
                test al, 16                     ; Test if Attribute Contains 16
                if ne print Directory           ; If So, Print Dir
                pop ax                          ; Restore AX
                ret                             ; Return

; Writes a string to the screen
;       Pass: ds:dx = address of string
;--------------------------------------
Write_Str:      
                push ax                         ; save registers                        
                push dx
                push si
                pushf
                cld                             ; set direction for inc
                mov si,dx                       ; place address into si
String_Loop:
                lodsb                           ; get char into al
                or al,al                        ; have I found 0 yet?
                jz End_Of_String                ; yes? then I'm done
                cmp al, 0d
                jne >s1
                lodsb
                or al,al                        ; have I found 0 yet?
                jz End_Of_String                ; yes? then I'm done
                cmp al, 0a               
                jne >s1
                call send_crlf
                jmp String_Loop
S1:             mov dl,al                       ; no? then write the char.
                call Write_Char
                jmp String_Loop
End_Of_String:
                popf                            ; restore registers
                pop si
                pop dx
                pop ax
                ret

; initalize video memory
;       Pass: nothing
;       Return: nothing
;-------------------------
Vid_Ini:
                jmp offset start

Screen_Seg      dw 0B800h
Screen_ptr      dw 0
Screen_X        db 0
Screen_Y        db 0
Color_Attr      db 7

start:          push ax                         ; save registers
                push bx
                push cx
                push dx
                mov bx,0B800h                   ; set for color
                int 11h                         ; get equipment list
                and al,30h                      ; keep display type
                cmp al,30h                      ; is it mono?
                jne Set_Base                    ; no? use b800
                mov bx,0B000h                   ; yes? use b000
Set_Base:
                mov Screen_Seg,bx               ; save screen segment
                call update_virtual_cursor      ; set current cursor location
                pop dx                          ; restore registers 
                pop cx
                pop bx                          
                pop ax
                ret

; Removes cursor from screen
;       Pass: nothing
;---------------------------
Hide_Cursor:
                push ax                         ; save registers
                push bx
                push cx
                push dx
                mov ah,1
                mov ch,0fh
                mov cl,0
                int 10h
                pop dx                          ; restore registers
                pop cx
                pop bx
                pop ax
                ret

; Puts cursor on screen
;       Pass: nothing
;----------------------
Show_Cursor:
                push ax                         ; save registers
                push bx
                push cx
                push dx
                mov ah,1
                mov ch,6
                mov cl,7
                int 10h
                pop dx                          ; restore registers
                pop cx
                pop bx
                pop ax
                ret

; Changes color attribute
;       Pass: al = attr
;------------------------
Change_Color:
                mov color_attr,al               ; move color attr into var
                ret

; Copy a section from the left of the string
;       Pass: si = source
;             cx = number  
;             di = destination          
;-------------------------------------------
Dup_Left:
                push ax                         ; save ax
                push cx
                push di
                push si
Left_Loop:      mov al, [si]b
                mov [di]b, al
                inc si
                inc di
                loop Left_Loop
                mov [di] b, 00
                pop si                          ; restore ax
                pop di
                pop cx
                pop ax
                ret

; Copy a section from the right of the string
;       Pass: si = source
;             cx = number  
;             di = destination          
Dup_Right:
                push ax                         ; save registers
                push di
                push si
                push cx
                add si, cx
Right_Loop:     mov al, [si]b
                cmp al, 00
                je done_Right
                mov [di]b, al
                inc si
                inc di
                jmp Right_Loop
Done_Right:     mov [di] b, 00
                pop cx                          ; restore registers
                pop si                          
                pop di
                pop ax
                ret

; forms a string by duplicating a character
;       Pass: di = offset of string 
;             al = character to duplicate  
;             cx = number of times  
;------------------------------------------
dup_str:
                push di                         ; save registers
Dup_str2:       mov [di], al                    ; move value into string
                inc di                          ; next string pos
                loop dup_str2                   ; loop in cx > 0
                mov [di]b, 00                   ; end string
                pop di                          ; retrive registers
                ret

; Sends a CRLF to goto the next line
;       Pass: nothing
;-----------------------------------
Send_CRLF:
                push ax
                push dx
                mov ah,2
                mov dl,13
                int 21h
                mov dl,10
                int 21h
                call Update_Virtual_Cursor
                pop dx
                pop ax
                ret

; Find a sub-string in a string
;       Pass: si = sub-string
;             di = string  
;       Return: al = position of sub-string (0 if not found)
;-----------------------------------------------------------
Find_str:
                jmp Find_Str2
Start_Pos       db 0        
Found_Flag      db 0                
Find_Str2:      push bx                         ; save registers
                push cx
                push dx
                push si
                push di
                xor ax,ax                       ; wipe out ax
                xor bp,bp
                xor bx,bx                       ; wipe out bx
Find_Str_Loop:  mov dl, [di+bx]                 ; load string
                cmp [si+bp]b, dl                ; compare bytes
                je Found_one                    ; jump if equal
                cmp [di+bx]b, 00                ; is it the end of the string
                je Found_String                 ; if so, exit
                cmp [si+bp]b, 0                 ; end of string
                je Found_String                 ; if so, exit
                mov Found_Flag, 0               ; reset flag
                mov Start_Pos, 0                ; reset starting pos
                xor bp,bp                       ; clear any sub-string offset
                inc bx                          ; next place in string
                jmp Find_Str_Loop               ; loop

Found_one:      inc bx
                cmp Found_Flag, 0               ; is this the first match?
                if e mov Start_Pos, bl          ; if so, save starting place
                mov Found_Flag, 1               ; set flag 
                cmp [si+bp]b, 00                ; last byte?
                je Found_String                 ; is so, exit
                inc bp                          ; next sub-str pos
                inc bx                          ; next str pos
                jmp Find_Str_Loop               ; loop

Found_String:   mov al, Start_Pos               ; return information
                pop di
                pop si
                pop dx
                pop cx
                pop bx
                ret

; Updates real cursor position
;       Pass: nothing
;-----------------------------
Update_Real_Cursor:
                push dx                         ; save register
                mov dl,Screen_X                 ; get pos. of virtual cursor 
                mov dh,Screen_Y                 
                call GoTo_XY                    ; move real cursor to this
                pop dx
                ret

; Updates virtual cursor position
;       Pass: nothing
;--------------------------------
Update_Virtual_Cursor:
                push ax                         ; save resisters
                push bx
                push cx
                push dx
                mov ah,3                        ; get cursor pos
                xor bh,bh                       ; on page 0
                int 10h                         ; call video
                call GoTo_XY                    ; move cursor to this pos
                pop dx                          ; restore registers
                pop cx
                pop bx 
                pop ax
                ret

; Clears screen to end of line
;       Pass: nothing
;------------------------------
Clear_To_End_Of_Line:
                push ax                         ; save registers
                push bx
                push cx
                push dx
                mov dl,Screen_X
                mov dh,Screen_Y
                mov ah,6                        ; clear to end of line
                xor al,al                       ; clear window 
                mov ch,dh                       ; all on same line
                mov cl,dl                       ; start at cursor pos
                mov dl,79                       ; stop at end of line
                mov bh,Color_Attr               ; load attr
                int 10h                         ; call video
                pop dx                          ; restore registers
                pop cx
                pop bx
                pop ax
                ret

; Returns the length of a string
;       Pass: si = offset of string
;       Return: cx = Length of string
;-------------------------------------
Length_Str:
                push si                         ; save original address 
                push si
LS_Label:       cmp b[si], 00                   ; is current byte 0?
                je Str_L_Done                   ; yes? leave
                inc si                          ; increase address
                jmp LS_Label                    ; repeat loop
Str_L_Done:     pop cx                          ; retrive address
                sub si, cx                      ; get length
                mov cx, si
                pop si
                ret

; Writes a character to the screen 
;       Pass: dl = character
;             dh = < ff (right), ff (down) 
;----------------------------------
Write_Char:
                push ax                         ; save registers
                push bx
                push dx
                push es
                mov ax,Screen_Seg               ; get segment for screen memory
                mov es,ax                       ; point es to screen
                mov bx,Screen_ptr               ; pointer to char. in memory 
                push dx
                mov dh,Color_Attr               ; load attr
                mov es:[bx],dx                  ; write to screen
                pop dx
                cmp dh, 0ff                     ; does it go down?
                je down                         ; yes? call down proc
                call Cursor_Right               ; move to next pos
                jmp finis                       ; leave
down:
                call Cursor_Down                ; write down
finis:                
                pop es                          ; restore registers
                pop dx
                pop bx
                pop ax
                ret

; Move cursor
;       Pass: dh = Row(Y)
;             dl = Column(X)
;----------------------------
GoTo_XY:
                push ax                         ; save registers
                push bx                         
                mov bh,0                        ; page 0
                mov ah,2                        ; set cursor pos
                int 10h                         ; call video

                mov al,dh                       ; get row
                mov bl,80                       ; multiply by 80
                mul bl                          ; ax = row * 80
                add al,dl                       ; add column                       
                adc ah,0                        ; ax = row * 80 + column
                shl ax,1                        ; convert to a byte offset
                mov Screen_ptr,ax               ; save cursor offset
                mov Screen_X,dl                 ; save cursor position         
                mov Screen_Y,dh                 
                pop bx                          ; restore registers
                pop ax
                ret

; Moves cursor down on space
;       Pass: nothing
;---------------------------
Cursor_Down:
                inc Screen_Y b                  ; move v. cursor to next line
                cmp Screen_Y b,25               ; is it on the last line?
                jbe ok2                         ; no? then leave
                dec Screen_Y b                  ; yes? then move back
ok2:                
                call update_real_cursor         ; move real cursor 
                ret

; Moves cursor right one space
;       Pass: nothing
;-----------------------------
Cursor_Right:   
                inc screen_ptr w                ; move to next char. pos.           
                inc screen_ptr w
                inc screen_X b                  ; move to next column
                cmp screen_X b,79               ; make sure column <= 79
                jbe ok                          ; jump if good
                call Send_CRLF                  ; go to next line
ok:             
                ret

Intro           db "                 .oO DIRX Fast Directory Listing 1.1 Oo.",0d,0a
                db "                      Created By Mark Earnest. 1994",0d,0a,0d,0a
                db " File Name     Attributes                 File Name    Attributes",0d,0a
                db "------------------------------------------------------------------------------",0d,0a,0
End_Line        db "------------------------------------------------------------------------------",0d,0a,0
Line            db 179,0
Directory       db " Dir",0
Hidden          db " Hid",0
Read_Only       db " R-O",0
System          db " Sys",0
PK_Message      db "Press any key To continue",0   
Any_File        db "*.*",0
FileSep         db ".",0
; File Info Block
Reserved        db ".oO Mark Earnest Oo. "           
Attrib          db ?                         
Time            dw ?                        
Date            dw ?                      
Size            dd ?                        
FName           db "dirx         ",00
; Block Ends
FLen            db ?
FBase           db 8 dup("?"),0
FExt            db 3 dup("?"),0
File_Name       db 128 dup("�"),0                   

CSeg            Ends
