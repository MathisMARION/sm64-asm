; Some collision types load extra parameters to influence
; the collision behavior. The loading of these extra params
; is dictated by the function surface_has_force, and the
; value is stored into the member .force of struct Surface.

.org 0x000FFD04 ; Function surface_has_force
; C code:
; static s32 surface_has_force(s16 surfaceType) {
;     s32 hasForce = FALSE;
; 
;     switch (surfaceType) {
;         case SURFACE_0004: // Unused
;         case SURFACE_FLOWING_WATER:
;         case SURFACE_DEEP_MOVING_QUICKSAND:
;         case SURFACE_SHALLOW_MOVING_QUICKSAND:
;         case SURFACE_MOVING_QUICKSAND:
;         case SURFACE_HORIZONTAL_WIND:
;         case SURFACE_INSTANT_MOVING_QUICKSAND:
;             hasForce = TRUE;
;             break;
; 
;         default:
;             break;
;     }
;     return hasForce;
; }
;
; Corresponding ASM:
; sll a0, a0, 0x16
; sra a0, a0, 0x16
; addiu sp, sp, 0xFFF8
; sw r0, 0x0004(sp)        hasForce = FALSE;
; addiu t6, a0, 0xFFFC   +
; sltiu at, t6, 0x002A   | if not (SURFACE_0004 <= surfaceType <= SURFACE_INSTANT_MOVING_QUICKSAND)
; beq at, r0, 0x000FFD4C |     return FALSE
; nop                    -
; sll t6, t6, 0x2        +
; lui at, 0x8039         | else
; addu at, at, t6        |     use lookup table at 8038BBD8/00108958 to jump at
; lw t6, 0xBBD8(at)      |       - 80382FBC/000FFD3C (case matched)
; jr t6                  |       - 80382FCC/000FFD4C (case not matched)
; nop                    -
; addiu t7, r0, 0x0001   + hasForce = TRUE;
; sw t7, 0x0004(sp)      -
; beq r0, r0, 0x000FFD54
; nop
; beq r0, r0, 0x000FFD54
; nop
; beq r0, r0, 0x000FFD64
; lw v0, 0x0004(sp)         return hasForce;
; beq r0, r0, 0x000FFD64
; nop
; jr ra
; addiu sp, sp, 0x0008
;
; The return section of the assembly contains unecessary jumps,
; replace it to return TRUE for SURFACE_BURNING (0x0001)

sll a0, a0, 0x16
sra a0, a0, 0x16
addiu sp, sp, 0xFFF8
sw r0, 0x0004(sp)
addiu t6, a0, 0xFFFC
sltiu at, t6, 0x002A
beq at, r0, @lut_ext ; Replaced this jump
nop
sll t6, t6, 0x2
lui at, 0x8039
addu at, at, t6
lw t6, 0xBBD8(at)
jr t6                ; Jump addresses are replaced in the LUT (see below)
nop
; Start of the modified return section
@lut_ext:
addiu t0, r0, 0x0001 ; if (surfaceType != SURFACE_BURNING)
bne a0, t0, @return0 ;     return FALSE;
nop                  ;
nop
nop
nop
nop
@return1:
addiu t7, r0, 0x0001 ; hasForce = TRUE;
sw t7, 0x0004(sp)    ;
@return0:
lw v0, 0x0004(sp)    ; return hasForce;
jr ra
addiu sp, sp, 0x0008

.org 0x00108958 ; Lookup table for the switch/case
.word @return1 + 0x80283280 ; SURFACE_0004 (0x0004)
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return1 + 0x80283280 ; SURFACE_FLOWING_WATER (0x000E)
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return1 + 0x80283280 ; SURFACE_DEEP_MOVING_QUICKSAND    (0x0024)
.word @return1 + 0x80283280 ; SURFACE_SHALLOW_MOVING_QUICKSAND (0x0025)
.word @return0 + 0x80283280
.word @return1 + 0x80283280 ; SURFACE_MOVING_QUICKSAND         (0x0027)
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return0 + 0x80283280
.word @return1 + 0x80283280 ; SURFACE_HORIZONTAL_WIND          (0x002C)
.word @return1 + 0x80283280 ; SURFACE_INSTANT_MOVING_QUICKSAND (0x002D)


.org 0x0000B6BC ; In function check_lava_boost
; C code:
; m->hurtCounter += (m->flags & MARIO_CAP_ON_HEAD) ? 12 : 18;
;
; Corresponding ASM:
; lw t2, 0x0028(sp)      +
; lw t3, 0x0004(t2)      |
; andi t4, t3, 0x0010    |
; beq t4, r0, 0x0000B6D8 | s0 = (m->flags & MARIO_CAP_ON_HEAD) ? 12 : 18;
; nop                    |
; beq r0, r0, 0x0000B6DC |
; addiu s0, r0, 0x000C   |
; addiu s0, r0, 0x0012   -
; lw t5, 0x0028(sp)      +
; lbu t7, 0x00B2(t5)     | m->hurtCounter += s0;
; addu t8, t7, s0        |
; sb t8, 0x00B2(t5)      -
;
; This replaces the first part with:
; s0 = m->floor->force;

lw s0, 0x0028(sp) ; s0 = m
lw s0, 0x0068(s0) ; s0 = m->floor
lh s0, 0x0002(s0) ; s0 = m->floor->force
nop
nop
nop
nop
nop


.org 0x00029388 ; In function act_lava_boost
; C code:
; m->hurtCounter += (m->flags & MARIO_CAP_ON_HEAD) ? 12 : 18;
;
; Corresponding ASM:
; lw t8, 0x0028(sp)      +
; lw t9, 0x0004(t8)      |
; andi t0, t9, 0x0010    |
; beq t0, r0, 0x000293A4 | s0 = (m->flags & MARIO_CAP_ON_HEAD) ? 12 : 18;
; nop                    |
; beq r0, r0, 0x000293A8 |
; addiu s0, r0, 0x000C   |
; addiu s0, r0, 0x0012   -
; lw t1, 0x0028(sp)      +
; lbu t2, 0x00B2(t1)     | m->hurtCounter += s0;
; addu t3, t2, s0        |
; sb t3, 0x00B2(t1)      -
;
; This replaces the first part with:
; s0 = m->floor->force;

lw s0, 0x0028(sp) ; s0 = m
lw s0, 0x0068(s0) ; s0 = m->floor
lh s0, 0x0002(s0) ; s0 = m->floor->force
nop
nop
nop
nop
nop


.org 0x0002519C ; In function lava_boost_on_wall
; C code:
; m->hurtCounter += (m->flags & MARIO_CAP_ON_HEAD) ? 12 : 18;
;
; Corresponding ASM:
; lw t4, 0x0028 (sp)     +
; lw t5, 0x0004 (t4)     |
; andi t6, t5, 0x0010    |
; beq t6, r0, 0x000251B8 | s0 = (m->flags & MARIO_CAP_ON_HEAD) ? 12 : 18;
; nop                    |
; beq r0, r0, 0x000251BC |
; addiu s0, r0, 0x000C   |
; addiu s0, r0, 0x0012   -
; lw t7, 0x0028 (sp)     +
; lbu t8, 0x00B2 (t7)    | m->hurtCounter += s0;
; addu t9, t8, s0        |
; sb t9, 0x00B2 (t7)     -
;
; This replaces the first part with:
; s0 = m->wall->force;

lw s0, 0x0028(sp) ; s0 = m
lw s0, 0x0060(s0) ; s0 = m->wall
lh s0, 0x0002(s0) ; s0 = m->wall->force
nop
nop
nop
nop
nop
