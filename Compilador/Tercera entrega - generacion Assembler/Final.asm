include macros2.asm 
include number.asm 
.MODEL LARGE
.386
.STACK 200h

MAXTEXTSIZE EQU 32

.DATA
NEW_LINE DB 0AH,0DH,'$'
CWprevio DW ?
@msj_entero db "Ingrese un valor entero", '$' 
@msj_real db "Ingrese un valor real", '$' 
abbaa dd ?
berta dd ?
b dd ?
var1 dd ?
a dd ?
c dd ?
d dd ?
e dd ?
cont dd ?
pepp dd ?
estoesunid dd ?
q dd ?
x dd ?
valorentero dd ?
_50 dd 50.0
_4 dd 4.0
_2 dd 2.0
@aux4 dd ?
_27_123456789 dd 27.123456789
_Hola12 db "Hola12", '$'
_1 dd 1.0
_3 dd 3.0
_0 dd 0.0
@Filter1 dd ?
_FIN_FILTER_1 db "FIN_FILTER_1", '$'
_5 dd 5.0
@aux42 dd ?
@aux43 dd ?
@aux48 dd ?
@aux50 dd ?
_1_3323 dd 1.3323
_3_4555 dd 3.4555
_7_115 dd 7.115
_3_0 dd 3.0
_7_11 dd 7.11
@Filter2 dd ?
_FIN_FILTER_2 db "FIN_FILTER_2", '$'
@Filter3 dd ?
_FIN_FILTER_3 db "FIN_FILTER_3", '$'
_3_3 dd 3.3
@Filter4 dd ?
_FIN_FILTER_4 db "FIN_FILTER_4", '$'
@aux143 dd ?
_10 dd 10.0
_hola db "hola", '$'
_chau db "chau", '$'
_cadenuski db "cadenuski", '$'
_20 dd 20.0
_CONDICION_AND db "CONDICION_AND", '$'
_100 dd 100.0
_200 dd 200.0
_300 dd 300.0

.CODE

START:

MOV AX,@DATA
MOV DS, AX
FINIT

fld _50
fstp q
fld _4
fld _2
fadd
fstp @aux4
fld @aux4
fstp c
fld _27_123456789
fstp cont
DisplayFloat cont,1
newLine

DisplayString @msj_entero 
int 21h 
newLine 1
GetFloat abbaa 
DisplayFloat abbaa,1
newLine

DisplayString @msj_real 
int 21h 
newLine 1
GetFloat e 
DisplayFloat e,1
newLine

LEA EAX, _Hola12
 MOV pepp , EAX
fld _1
fstp var1
fld _3
fstp c
fld _4
fstp d
fld var1
fld _3
fxch
fcomp
fstsw ax
sahf
JNA etiqueta_26

fld var1
fstp @Filter1
JMP etiqueta_35

etiqueta_26:
fld c
fld _3
fxch
fcomp
fstsw ax
sahf
JNA etiqueta_30

fld c
fstp @Filter1
JMP etiqueta_35

etiqueta_30:
fld d
fld _3
fxch
fcomp
fstsw ax
sahf
JNA etiqueta_34

fld d
fstp @Filter1
JMP etiqueta_35

etiqueta_34:
fld _0
fstp @Filter1
etiqueta_35:
fld @Filter1
fstp abbaa
DisplayFloat abbaa,1
newLine

DisplayString _FIN_FILTER_1,1
newLine

fld _5
fld _3
fmul
fstp @aux42
fld _4
fld @aux42
fadd
fstp @aux43
fld @aux43
fstp a
DisplayFloat a,1
newLine

fld a
fld _1
fsub
fstp @aux48
fld @aux48
fld _3
fdiv
fstp @aux50
fld @aux50
fstp estoesunid
DisplayFloat estoesunid,1
newLine

fld _1_3323
fstp e
fld _3_4555
fstp b
fld _7_115
fstp cont
fld e
fld _3_0
fxch
fcomp
fstsw ax
sahf
JNA etiqueta_67

fld e
fld _7_11
fxch
fcomp
fstsw ax
sahf
JA etiqueta_67

fld e
fstp @Filter2
JMP etiqueta_80

etiqueta_67:
fld b
fld _3_0
fxch
fcomp
fstsw ax
sahf
JNA etiqueta_73

fld b
fld _7_11
fxch
fcomp
fstsw ax
sahf
JA etiqueta_73

fld b
fstp @Filter2
JMP etiqueta_80

etiqueta_73:
fld cont
fld _3_0
fxch
fcomp
fstsw ax
sahf
JNA etiqueta_79

fld cont
fld _7_11
fxch
fcomp
fstsw ax
sahf
JA etiqueta_79

fld cont
fstp @Filter2
JMP etiqueta_80

etiqueta_79:
fld _0
fstp @Filter2
etiqueta_80:
fld @Filter2
fstp berta
DisplayFloat berta,1
newLine

DisplayString _FIN_FILTER_2,1
newLine

fld _1_3323
fstp e
fld _3_4555
fstp b
fld _7_115
fstp cont
fld e
fld _1_3323
fxch
fcomp
fstsw ax
sahf
JE etiqueta_95

fld e
fstp @Filter3
JMP etiqueta_104

etiqueta_95:
fld cont
fld _1_3323
fxch
fcomp
fstsw ax
sahf
JE etiqueta_99

fld cont
fstp @Filter3
JMP etiqueta_104

etiqueta_99:
fld b
fld _1_3323
fxch
fcomp
fstsw ax
sahf
JE etiqueta_103

fld b
fstp @Filter3
JMP etiqueta_104

etiqueta_103:
fld _0
fstp @Filter3
etiqueta_104:
fld @Filter3
fstp berta
DisplayFloat berta,1
newLine

DisplayString _FIN_FILTER_3,1
newLine

fld _1_3323
fstp e
fld _3_4555
fstp b
fld _7_115
fstp cont
fld e
fld _3_0
fxch
fcomp
fstsw ax
sahf
JNA etiqueta_122

fld e
fld _3_3
fxch
fcomp
fstsw ax
sahf
JA etiqueta_122

fld e
fstp @Filter4
JMP etiqueta_135

etiqueta_122:
fld b
fld _3_0
fxch
fcomp
fstsw ax
sahf
JNA etiqueta_128

fld b
fld _3_3
fxch
fcomp
fstsw ax
sahf
JA etiqueta_128

fld b
fstp @Filter4
JMP etiqueta_135

etiqueta_128:
fld cont
fld _3_0
fxch
fcomp
fstsw ax
sahf
JNA etiqueta_134

fld cont
fld _3_3
fxch
fcomp
fstsw ax
sahf
JA etiqueta_134

fld cont
fstp @Filter4
JMP etiqueta_135

etiqueta_134:
fld _0
fstp @Filter4
etiqueta_135:
fld @Filter4
fstp berta
DisplayFloat berta,1
newLine

DisplayString _FIN_FILTER_4,1
newLine

fld _5
fstp a
etiqueta_141:
fld a
fld _1
fadd
fstp @aux143
fld @aux143
fstp a
DisplayFloat a,1
newLine

fld a
fld _10
fxch
fcomp
fstsw ax
sahf
JNE etiqueta_141

fld c
fld _10
fxch
fcomp
fstsw ax
sahf
JAE etiqueta_155

DisplayFloat c,1
newLine

etiqueta_155:
fld c
fld _10
fxch
fcomp
fstsw ax
sahf
JA etiqueta_161

DisplayString _hola,1
newLine

JMP etiqueta_162

etiqueta_161:
DisplayString _chau,1
newLine

etiqueta_162:
DisplayString _cadenuski,1
newLine

fld c
fld _10
fxch
fcomp
fstsw ax
sahf
JAE etiqueta_172

fld q
fld _20
fxch
fcomp
fstsw ax
sahf
JNA etiqueta_172

DisplayString _CONDICION_AND,1
newLine

etiqueta_172:
fld _100
fstp q
fld _200
fstp c
fld _300
fstp d
DisplayFloat q,1
newLine

DisplayFloat c,1
newLine

DisplayFloat d,1
newLine


MOV AH, 1
INT 21h
MOV AX, 4C00h
INT 21h

END START
