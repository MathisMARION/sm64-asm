; Original code by aglab2, made for Star Revenge 6.25
; This version is modified to not use custom HUD icons,
; and it also stops weird numbers from being displayed
; while in cannons.

.org 0xF484; (0x80254484 RAM) Hook to Cap Timer Code
J 0x80406880 ;hook

.org 0x1206880; (0x80406880 RAM) Cap Timer HUD Code
SW T9, 0x0010(SP) ;ensures vanilla variable is not messed up

ADDIU A0, R0, 0x36 ;HUD Distance From Left
ADDIU A1, R0, 0x10 ;HUD Distance From Bottom
LUI A2, 0x8034
ADDIU A2, A2, 0x8388 ;Address Pointing to 25. Necessary for Some Reason
ADDIU A3, T6, 0 ;Cap Timer Value
ADDIU T9, R0, 30
DIVU A3, T9 ;Divides timer by 30, putting it into seconds
MFLO A3

SLTIU T9, A3, 100 ; This value is the threshold in seconds after which the timer is not displayed
BEQ T9, R0, NoDisplay
NOP

JAL 0x802D62D8 ;HUD Number Printing Function
NOP

NoDisplay:

LW T9, 0x0010(SP) ;ensures vanilla variable is not messed up

BNE T9, R0, NotZero ;vanilla stuff
NOP

J 0x8025448C ;vanilla stuff
NOP

NotZero:
J 0x802544D0 ;vanilla stuff
NOP