; Define a new surface type and a flag.
; If these need to be changed, know that the ASM
; code assumes that the 16 upper bits are zero.
SURFACE_FIRSTY_WALL   equ 0x00000002
MARIO_HIT_FIRSTY_WALL equ 0x00000200

.org 0x00028988 ; Function act_air_hit_wall (0x8026D988 / 0x00028988)
; C code:
; s32 act_air_hit_wall(struct MarioState *m) {
;     if (m->heldObj != NULL) {
;         mario_drop_held_object(m);
;     }
; 
;     if (++(m->actionTimer) <= 2) {
;         if (m->input & INPUT_A_PRESSED) {
;             m->vel[1] = 52.0f;
;             m->faceAngle[1] += 0x8000;
;             return set_mario_action(m, ACT_WALL_KICK_AIR, 0);
;         }
;     } else if (m->forwardVel >= 38.0f) {
; ...
;
; Corresponding ASM:
; addiu sp, sp, 0xFFE8   +
; sw ra, 0x0014(sp)      | stack init
; sw a0, 0x0018(sp)      -
; lw t6, 0x0018(sp)      +
; lw t7, 0x007C(t6)      | if (m->heldObj != NULL) {
; beq t7, r0, 0x000289AC |     mario_drop_held_object(m)
; nop                    | }
; jal 0x8024C6C0         |
; lw a0, 0x0018(sp)      -
; lw t8, 0x0018(sp)      +
; lhu t9, 0x001A(t8)     |
; addiu t0, t9, 0x0001   |
; sh t0, 0x001A(t8)      |
; lw t1, 0x0018(sp)      | if (++(m->actionTimer) <= 2)
; lhu t2, 0x001A(t1)     |
; slti at, t2, 0x0003    |
; beq at, r0, 0x00028A2C |
; nop                    -
; lw t3, 0x0018(sp)      +
; lhu t4, 0x0002(t3)     |
; andi t5, t4, 0x0002    | if (m->input & BUTTON_A_PRESSED)
; beq t5, r0, 0x00028A24 |
; nop                    -
; lui at, 0x4250         +
; mtc1 at, f4            | m->vel[1] = 52.0f;
; lw t6, 0x0018(sp)      |
; swc1 f4, 0x004C(t6)    -
; lw t7, 0x0018 (sp)     +
; ori at, r0, 0x8000     |
; lh t9, 0x002E (t7)     | m->faceAngle[1] += 0x8000;
; addu t0, t9, at        |
; sh t0, 0x002E(a0)      -
; lui a1, 0x0300         +
; ori a1, a1, 0x0886     |
; lw a0, 0x0018 (sp)     |
; jal 0x80252CF4         | return set_mario_action(m, ACT_WALL_KICK_AIR, 0);
; or a2, r0, r0          |
; beq r0, r0, 0x00028B44 |
; nop                    +
; beq r0, r0, 0x00028B30 + skip else branch
; nop                    -
;
; To make space for code to insert, we optimize the assembly by abusing delay
; slots, and by reusing the m object from a0 instead of loading it from the
; stack. The the condition on m->actionTimer also loads the data twice.
; We want to insert the following C code after the first condition:
;   m->unkC4 = m->forwardVel;
;   if (m->wall->type == SURFACE_FIRSTY_WALL)
;       m->flags |= MARIO_HIT_FIRSTY_WALL;
;   else
;       m->flags &= ~MARIO_HIT_FIRSTY_WALL;
; Line 1 stores the velocity before bonk in m->unkC4 (this field is only used
; when Mario is getting blown by a Fwoosh or the snowman's head, so it should
; not interfere with the bonk code).
; The rest sets a flag in m->flags depending on the wall type.

addiu sp, sp, 0xFFE8     ; +
lw t7, 0x007C(a0)        ; | stack init +
beq t7, r0, @not_holding ; | if (m->heldObj != NULL) {
sw ra, 0x0014(sp)        ; |     mario_drop_held_object(m)
jal 0x8024C6C0           ; | }
@not_holding:            ; |
sw a0, 0x0018(sp)        ; -
lw a0, 0x0018(sp)        ; keep m into a0 to remove stack reads in the rest
; New code:
lwc1 f0, 0x0054(a0)                ; + m->unkC4 = m->forwardVel;
swc1 f0, 0x00C4(a0)                ; -
lw t0, 0x0060(a0)                  ; +
lh t0, 0x0000(t0)                  ; |
ori t1, r0, SURFACE_FIRSTY_WALL    ; | if (m->wall->type == SURFACE_FIRSTY_WALL)
lw t2, 0x0004(a0)                  ; |     m->flags |= MARIO_HIT_FIRSTY_WALL;
beq t0, t1, @firsty_wall           ; | else
ori t2, t2, MARIO_HIT_FIRSTY_WALL  ; |     m->flags &= ~MARIO_HIT_FIRSTY_WALL;
xori t2, t2, MARIO_HIT_FIRSTY_WALL ; |
@firsty_wall:                      ; |
sw t2, 0x0004(a0)                  ; -
; Optimized original code:
lhu t9, 0x001A(a0)     ; +
addiu t0, t9, 0x0001   ; |
slti at, t0, 0x0003    ; | if (++(m->actionTimer) <= 2) 
beq at, r0, 0x00028A2C ; |
sh t0, 0x001A(a0)      ; -
lhu t4, 0x0002(a0)     ; +
andi t5, t4, 0x0002    ; |
beq t5, r0, 0x00028A24 ; | if (m->input & BUTTON_A_PRESSED) {
lui at, 0x4250         ; |     m->vel[1] = 52.0f;
mtc1 at, f4            ; |
swc1 f4, 0x004C(a0)    ; -
ori at, r0, 0x8000     ; +
lh t9, 0x002E(a0)      ; |     m->faceAngle[1] += 0x8000;
addu t0, t9, at        ; |
sh t0, 0x002E(a0)      ; -
lui a1, 0x0300         ; +
ori a1, a1, 0x0886     ; |
jal 0x80252CF4         ; |     return set_mario_action(m, ACT_WALL_KICK_AIR, 0);
or a2, r0, r0          ; | }
beq r0, r0, 0x00028B44 ; |
nop                    ; +


.org 0x0000D760 ; In function set_mario_action_airborne 0x80252460 / 0x0000D460
; C code:
; case ACT_WALL_KICK_AIR:
; case ACT_TOP_OF_POLE_JUMP:
;     set_mario_y_vel_based_on_fspeed(m, 62.0f, 0.0f);
;     if (m->forwardVel < 24.0f) {
;         m->forwardVel = 24.0f;
;     }
;     m->wallKickTimer = 0;
;     break;
; ...
;
; Corresponding ASM:
; lw a0, 0x0028(sp)      +
; lui a1, 0x4278         | set_mario_y_vel_based_on_fspeed(m, 62.0f, 0.0f);
; jal 0x802523C8         |
; addiu a2, r0, 0x0000   -
; lw t4, 0x0028(sp)      +
; lui at, 0x41C0         |
; mtc1 at, f10           |
; lwc1 f8, 0x0054(t4)    | if (m->forwardVel < 24.0f)
; c.lt.s f8, f10         |
; nop                    |
; bc1f 0x0000D7A0        |
; nop                    -
; lui at, 0x41C0         +
; mtc1 at, f16           | m->forwardVel = 24.0f;
; lw t5, 0x0028(sp)      |
; swc1 f16, 0x0054(t5)   -
; lw t7, 0x0028(sp)      + m->wallKickTimer = 0;
; sb r0, 0x002A(t7)      -
; beq r0, r0, 0x0000D9A4 + break;
; nop                    -
;
; We want to add this code at the beginning of the case:
;     if (m->flags & MARIO_HIT_FIRSTY_WALL)
;         m->forwardVel = m->unkC4;
; We can make space by reusing a0 and not loading m several times from the
; stack. Calling set_mario_y_vel_based_on_fspeed does not change a0 thankfully.
; The 24.0f constant can be reused.

lw a0, 0x0028(sp)                  ; +
lw t0, 0x0004(a0)                  ; |
andi t0, t0, MARIO_HIT_FIRSTY_WALL ; | if (m->flags & MARIO_HIT_FIRSTY_WALL)
beq t0, r0, @not_firsty_wall       ; |     m->forwardVel = m->unkC4;
lwc1 f0, 0x00C4(a0)                ; |
swc1 f0, 0x0054(a0)                ; -
@not_firsty_wall:
lui a1, 0x4278         ; +
jal 0x802523C8         ; | set_mario_y_vel_based_on_fspeed(m, 62.0f, 0.0f);
addiu a2, r0, 0x0000   ; -
lui at, 0x41C0         ; +
mtc1 at, f10           ; |
lwc1 f8, 0x0054(a0)    ; |
c.lt.s f8, f10         ; | if (m->forwardVel < 24.0f)
nop                    ; |     m->forwardVel = 24.0f;
bc1f @not_set_vel      ; |
nop                    ; |
swc1 f10, 0x0054(a0)   ; -
@not_set_vel:
sb r0, 0x002A(a0)      ;  m->wallKickTimer = 0;
beq r0, r0, 0x0000D9A4 ; + break;
nop                    ; -
