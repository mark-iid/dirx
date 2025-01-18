; DIRX.ASM
; DIRX Fast Directory Listing
; Mark Earnest
; Latest Revision: 6/3/95

CSeg            Segment Byte Public 'Prog'
                Assume CS:Cseg, DS:Cseg, ES:Cseg
                Org            100h

;------------------------------------------------------------------------------
; Macro: Set_DTA
; 
; Description:
; This macro sets the Data Transfer Area (DTA) for DOS file operations. It 
; saves the current DX register, sets the AH register to 1Ah (DOS Set DTA 
; function), moves the offset of the file list to the DX register, and calls 
; interrupt 21h to set the DTA. Finally, it restores the DX register.
; 
; Parameters:
; #1 - The offset of the file list to be used for the DTA.
; 
; Usage:
; Call this macro to set the DTA before performing file operations that 
; require a specific DTA.
;------------------------------------------------------------------------------
Set_DTA         Macro                           ; Set Data Transfer Access 
                push dx                         ; Save DX Register
                mov ah, 1ah                     ; DOS Set DTA
                mov dx, offset #1               ; Move pointer to file list
                int 21h                         ; Call DOS
                pop dx                          ; Restore DX Register
#EM                                             ; End Macro

; Macro: Print
; Description: This macro is used to print a string to the output.
; Parameters: 
;   #1 - The offset of the string to be printed.
; 
; Instructions:
;   1. Push the current value of the DX register onto the stack to save it.
;   2. Move the offset of the string (passed as parameter #1) into the DX register.
;   3. Call the `write_str` function to print the string.
;   4. Pop the saved value of the DX register from the stack to restore it.
; 
; Usage:
;   Print <string_offset>
Print           Macro                           ; Print String
                push dx                         ; Save DX Register
                mov dx, offset #1               ; Load String
                call write_str                  ; Print String
                pop dx                          ; Restore DX Register
#EM                                             ; End Macro


; This is the main entry point of the program.
; It performs the following steps:
; 1. Initializes the machine video settings.
; 2. Hides the cursor.
; 3. Initializes the program.
; 4. Prints the introduction.
; 5. Retrieves the first two files.
; 6. Retrieves the next files.
; 7. Shows the cursor.
; 8. Ends the program and returns control to DOS.
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

; This code initializes a program by processing a command tail or setting a default file name.
; 
; Prog_Ini:
; - Clears the CX register.
; - Loads the command tail length from memory location 0080h into CL.
; - If the command tail length is zero, it jumps to label L20 to set a default file name.
; - Otherwise, it increments SI to point to the command tail, loads the destination string address into DI,
;   decreases the command tail length, and calls Dup_Left to copy the command tail to the destination string.
; - Jumps to label L21 to skip setting the default file name.
; 
; L20:
; - Sets CX to 4 to copy 4 characters.
; - Loads the address of the default file name "*.*" into SI.
; - Loads the destination string address into DI.
; - Calls Dup_Left to copy "*.*" into the destination string.
; 
; L21:
; - Sets the AL register to 0f (BWhite on Black).
; - Calls change_color to set the display color.
; - Returns from the subroutine.
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

; SplitFName:
; This procedure splits a file name into its base name and extension.
; It uses the period (.) as the separator between the base name and the extension.
; 
; Registers used:
; - DI: Destination index for string operations
; - SI: Source index for string operations
; - CX: Counter for string operations
; - AL: Accumulator for comparison results
; 
; External procedures called:
; - find_str: Finds the position of a period (.) in the file name
; - dup_right: Copies the extension part of the file name to the FExt buffer
; - dup_left: Copies the base part of the file name to the FBase buffer
; - dup_str: Duplicates a string
; 
; Data:
; - FName: The full file name to be split
; - FileSep: The period (.) character used as a separator
; - FExt: Buffer to store the file extension
; - FBase: Buffer to store the base name of the file
; 
; Flow:
; 1. Load the file name and period separator into DI and SI respectively.
; 2. Call find_str to locate the period in the file name.
; 3. If no period is found, handle special cases for 1 or 2 character file names.
; 4. If a period is found, split the file name into base and extension.
; 5. Copy the base name to FBase and the extension to FExt.
; 6. Handle special cases for file names with 1 or 2 characters.
; 7. Return from the procedure.
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


; Get_First2Files:
; This routine sets up the Disk Transfer Area (DTA) and searches for the first two files matching a specified file mask.
; 
; Steps:
; 1. Set the Disk Transfer Area (DTA) using the Set_DTA macro.
; 2. Load the CX register with 23 to specify that all files should be considered.
; 3. Load the DX register with the offset address of the file mask.
; 4. Set AH to 4Eh to prepare for the DOS Find First File function.
; 5. Call interrupt 21h to execute the DOS Find First File function.
; 6. If the carry flag is set (indicating no files found), jump to label L4.
; 7. If files are found, call the Main_Get_Files routine to process the files.
; 8. Reset the CX register to 0.
; 9. Set the CX register to 6 to initialize a counter.
; 10. Call the send_crlf routine to move to the next line.
; 11. Return from the routine.
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

; This routine iterates through files in a directory, processes them, and handles screen output.
; It uses DOS interrupts to find the next file and perform various screen operations.
;
; Get_NextFiles:
; - Sets up the Disk Transfer Area (DTA) for file operations.
; - Uses DOS interrupt 21h with function 4Fh to find the next file.
; - If no more files are found, it jumps to label L3.
; - Calls Main_Get_Files to process the found files.
; - Increments the CL register and compares it to 23.
; - If CL is greater than 23, it jumps to label L1.
; - Calls send_crlf to move to the next line and loops back to find the next file.
;
; L1:
; - Sets the cursor to column 15 and updates the real cursor position.
; - Changes the text color to flashing yellow on black.
; - Prints a message and waits for a key press.
; - Resets the cursor to column 0 and clears the line.
; - Clears the CX register and loops back to find the next file.
;
; L2:
; - Updates the virtual cursor position.
; - Moves the cursor to various columns (41, 54, 77) and prints lines.
; - Moves to the next line.
;
; L4:
; - Restores the DX register.
;
; L3:
; - Prints the end line message and returns from the routine.
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

; Main_Get_Files:
; This routine processes and prints file information in a formatted manner.
; It performs the following steps:
; 1. Loads the file name into the SI register.
; 2. Saves the current count in the CX register.
; 3. Calls length_str to get the length of the file name.
; 4. Calls SplitFName to split the file name into base and extension.
; 5. Restores the count from the CX register.
; 6. Prints a line.
; 7. Prints the base part of the file name.
; 8. Updates the virtual cursor location.
; 9. Sets the screen column to 11 and updates the real cursor.
; 10. Prints the file extension.
; 11. Moves the cursor to column 14 and updates the real cursor.
; 12. Prints a line.
; 13. Calls Get_Attr to report file attributes.
; 14. Runs the Set_DTA macro with the Reserved parameter.
; 15. Uses DOS interrupt 21h with function 4Fh to find the next file.
; 16. If no files are left, jumps to label L2.
; 17. Repeats steps 1-13 for the next file, with different cursor positions.
; 18. Moves the cursor to column 77 and updates the real cursor.
; 19. Prints a line.
; 20. Returns from the routine.
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

; This subroutine checks the attribute byte of a file and prints the corresponding attribute types.
; It saves the current value of the AX register, then loads the attribute byte into AH.
; The attribute byte is tested for specific bits to determine the file attributes:
; - Bit 0 (1): Read-Only
; - Bit 1 (2): Hidden
; - Bit 2 (4): System
; - Bit 4 (16): Directory
; If the corresponding bit is set, the appropriate attribute type is printed.
; Finally, the original value of AX is restored and the subroutine returns.
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
