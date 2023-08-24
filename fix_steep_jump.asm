; diff --git a/src/game/mario.c b/src/game/mario.c
; index cc5e864..90e95bb 100644
; --- a/src/game/mario.c
; +++ b/src/game/mario.c
; @@ -658,8 +658,7 @@ s32 mario_floor_is_steep(struct MarioState *m) {
;                  break;
; 
;              case SURFACE_NOT_SLIPPERY:
; -                normY = 0.8660254f; // ~cos(30 deg)
; -                break;
; +                return result;
;          }
; 
;          result = m->floor->normal.y <= normY;

; In function mario_floor_is_steep (0x0000ce24 / 0x80251e24)
.org 0x0000ce74
beq s0, at, 0x0000cf04
