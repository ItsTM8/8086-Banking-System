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