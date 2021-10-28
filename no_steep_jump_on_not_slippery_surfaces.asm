; Replace function call to mario_floor_is_steep with our custom function

; In mario_set_jumping_action
.orga 0x0000E128
jal 0x80400000

; In set_jump_from_landing
.orga 0x0000DED4
jal 0x80400000


; Custom function mario_floor_is_steep_and_slippery
.orga 0x01200000

addiu sp, sp, -4
sw ra, 4(sp)

; Call to mario_get_floor_class
; arg0 should be MarioState
jal 0x8025177C
nop

; Check if surface is of class SURFACE_NOT_SLIPPERY (0x0015)
ori t0, r0, 0x0015
beq v0, t0, notSlippery
nop

; Call to mario_floor_is_steep
; arg0 should be MarioState (the previous function call does not overwrite a0)
jal 0x80251E24
nop

; Return the result of mario_floor_is_steep
beq r0, r0, exit
nop

notSlippery:

; Return FALSE
ori v0, r0, 0

exit:

lw ra, 4(sp)
jr ra
addiu sp, sp, 4