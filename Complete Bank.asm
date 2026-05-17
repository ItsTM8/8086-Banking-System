ORG 100h
JMP start

; =========================
; data section
; =========================

LOGO1 DB '  ____              _        $'
LOGO2 DB ' | __ )  __ _ _ __ | | __    $'
LOGO3 DB ' |  _ \ / _` |  _ \| |/ /    $'
LOGO4 DB ' | |_) | (_| | | | |   <     $'
LOGO5 DB ' |____/ \__,_|_| |_|_|\_\    $'

LOGO6 DB '      ATM BANKING SYSTEM     $'

TITLE1 DB '+--------------------------------------------------------------+$'
TITLE2 DB '|                 ATM BANKING MANAGEMENT SYSTEM                |$'
TITLE3 DB '+--------------------------------------------------------------+$'
LINE DB '=====================================$'

LOGIN_ATTEMPTS DB 0
TEMP_AMOUNT DW 0

MAIN1 DB '|  [1]  CREATE NEW ACCOUNT                    |$'
MAIN2 DB '|  [2]  LOGIN TO ACCOUNT                      |$'
MAIN3 DB '|  [3]  ADMIN PANEL                           |$'
MAIN4 DB '|  [4]  EXIT SYSTEM                           |$'

USER1 DB '|  [1]  CHECK BALANCE                         |$'
USER2 DB '|  [2]  DEPOSIT MONEY                         |$'
USER3 DB '|  [3]  WITHDRAW MONEY                        |$'
USER4 DB '|  [4]  TRANSACTION HISTORY                   |$'
USER5 DB '|  [5]  TRANSFER MONEY                        |$'
USER6 DB '|  [6]  LOGOUT                                |$'

ADMIN1 DB '|  [1]  VIEW ALL ACCOUNTS                    |$'
ADMIN2 DB '|  [2]  DELETE ACCOUNT                       |$'
ADMIN3 DB '|  [3]  SYSTEM STATISTICS                    |$'
ADMIN4 DB '|  [4]  BACK TO MAIN MENU                    |$'

CHOICE_MSG DB '|  ENTER CHOICE: $'
ENTER_USER DB '|  ENTER USERNAME: $'
ENTER_PASS DB '|  ENTER PASSWORD: $'
ENTER_AMOUNT DB '|  ENTER AMOUNT: $'
ENTER_ADMIN DB '|  ENTER ADMIN PIN: $'
TRANSFER_USER DB '|  RECEIVER USERNAME: $'
WELCOME_MSG DB '|  WELCOME ACCOUNT: $'
TIME_MSG DB '|  TIME: $'
ACCNUM_MSG DB '|  ACCOUNT NUMBER: $'

BOX_START DB '|  $'
BOX_END DB '  |$'
SUCCESS_TEXT DB ' SUCCESS! $'
DEPOSIT_TEXT DB ' AMOUNT DEPOSITED SUCCESSFULLY! $'
WITHDRAW_TEXT DB ' AMOUNT WITHDRAWN SUCCESSFULLY! $'
TRANSFER_TEXT DB ' MONEY TRANSFERRED SUCCESSFULLY! $'
DELETE_TEXT DB ' ACCOUNT DELETED! $'
LOCK_TEXT DB ' ACCOUNT LOCKED! $'

FAIL_MSG DB '|  XXX INVALID LOGIN! XXX                   |$'
INVALID_MSG DB '|  XXX INVALID AMOUNT! XXX                 |$'
INSUFF_MSG DB '|  XXX INSUFFICIENT BALANCE! XXX          |$'
EXIST_MSG DB '|  XXX USERNAME ALREADY EXISTS! XXX        |$'
FULL_MSG DB '|  XXX MAXIMUM ACCOUNTS REACHED! XXX       |$'
ADMIN_FAIL DB '|  XXX WRONG ADMIN PIN! XXX                |$'

BAL_MSG DB '|  CURRENT BALANCE: Rs. $'
TOTAL_MSG DB '|  TOTAL ACCOUNTS: $'
ACTIVE_MSG DB '|  ACTIVE ACCOUNTS: $'

HISTORY_TITLE DB '|           TRANSACTION HISTORY                 |$'
DEP_HIST DB '     DEPOSIT  : Rs. $'
WIT_HIST DB '     WITHDRAW : Rs. $'
TRANS_HIST DB '     TRANSFER : Rs. $'
NO_HIST DB '     NO TRANSACTIONS FOUND$'

FILE_NAME DB 'BANK.DAT',0

USERNAMES DB 200 DUP('$')
PASSWORDS DB 200 DUP('$')
BALANCES DW 10 DUP(500)
STATUS DB 10 DUP(0)
ACC_COUNT DB 0
CURRENT_USER DB 0
ACCOUNT_NUM DW 10 DUP(0)
NEXT_ACC_NUM DW 1001

HIST_TYPE DB 50 DUP(0)
HIST_AMOUNT DW 50 DUP(0)
HIST_COUNT DB 10 DUP(0)

INPUT_USER DB 21 DUP('$')
INPUT_PASS DB 21 DUP('$')

; =========================
; program start
; =========================

start:
mov ax,cs
mov ds,ax

call load_data
call show_ascii_logo
call wait_key

; =========================
; main menu
; =========================

main_menu:
call draw_atm_box
call show_ascii_logo_small

mov dx,offset MAIN1
call print
call newline
mov dx,offset MAIN2
call print
call newline
mov dx,offset MAIN3
call print
call newline
mov dx,offset MAIN4
call print
call newline
call draw_bottom_border

mov dx,offset CHOICE_MSG
call print

mov ah,01h
int 21h
sub al,30h

cmp al,1
je create_account
cmp al,2
je login_system
cmp al,3
je admin_panel
cmp al,4
je exit_program
jmp main_menu

; =========================
; screen drawing procedures
; =========================

draw_atm_box proc
call clear_screen
mov dx,offset TITLE1
call print
call newline
mov dx,offset TITLE2
call print
call newline
mov dx,offset TITLE3
call print
call newline
call newline
ret
draw_atm_box endp

draw_bottom_border proc
mov dx,offset TITLE3
call print
call newline
ret
draw_bottom_border endp

show_ascii_logo proc
call clear_screen
mov dx,offset LOGO1
call print
call newline
mov dx,offset LOGO2
call print
call newline
mov dx,offset LOGO3
call print
call newline
mov dx,offset LOGO4
call print
call newline
mov dx,offset LOGO5
call print
call newline
mov dx,offset LOGO6
call print
call newline
call newline
ret
show_ascii_logo endp

show_ascii_logo_small proc
mov dx,offset LOGO6
call print
call newline
ret
show_ascii_logo_small endp

; =========================
; masked password input
; =========================

get_masked_password proc
push di
mov cx,0

mask_loop:
mov ah,08h
int 21h
cmp al,13
je mask_done
cmp cx,20
jae mask_loop
mov [di],al
inc di
inc cx
mov dl,'*'
mov ah,02h
int 21h
jmp mask_loop

mask_done:
mov byte ptr [di],'$'
pop di
ret
get_masked_password endp

; =========================
; create account
; =========================

create_account:
call draw_atm_box
mov al,ACC_COUNT
cmp al,10
jae system_full

mov dx,offset ENTER_USER
call print
mov di,offset INPUT_USER
call get_string
call newline

call user_exists
cmp al,1
je user_exists_msg

mov dx,offset ENTER_PASS
call print
mov di,offset INPUT_PASS
call get_masked_password
call newline

mov si,0

find_slot:
cmp STATUS[si],0
je slot_found
inc si
cmp si,10
jl find_slot
jmp system_full

slot_found:
mov ax,si
mov bx,20
mul bx
mov bx,ax

lea di,INPUT_USER
lea dx,USERNAMES[bx]
call copy_string

lea di,INPUT_PASS
lea dx,PASSWORDS[bx]
call copy_string

mov bx,si
shl bx,1
mov word ptr BALANCES[bx],500

mov STATUS[si],1

mov bx,si
shl bx,1
mov ax,NEXT_ACC_NUM
mov ACCOUNT_NUM[bx],ax
inc NEXT_ACC_NUM

mov bx,si
mov HIST_COUNT[bx],0
inc ACC_COUNT

call save_data

call draw_atm_box
mov dx,offset SUCCESS_TEXT
call print_success_line
mov dx,offset ACCNUM_MSG
call print
mov bx,si
shl bx,1
mov ax,ACCOUNT_NUM[bx]
call print_number
call newline
call draw_bottom_border
call wait_key
jmp main_menu

system_full:
call draw_atm_box
mov dx,offset FULL_MSG
call print
call draw_bottom_border
call wait_key
jmp main_menu

user_exists_msg:
call draw_atm_box
mov dx,offset EXIST_MSG
call print
call draw_bottom_border
call wait_key
jmp main_menu

; =========================
; login system
; =========================

login_system:
mov LOGIN_ATTEMPTS,0

login_try:
cmp LOGIN_ATTEMPTS,3
je lock_account

call draw_atm_box
mov dx,offset ENTER_USER
call print
mov di,offset INPUT_USER
call get_string
call newline

mov dx,offset ENTER_PASS
call print
mov di,offset INPUT_PASS
call get_masked_password
call newline

call verify_user
cmp al,1
je login_ok

inc LOGIN_ATTEMPTS
call draw_atm_box
mov dx,offset FAIL_MSG
call print
call newline
call draw_bottom_border
call wait_key
jmp login_try

lock_account:
call draw_atm_box
mov dx,offset LOCK_TEXT
call print_success_line
call draw_bottom_border
call wait_key
jmp main_menu

login_ok:
call draw_atm_box
mov dx,offset SUCCESS_TEXT
call print_success_line
call draw_bottom_border
call wait_key
call user_session
jmp main_menu

; =========================
; user session menu
; =========================

user_session:
user_loop:
call draw_atm_box

mov dx,offset WELCOME_MSG
call print
mov bl,CURRENT_USER
mov bh,0
shl bx,1
mov ax,ACCOUNT_NUM[bx]
call print_number
call newline

mov dx,offset BAL_MSG
call print
mov bl,CURRENT_USER
mov bh,0
shl bx,1
mov ax,BALANCES[bx]
call print_number
call newline

mov dx,offset TIME_MSG
call print
call show_time
call newline
call newline

mov dx,offset USER1
call print
call newline
mov dx,offset USER2
call print
call newline
mov dx,offset USER3
call print
call newline
mov dx,offset USER4
call print
call newline
mov dx,offset USER5
call print
call newline
mov dx,offset USER6
call print
call newline
call draw_bottom_border

mov dx,offset CHOICE_MSG
call print
mov ah,01h
int 21h
sub al,30h

cmp al,1
je check_balance
cmp al,2
je deposit
cmp al,3
je withdraw
cmp al,4
je show_history
cmp al,5
je transfer_money
cmp al,6
je logout
jmp user_loop

; =========================
; check balance
; =========================

check_balance:
call draw_atm_box
mov dx,offset BAL_MSG
call print
mov bl,CURRENT_USER
mov bh,0
shl bx,1
mov ax,BALANCES[bx]
call print_number
call newline
call draw_bottom_border
call wait_key
jmp user_loop

; =========================
; deposit money
; =========================

deposit:
call draw_atm_box
mov dx,offset ENTER_AMOUNT
call print
call get_number
cmp ax,0
jle invalid_dep

mov TEMP_AMOUNT,ax

mov bl,CURRENT_USER
mov bh,0
shl bx,1
add BALANCES[bx],ax

mov cl,1
call add_history
call save_data

call draw_atm_box
mov dx,offset DEPOSIT_TEXT
call print_success_line

mov dx,offset BAL_MSG
call print
mov bl,CURRENT_USER
mov bh,0
shl bx,1
mov ax,BALANCES[bx]
call print_number
call newline

call draw_bottom_border
call wait_key
jmp user_loop

invalid_dep:
call draw_atm_box
mov dx,offset INVALID_MSG
call print
call draw_bottom_border
call wait_key
jmp user_loop

; =========================
; withdraw money
; =========================

withdraw:
call draw_atm_box
mov dx,offset ENTER_AMOUNT
call print
call get_number
cmp ax,0
jle invalid_wit

mov TEMP_AMOUNT,ax

mov bl,CURRENT_USER
mov bh,0
shl bx,1
cmp ax,BALANCES[bx]
jg no_balance

sub BALANCES[bx],ax
mov cl,2
call add_history
call save_data

call draw_atm_box
mov dx,offset WITHDRAW_TEXT
call print_success_line

mov dx,offset BAL_MSG
call print
mov bl,CURRENT_USER
mov bh,0
shl bx,1
mov ax,BALANCES[bx]
call print_number
call newline

call draw_bottom_border
call wait_key
jmp user_loop

no_balance:
call draw_atm_box
mov dx,offset INSUFF_MSG
call print
call draw_bottom_border
call wait_key
jmp user_loop

invalid_wit:
call draw_atm_box
mov dx,offset INVALID_MSG
call print
call draw_bottom_border
call wait_key
jmp user_loop

; =========================
; transaction history
; =========================

show_history:
call draw_atm_box
mov dx,offset HISTORY_TITLE
call print_green
call newline
mov dx,offset LINE
call print_green
call newline

mov al,CURRENT_USER
mov ah,0
mov bl,5
mul bl
mov si,ax

mov bl,CURRENT_USER
mov bh,0
mov cl,HIST_COUNT[bx]
cmp cl,0
je empty_history

mov ch,0
mov di,0

display_loop:
cmp di,cx
jge end_history

mov bx,si
add bx,di
mov al,HIST_TYPE[bx]

cmp al,1
je show_dep
cmp al,2
je show_wit

mov dx,offset TRANS_HIST
call print_green
jmp show_value

show_dep:
mov dx,offset DEP_HIST
call print_green
jmp show_value

show_wit:
mov dx,offset WIT_HIST
call print_green

show_value:
mov ax,si
add ax,di
shl ax,1
mov bx,ax
mov ax,HIST_AMOUNT[bx]
call print_number_green
call newline
inc di
jmp display_loop

empty_history:
mov dx,offset NO_HIST
call print_green
call newline

end_history:
call draw_bottom_border
call wait_key
jmp user_loop

; =========================
; add transaction history
; =========================

add_history proc
push ax
push bx
push cx
push dx
push si
push di

mov dh,cl

mov al,CURRENT_USER
mov ah,0
mov bl,5
mul bl
mov si,ax

mov bl,CURRENT_USER
mov bh,0
mov al,HIST_COUNT[bx]
mov ah,0
mov bx,ax

cmp bx,5
jl store_new

mov cx,4
mov di,si
inc si

shift_loop:
mov al,HIST_TYPE[si]
mov HIST_TYPE[di],al

push si
push di

mov ax,si
shl ax,1
mov si,ax
mov ax,HIST_AMOUNT[si]

mov bx,di
shl bx,1
mov HIST_AMOUNT[bx],ax

pop di
pop si

inc si
inc di
loop shift_loop

mov al,CURRENT_USER
mov ah,0
mov bl,5
mul bl
mov si,ax
mov bx,4

store_new:
mov di,si
add di,bx

mov al,dh
mov HIST_TYPE[di],al

mov ax,di
shl ax,1
mov di,ax
mov ax,TEMP_AMOUNT
mov HIST_AMOUNT[di],ax

mov bl,CURRENT_USER
mov bh,0
cmp HIST_COUNT[bx],5
jge add_done
inc HIST_COUNT[bx]

add_done:
pop di
pop si
pop dx
pop cx
pop bx
pop ax
ret
add_history endp

; =========================
; transfer money
; =========================

transfer_money:
call draw_atm_box
mov dx,offset TRANSFER_USER
call print
mov di,offset INPUT_USER
call get_string
call newline

mov dx,offset ENTER_AMOUNT
call print
call get_number
cmp ax,0
jle invalid_transfer

mov TEMP_AMOUNT,ax
mov si,0

find_receiver:
cmp si,10
jge invalid_transfer
cmp STATUS[si],1
jne next_receiver

push si
mov ax,si
mov bx,20
mul bx
mov bx,ax
lea di,INPUT_USER
lea dx,USERNAMES[bx]
call compare_string
pop si

cmp al,1
je receiver_found

next_receiver:
inc si
jmp find_receiver

receiver_found:
mov al,CURRENT_USER
mov ah,0
cmp ax,si
je invalid_transfer

mov bl,CURRENT_USER
mov bh,0
shl bx,1
mov ax,TEMP_AMOUNT
cmp ax,BALANCES[bx]
jg no_balance_transfer

sub BALANCES[bx],ax

mov bx,si
shl bx,1
add BALANCES[bx],ax

mov cl,3
call add_history
call save_data

call draw_atm_box
mov dx,offset TRANSFER_TEXT
call print_success_line

mov dx,offset BAL_MSG
call print
mov bl,CURRENT_USER
mov bh,0
shl bx,1
mov ax,BALANCES[bx]
call print_number
call newline

call draw_bottom_border
call wait_key
jmp user_loop

invalid_transfer:
call draw_atm_box
mov dx,offset INVALID_MSG
call print
call draw_bottom_border
call wait_key
jmp user_loop

no_balance_transfer:
call draw_atm_box
mov dx,offset INSUFF_MSG
call print
call draw_bottom_border
call wait_key
jmp user_loop

; =========================
; admin panel
; =========================

admin_panel:
call draw_atm_box
mov dx,offset ENTER_ADMIN
call print
mov di,offset INPUT_PASS
call get_masked_password
call newline

cmp byte ptr INPUT_PASS,'9'
jne admin_fail_label
cmp byte ptr INPUT_PASS+1,'9'
jne admin_fail_label
cmp byte ptr INPUT_PASS+2,'9'
jne admin_fail_label
cmp byte ptr INPUT_PASS+3,'9'
jne admin_fail_label
cmp byte ptr INPUT_PASS+4,'$'
jne admin_fail_label

admin_menu:
call draw_atm_box
mov dx,offset ADMIN1
call print
call newline
mov dx,offset ADMIN2
call print
call newline
mov dx,offset ADMIN3
call print
call newline
mov dx,offset ADMIN4
call print
call newline
call draw_bottom_border

mov dx,offset CHOICE_MSG
call print
mov ah,01h
int 21h
sub al,30h

cmp al,1
je view_accounts
cmp al,2
je delete_account
cmp al,3
je system_stats
cmp al,4
je main_menu
jmp admin_menu

admin_fail_label:
call draw_atm_box
mov dx,offset ADMIN_FAIL
call print
call draw_bottom_border
call wait_key
jmp main_menu

; =========================
; view accounts
; =========================

view_accounts:
call draw_atm_box
mov si,0

view_loop:
cmp si,10
jge view_done
cmp STATUS[si],1
jne next_view

mov ax,si
mov bx,20
mul bx
mov bx,ax

lea dx,USERNAMES[bx]
call print
mov dx,offset BAL_MSG
call print

mov bx,si
shl bx,1
mov ax,BALANCES[bx]
call print_number
call newline

next_view:
inc si
jmp view_loop

view_done:
call draw_bottom_border
call wait_key
jmp admin_menu

; =========================
; delete account
; =========================

delete_account:
call draw_atm_box
mov dx,offset ENTER_USER
call print
mov di,offset INPUT_USER
call get_string
call newline

mov si,0

del_loop:
cmp si,10
jge del_done
cmp STATUS[si],1
jne next_del

mov ax,si
mov bx,20
mul bx
mov bx,ax

lea di,INPUT_USER
lea dx,USERNAMES[bx]
call compare_string
cmp al,1
je found_del

next_del:
inc si
jmp del_loop

found_del:
mov STATUS[si],0
dec ACC_COUNT
call save_data

call draw_atm_box
mov dx,offset DELETE_TEXT
call print_success_line
call draw_bottom_border
call wait_key
jmp admin_menu

del_done:
call draw_atm_box
mov dx,offset FAIL_MSG
call print
call draw_bottom_border
call wait_key
jmp admin_menu

; =========================
; system statistics
; =========================

system_stats:
call draw_atm_box
mov dx,offset TOTAL_MSG
call print
mov al,ACC_COUNT
cbw
call print_number
call newline

mov dx,offset ACTIVE_MSG
call print

mov si,0
mov cx,0

count_loop:
cmp si,10
jge show_active
cmp STATUS[si],1
jne skip_active
inc cx

skip_active:
inc si
jmp count_loop

show_active:
mov ax,cx
call print_number
call newline
call draw_bottom_border
call wait_key
jmp admin_menu

logout:
ret

; =========================
; verify user login
; =========================

verify_user proc
mov si,0

verify_loop:
cmp si,10
jge verify_fail

cmp STATUS[si],1
jne next_user

mov ax,si
mov bx,20
mul bx
mov bx,ax

lea di,INPUT_USER
lea dx,USERNAMES[bx]
call compare_string
cmp al,1
jne next_user

lea di,INPUT_PASS
lea dx,PASSWORDS[bx]
call compare_string
cmp al,1
je verify_success

next_user:
inc si
jmp verify_loop

verify_fail:
mov al,0
ret

verify_success:
mov ax,si
mov CURRENT_USER,al
mov al,1
ret
verify_user endp

; =========================
; check if username exists
; =========================

user_exists proc
mov si,0

check_loop:
cmp si,10
jge not_found

cmp STATUS[si],1
jne check_next

mov ax,si
mov bx,20
mul bx
mov bx,ax

lea di,INPUT_USER
lea dx,USERNAMES[bx]
call compare_string
cmp al,1
je found_user

check_next:
inc si
jmp check_loop

not_found:
mov al,0
ret

found_user:
mov al,1
ret
user_exists endp

; =========================
; save data to file
; =========================

save_data proc
mov ah,3ch
mov cx,0
mov dx,offset FILE_NAME
int 21h
jc save_exit
mov bx,ax

mov ah,40h
mov cx,200
mov dx,offset USERNAMES
int 21h

mov ah,40h
mov cx,200
mov dx,offset PASSWORDS
int 21h

mov ah,40h
mov cx,20
mov dx,offset BALANCES
int 21h

mov ah,40h
mov cx,10
mov dx,offset STATUS
int 21h

mov ah,40h
mov cx,1
mov dx,offset ACC_COUNT
int 21h

mov ah,40h
mov cx,20
mov dx,offset ACCOUNT_NUM
int 21h

mov ah,40h
mov cx,2
mov dx,offset NEXT_ACC_NUM
int 21h

mov ah,40h
mov cx,50
mov dx,offset HIST_TYPE
int 21h

mov ah,40h
mov cx,100
mov dx,offset HIST_AMOUNT
int 21h

mov ah,40h
mov cx,10
mov dx,offset HIST_COUNT
int 21h

mov ah,3eh
int 21h

save_exit:
ret
save_data endp

; =========================
; load data from file
; =========================

load_data proc
mov ah,3dh
mov al,0
mov dx,offset FILE_NAME
int 21h
jc load_exit
mov bx,ax

mov ah,3fh
mov cx,200
mov dx,offset USERNAMES
int 21h

mov ah,3fh
mov cx,200
mov dx,offset PASSWORDS
int 21h

mov ah,3fh
mov cx,20
mov dx,offset BALANCES
int 21h

mov ah,3fh
mov cx,10
mov dx,offset STATUS
int 21h

mov ah,3fh
mov cx,1
mov dx,offset ACC_COUNT
int 21h

mov ah,3fh
mov cx,20
mov dx,offset ACCOUNT_NUM
int 21h

mov ah,3fh
mov cx,2
mov dx,offset NEXT_ACC_NUM
int 21h

mov ah,3fh
mov cx,50
mov dx,offset HIST_TYPE
int 21h

mov ah,3fh
mov cx,100
mov dx,offset HIST_AMOUNT
int 21h

mov ah,3fh
mov cx,10
mov dx,offset HIST_COUNT
int 21h

mov ah,3eh
int 21h

load_exit:
ret
load_data endp

; =========================
; output procedures
; =========================

print proc
mov ah,09h
int 21h
ret
print endp

print_dollar proc
mov dl,'$'
mov ah,02h
int 21h
ret
print_dollar endp

; prints success line with real dollar symbols
print_success_line proc
push dx
mov dx,offset BOX_START
call print
call print_dollar
call print_dollar
call print_dollar
pop dx
call print
call print_dollar
call print_dollar
call print_dollar
mov dx,offset BOX_END
call print
call newline
ret
print_success_line endp

; prints string in green color
print_green proc
push ax
push bx
push cx
push dx
push si

mov si,dx

pg_loop:
mov al,[si]
cmp al,'$'
je pg_done

mov ah,09h
mov bh,0
mov bl,02h
mov cx,1
int 10h

mov ah,03h
mov bh,0
int 10h

inc dl
cmp dl,80
jb pg_set
mov dl,0
inc dh

pg_set:
mov ah,02h
mov bh,0
int 10h

inc si
jmp pg_loop

pg_done:
pop si
pop dx
pop cx
pop bx
pop ax
ret
print_green endp

print_number_green proc
push ax
push bx
push cx
push dx

mov bx,10
mov cx,0

png_div:
mov dx,0
div bx
push dx
inc cx
cmp ax,0
jne png_div

png_print:
pop dx
add dl,'0'
mov al,dl
call print_char_green
loop png_print

pop dx
pop cx
pop bx
pop ax
ret
print_number_green endp

print_char_green proc
push ax
push bx
push cx
push dx

mov ah,09h
mov bh,0
mov bl,02h
mov cx,1
int 10h

mov ah,03h
mov bh,0
int 10h

inc dl
cmp dl,80
jb pcg_set
mov dl,0
inc dh

pcg_set:
mov ah,02h
mov bh,0
int 10h

pop dx
pop cx
pop bx
pop ax
ret
print_char_green endp

newline proc
mov dl,13
mov ah,02h
int 21h
mov dl,10
int 21h
ret
newline endp

clear_screen proc
mov ax,0003h
int 10h
ret
clear_screen endp

; clears old keypresses, then waits for a new key
wait_key proc
clear_keys:
mov ah,01h
int 16h
jz wait_now
mov ah,00h
int 16h
jmp clear_keys

wait_now:
mov ah,00h
int 16h
ret
wait_key endp

show_time proc
mov ah,2ch
int 21h
mov al,ch
cbw
call print_number
mov dl,':'
mov ah,02h
int 21h
mov al,cl
cbw
call print_number
ret
show_time endp

; =========================
; input and string procedures
; =========================

get_string proc
mov cx,0

input_loop:
mov ah,01h
int 21h
cmp al,13
je input_done
cmp cx,20
jae input_loop
mov [di],al
inc di
inc cx
jmp input_loop

input_done:
mov byte ptr [di],'$'
ret
get_string endp

copy_string proc
push bx

copy_loop:
mov al,[di]
mov bx,dx
mov [bx],al
cmp al,'$'
je copy_done
inc di
inc dx
jmp copy_loop

copy_done:
pop bx
ret
copy_string endp

compare_string proc
push si
push di
push bx
push dx

mov si,di
mov bx,dx

cmp_loop:
mov al,[si]
mov dl,[bx]
cmp al,dl
jne not_equal
cmp al,'$'
je equal
inc si
inc bx
jmp cmp_loop

equal:
mov al,1
jmp cmp_done

not_equal:
mov al,0

cmp_done:
pop dx
pop bx
pop di
pop si
ret
compare_string endp

get_number proc
push bx
push cx
push dx

mov cx,0

read_loop:
mov ah,01h
int 21h
cmp al,13
je done_num
cmp al,'0'
jl invalid_num
cmp al,'9'
jg invalid_num

sub al,'0'
mov bl,al
mov bh,0

mov ax,cx
mov dx,10
mul dx
add ax,bx
mov cx,ax
jmp read_loop

invalid_num:
mov ax,0
jmp num_exit

done_num:
mov ax,cx

num_exit:
pop dx
pop cx
pop bx
ret
get_number endp

print_number proc
push ax
push bx
push cx
push dx

mov bx,10
mov cx,0

div_loop:
mov dx,0
div bx
push dx
inc cx
cmp ax,0
jne div_loop

print_loop:
pop dx
add dl,'0'
mov ah,02h
int 21h
loop print_loop

pop dx
pop cx
pop bx
pop ax
ret
print_number endp

; =========================
; exit program
; =========================

exit_program:
mov ah,4ch
int 21h