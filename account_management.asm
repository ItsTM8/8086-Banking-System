org 100h

jmp start

; ========================= data section =========================

; title shown on screen
title_msg      db '==== banking management system ====$'

; main menu options
main1          db '1. create account$'
main2          db '2. login$'
main3          db '3. exit$'

; user menu options
user1          db '1. check balance$'
user2          db '2. deposit$'
user3          db '3. withdraw$'
user4          db '4. logout$'

; common messages
choice_msg     db 'Enter choice: $'

enter_user     db 'Enter username: $'
enter_pass     db 'Enter password: $'

success_msg    db 'Success!$'
fail_msg       db 'Invalid login!$'
exist_msg      db 'Username exists!$'
full_msg       db 'System full!$'

bal_msg        db 'Current balance: $'
dep_msg        db 'Enter deposit amount: $'
wit_msg        db 'Enter withdraw amount: $'

invalid_msg    db 'Invalid amount!$'
insuff_msg     db 'Insufficient balance!$'

; Add these with your other message strings
enter_admin     db 'Enter Admin PIN: $'
admin1          db '1. View All Accounts$'
admin2          db '2. Delete Account$'
admin3          db '3. System Statistics$'
admin4          db '4. Back to Main Menu$'
admin_fail_msg  db 'Wrong PIN!$'
delete_msg      db 'Account Deleted!$'
total_msg       db 'Total Accounts: $'
active_msg      db 'Active Accounts: $'
file_name       db 'BANK.DAT',0

transfer_user db 'Receiver Username: $'
enter_amount  db 'Enter Amount: $'
history_title db 'Transaction History$'
dep_hist      db 'Deposit: Rs. $'
wit_hist      db 'Withdraw: Rs. $'
trans_hist    db 'Transfer: Rs. $'
no_hist       db 'No Transactions$'
line          db '=================$'

; ========================= storage =========================

; stores usernames
usernames      db 200 dup('$')

; stores passwords
passwords      db 200 dup('$')

; stores balances
balances       dw 10 dup(500)

; account status array
; 0 = empty
; 1 = occupied
status         db 10 dup(0)

; total number of accounts
acc_count      db 0

; current logged in user
current_user   db 0

; temporary buffers
input_user     db 21 dup('$')
input_pass     db 21 dup('$')

; ========================= start =========================

start:

; initialize data segment
mov ax, cs
mov ds, ax

; ========================= main menu =========================

main_menu:

; clear screen
call clear_screen

; print title
mov dx, offset title_msg
call print
call newline
call newline

; print menu options
mov dx, offset main1
call print
call newline

mov dx, offset main2
call print
call newline

mov dx, offset main3
call print
call newline
call newline

; ask user for choice
mov dx, offset choice_msg
call print

; take character input
mov ah, 01h
int 21h

; convert ascii to number
sub al, 30h

; check menu selection
cmp al, 1
je create_account

cmp al, 2
je login_system

cmp al, 3
je exit_program

; invalid choice -> show menu again
jmp main_menu

; ========================= create account =========================

create_account:

call clear_screen

; check if 10 accounts already exist
mov al, acc_count
cmp al, 10
jae system_full

; ask for username
mov dx, offset enter_user
call print

mov di, offset input_user
call get_string

call newline

; check if username already exists
call user_exists

cmp al, 1
je user_exists_msg

; ask for password
mov dx, offset enter_pass
call print

mov di, offset input_pass
call get_string

call newline

mov si, 0

; ========================= find empty slot =========================

find_slot:

; check if slot is empty
cmp status[si], 0
je slot_found

inc si

; continue until 10 slots checked
cmp si, 10
jl find_slot

jmp system_full

slot_found:

; calculate memory offset
; each username uses 20 bytes

mov ax, si
mov bl, 20
mul bl
mov bx, ax

; copy username
lea di, input_user
lea dx, usernames[bx]
call copy_string

; copy password
lea di, input_pass
lea dx, passwords[bx]
call copy_string

; calculate balance position
mov bx, si
shl bx, 1

; initial balance = 500
mov word ptr balances[bx], 500

; mark account active
mov status[si], 1

; increase account count
inc acc_count

; show success message
mov dx, offset success_msg
call print

call wait_key

jmp main_menu

; ========================= system full =========================

system_full:

mov dx, offset full_msg
call print

call wait_key

jmp main_menu

; ========================= username exists =========================

user_exists_msg:

mov dx, offset exist_msg
call print

call wait_key

jmp main_menu

; ========================= login =========================

login_system:

call clear_screen

; ask username
mov dx, offset enter_user
call print

mov di, offset input_user
call get_string

call newline

; ask password
mov dx, offset enter_pass
call print

mov di, offset input_pass
call get_string

call newline

; verify credentials
call verify_user

cmp al, 1
je login_success

; invalid login
mov dx, offset fail_msg
call print

call wait_key

jmp main_menu

login_success:

; successful login
mov dx, offset success_msg
call print

call wait_key

; go to user menu
call user_session

jmp main_menu

; ========================= verify user =========================

verify_user proc

; total accounts
mov cl, acc_count

cmp cl, 0
je verify_fail

mov si, 0

verify_loop:

; check active account only
cmp status[si], 1
jne next_user

; calculate address
mov ax, si
mov bx, 20
mul bx
mov bx, ax

; compare username
lea di, input_user
lea dx, usernames[bx]

call compare_string

cmp al, 1
jne next_user

; compare password
lea di, input_pass
lea dx, passwords[bx]

call compare_string

cmp al, 1
je verify_success

next_user:

inc si
dec cl
jnz verify_loop

verify_fail:

; login failed
mov al, 0
ret

verify_success:

; save current user index
mov ax, si
mov current_user, al

mov al, 1
ret

verify_user endp

; ========================= user exists =========================

user_exists proc

mov cl, acc_count

cmp cl, 0
je not_found

mov si, 0

check_loop:

; calculate username address
mov ax, si
mov bl, 20
mul bl
mov bx, ax

; compare entered username
lea di, input_user
lea dx, usernames[bx]

call compare_string

cmp al, 1
je found_user

inc si

dec cl
jnz check_loop

not_found:

mov al, 0
ret

found_user:

mov al, 1
ret

user_exists endp

; ========================= utility procedures =========================

; print string procedure
print proc

mov ah, 09h
int 21h

ret

print endp

; move cursor to next line
newline proc

mov dl, 13
mov ah, 02h
int 21h

mov dl, 10
int 21h

ret

newline endp

; clear screen procedure
clear_screen proc

mov ax, 0003h
int 10h

ret

clear_screen endp

; wait for key press
wait_key proc

mov ah, 00h
int 16h

ret

wait_key endp

; ========================= get string =========================

get_string proc

mov cx, 0

input_loop:

; read character
mov ah, 01h
int 21h

; stop at enter key
cmp al, 13
je input_done

; store character
mov [di], al

inc di
inc cx

; maximum 20 characters
cmp cx, 20
jl input_loop

input_done:

; end string with $
mov byte ptr [di], '$'

ret

get_string endp

; ========================= copy string =========================

copy_string proc

push bx

copy_loop:

; get source character
mov al, [di]

; copy into destination
mov bx, dx
mov [bx], al

; stop when $ found
cmp al, '$'
je copy_done

inc di
inc dx

jmp copy_loop

copy_done:

pop bx
ret

copy_string endp

; ========================= compare string =========================

compare_string proc

push si
push di
push bx

mov si, di
mov bx, dx

cmp_loop:

; get characters
mov al, [si]
mov dl, [bx]

; compare characters
cmp al, dl
jne not_equal

; if end reached
cmp al, '$'
je equal

inc si
inc bx

jmp cmp_loop

equal:

; strings matched
mov al, 1
jmp cmp_done

not_equal:

; strings not matched
mov al, 0

cmp_done:

pop bx
pop di
pop si
ret
compare_string endp

; ============================================================
; TAQWA'S MODULES (01-135232-101)
; Added: Check Balance, Deposit, Withdraw, 
;        Transaction History, Transfer Money
; ============================================================

; ============================================================
; CHECK BALANCE
; ============================================================

check_balance:
    call draw_atm_box
    mov dx, offset bal_msg
    call print
    mov bl, current_user
    mov bh, 0
    shl bx, 1
    mov ax, balances[bx]
    call print_number
    call newline
    call draw_bottom_border
    call wait_key
    jmp user_loop

; ============================================================
; DEPOSIT MONEY
; ============================================================

deposit:
    call draw_atm_box
    mov dx, offset dep_msg
    call print
    call get_number
    cmp ax, 0
    jle invalid_dep

    mov temp_amount, ax

    mov bl, current_user
    mov bh, 0
    shl bx, 1
    add balances[bx], ax

    mov cl, 1
    call add_history
    call save_data

    call draw_atm_box
    mov dx, offset success_msg
    call print
    call newline
    mov dx, offset bal_msg
    call print
    mov bl, current_user
    mov bh, 0
    shl bx, 1
    mov ax, balances[bx]
    call print_number
    call newline
    call draw_bottom_border
    call wait_key
    jmp user_loop

invalid_dep:
    call draw_atm_box
    mov dx, offset invalid_msg
    call print
    call draw_bottom_border
    call wait_key
    jmp user_loop

; ============================================================
; WITHDRAW MONEY (Minimum balance: 500)
; ============================================================

withdraw:
    call draw_atm_box
    mov dx, offset wit_msg
    call print
    call get_number
    cmp ax, 0
    jle invalid_wit

    mov temp_amount, ax

    mov bl, current_user
    mov bh, 0
    shl bx, 1
    cmp ax, balances[bx]
    jg no_balance

    sub balances[bx], ax
    mov cl, 2
    call add_history
    call save_data

    call draw_atm_box
    mov dx, offset success_msg
    call print
    call newline
    mov dx, offset bal_msg
    call print
    mov bl, current_user
    mov bh, 0
    shl bx, 1
    mov ax, balances[bx]
    call print_number
    call newline
    call draw_bottom_border
    call wait_key
    jmp user_loop

no_balance:
    call draw_atm_box
    mov dx, offset insuff_msg
    call print
    call draw_bottom_border
    call wait_key
    jmp user_loop

invalid_wit:
    call draw_atm_box
    mov dx, offset invalid_msg
    call print
    call draw_bottom_border
    call wait_key
    jmp user_loop

; ============================================================
; TRANSACTION HISTORY (Circular buffer - last 5)
; ============================================================

show_history:
    call draw_atm_box
    mov dx, offset history_title
    call print
    call newline
    mov dx, offset line
    call print
    call newline

    mov al, current_user
    mov ah, 0
    mov bl, 5
    mul bl
    mov si, ax

    mov bl, current_user
    mov bh, 0
    mov cl, hist_count[bx]
    cmp cl, 0
    je empty_history

    mov ch, 0
    mov di, 0

display_loop:
    cmp di, cx
    jge end_history

    mov bx, si
    add bx, di
    mov al, hist_type[bx]

    cmp al, 1
    je show_dep
    cmp al, 2
    je show_wit

    mov dx, offset trans_hist
    call print
    jmp show_value

show_dep:
    mov dx, offset dep_hist
    call print
    jmp show_value

show_wit:
    mov dx, offset wit_hist
    call print

show_value:
    mov ax, si
    add ax, di
    shl ax, 1
    mov bx, ax
    mov ax, hist_amount[bx]
    call print_number
    call newline
    inc di
    jmp display_loop

empty_history:
    mov dx, offset no_hist
    call print
    call newline

end_history:
    call draw_bottom_border
    call wait_key
    jmp user_loop

; ============================================================
; ADD TO TRANSACTION HISTORY
; ============================================================

add_history proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov dh, cl

    mov al, current_user
    mov ah, 0
    mov bl, 5
    mul bl
    mov si, ax

    mov bl, current_user
    mov bh, 0
    mov al, hist_count[bx]
    mov ah, 0
    mov bx, ax

    cmp bx, 5
    jl store_new

    mov cx, 4
    mov di, si
    inc si

shift_loop:
    mov al, hist_type[si]
    mov hist_type[di], al

    push si
    push di

    mov ax, si
    shl ax, 1
    mov si, ax
    mov ax, hist_amount[si]

    mov bx, di
    shl bx, 1
    mov hist_amount[bx], ax

    pop di
    pop si

    inc si
    inc di
    loop shift_loop

    mov al, current_user
    mov ah, 0
    mov bl, 5
    mul bl
    mov si, ax
    mov bx, 4

store_new:
    mov di, si
    add di, bx
    mov al, dh
    mov hist_type[di], al

    mov ax, di
    shl ax, 1
    mov di, ax
    mov ax, temp_amount
    mov hist_amount[di], ax

    mov bl, current_user
    mov bh, 0
    cmp hist_count[bx], 5
    jge add_done
    inc hist_count[bx]

add_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
add_history endp

; ============================================================
; TRANSFER MONEY BETWEEN ACCOUNTS
; ============================================================

transfer_money:
    call draw_atm_box
    mov dx, offset transfer_user
    call print
    mov di, offset input_user
    call get_string
    call newline

    mov dx, offset enter_amount
    call print
    call get_number
    cmp ax, 0
    jle invalid_transfer

    mov temp_amount, ax
    mov si, 0

find_receiver:
    cmp si, 10
    jge invalid_transfer
    cmp status[si], 1
    jne next_receiver

    push si
    mov ax, si
    mov bx, 20
    mul bx
    mov bx, ax
    lea di, input_user
    lea dx, usernames[bx]
    call compare_string
    pop si

    cmp al, 1
    je receiver_found

next_receiver:
    inc si
    jmp find_receiver

receiver_found:
    mov al, current_user
    mov ah, 0
    cmp ax, si
    je invalid_transfer

    mov bl, current_user
    mov bh, 0
    shl bx, 1
    mov ax, temp_amount
    cmp ax, balances[bx]
    jg no_balance_transfer

    sub balances[bx], ax

    mov bx, si
    shl bx, 1
    add balances[bx], ax

    mov cl, 3
    call add_history
    call save_data

    call draw_atm_box
    mov dx, offset success_msg
    call print
    call newline
    mov dx, offset bal_msg
    call print
    mov bl, current_user
    mov bh, 0
    shl bx, 1
    mov ax, balances[bx]
    call print_number
    call newline
    call draw_bottom_border
    call wait_key
    jmp user_loop

invalid_transfer:
    call draw_atm_box
    mov dx, offset invalid_msg
    call print
    call draw_bottom_border
    call wait_key
    jmp user_loop

no_balance_transfer:
    call draw_atm_box
    mov dx, offset insuff_msg
    call print
    call draw_bottom_border
    call wait_key
    jmp user_loop


; ============================================================
; TEHREEM'S ADDITIONS - Second Commit
; Modules: Admin Panel, File I/O, Password Masking, UI
; ============================================================

; ============================================================
; PASSWORD MASKING (shows *** while typing)
; ============================================================

get_masked_password proc
    push di
    mov cx, 0

mask_loop:
    mov ah, 08h
    int 21h
    cmp al, 13
    je mask_done
    cmp cx, 20
    jae mask_loop
    mov [di], al
    inc di
    inc cx
    mov dl, '*'
    mov ah, 02h
    int 21h
    jmp mask_loop

mask_done:
    mov byte ptr [di], '$'
    pop di
    ret
get_masked_password endp

; ============================================================
; ADMIN PANEL 
; ============================================================

admin_panel:
    call clear_screen
    mov dx, offset enter_admin
    call print
    mov di, offset input_pass
    call get_masked_password
    call newline

    cmp byte ptr input_pass, '9'
    jne admin_fail
    cmp byte ptr input_pass+1, '9'
    jne admin_fail
    cmp byte ptr input_pass+2, '9'
    jne admin_fail
    cmp byte ptr input_pass+3, '9'
    jne admin_fail

admin_menu:
    call clear_screen
    mov dx, offset admin1
    call print
    call newline
    mov dx, offset admin2
    call print
    call newline
    mov dx, offset admin3
    call print
    call newline
    mov dx, offset admin4
    call print
    call newline

    mov dx, offset choice_msg
    call print
    mov ah, 01h
    int 21h
    sub al, 30h

    cmp al, 1
    je view_accounts
    cmp al, 2
    je delete_account
    cmp al, 3
    je system_stats
    cmp al, 4
    je main_menu
    jmp admin_menu

admin_fail:
    mov dx, offset admin_fail_msg
    call print
    call wait_key
    jmp main_menu

view_accounts:
    call clear_screen
    mov si, 0
view_loop:
    cmp si, 10
    jge view_done
    cmp status[si], 1
    jne next_view
    mov ax, si
    mov bx, 20
    mul bx
    mov bx, ax
    lea dx, usernames[bx]
    call print
    call newline
next_view:
    inc si
    jmp view_loop
view_done:
    call wait_key
    jmp admin_menu

delete_account:
    call clear_screen
    mov dx, offset enter_user
    call print
    mov di, offset input_user
    call get_string
    call newline

    mov si, 0
del_loop:
    cmp si, 10
    jge del_done
    cmp status[si], 1
    jne next_del
    mov ax, si
    mov bx, 20
    mul bx
    mov bx, ax
    lea di, input_user
    lea dx, usernames[bx]
    call compare_string
    cmp al, 1
    je found_del
next_del:
    inc si
    jmp del_loop
found_del:
    mov status[si], 0
    dec acc_count
    call save_data
    mov dx, offset delete_msg
    call print
    call wait_key
    jmp admin_menu
del_done:
    mov dx, offset fail_msg
    call print
    call wait_key
    jmp admin_menu

system_stats:
    call clear_screen
    mov dx, offset total_msg
    call print
    mov al, acc_count
    cbw
    call print_number
    call newline

    mov dx, offset active_msg
    call print
    mov si, 0
    mov cx, 0
count_loop:
    cmp si, 10
    jge show_active
    cmp status[si], 1
    jne skip_active
    inc cx
skip_active:
    inc si
    jmp count_loop
show_active:
    mov ax, cx
    call print_number
    call wait_key
    jmp admin_menu

; ============================================================
; FILE I/O - SAVE DATA
; ============================================================

save_data proc
    mov ah, 3ch
    mov cx, 0
    mov dx, offset file_name
    int 21h
    jc save_exit
    mov bx, ax

    mov ah, 40h
    mov cx, 200
    mov dx, offset usernames
    int 21h

    mov ah, 40h
    mov cx, 200
    mov dx, offset passwords
    int 21h

    mov ah, 40h
    mov cx, 20
    mov dx, offset balances
    int 21h

    mov ah, 40h
    mov cx, 10
    mov dx, offset status
    int 21h

    mov ah, 40h
    mov cx, 1
    mov dx, offset acc_count
    int 21h

    mov ah, 3eh
    int 21h
save_exit:
    ret
save_data endp

; ============================================================
; FILE I/O - LOAD DATA
; ============================================================

load_data proc
    mov ah, 3dh
    mov al, 0
    mov dx, offset file_name
    int 21h
    jc load_exit
    mov bx, ax

    mov ah, 3fh
    mov cx, 200
    mov dx, offset usernames
    int 21h

    mov ah, 3fh
    mov cx, 200
    mov dx, offset passwords
    int 21h

    mov ah, 3fh
    mov cx, 20
    mov dx, offset balances
    int 21h

    mov ah, 3fh
    mov cx, 10
    mov dx, offset status
    int 21h

    mov ah, 3fh
    mov cx, 1
    mov dx, offset acc_count
    int 21h

    mov ah, 3eh
    int 21h
load_exit:
    ret
load_data endp
