; Overwrite the function try_print_debug_mario_object_info
.orga 0x000861c0

addiu sp, sp, 0xFFE8
sw ra, 0x14(sp)
; Call to our custom function
jal 0x80406000
nop
lw ra, 0x14(sp)
jr ra
addiu sp, sp, 0x18

.orga 0x01206000
.headersize 0x80406000 - 0x01206000

; --Function-wrapper-start--
addiu sp, sp, 0xFFE8
sw ra, 0x14(sp)
; --------------------------

; a0: General prefix for RAM addresses
lui a0, 0x8034
; t7: Address of the Mario Object struct
; &marioState.marioObj = 0x8033B170 + 0x88 = 0x8033B1F8
lw t7, 0xB1F8(a0)
; t6: Mario's current state
; &marioState.state = 0x8033B170 + 0x0C = 0x8033B17C
lw t6, 0xB17C(a0)

; Check for airborne actions
; ACT_GROUP_MASK = 0x000001C0
andi t0, t6, 0x01C0
; ACT_GROUP_AIRBORNE = 0x00000080
andi t0, t0, 0x0080
bne t0, r0, airborne

; Set Mario's shoe color to dark cyan
li a2, 0x00444400
li.u a3, 0x00666600
jal set_shoe_color
li.l a3, 0x00666600

; Save 1 to marioObj.unused2 (offset 0x210)
; to enable the double jump ability
ori t1, r0, 1
beq r0, r0, skip
sb t1, 0x210(t7)

airborne:

; Check if midair jump is available (marioObj.unused2 == 1)
lb t0, 0x210(t7)
beq t0, r0, skip

; Set Mario's shoe color to dark cyan
li a2, 0x00444400
li.u a3, 0x00666600
jal set_shoe_color
li.l a3, 0x00666600

; Check if state is ACT_TRIPLE_JUMP (0x01000882)
lui t0, 0x0100
addiu t0, t0, 0x0882
beq t0, t6, checkA
; Check if state is ACT_BACKFLIP (0x01000883)
addiu t0, t0, 1
beq t0, t6, checkA
; Check if state is ACT_SIDE_FLIP (0x01000887)
addiu t0, t0, 4
beq t0, t6, checkA
; Check if state is ACT_WATER_JUMP (0x01000889)
addiu t0, t0, 2
beq t0, t6, checkA
; Check if state is ACT_FREEFALL (0x0100088C)
addiu t0, t0, 3
beq t0, t6, checkA
; Check if state is ACT_JUMP (0x03000880)
lui t0, 0x0300
addiu t0, t0, 0x0880
beq t0, t6, checkA
; Check if state is ACT_DOUBLE_JUMP (0x03000881)
addiu t0, t0, 1
beq t0, t6, checkA
; Check if state is ACT_STEEP_JUMP (0x03000885)
addiu t0, t0, 4
beq t0, t6, checkA
; Check if state is ACT_WALL_KICK_AIR (0x03000886)
addiu t0, t0, 1
beq t0, t6, checkA
; Check if state is ACT_LONG_JUMP (0x03000888)
addiu t0, t0, 2
beq t0, t6, checkA
; Check if state is ACT_TOP_OF_POLE_JUMP (0x0300088D)
addiu t0, t0, 5
beq t0, t6, checkA
; Check if state is ACT_GROUND_POUND (0x008008A9)
lui t0, 0x0080
addiu t0, t0, 0x08A9
beq t0, t6, checkA
nop

beq r0, r0, skip
nop

checkA:

; Set Mario's shoe color to cyan
li a2, 0x00888800
li.u a3, 0x00ffff00
jal set_shoe_color
li.l a3, 0x00ffff00

; Load buttons pressed on the current frame
; &controller.buttonPressed = 0x8033AF90 + 0x12 = 0x8033AFA2
lh t0, 0xAFA2(a0)

; Check if A (0x8000) is pressed
andi t0, t0, 0x8000
beq t0, r0, skip
nop

; Save 0 to marioObj.unused2 (offset 0x210)
; to disable the double jump ability
sh r0, 0x210(t7)

; Set Mario's shoe color to default
li a2, 0x721c0f00
li.u a3, 0x390e0700
jal set_shoe_color
li.l a3, 0x390e0700

; Set Mario's state to a jump
; arg0 is a pointer to the Mario struct (0x8033B170)
; arg1 is the state ACT_JUMP (0x03000880)
; arg2 isn't necessery
; call to set_mario_action (0x80252CF4)
addiu a0, a0, 0xB170
lui a1, 0x0300
jal 0x80252CF4
addiu a1, a1, 0x0880

skip:

; --Function-wrapper-end----
lw ra, 0x14(sp)
jr ra
addiu sp, sp, 0x18
; --------------------------

; Small routine, color is passed in a2 and a3 as 0xRRGGBB00
set_shoe_color:
; ROM Manager may decide to relocate bank 4, so the shoe color is not always at
; the same place. Inlined version of get_segment_base_addr(4):
li at, 0x80000000
lw v0, 0x8033b400 + 4 * 0x04
or v0, at
; *(uint32_t *)mario_brown1_lights_group.a.col = color_ambiant;
sw a2, 0x48(v0)
jr ra
; *(uint32_t *)mario_brown1_lights_group.l[0].col = color_light;
sw a3, 0x50(v0)
