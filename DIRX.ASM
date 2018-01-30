; DIRX.ASM
; DIRX Fast Directory Listing
; By Mark Earnest
; Uses MarkLib Library functions
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
FName           db "Pink Floyd   ",00
; Block Ends
FLen            db ?
FBase           db 8 dup("?"),0
FExt            db 3 dup("?"),0
File_Name       db 128 dup("�"),0                   

CSeg            Ends
