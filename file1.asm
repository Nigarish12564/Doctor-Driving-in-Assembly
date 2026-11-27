[org 0x0100]
jmp start

; ---- Phase 2 constants (Partner B) ----
BUF_SEG        equ 5000h        ; hidden screen buffer (segment), copied to A000h each frame
TIME_DIV       equ 11           ; ticks per pixel of the time bar
TIME_TOTAL     equ 1276         ; 116 pixels * 11 ticks = about 70 seconds
FUEL_MAX       equ 40           ; width of the fuel bar in pixels
FUEL_DIV       equ 2000         ; speed units that use up 1 pixel of fuel
FUEL_IDLE      equ 30           ; fuel use per tick even when stopped
FUEL_LOW       equ 8            ; bar turns red at or below this
GOAL_M         equ 1000         ; level length in metres
CRASH_PENALTY  equ 50           ; points lost per collision
CAR_START_Y    equ 90           ; row where a new car appears (horizon is 88)
CAR_GONE_Y     equ 150          ; row where a car has passed the player
HIT_Y          equ 146          ; car bottom at this row = touching the bonnet
PATTERN_LEN    equ 12           ; entries in lane_pattern
road_shift: dw 0                ; sideways shift of the road on the current row
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
     db 28, 52, 40, 28           ; building tan
    db 29, 30, 36, 50           ; building blue-grey
    db 30, 63, 58, 30           ; window yellow
    db 27, 61, 40, 14           ; light orange   (already there)
    db 28, 52, 40, 28           ; building tan   <- new
    db 29, 30, 36, 50           ; building blue-grey   <- new
    db 30, 63, 58, 30           ; window yellow  <- new
    db 0FFh

    ; each line = x, y, width (every row is 1 pixel tall)
left_arrow_rows:
    dw 174, 178, 1
    dw 172, 179, 3
    dw 170, 180, 5
    dw 172, 181, 3
    dw 174, 182, 1
    dw 175, 179, 3              ; stem
    dw 175, 180, 3
    dw 175, 181, 3
    dw 0FFFFh

right_arrow_rows:
    dw 193, 178, 1
    dw 193, 179, 3
    dw 193, 180, 5
    dw 193, 181, 3
    dw 193, 182, 1
    dw 190, 179, 3              ; stem
    dw 190, 180, 3
    dw 190, 181, 3
    dw 0FFFFh

hazard_rows:
    dw 185, 177, 1
    dw 184, 178, 3
    dw 183, 179, 5
    dw 182, 180, 7
    dw 181, 181, 9
    dw 0FFFFh

building_table:
    dw 106, 62, 30,  36, 28     ; left side, far
    dw  70, 48, 36,  64, 29
    dw  20, 30, 50, 100, 28
    dw   0, 30, 20, 120, 29
    dw 184, 62, 30,  36, 29     ; right side, far
    dw 214, 48, 36,  64, 28
    dw 250, 30, 50, 100, 29
    dw 300, 30, 20, 120, 28
    dw 0FFFFh                   ; end of the list


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

gold_car_x: dw 155
gold_car_y: dw 96
gold_car_w: dw 10
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
distance_text: db 'DIST 0000 / 1000 m', 0
distance_row: db 1
distance_col: db 5

; ---- score ----
score_text: db 'SCORE  0000', 0
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

;===gear
gear_text: db 'D', 0            ; change to 'R' later when reversing

;--lane guide
current_lane: db 1              ; 0 = left, 1 = middle, 2 = right
arrow_x: dw 0                   ; centre x of the arrow being drawn

;---indicator---
indicator_left:  db 0           ; 1 = left arrow lit
indicator_right: db 0           ; 1 = right arrow lit


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
    push ax                     ; work out the shift for this row
    push bx
    push dx
    mov ax, cx
    xor dx, dx
    mov bx, 3
    div bx                      ; AX = lane spacing on this row (width / 3)
    mov bl, [current_lane]
    xor bh, bh
    neg bx
    inc bx                      ; BX = 1 - lane  (+1, 0 or -1)
    imul bx                     ; AX = spacing * (1 - lane)
    mov [road_shift], ax
    pop dx
    pop bx
    pop ax
    add di, [road_shift]        ; slide this row sideways

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

    push ax
    mov al, dl
    add al, [road_scroll]       ; dashes slide down the road
    test al, 8                  ; dashes: 8 rows on, 8 rows off
    pop ax
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
    sub di, [road_shift]        ; undo the shift before moving to the next row
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
    test dx, dx
    jz rect_done                ; height 0 = draw nothing
    mov al, [rect_c]
rect_row:
    mov di, bx
    mov cx, [rect_w]
    rep stosb
    add bx, 320                 ; next row
    dec dx
    jnz rect_row
rect_done:

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
    call printStringT

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
    call printStringT
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
    call printStringT
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
    call printStringT

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

    ; Fuel left: width = fuel_level, red when low
    mov word [rect_x], 205
    mov word [rect_y], 185
    mov al, [fuel_level]
    mov ah, 0
    mov [rect_w], ax
    mov word [rect_h], 6
    mov byte [rect_c], 23
    cmp al, FUEL_LOW
    ja fuel_colour_ok
    mov byte [rect_c], 21       ; low fuel = red
fuel_colour_ok:
    call drawRect

    ; Print E below the bar
    mov byte [text_row], 24
    mov byte [text_col], 25
    mov byte [text_colour], 15
    mov si, fuel_empty_text
    call printStringT

    ; Print F below the bar
    mov byte [text_row], 24
    mov byte [text_col], 30
    mov byte [text_colour], 15
    mov si, fuel_full_text
    call printStringT

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
    call printStringT

    ; Print km/h below the speed
    mov byte [text_row], 23
    mov byte [text_col], 15
    mov byte [text_colour], 15
    mov si, speed_unit_text
    call printStringT

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

drawBuildings:
    push ax
    push bx
    push dx
    push si

    mov si, building_table
bld_next:
    cmp word [si], 0FFFFh
    jne bld_draw
    jmp bld_done
bld_draw:
    mov ax, [si]                ; building body
    mov [rect_x], ax
    mov ax, [si+2]
    mov [rect_y], ax
    mov ax, [si+4]
    mov [rect_w], ax
    mov ax, [si+6]
    mov [rect_h], ax
    mov ax, [si+8]
    mov [rect_c], al
    call drawRect

    mov word [rect_w], 4        ; windows: 4 x 6 pixels
    mov word [rect_h], 6
    mov byte [rect_c], 30
    mov dx, [si+2]
    add dx, 6                   ; DX = y of the first window row
bld_win_row:
    mov ax, [si+2]
    add ax, [si+6]
    sub ax, 12                  ; stop before the bottom of the building
    cmp dx, ax
    jae bld_win_done
    mov [rect_y], dx
    mov bx, [si]
    add bx, 5                   ; BX = x of the first window
bld_win_col:
    mov ax, [si]
    add ax, [si+4]
    sub ax, 9                   ; stop before the right side
    cmp bx, ax
    ja bld_next_row
    mov [rect_x], bx
    call drawRect
    add bx, 10                  ; next window to the right
    jmp bld_win_col
bld_next_row:
    add dx, 14                  ; next row of windows
    jmp bld_win_row
bld_win_done:
    add si, 10                  ; next building (5 words)
    jmp bld_next
bld_done:
    pop si
    pop dx
    pop bx
    pop ax
    ret

drawGear:
    push ax
    push si

    mov word [rect_x], 4        ; white border
    mov word [rect_y], 180
    mov word [rect_w], 16
    mov word [rect_h], 16
    mov byte [rect_c], 15
    call drawRect

    mov word [rect_x], 5        ; dark inside
    mov word [rect_y], 181
    mov word [rect_w], 14
    mov word [rect_h], 14
    mov byte [rect_c], 22
    call drawRect

    mov byte [text_row], 23     ; the letter D in green
    mov byte [text_col], 1
    mov byte [text_colour], 23
    mov si, gear_text
    call printStringT

    pop si
    pop ax
    ret

drawLaneArrows:
    push ax
    push bx
    push cx
    push dx

    mov word [rect_x], 210      ; orange border of the panel
    mov word [rect_y], 4
    mov word [rect_w], 30
    mov word [rect_h], 24
    mov byte [rect_c], 19
    call drawRect

    mov word [rect_x], 211      ; dark inside
    mov word [rect_y], 5
    mov word [rect_w], 28
    mov word [rect_h], 22
    mov byte [rect_c], 22
    call drawRect

    mov bx, 0                   ; lane number: 0, 1, 2
arrow_next:
    mov ax, bx
    mov dl, 9
    mul dl                      ; AX = lane * 9
    add ax, 215
    mov [arrow_x], ax           ; centre x of this arrow

    mov byte [rect_c], 7        ; grey arrow
    cmp bl, [current_lane]
    jne arrow_colour_ok
    mov byte [rect_c], 26       ; gold arrow = the lane the car is in
arrow_colour_ok:

    mov cx, 4                   ; the arrow head has 4 rows
    mov word [rect_y], 7
    mov word [rect_w], 1
    mov word [rect_h], 1
    mov dx, [arrow_x]
head_loop:
    mov [rect_x], dx
    call drawRect
    dec dx                      ; next row starts 1 pixel more left
    add word [rect_w], 2        ; and is 2 pixels wider
    inc word [rect_y]           ; and 1 row lower
    loop head_loop

    mov ax, [arrow_x]           ; the arrow stem
    dec ax
    mov [rect_x], ax
    mov word [rect_y], 11
    mov word [rect_w], 3
    mov word [rect_h], 10
    call drawRect

    inc bx                      ; next lane
    cmp bx, 3
    jb arrow_next

    pop dx
    pop cx
    pop bx
    pop ax
    ret

    ; drawRows: SI = table, rect_c = colour
drawRows:
    push ax
    push si
    mov word [rect_h], 1
rows_next:
    cmp word [si], 0FFFFh
    je rows_done
    mov ax, [si]
    mov [rect_x], ax
    mov ax, [si+2]
    mov [rect_y], ax
    mov ax, [si+4]
    mov [rect_w], ax
    call drawRect
    add si, 6                   ; next line of the table
    jmp rows_next
rows_done:
    pop si
    pop ax
    ret

drawIndicators:
    push ax
    push si

    mov byte [rect_c], 8        ; dark grey = off
    cmp byte [indicator_left], 0
    je left_is_off
    mov byte [rect_c], 23       ; green = on
left_is_off:
    mov si, left_arrow_rows
    call drawRows

    mov byte [rect_c], 8
    cmp byte [indicator_right], 0
    je right_is_off
    mov byte [rect_c], 23
right_is_off:
    mov si, right_arrow_rows
    call drawRows

    mov byte [rect_c], 4        ; red hazard triangle
    mov si, hazard_rows
    call drawRows

    pop si
    pop ax
    ret

font_off: dw 0
font_seg: dw 0

; printStringT: like printString, but only the letter pixels are drawn
; SI = text ending in 0, uses text_row, text_col, text_colour
printStringT:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push es

    mov ax, 1130h
    mov bh, 3                   ; ask the BIOS where the 8x8 font is
    int 10h                     ; ES:BP = font
    mov [font_off], bp
    mov [font_seg], es
    pop es                      ; ES = video memory again
    push es

    mov cl, 3                   ; shift amount (x8)
    mov al, [text_row]
    mov ah, 0
    shl ax, cl                  ; y = row * 8
    mov bx, 320
    mul bx
    mov di, ax
    mov al, [text_col]
    mov ah, 0
    shl ax, cl                  ; x = col * 8
    add di, ax                  ; DI = top-left pixel of the first letter

tt_char:
    lodsb
    cmp al, 0
    je tt_done
    mov ah, 0
    shl ax, cl
    mov bx, ax
    add bx, [font_off]          ; BX = this letter's 8 font bytes
    push di                     ; remember the letter's start
    mov dx, 8                   ; 8 rows
tt_row:
    push es
    mov es, [font_seg]
    mov al, [es:bx]             ; one row of the letter
    pop es
    push di                     ; remember the row's start
    mov cx, 8
tt_bit:
    test al, 80h
    jz tt_skip
    mov ah, [text_colour]
    mov [es:di], ah             ; only set pixels are drawn
tt_skip:
    shl al, 1
    inc di
    loop tt_bit
    pop di
    add di, 320                 ; next row
    inc bx
    dec dx
    jnz tt_row
    pop di
    add di, 8                   ; next letter
    mov cl, 3                   ; LOOP used CX, so reset the shift amount
    jmp tt_char

tt_done:
    pop es
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; ======================================================================
;  PHASE 2 - PARTNER B
;  moving traffic, collisions, time / fuel, distance / score, end of level
; ======================================================================

; ---- state shared with Partner A ----
speed:          dw 0            ; km/h, 0..120. Partner A changes it, Partner B reads it
game_state:     db 0            ; 0 playing, 1 level complete, 2 time up, 3 out of fuel, 4 quit

; ---- Partner B state ----
distance_m:     dw 0            ; metres driven (0..1000)
dist_frac:      dw 0            ; leftover speed that has not made a whole metre yet
score_val:      dw 0
time_ticks:     dw TIME_TOTAL   ; game ticks left (18.2 per second)
fuel_level:     db FUEL_MAX     ; 0..40 = width of the green bar in pixels
fuel_acc:      dw 0
crash_timer:    db 0            ; ticks the CRASH message stays on screen
road_scroll:    db 0            ; moves the white road dashes
lane_idx:       db 0            ; next entry of lane_pattern
last_tick:      dw 0

; ---- traffic: three cars, same order as the structs (blue, teal, gold) ----
car_lane:       db 0, 2, 1                  ; lane of each car (0 left, 1 middle, 2 right)
car_posy:       dw 118, 104, 96             ; top row of each car
car_ptr:        dw blue_car_x, teal_car_x, gold_car_x   ; each struct = x, y, w, h
lane_pattern:   db 1,0,2,2,0,1,2,1,0,0,2,1  ; repeating pattern for new cars

crash_text:     db 'CRASH! -50', 0
msg_win:        db 'LEVEL COMPLETE!', 0
msg_time:       db '  TIME IS UP!  ', 0
msg_fuel:       db ' OUT OF FUEL!  ', 0
msg_key:        db 'PRESS ANY KEY', 0


; numToText: AX = number, DI = first digit in memory, CX = number of digits
; (leading zeros). Writes ASCII digits from the right.
numToText:
    push ax
    push bx
    push cx
    push dx
    push di
    add di, cx
    dec di                      ; DI = last digit
    mov bx, 10
ntt_loop:
    xor dx, dx
    div bx                      ; AX = AX / 10, DX = digit
    add dl, '0'
    mov [di], dl
    dec di
    loop ntt_loop
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; respawnCar: BX = car number. Puts it back at the far end of the road
; in the next lane of the repeating pattern.
respawnCar:
    push ax
    push si
    mov si, bx
    shl si, 1
    mov word [car_posy+si], CAR_START_Y
    mov al, [lane_idx]
    mov ah, 0
    mov si, ax
    mov al, [lane_pattern+si]
    mov [car_lane+bx], al
    mov al, [lane_idx]
    inc al
    cmp al, PATTERN_LEN
    jb rc_store
    mov al, 0
rc_store:
    mov [lane_idx], al
    pop si
    pop ax
    ret


; moveTraffic: every car comes closer. Near cars move faster (perspective)
; and the player's speed makes them come faster still.
moveTraffic:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    mov bx, 0
mt_next:
    mov si, bx
    shl si, 1
    mov ax, [car_posy+si]
    mov dx, ax
    sub dx, 88                  ; rows below the horizon
    mov cl, 5
    shr dx, cl                  ; / 32
    inc dx                      ; DX = at least 1 row per tick
    mov di, [speed]
    mov cl, 6
    shr di, cl                  ; speed / 64
    add dx, di
    add ax, dx
    mov [car_posy+si], ax
    cmp ax, CAR_GONE_Y
    jb mt_ok
    call respawnCar             ; passed the player: start again far away
mt_ok:
    inc bx
    cmp bx, 3
    jb mt_next
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; placeCars: turns car_lane + car_posy into x, y, w, h for each car struct
; so that drawBlueCar / drawTealCar / drawGoldCar work unchanged.
placeCars:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    mov bx, 0
pc_next:
    mov si, bx
    shl si, 1
    mov di, [car_ptr+si]        ; DI -> x, y, w, h of this car
    mov ax, [car_posy+si]
    mov [di+2], ax              ; y
    shl ax, 1
    sub ax, 148                 ; AX = road width on this row (2y - 148)
    mov cx, ax                  ; CX = road width
    xor dx, dx
    mov si, 5
    div si                      ; AX = car width = road / 5
    mov [di+4], ax              ; w
    mov dx, ax
    shl ax, 1
    add ax, dx                  ; AX = 3w
    shr ax, 1
    shr ax, 1                   ; AX = 3w / 4
    mov [di+6], ax              ; h
    mov ax, cx
    xor dx, dx
    mov si, 3
    div si                      ; AX = distance from the road centre to a side lane
    mov dx, [di+4]
    shr dx, 1                   ; DX = half the car width
     mov cx, 160                 ; centre of the screen = the player's lane
    push ax
    mov al, [car_lane+bx]
    sub al, [current_lane]      ; -2..+2 lanes away from the player
    cbw
    mov si, ax
    pop ax                      ; AX = lane distance in pixels
    push dx
    imul si                     ; AX = distance * lanes away
    pop dx                      ; DX = half the car width again
    add cx, ax
pc_set:
    sub cx, dx
    mov [di], cx                ; x
    inc bx
    cmp bx, 3
    jae pc_done
    jmp pc_next
pc_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; crashHit: BX = car that was hit. Stops the car, takes points away.
crashHit:
    push ax
    mov word [speed], 0
    mov ax, [score_val]
    sub ax, CRASH_PENALTY
    jnc ch_store
    mov ax, 0                   ; score never goes below 0
ch_store:
    mov [score_val], ax
    mov byte [crash_timer], 12
    call respawnCar             ; the car we hit disappears
    pop ax
    ret


; checkCollision: a car in the player's lane that reaches the bonnet is a hit
checkCollision:
    push ax
    push bx
    push si
    push di
    mov bx, 0
cc_next:
    mov al, [car_lane+bx]
    cmp al, [current_lane]
    jne cc_skip
    mov si, bx
    shl si, 1
    mov di, [car_ptr+si]
    mov ax, [di+2]              ; y
    add ax, [di+6]              ; + height = bottom of the car
    cmp ax, HIT_Y
    jb cc_skip
    call crashHit
cc_skip:
    inc bx
    cmp bx, 3
    jb cc_next
    pop di
    pop si
    pop bx
    pop ax
    ret


; updateRoadScroll: white dashes move faster when the car is faster
updateRoadScroll:
    push ax
    push cx
    mov ax, [speed]
    add ax, 31
    mov cl, 5
    shr ax, cl                  ; 0 when stopped, 1..4 when moving
    add byte [road_scroll], al
    pop cx
    pop ax
    ret


; updateDistance: 64 speed units = 1 metre. Every metre gives 1 point.
updateDistance:
    push ax
    mov ax, [speed]
    add [dist_frac], ax
ud_loop:
    cmp word [dist_frac], 64
    jb ud_done
    sub word [dist_frac], 64
    inc word [distance_m]
    inc word [score_val]
    cmp word [score_val], 9999
    jbe ud_loop
    mov word [score_val], 9999
    jmp ud_loop
ud_done:
    pop ax
    ret


; updateFuel: fuel goes down with the speed (and a little when idling)
updateFuel:
    push ax
    mov ax, [speed]
    add ax, FUEL_IDLE
    add [fuel_acc], ax
    cmp word [fuel_acc], FUEL_DIV
    jb uf_done
    sub word [fuel_acc], FUEL_DIV
    cmp byte [fuel_level], 0
    je uf_done
    dec byte [fuel_level]
uf_done:
    pop ax
    ret


updateTime:
    cmp word [time_ticks], 0
    je ut_done
    dec word [time_ticks]
ut_done:
    ret


; updateHud: refreshes the texts and the time bar from the game values
updateHud:
    push ax
    push bx
    push cx
    push dx
    push di

    mov ax, [speed]             ; speed box: 3 digits
    mov di, speed_text
    mov cx, 3
    call numToText

    mov ax, [distance_m]        ; DIST 0420 / 1000 m
    mov di, distance_text+5
    mov cx, 4
    call numToText

    mov ax, [score_val]         ; SCORE  4793
    mov di, score_text+7
    mov cx, 4
    call numToText

    mov ax, [time_ticks]        ; time bar: red part shrinks from the top
    xor dx, dx
    mov bx, TIME_DIV
    div bx                      ; AX = pixels of time left
    cmp ax, [time_bar_h]
    jbe uh_time_ok
    mov ax, [time_bar_h]
uh_time_ok:
    mov [time_left_h], ax
    mov bx, [time_bar_y]
    add bx, [time_bar_h]        ; BX = bottom of the bar
    sub bx, ax
    mov [time_left_y], bx

    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; checkEnd: level complete at 1000 m, over when time or fuel is 0
checkEnd:
    cmp word [distance_m], GOAL_M
    jb ce_time
    mov word [distance_m], GOAL_M
    mov byte [game_state], 1
    ret
ce_time:
    cmp word [time_ticks], 0
    jne ce_fuel
    mov byte [game_state], 2
    ret
ce_fuel:
    cmp byte [fuel_level], 0
    jne ce_done
    mov byte [game_state], 3
ce_done:
    ret


; updateGame: everything Partner B does once per tick
updateGame:
    call moveTraffic
    call placeCars
    call checkCollision
    call updateRoadScroll
    call updateDistance
    call updateFuel
    call updateTime
    call updateHud
    call checkEnd
    cmp byte [crash_timer], 0
    je ug_done
    dec byte [crash_timer]
ug_done:
    ret


; drawCrashText: small CRASH box while crash_timer is running
drawCrashText:
    push si
    cmp byte [crash_timer], 0
    je dct_done
    mov word [rect_x], 116
    mov word [rect_y], 44
    mov word [rect_w], 88
    mov word [rect_h], 16
    mov byte [rect_c], 22
    call drawRect
    mov byte [text_row], 6
    mov byte [text_col], 15
    mov byte [text_colour], 21
    mov si, crash_text
    call printStringT
dct_done:
    pop si
    ret


; showEndMessage: box in the middle of the screen, text depends on game_state
showEndMessage:
    push ax
    push si
    push es
    mov ax, BUF_SEG
    mov es, ax

    mov word [rect_x], 68
    mov word [rect_y], 64
    mov word [rect_w], 176
    mov word [rect_h], 48
    mov byte [rect_c], 15
    call drawRect
    mov word [rect_x], 69
    mov word [rect_y], 65
    mov word [rect_w], 174
    mov word [rect_h], 46
    mov byte [rect_c], 22
    call drawRect

    mov si, msg_win
    mov byte [text_colour], 26  ; gold for a win
    cmp byte [game_state], 1
    je em_print
    mov byte [text_colour], 21  ; red for a loss
    mov si, msg_time
    cmp byte [game_state], 2
    je em_print
    mov si, msg_fuel
em_print:
    mov byte [text_row], 9
    mov byte [text_col], 12
    call printStringT

    mov byte [text_row], 11
    mov byte [text_col], 13
    mov byte [text_colour], 15
    mov si, msg_key
    call printStringT

    call flipScreen
    pop es
    pop si
    pop ax
    ret


; ---- frame handling: everything is drawn in a hidden buffer, then copied ----
drawScene:
    call drawSky
    call drawGrass
    call drawBuildings
    call drawRoad
    call drawTraffic            ; cars go after the road, before the bonnet
    call drawCar                ; bonnet + dashboard
    call drawTime
    call drawDistance
    call drawScore
    call drawFuel
    call drawSpeed
    call drawSteeringWheel
    call drawGear
    call drawLaneArrows
    call drawIndicators
    call drawCrashText
    ret


flipScreen:
    push ax
    push cx
    push dx
    push si
    push di
    push ds
    push es
    mov dx, 3DAh                ; wait for the vertical retrace (less flicker)
fl_w1:
    in al, dx
    test al, 8
    jnz fl_w1
fl_w2:
    in al, dx
    test al, 8
    jz fl_w2
    mov ax, BUF_SEG
    mov ds, ax
    mov ax, 0A000h
    mov es, ax
    xor si, si
    xor di, di
    mov cx, 32000
    cld
    rep movsw                   ; copy the whole 320 x 200 screen
    pop es
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    ret


drawFrame:
    push ax
    push es
    mov ax, BUF_SEG
    mov es, ax
    call drawScene
    call flipScreen
    pop es
    pop ax
    ret


; waitTick: one game step per BIOS timer tick (18.2 per second)
waitTick:
    push ax
    push cx
    push dx
wt_again:
    mov ah, 0
    int 1Ah                     ; CX:DX = tick counter
    cmp dx, [last_tick]
    je wt_again
    mov [last_tick], dx
    pop dx
    pop cx
    pop ax
    ret


flushKeys:
    push ax
fk_loop:
    mov ah, 1
    int 16h
    jz fk_done
    mov ah, 0
    int 16h
    jmp fk_loop
fk_done:
    pop ax
    ret


; ----------------------------------------------------------------------
; handleInput - Partner A: keyboard, acceleration, braking, lane switching
; Changes [speed], [current_lane] and the indicator flags.
; ----------------------------------------------------------------------
indicator_timer: db 0           ; ticks left before the indicator turns off

handleInput:
    push ax

    cmp byte [indicator_timer], 0   ; count the indicator down once per tick
    je hi_next
    dec byte [indicator_timer]
    jnz hi_next
    mov byte [indicator_left], 0
    mov byte [indicator_right], 0

hi_next:
    mov ah, 1
    int 16h
    jnz hi_key
    jmp hi_done
hi_key:
    mov ah, 0
    int 16h                     ; AH = scan code
    cmp ah, 01h                 ; Esc = quit
    jne hi_up
    mov byte [game_state], 4
    jmp hi_done

hi_up:
    cmp ah, 48h                 ; Up Arrow
    jne hi_space
    add word [speed], 4
    cmp word [speed], 120
    jbe hi_next
    mov word [speed], 120
    jmp hi_next

hi_space:
    cmp ah, 39h                 ; Space
    jne hi_left
    cmp word [speed], 8
    jae hi_brake
    mov word [speed], 8         ; so it never goes below 0
hi_brake:
    sub word [speed], 8
    jmp hi_next

hi_left:
    cmp ah, 4Bh                 ; Left Arrow
    jne hi_right
    cmp byte [current_lane], 0  ; edge lane: do nothing
    je hi_next
    dec byte [current_lane]
    mov byte [indicator_left], 1
    mov byte [indicator_right], 0
    mov byte [indicator_timer], 15
    jmp hi_next

hi_right:
    cmp ah, 4Dh                 ; Right Arrow
    jne hi_next
    cmp byte [current_lane], 2
    jae hi_next
    inc byte [current_lane]
    mov byte [indicator_right], 1
    mov byte [indicator_left], 0
    mov byte [indicator_timer], 15
    jmp hi_next

hi_done:
    pop ax
    ret


start:
    mov ax, 0013h
    int 10h
    cld
    call set_palette

game_loop:
    call waitTick
    call handleInput            ; Partner A
    call updateGame             ; Partner B
    call drawFrame
    cmp byte [game_state], 0
    je game_loop

    cmp byte [game_state], 4    ; Esc: leave without a message
    je terminate
    call showEndMessage
    call flushKeys
    mov ah, 0                   ; wait for a key
    int 16h

terminate:
    mov ax, 0003h               ; back to text mode
    int 10h
    mov ax, 4C00h
    int 21h