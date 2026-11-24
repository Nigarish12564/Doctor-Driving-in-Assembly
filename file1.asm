[org 0x0100]
jmp start

sky_blue: db 16, 33, 51, 59
grass_green: db 17, 30, 42, 25
road_grey: db 18, 22, 22, 25
bonnet_orange: db 19, 57, 30,  7
bonnet_light: db 27
dashboard_colour: db 20, 12, 12, 14
car_colour: db 0
window_colour: db 22
light_colour: db 21
blue_car_colour: db 24
teal_car_colour: db 25
gold_car_colour: db 26
score_colour: db 26
distance_colour: db 15
time_left_colour: db 21
time_bar_empty_colour: db 22
time_text_colour: db 15
text_colour: db 0

palette_table:
    db 16, 33, 51, 59           ; sky blue
    db 17, 30, 42, 25           ; grass green
    db 18, 22, 22, 25           ; road grey
    db 19, 57, 30,  7           ; bonnet orange
    db 20, 12, 12, 14           ; dashboard
    db 21, 58, 17, 10           ; red
    db 22,  3,  3,  5           ; almost black
    db 23, 15, 50, 22           ; fuel green
    db 24, 10, 21, 50           ; car blue
    db 25,  8, 40, 37           ; car teal
    db 26, 63, 50, 10           ; gold
    db 27, 61, 40, 14           ; light orange
    db 0FFh



; ---- shared by the rectangle routine ----
rect_x: dw 0
rect_y: dw 0
rect_w: dw 0
rect_h: dw 0
rect_c: db 0

; ---- shared by the traffic car routine ----
car_x: dw 0
car_y: dw 0
car_w: dw 0
car_h: dw 0

; ---- the three traffic cars ----
blue_car_x: dw 120
blue_car_y: dw 118
blue_car_w: dw 18
blue_car_h: dw 14

teal_car_x: dw 174
teal_car_y: dw 104
teal_car_w: dw 11
teal_car_h: dw 9

gold_car_x: dw 156
gold_car_y: dw 96
gold_car_w: dw 8
gold_car_h: dw 7

; ---- shared by the text routine ----
text_row: db 0
text_col: db 0

; ---- time ----
time_text: db 'Time', 0
time_row: db 2
time_col: db 0
time_bar_x: dw 8
time_bar_y: dw 26
time_bar_w: dw 8
time_bar_h: dw 116
time_left_y: dw 80
time_left_h: dw 62

; ---- distance ----
distance_text: db 'DIST  420 / 1000 m', 0
distance_row: db 1
distance_col: db 5

; ---- score ----
score_text: db 'SCORE  4793', 0
score_row: db 2
score_col: db 5

; ---- fuel bar ----
fuel_text: db 'FUEL', 0
fuel_empty_text: db 'E', 0
fuel_full_text: db 'F', 0

; ---- speed display ----
speed_text: db '078', 0
speed_unit_text: db 'km/h', 0
;----steering wheel:
wheel_dy2: dw 0

; set_colour: BX = colour number, DH = red, CH = green, CL = blue (0..63)
set_palette:
    mov si, palette_table
palette_loop:
    cmp byte [si], 0FFh
    je palette_done
    mov bl, [si]
    mov bh, 0
    mov dh, [si+1]              ; red
    mov ch, [si+2]              ; green
    mov cl, [si+3]              ; blue
    mov ax, 1010h               ; BIOS: set one palette colour
    int 10h
    add si, 4                   ; next table line
    jmp palette_loop
palette_done:
    ret



drawSky:
    push ax
    push cx
    push di

    mov cx, 28160
    mov di, 0
    mov al, [sky_blue]
    rep stosb

    pop di
    pop cx
    pop ax
    ret



drawGrass:
    push ax
    push cx
    push di

    mov cx, 35840
    mov di, 28160               ; row 88, column 0
    mov al, [grass_green]
    rep stosb

    pop di
    pop cx
    pop ax
    ret


drawRoad:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov di, 28306               ; row 88, x = 146  (88 * 320 + 146)
    mov cx, 28                  ; width of the first row
    mov dx, 80                  ; rows 88 to 167
    mov al, [road_grey]
road_row:
    push cx                     ; save the width (rep stosb makes CX = 0)
    push di                     ; save where this row started
    rep stosb                   ; draw one row of grey
    pop di                      ; DI = start of the row again
    pop cx                      ; CX = width again

    mov byte [es:di], 15        ; left edge, 2 white pixels
    mov byte [es:di+1], 15
    mov bx, di
    add bx, cx                  ; BX = just after the last pixel of the row
    mov byte [es:bx-1], 15      ; right edge, 2 white pixels
    mov byte [es:bx-2], 15

    test dl, 8                  ; dashes: 8 rows on, 8 rows off
    jz skip_dashes
    push ax                     ; keep the grey colour in AL safe
    mov ax, cx
    mov bl, 6
    div bl                      ; AL = width / 6 = lane line distance
    mov ah, 0
    mov si, ax                  ; SI = distance from the centre
    pop ax                      ; grey colour back in AL

    mov bx, cx
    shr bx, 1                   ; BX = half the width
    add bx, di                  ; BX = address of the centre pixel of this row
    mov byte [es:bx+si], 15     ; right lane line, 2 white pixels
    mov byte [es:bx+si+1], 15
    sub bx, si
    mov byte [es:bx-1], 15      ; left lane line, 2 white pixels
    mov byte [es:bx-2], 15
skip_dashes:
    add di, 319                 ; one row down (+320) and one pixel left (-1)
    add cx, 2                   ; 1 pixel wider on each side
    dec dx
    jnz road_row

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret




drawDashboard:
    push ax
    push cx
    push di
    mov cx, 10240               ; 32 rows * 320 pixels (rows 168 to 199)
    mov di, 53760               ; row 168, column 0  (168 * 320)
    mov al, [dashboard_colour]
    rep stosb
    pop di
    pop cx
    pop ax
    ret



drawCar:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    mov bx, 0                   ; BX = current column x (0..319)
car_column:
    mov ax, bx
    cmp ax, 160
    jb car_left_side
    sub ax, 160                 ; right side: u = x - 160
    jmp car_have_u
car_left_side:
    mov dx, 160                 ; left side: u = 160 - x
    sub dx, ax
    mov ax, dx
car_have_u:
    mul ax                      ; AX = u * u
    mov si, 1113
    div si                      ; AX = u * u / 1113
    add ax, 144                 ; AX = top row of this column
    mov cx, 168
    sub cx, ax                  ; CX = height of this column
    mov dx, 320
    mul dx                      ; AX = top * 320
    add ax, bx                  ; AX = top * 320 + x
    mov di, ax                  ; DI = first pixel of the column
    mov al, [bonnet_light]
    mov byte [es:di], al        ; light orange pixel on top
    add di, 320                 ; one row down
    dec cx
    jcxz car_next_column        ; column was only 1 pixel tall
    mov al, [bonnet_orange]
car_strip:
    mov byte [es:di], al        ; normal orange for the rest of the column
    add di, 320
    loop car_strip
car_next_column:
    inc bx
    cmp bx, 320
    jb car_column
    call drawDashboard          ; draw the dashboard under the bonnet
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; drawRect: draws one rectangle from rect_x, rect_y, rect_w, rect_h, rect_c
drawRect:
    push ax
    push bx
    push cx
    push dx
    push di

    mov ax, [rect_y]
    mov bx, 320
    mul bx                      ; AX = y * 320
    add ax, [rect_x]
    mov bx, ax                  ; BX = start of the current row
    mov dx, [rect_h]            ; DX = rows left to draw
    mov al, [rect_c]
rect_row:
    mov di, bx
    mov cx, [rect_w]
    rep stosb
    add bx, 320                 ; next row
    dec dx
    jnz rect_row

    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; printString: SI = text ending in 0, uses text_row, text_col, text_colour
printString:
    push ax
    push bx
    push dx
    push si

    mov dh, [text_row]
    mov dl, [text_col]
    mov ah, 02h                 ; BIOS: put the cursor there
    mov bh, 0
    int 10h
print_loop:
    lodsb                       ; AL = next letter
    cmp al, 0
    je print_done
    mov ah, 0Eh                 ; BIOS: print the letter in AL
    mov bh, 0
    mov bl, [text_colour]
    int 10h
    jmp print_loop
print_done:
    pop si
    pop dx
    pop bx
    pop ax
    ret


; drawTrafficCar: box car from car_x, car_y, car_w, car_h, car_colour
drawTrafficCar:
    push ax
    push bx

    mov ax, [car_x]             ; body
    mov [rect_x], ax
    mov ax, [car_y]
    mov [rect_y], ax
    mov ax, [car_w]
    mov [rect_w], ax
    mov ax, [car_h]
    mov [rect_h], ax
    mov al, [car_colour]
    mov [rect_c], al
    call drawRect

    mov ax, [car_x]             ; rear window: x+2, y+2, w-4, h/3
    add ax, 2
    mov [rect_x], ax
    mov ax, [car_y]
    add ax, 2
    mov [rect_y], ax
    mov ax, [car_w]
    sub ax, 4
    mov [rect_w], ax
    mov ax, [car_h]
    mov bl, 3
    div bl                      ; AL = h / 3
    mov ah, 0
    mov [rect_h], ax
    mov al, [window_colour]
    mov [rect_c], al
    call drawRect

    mov word [rect_w], 3        ; tail lights, 3 x 3 pixels
    mov word [rect_h], 3
    mov ax, [car_y]
    add ax, [car_h]
    sub ax, 4
    mov [rect_y], ax
    mov al, [light_colour]
    mov [rect_c], al

    mov ax, [car_x]             ; left light
    inc ax
    mov [rect_x], ax
    call drawRect

    mov ax, [car_x]             ; right light
    add ax, [car_w]
    sub ax, 4
    mov [rect_x], ax
    call drawRect

    pop bx
    pop ax
    ret



drawBlueCar:
    push ax
    mov ax, [blue_car_x]
    mov [car_x], ax
    mov ax, [blue_car_y]
    mov [car_y], ax
    mov ax, [blue_car_w]
    mov [car_w], ax
    mov ax, [blue_car_h]
    mov [car_h], ax
    mov al, [blue_car_colour]
    mov [car_colour], al
    call drawTrafficCar
    pop ax
    ret


drawTealCar:
    push ax
    mov ax, [teal_car_x]
    mov [car_x], ax
    mov ax, [teal_car_y]
    mov [car_y], ax
    mov ax, [teal_car_w]
    mov [car_w], ax
    mov ax, [teal_car_h]
    mov [car_h], ax
    mov al, [teal_car_colour]
    mov [car_colour], al
    call drawTrafficCar
    pop ax
    ret


drawGoldCar:
    push ax
    mov ax, [gold_car_x]
    mov [car_x], ax
    mov ax, [gold_car_y]
    mov [car_y], ax
    mov ax, [gold_car_w]
    mov [car_w], ax
    mov ax, [gold_car_h]
    mov [car_h], ax
    mov al, [gold_car_colour]
    mov [car_colour], al
    call drawTrafficCar
    pop ax
    ret


drawTraffic:                    ; farthest car first
    call drawGoldCar
    call drawTealCar
    call drawBlueCar
    ret


drawTime:                       ; "Time" label and the time bar
    push ax
    push si

    mov al, [time_row]
    mov [text_row], al
    mov al, [time_col]
    mov [text_col], al
    mov al, [time_text_colour]
    mov [text_colour], al
    mov si, time_text
    call printString

    mov ax, [time_bar_x]        ; empty part of the bar
    mov [rect_x], ax
    mov ax, [time_bar_y]
    mov [rect_y], ax
    mov ax, [time_bar_w]
    mov [rect_w], ax
    mov ax, [time_bar_h]
    mov [rect_h], ax
    mov al, [time_bar_empty_colour]
    mov [rect_c], al
    call drawRect

    mov ax, [time_left_y]       ; red part = time left
    mov [rect_y], ax
    mov ax, [time_left_h]
    mov [rect_h], ax
    mov al, [time_left_colour]
    mov [rect_c], al
    call drawRect

    pop si
    pop ax
    ret


drawDistance:
    push ax
    push si
    mov al, [distance_row]
    mov [text_row], al
    mov al, [distance_col]
    mov [text_col], al
    mov al, [distance_colour]
    mov [text_colour], al
    mov si, distance_text
    call printString
    pop si
    pop ax
    ret


drawScore:
    push ax
    push si
    mov al, [score_row]
    mov [text_row], al
    mov al, [score_col]
    mov [text_col], al
    mov al, [score_colour]
    mov [text_colour], al
    mov si, score_text
    call printString
    pop si
    pop ax
    ret


drawFuel:
    push ax
    push si

    ; Print FUEL label
    mov byte [text_row], 22
    mov byte [text_col], 25
    mov byte [text_colour], 15
    mov si, fuel_text
    call printString

    ; Draw the outer white border
    mov word [rect_x], 204
    mov word [rect_y], 184
    mov word [rect_w], 42
    mov word [rect_h], 8
    mov byte [rect_c], 15
    call drawRect

    ; Thin white border: dark inner area
    mov word [rect_x], 205
    mov word [rect_y], 185
    mov word [rect_w], 40
    mov word [rect_h], 6
    mov byte [rect_c], 22
    call drawRect

    ; Half-full green fuel
    mov word [rect_x], 205
    mov word [rect_y], 185
    mov word [rect_w], 20
    mov word [rect_h], 6
    mov byte [rect_c], 23
    call drawRect

    ; Print E below the bar
    mov byte [text_row], 24
    mov byte [text_col], 25
    mov byte [text_colour], 15
    mov si, fuel_empty_text
    call printString

    ; Print F below the bar
    mov byte [text_row], 24
    mov byte [text_col], 30
    mov byte [text_colour], 15
    mov si, fuel_full_text
    call printString

    pop si
    pop ax
    ret


drawSpeed:
    push ax
    push si

    ; Draw the outer white border
    mov word [rect_x], 104
    mov word [rect_y], 176
    mov word [rect_w], 64
    mov word [rect_h], 22
    mov byte [rect_c], 15
    call drawRect

    ; Draw the dark inner box
    mov word [rect_x], 105
    mov word [rect_y], 177
    mov word [rect_w], 62
    mov word [rect_h], 20
    mov byte [rect_c], 22
    call drawRect

    ; Print the speed in gold
    mov byte [text_row], 22
    mov byte [text_col], 15
    mov byte [text_colour], 26
    mov si, speed_text
    call printString

    ; Print km/h below the speed
    mov byte [text_row], 23
    mov byte [text_col], 15
    mov byte [text_colour], 15
    mov si, speed_unit_text
    call printString

    pop si
    pop ax
    ret





drawSteeringWheel:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov si, 137                 ; y = top row of the wheel
w_row:
    mov ax, si
    sub ax, 180                 ; centre y = 180
    imul ax
    mov [wheel_dy2], ax         ; dy squared

    mov cx, 257                 ; x = left side of the wheel
w_col:
    mov ax, cx
    sub ax, 300                 ; centre x = 300
    imul ax
    add ax, [wheel_dy2]         ; AX = distance squared from centre

    mov bl, 0                   ; default colour: black
    cmp ax, 1849                ; outside the wheel (43 squared)?
    ja w_next
    cmp ax, 144                 ; inside the hub (12 squared)?
    jbe w_hub
    cmp word [wheel_dy2], 9     ; spoke rows
    jbe w_draw
    cmp ax, 1225                ; inside the hole (35 squared)?
    jb w_next
    jmp w_draw
w_hub:
    mov bl, 7                   ; grey hub

w_draw:
    push ax
    mov ax, si
    mov dx, 320
    mul dx
    add ax, cx
    mov di, ax
    mov [es:di], bl             ; put the pixel
    pop ax

w_next:
    inc cx
    cmp cx, 320
    jb w_col

    inc si
    cmp si, 200
    jb w_row

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


start:
    mov ax, 0013h
    int 10h
    mov ax, 0A000h
    mov es, ax
    cld
    call set_palette

    call drawSky
    call drawGrass
    call drawRoad
    call drawTraffic            ; cars go after the road, before the bonnet
    call drawCar                ; bonnet + dashboard
    call drawTime
    call drawDistance
    call drawScore
    call drawFuel
    call drawSpeed
    call drawSteeringWheel

    mov ah, 0                   ; wait for a key
    int 16h

terminate:
    mov ax, 0003h               ; back to text mode
    int 10h
    mov ax, 4C00h
    int 21h