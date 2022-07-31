; Define a new surface type.
; If this needs to be changed, know that the ASM
; code assumes that the 16 upper bits are zero.
SURFACE_WIDE_WALLKICK equ 0x00000003

.org 0x00011484;  In function perform_air_quarter_step 0x802560AC / 0x000110AC
; C code:
; if (wallDYaw < -0x6000 || wallDYaw > 0x6000) {
;     m->flags |= MARIO_UNKNOWN_30;
;     return AIR_STEP_HIT_WALL;
; }
;
; Corresponding ASM:
; lh t7, 0x004E(sp)       +
; slti at, t7, 0xA000     | if (wallDYaw < -0x6000)
; bne at, r0, 0x000114A0  |
; nop                     -
; slti at, t7, 0x6001     +
; bne at, r0, 0x000114BC  | if (wallDYaw > 0x6000)
; nop                     -
; lw t8, 0x0050(sp)       +
; lui at, 0x4000          |
; lw t9, 0x0004(t8)       | m->flags |= MARIO_UNKNOWN_30;
; or t0, t9, at           |
; sw t0, 0x0004(t8)       -
; beq r0, r0, 0x000114CC  + return AIR_STEP_HIT_WALL;
; addiu v0, r0, 0x0002    -
;
; The flag set isn't used anywhere else so we can get rid of it.
; t6 contains m->wall->type from previous instructions so it can be reused.
; We want to replace the condition with:
; if (abs(wallDYaw) > 0x6000 - 0x0010 * (m->wall->type == SURFACE_WIDE_WALLKICK))

lh t0, 0x004E(sp)                 ; +
bgtz t0, @positive_angle          ; |
ori t1, r0, SURFACE_WIDE_WALLKICK ; |
sub t0, r0, t0                    ; | t0 = abs(wallDYaw)
@positive_angle:                  ; | t2 = 0x6001 - (m->wall->type == SURFACE_WIDE_WALLKICK)
bne t6, t1, @normal_wall          ; |
ori t2, r0,  0x6001               ; |
addi t2, t2, -0x0010              ; -
@normal_wall:
slt at, t2, t0                    ; +
beq at, r0, 0x000114BC            ; | if (t0 > t2)
nop                               ; -
beq r0, r0, 0x000114CC            ; + return AIR_STEP_HIT_WALL;
addiu v0, r0, 0x0002              ; -
