;	set game state memory location
.equ    HEAD_X,         0x1000  ; Snake head's position on x
.equ    HEAD_Y,         0x1004  ; Snake head's position on y
.equ    TAIL_X,         0x1008  ; Snake tail's position on x
.equ    TAIL_Y,         0x100C  ; Snake tail's position on Y
.equ    SCORE,          0x1010  ; Score address
.equ    GSA,            0x1014  ; Game state array address

.equ    CP_VALID,       0x1200  ; Whether the checkpoint is valid.
.equ    CP_HEAD_X,      0x1204  ; Snake head's X coordinate. (Checkpoint)
.equ    CP_HEAD_Y,      0x1208  ; Snake head's Y coordinate. (Checkpoint)
.equ    CP_TAIL_X,      0x120C  ; Snake tail's X coordinate. (Checkpoint)
.equ    CP_TAIL_Y,      0x1210  ; Snake tail's Y coordinate. (Checkpoint)
.equ    CP_SCORE,       0x1214  ; Score. (Checkpoint)
.equ    CP_GSA,         0x1218  ; GSA. (Checkpoint)

.equ    LEDS,           0x2000  ; LED address
.equ    SEVEN_SEGS,     0x1198  ; 7-segment display addresses
.equ    RANDOM_NUM,     0x2010  ; Random number generator address
.equ    BUTTONS,        0x2030  ; Buttons addresses

; button state
.equ    BUTTON_NONE,    0
.equ    BUTTON_LEFT,    1
.equ    BUTTON_UP,      2
.equ    BUTTON_DOWN,    3
.equ    BUTTON_RIGHT,   4
.equ    BUTTON_CHECKPOINT,    5

; array state
.equ    DIR_LEFT,       1       ; leftward direction
.equ    DIR_UP,         2       ; upward direction
.equ    DIR_DOWN,       3       ; downward direction
.equ    DIR_RIGHT,      4       ; rightward direction
.equ    FOOD,           5       ; food

; constants
.equ    NB_ROWS,        8       ; number of rows
.equ    NB_COLS,        12      ; number of columns
.equ    NB_CELLS,       96      ; number of cells in GSA
.equ    RET_ATE_FOOD,   1       ; return value for hit_test when food was eaten
.equ    RET_COLLISION,  2       ; return value for hit_test when a collision was detected
.equ    ARG_HUNGRY,     0       ; a0 argument for move_snake when food wasn't eaten
.equ    ARG_FED,        1       ; a0 argument for move_snake when food was eaten


; initialize stack pointer
addi    sp, zero, LEDS

; main procedure
main:
    stw zero, CP_VALID(zero)            ; no copy is valid at start

go_to_init_game:
    call wait
    call init_game

go_to_get_inputs: 
    call wait
    call wait
    call wait
    call get_input

    addi t0, zero, BUTTON_CHECKPOINT
    beq v0, t0, go_to_restore_checkpoint; if CHECKPOINT button pressed

    call hit_test

    addi t0, zero, RET_ATE_FOOD
    beq t0, v0, go_to_food_eaten        ; if food eaten

    addi t0, zero, RET_COLLISION
    beq t0, v0, go_to_init_game         ; if collided, end game

    addi a0, zero, ARG_HUNGRY
    call move_snake

go_to_new:
    call clear_leds
    call draw_array
    jmpi go_to_get_inputs

go_to_food_eaten:
    ldw t0, SCORE(zero)
    addi t0, t0, 1
    stw t0, SCORE(zero)

    call display_score

    addi a0, zero, ARG_FED
    call move_snake
    call create_food
    call save_checkpoint
    beq v0, zero, go_to_new             ; if checkpoint (saved) is not valid
    jmpi go_to_blink_score              ; else (valid) go to blink score 

go_to_restore_checkpoint:
    call restore_checkpoint
    beq v0, zero, go_to_get_inputs      ; if checkpoint is not valid
    jmpi go_to_blink_score              ; else (checkpoint is valid)

go_to_blink_score:
    call blink_score
    jmpi go_to_new                      


; BEGIN: clear_leds
clear_leds:
    stw zero, LEDS(zero)                ; clear LEDS0
    stw zero, LEDS+4(zero)              ; clear LEDS1
    stw zero, LEDS+8(zero)              ; clear LEDS2
    ret
; END: clear_leds


; BEGIN: set_pixel
set_pixel:
    add t7, zero, zero                  ; LEDS counter, check in whick LEDS the pixel is located

loop_set_pixel:
    cmplti t0, a0, 4                    ; if x is < 4, we're in the correct LEDS
    bne t0, zero, end_set_pixel         ; we go to end to compute the index and turn on the pixel
    addi t7, t7, 4                      ; else, the pixel is in the next LEDS
    addi a0, a0, -4                     ; we jump to next LEDS and recheck
    jmpi loop_set_pixel

end_set_pixel:
    addi t1, zero, 1                    ; only 1 bit on
    slli t0, a0, 3                      ; t0 = x * 8
    add t0, t0, a1                      ; t0 = x * 8 + y
    sll t1, t1, t0                      ; bit is shifted to the corresponding index
    ldw t2, LEDS(t7)                    ; get current LEDS state
    or t2, t2, t1                       ; turn on the targeted pixel without modifying old state
    stw t2, LEDS(t7)                    ; restore the new state in corresponding LEDS
    ret
; END: set_pixel


; BEGIN: display_score
display_score:
    ldw t0, SCORE(zero)                 ; load current game score
    add t1, zero, zero                  ; digit counter for second SEVEN_SEGS

loop_display_score:
    cmplti t2, t0, 10                   ; if score is smaller than 10
    bne t2, zero, end_display_score     ; we can display first and second SEVEN_SEGS
    addi t0, t0, -10                    ; else decrement score by 10
    addi t1, t1, 1                      ; and increment second SEVEN_SEGS digit
    jmpi loop_display_score             ; iterate again

end_display_score:
    slli t0, t0, 2                      ; multiply t0 by 4 to turn it into an address
    slli t1, t1, 2                      ; multiply t1 by 4 to turn it into an address
    ldw t0, digit_map(t0)               ; get display for first digit
    ldw t1, digit_map(t1)               ; get display for second digit
    ldw t2, digit_map(zero)             ; get display 0 for third and fourth digits

    stw t2, SEVEN_SEGS(zero)            ; display 0 on fourth SEVEN_SEGS
    stw t2, SEVEN_SEGS+4(zero)          ; display 0 on third SEVEN_SEGS
    stw t1, SEVEN_SEGS+8(zero)          ; display second digit on second SEVEN_SEGS          
    stw t0, SEVEN_SEGS+12(zero)         ; display first digit on first SEVEN_SEGS 
    ret
; END: display_score


; BEGIN: init_game
init_game:
    addi sp, sp, -4                     ;  push registers to stack
    stw ra, 0(sp)

    add t0, zero, zero                  ; counter to reset all GSA

loop_gsa_init_game:
    slli t1, t0, 2                      ; multiply t0 by 4 to turn it into an address
    stw zero, GSA(t1)                   ; set corresponding GSA entry to 0
    addi t0, t0, 1                      ; decrement GSA counter$
    cmplti t1, t0, NB_CELLS
    bne  t1, zero, loop_gsa_init_game   ; iterate until all GSA is set to 0

    stw zero, HEAD_X(zero)              ; set head x coordinate to 0
    stw zero, HEAD_Y(zero)              ; set head y coordinate to 0
    stw zero, TAIL_X(zero)              ; set tail x coordinate to 0
    stw zero, TAIL_Y(zero)              ; set tail y coordinate to 0

    stw zero, SCORE(zero)               ; set score to 0
    ldw t0, digit_map(zero)             ; get display 0 from digit_map
    stw t0, SEVEN_SEGS(zero)            ; display 0 on fourth SEVEN_SEGS
    stw t0, SEVEN_SEGS+4(zero)          ; display 0 on third SEVEN_SEGS
    stw t0, SEVEN_SEGS+8(zero)          ; display 0 on second SEVEN_SEGS       
    stw t0, SEVEN_SEGS+12(zero)         ; display 0 on first SEVEN_SEGS

    addi t0, zero, DIR_RIGHT            ; get the RIGHT direction
    stw t0, GSA(zero)                   ; store it in first cell

    call clear_leds                     ; clear LEDS
    call create_food                    ; generate random food
    call draw_array                     ; turn on LEDS
	call display_score                  ; turn on score

    ldw ra, 0(sp)
    addi sp, sp, 4                      ;  pop registers from stack
    ret

; END: init_game


; BEGIN: create_food
create_food:
    ldw t0, RANDOM_NUM(zero)            ; get random number
    andi t0, t0, 0xFF                   ; mask to get 8 LSBs (lowest byte)

    cmpgei t1, t0, NB_CELLS             ; if random number is bigger than number of cells (out of bounds)
    bne t1, zero, create_food           ; we regenerate a random number

    slli t1, t0, 2                      ; multiply t0 by 4 to turn it into an address
    ldw t2, GSA(t1)                     ; if cell is taken by snake
    bne t2, zero, create_food           ; we regenerate a random number
    
    addi t2, zero, FOOD                 ; else we reserve this cell for food
    stw t2, GSA(t1)                     ; and store it in GSA
    ret
; END: create_food


; BEGIN: hit_test
hit_test:
    ldw t0, HEAD_X(zero)                ; get old snake head x coordinate
    ldw t1, HEAD_Y(zero)                ; get old snake head y coordinate

    slli t4, t0, 3                      ; t4 = x * 8
    add t4, t4, t1                      ; t4 = x * 8 + y
    slli t4, t4, 2                      ; multiply t4 by 4 to turn it into an address
    ldw t2, GSA(t4)                     ; get current head direction with index t4
    srli t4, t4, 2                      ; divide t4 by 4 to return it into an index

    addi t3, zero, DIR_LEFT             ; if old head direction is LEFT
    beq t2, t3, check_left_hit_test     ; branch to check if collision occured
    
    addi t3, zero, DIR_UP               ; if old head direction is UP
    beq t2, t3, check_up_hit_test       ; branch to check if collision occured

    addi t3, zero, DIR_DOWN             ; if old head direction is DOWN
    beq t2, t3, check_down_hit_test     ; branch to check if collision occured

    addi t3, zero, DIR_RIGHT            ; if old head direction is RIGHT
    beq t2, t3, check_right_hit_test    ; branch to check if collision occured

    jmpi end_hit_test                   ; food ?


check_left_hit_test: 
    addi t4, t4, -8                     ; get expected head index
    bne t0, zero, check_snake_or_food_hit_test  ; if head is not on the LEFT corner, check other collisions
    jmpi fatal_collision_hit_test       ; else end game with collision

check_up_hit_test:
    addi t4, t4, -1                     ; get expected head index
    bne t1, zero, check_snake_or_food_hit_test  ; if head is not on the UPPER corner, check other collisions
    jmpi fatal_collision_hit_test       ; else end game with collision 

check_down_hit_test:
    addi t4, t4, 1                      ; get expected head index
    cmpgei t2, t1, NB_ROWS-1
    beq t2, zero, check_snake_or_food_hit_test  ; if head is not on the LOWER corner, check other collisions
    jmpi fatal_collision_hit_test       ; else end game with collision

check_right_hit_test:
    addi t4, t4, 8                      ; get expected head index
    cmpgei t2, t0, NB_COLS-1
    beq t2, zero, check_snake_or_food_hit_test  ; if head is not on the RIGHT corner, check other collisions
    jmpi fatal_collision_hit_test       ; else end game with collision

check_snake_or_food_hit_test:
    slli t4, t4, 2                      ; multiply t4 by 4 to turn it into an address
    ldw t3, GSA(t4)                     ; load expected head value

    add v0, zero, zero                  
    beq t3, zero, end_hit_test          ; if value is 0, no collision occured and v0 = 0

    addi t2, zero, FOOD                 
    bne t3, t2, fatal_collision_hit_test; if value is differet than FOOD, collision is fatal with body
    addi v0, zero, RET_ATE_FOOD         ; else collision with food, return v0 = 1
    jmpi end_hit_test

fatal_collision_hit_test:
    addi v0, zero, RET_COLLISION        ; collision is fatal, return v0 = 2

end_hit_test:
    ret
; END: hit_test


; BEGIN: get_input
get_input:
    ldw t0, BUTTONS+4(zero)             ; get edgecapture
    stw zero, BUTTONS+4(zero)           ; clear edgecapture
    andi t3, t0, 16                     ; mask for button4, CHECKPOINT
    andi t7, t0, 8                      ; mask for button3, LEFT
    andi t6, t0, 4                      ; mask for button2, UP
    andi t5, t0, 2                      ; mask for button1, DOWN
    andi t4, t0, 1                      ; mask for button0, RIGHT

    bne t3, zero, checkpoint_get_input  ; branch if button4 was pressed

    ldw t1, HEAD_X(zero)                ; get snake head x coordinate
    ldw t2, HEAD_Y(zero)                ; get snake head y coordinate
    slli t1, t1, 3                      ; t1 = x * 8
    add t1, t1, t2                      ; t1 = x * 8 + y
    slli t1, t1, 2                      ; multiply t1 by 4 to turn it into an address
    ldw t2, GSA(t1)                     ; get current head direction with index t1 (address)

    bne t4, zero, left_get_input        ; branch if button3 was pressed
    bne t5, zero, up_get_input          ; branch if button2 was pressed
    bne t6, zero, down_get_input        ; branch if button1 was pressed
    bne t7, zero, right_get_input       ; branch if button0 was pressed

    addi v0, zero, BUTTON_NONE          ; modify output accordingly
    jmpi end_get_input                  ; no button was pressed

checkpoint_get_input:
    addi v0, zero, BUTTON_CHECKPOINT    ; modify output accordingly
    jmpi end_get_input

left_get_input:
    addi v0, zero, BUTTON_LEFT          ; modify output accordingly
    cmpeqi t3, t2, DIR_RIGHT            ; if current direction is RIGHT
    bne t3, zero, end_get_input         ; branch to end since we cannot turn

    jmpi end_buttons_get_input          ; branch ot end_buttons to store new direction

up_get_input:
    addi v0, zero, BUTTON_UP            ; modify output accordingly
    cmpeqi t3, t2, DIR_DOWN             ; if current direction is DOWN
    bne t3, zero, end_get_input         ; branch to end since we cannot turn

    jmpi end_buttons_get_input          ; branch ot end_buttons to store new direction

down_get_input:
    addi v0, zero, BUTTON_DOWN          ; modify output accordingly
    cmpeqi t3, t2, DIR_UP               ; if current direction is UP
    bne t3, zero, end_get_input         ; branch to end since we cannot turn

    jmpi end_buttons_get_input          ; branch ot end_buttons to store new direction

right_get_input:
    addi v0, zero, BUTTON_RIGHT         ; modify output accordingly
    cmpeqi t3, t2, DIR_LEFT             ; if current direction is LEFT
    bne t3, zero, end_get_input         ; branch to end since we cannot turn

    jmpi end_buttons_get_input          ; branch ot end_buttons to store new direction

end_buttons_get_input:
    stw v0, GSA(t1)                     ; store new head direction accordingly
end_get_input:
    ret
; END: get_input


; BEGIN: draw_array
draw_array:
    addi sp, sp, -12                    ; push registers to stack
    stw ra, 0(sp)
    stw s0, 4(sp)                       
    stw s1, 8(sp)

    add s0, zero, zero                  ; counter for x
    add s1, zero, zero                  ; counter for y

outer_draw_array:
    cmplti t0, s0, NB_COLS              ; if outer is done go to end
    beq t0, zero, end_draw_array        ; else continue iterating

inner_draw_array:
    slli t0, s0, 3                      ; t0 = x * 8
    add t0, t0, s1                      ; t0 = x * 8 + y

    slli t0, t0, 2                      ; multiply t0 by 4 to turn it into an address
    ldw t0, GSA(t0)                     ; get GSA line for corresponding index
    cmpeq t0, t0, zero                  ; if GSA line is 0, pixel is off, else call set_pixel
    bne t0, zero, do_not_set_pixel_draw_array 

    add a0, zero, s0                    ; set input to x coordinate
    add a1, zero, s1                    ; set input to y coordinate
    call set_pixel                      ; set the pixel (to 1)

do_not_set_pixel_draw_array:
    addi s1, s1, 1                      ; increment y counter
    cmplti t0, s1, NB_ROWS              ; if inner is not done
    bne t0, zero, inner_draw_array      ; continue looping inner
    addi s0, s0, 1                      ; increment x counter
    add s1, zero, zero                  ; reset counter for y
    jmpi outer_draw_array               ; else loop outer

end_draw_array:
    ldw ra, 0(sp)                       ;  pop registers from stack
    ldw s0, 4(sp)
    ldw s1, 8(sp)
    addi sp, sp, 12
    ret
; END: draw_array


; BEGIN: move_snake
move_snake:
    add t7, zero, zero                  ; iteration number
    ldw t0, HEAD_X(zero)                ; get old snake head x coordinate
    ldw t1, HEAD_Y(zero)                ; get old snake head y coordinate
    
loop_twice_move_snake:
    slli t4, t0, 3                      ; t4 = x * 8
    add t4, t4, t1                      ; t4 = x * 8 + y
    slli t4, t4, 2                      ; multiply t4 by 4 to turn it into an address
    ldw t2, GSA(t4)                     ; get current head direction with index t4
    srli t4, t4, 2                      ; divide t4 by 4 to return it into an index

    addi t3, zero, DIR_LEFT             ; if old head direction is LEFT
    beq t2, t3, go_left_move_snake      ; branch to compute new head coordinates
    
    addi t3, zero, DIR_UP               ; if old head direction is UP
    beq t2, t3, go_up_move_snake        ; branch to compute new head coordinates

    addi t3, zero, DIR_DOWN             ; if old head direction is DOWN
    beq t2, t3, go_down_move_snake      ; branch to compute new head coordinates

    addi t3, zero, DIR_RIGHT            ; if old head direction is RIGHT
    beq t2, t3, go_right_move_snake     ; branch to compute new head coordinates

    jmpi end_move_snake                 ; food ?

go_left_move_snake:
    addi t0, t0, -1                     ; shift old x index LEFT
    addi t5, t4, -8                     ; get new head index

    beq t7, zero, end_head_move_snake   ; if still in first iteration go to modify head
    jmpi end_tail_move_snake            ; else go to modify tail

go_up_move_snake:
    addi t1, t1, -1                     ; shift old y index UP
    addi t5, t4, -1                     ; get new head index

    beq t7, zero, end_head_move_snake   ; if still in first iteration go to modify head
    jmpi end_tail_move_snake            ; else go to modify tail

go_down_move_snake:
    addi t1, t1, 1                      ; shift old y index DOWN 
    addi t5, t4, 1                      ; get new head index 

    beq t7, zero, end_head_move_snake   ; if still in first iteration go to modify head
    jmpi end_tail_move_snake            ; else go to modify tail          

go_right_move_snake:
    addi t0, t0, 1                      ; shift old x index RIGHT
    addi t5, t4, 8                      ; get new head index

    beq t7, zero, end_head_move_snake   ; if still in first iteration go to modify head
    jmpi end_tail_move_snake            ; else go to modify tail

end_head_move_snake:
    stw t0, HEAD_X(zero)                ; store new snake head x coordinate
    stw t1, HEAD_Y(zero)                ; store new snake head y coordinate
    slli t5, t5, 2                      ; multiply t5 by 4 to it into an address
    stw t2, GSA(t5)                     ; store the direction in new head

    bne a0, zero, end_move_snake        ; if snake collides with food, tail isn't modified (a0 = 1)
    ldw t0, TAIL_X(zero)                ; get old snake tail x coordinate
    ldw t1, TAIL_Y(zero)                ; get old snake tail y coordinate

    addi t7, t7, 1                      ; increment loop counter
    jmpi loop_twice_move_snake          ; branch for second iteration

end_tail_move_snake:
    stw t0, TAIL_X(zero)                ; store new snake head x coordinate
    stw t1, TAIL_Y(zero)                ; store new snake head y coordinate
    slli t4, t4, 2                      ; multiply t4 by 4 to it into an address
    stw zero, GSA(t4)                   ; detach the old tail from snake
end_move_snake:
    ret
; END: move_snake


; BEGIN: save_checkpoint
save_checkpoint:
    add v0, zero, zero                  ; set output v0 to 0
    ldw t0, SCORE(zero)                 ; load score

get_multiple_save_checkpoint:
    cmplti t2, t0, 10                   ; iterate until t0 < 10
    bne t2, zero, end_multiple_save_checkpoint 
    addi t0, t0, -10                    ; decrement score by 10
    jmpi get_multiple_save_checkpoint

end_multiple_save_checkpoint:
    bne t0, zero, end_save_checkpoint   ; if score wasn't a multiple of 10, we do nothing
    addi t1, zero, 1                    
    stw t1, CP_VALID(zero)              ; else set CP_VALID to 1

    add t0, zero, zero                  ; loop counter 
loop_save_checkpoint:
    slli t2, t0, 2
    ldw t1, HEAD_X(t2)                  ; load value from origin memory region
    stw t1, CP_HEAD_X(t2)               ; store value to detination memory region

    addi t0, t0, 1                      ; increment counter
    cmplti t1, t0, NB_CELLS+5
    bne t1, zero, loop_save_checkpoint  ; iterate until count is done

    addi v0, zero, 1                    ; set output v0 to 1 since score is a multiple of 10

end_save_checkpoint:
    ret 
; END: save_checkpoint


; BEGIN: restore_checkpoint
restore_checkpoint:
    ldw v0, CP_VALID(zero)              ; check if the copy is valid
    beq v0, zero, end_restore_checkpoint; if it isn't, we do nothing, put the copy in current game
    add t0, zero, zero                  ; loop counter 
gsa_restore_checkpoint:
    slli t2, t0, 2
    ldw t1, CP_HEAD_X(t2)               ; load value from origin memory region
    stw t1, HEAD_X(t2)                  ; store value to detination memory region

    addi t0, t0, 1                      ; increment counter
    cmplti t1, t0, NB_CELLS+5
    bne t1, zero, gsa_restore_checkpoint; iterate until count is done

    addi v0, zero, 1                    ; set output v0 to 1 since score is a multiple of 10

end_restore_checkpoint:
    ret
; END: restore_checkpoint


; BEGIN: blink_score
blink_score:
    addi sp, sp, -8                     ;  push registers to stack
    stw ra, 0(sp)
    stw s1, 4(sp)

    add s1, zero, zero                  ; initialize counter for 5 iterations

loop_blink_score:
    stw zero, SEVEN_SEGS(zero)            ; display 0 on fourth SEVEN_SEGS
    stw zero, SEVEN_SEGS+4(zero)          ; display 0 on third SEVEN_SEGS
    stw zero, SEVEN_SEGS+8(zero)          ; display 0 on second SEVEN_SEGS       
    stw zero, SEVEN_SEGS+12(zero)         ; display 0 on first SEVEN_SEGS

    call wait                           ; call wait
    call display_score                  ; display the score
    call wait

    addi s1, s1, 1                      ; increment counter
    addi t2, zero, 5
    blt s1, t2, loop_blink_score        ; iterate until count reaches 5

    ldw s1, 4(sp)
    ldw ra, 0(sp)                       ;  pop registers from stack
    addi sp, sp, 8
    ret
; END: blink_score

; wait procedure
wait:
    addi t0, zero, 1
    slli t0, t0, 20                     ; initial count (2^20)

loop_wait:
    beq t0, zero, end_wait              ; iterate until count is 0
    addi t0, t0, -1                     ; decrement counter
    jmpi loop_wait

end_wait:
    ret


digit_map:
.word 0xFC ; 0
.word 0x60 ; 1
.word 0xDA ; 2
.word 0xF2 ; 3
.word 0x66 ; 4
.word 0xB6 ; 5
.word 0xBE ; 6
.word 0xE0 ; 7
.word 0xFE ; 8
.word 0xF6 ; 9