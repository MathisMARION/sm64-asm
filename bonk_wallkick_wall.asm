; --- a/include/surface_terrains.h
; +++ b/include/surface_terrains.h
; @@ -6,6 +6,7 @@
;  #define SURFACE_BURNING                      0x0001 // Lava / Frostbite (in SL), but is used mostly for Lava
;  #define SURFACE_0004                         0x0004 // Unused, has no function and has parameters
;  #define SURFACE_HANGABLE                     0x0005 // Ceiling that Mario can climb on
; +#define SURFACE_BONK_WALLKICK                0x0006 // Surface that allow to wallkick even with a hard bonk
;  #define SURFACE_SLOW                         0x0009 // Slow down Mario, unused
;  #define SURFACE_DEATH_PLANE                  0x000A // Death floor
;  #define SURFACE_CLOSE_CAMERA                 0x000B // Close camera
SURFACE_BONK_WALLKICK equ 0x0006

; --- a/src/game/mario.c
; +++ b/src/game/mario.c
; @@ -882,6 +882,14 @@ static u32 set_mario_action_airborne(struct MarioState *m, u32 action, u32 actio
;          case ACT_JUMP_KICK:
;              m->vel[1] = 20.0f;
;              break;
; +
; +        case ACT_BACKWARD_AIR_KB:
; +            if (m->wall && m->wall->type == SURFACE_BONK_WALLKICK) {
; +                m->action = ACT_AIR_HIT_WALL;
; +                m->wallKickTimer = 5;
; +            }
; +            break;
;      }
;
;      m->peakHeight = m->pos[1];
.orga 0x000d5a4 ; In function set_mario_action_airborne (0x80252460 / 0x0000d460)
; branch if (action == 0x01000882) ACT_TRIPLE_JUMP
;  -1 by using the delay slot
; lui at, 0x0100         > lui t0, 0x0100
; ori at, at, 0x0882     > ori at, t0, 0x0882
; beq s0, at, 0x0000d674 > beq s0, at, 0x0000d674
; nop                    >
lui t0, 0x0100
ori at, t0, 0x0882
beq s0, at, 0x0000d674
; branch if (action == 0x01000883) ACT_BACKFLIP
;  -1 by reusing t0
;  -1 by using the delay slot
; lui at, 0x0100         >
; ori at, at, 0x0883     > ori at, t0, 0x0883
; beq s0, at, 0x0000d63c > beq s0, at, 0x0000d63c
; nop                    >
ori at, t0, 0x0883
beq s0, at, 0x0000d63c
; branch if (action == 0x01000887) ACT_SIDE_FLIP
;  -1 by reusing t0
;  -1 by using the delay slot
; lui at, 0x0100         >
; ori at, at, 0x0887     > ori at, t0, 0x0887
; beq s0, at, 0x0000d7b0 > beq s0, at, 0x0000d7b0
; nop                    > nop
ori at, t0, 0x0887
beq s0, at, 0x0000d7b0
; branch if (action == 0x01000889) ACT_WATER_JUMP
;  -1 by reusing t0
;  -1 by using the delay slot
; lui at, 0x0100         >
; ori at, at, 0x0889     > ori at, t0, 0x0889
; beq s0, at, 0x0000d6bc > beq s0, at, 0x0000d6bc
; nop                    >
ori at, t0, 0x0889
beq s0, at, 0x0000d6bc
; branch if (action == 0x010008a3) ACT_HOLD_WATER_JUMP
;  -1 by reusing t0
;  -1 by using the delay slot
; lui at, 0x0100         >
; ori at, at, 0x08a3     > ori at, t0, 0x08a3
; beq s0, at, 0x0000d6bc > beq s0, at, 0x0000d6bc
; nop                    >
ori at, t0, 0x08a3
beq s0, at, 0x0000d6bc
; branch if (action == 0x010008b4) ACT_HOLD_WATER_JUMP
;  -1 by reusing t0
;  -1 by using the delay slot
; lui at, 0x0102         >
; ori at, at, 0x08b4     > ori at, t0, 0x08b4
; beq s0, at, 0x0000d6e0 > beq s0, at, 0x0000d6e0
; nop                    >
ori at, t0, 0x08b4
beq s0, at, 0x0000d6e0
; branch to default
;  +2 by adding a condition on ACT_BACKWARD_AIR_KB (0x010208b0)
;  -1 by using the delay slot
;                        > lui at, at, 0x0102
;                        > ori at, at, 0x08b0
; beq r0, r0, 0x0000d9a4 > bne s0, at, 0x0000d9a4
; nop                    >
lui at, 0x0102
ori at, at, 0x08b0
bne s0, at, 0x0000d9a4
; if (m->wall && m->wall->type == SURFACE_BONK_WALLKICK)
;   +5 for new code
lw t1, 0x60(a0)
beq t1, r0, @endif
ori t2, r0, SURFACE_BONK_WALLKICK
lh t1, 0x00(t1)
bne t1, t2, @endif
; m->action = ACT_AIR_HIT_WALL;
;   +2 for new code
ori at, r0, 0x08a7
sw at, 0x0c(a0)
; m->wallKickTimer = 5;
;   +2 for new code
ori at, r0, 5
sb at, 0x2a(a0)
@endif:
; break;
;   +1 for new code
b 0x0000d9a4
