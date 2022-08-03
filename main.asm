[org 0x0100]

	jmp start

	%define	GROUND_LEVEL 183
	%define	HURDLE_1_X 40
	%define	HURDLE_1_Y 143
	%define	HURDLE_2_X 120
	%define	HURDLE_2_Y 159
	%define	HURDLE_3_X 200
	%define	HURDLE_3_Y 151
	%define HURDLE_WIDTH 26
	%define HURDLE_TOP_MARGIN 2
	%define	MAX_UP 60
	%define	MAX_X 300
	%define	MIN_X 0
	%define	MAX_Y 199
	%define	MIN_Y 0
	%define	TRUE 1
	%define	FALSE 0
	%define	NOTES_NOSS	1782
	%define GOOMBA_WIDTH 16
	%define GOOMBA_HEIGHT 16
	%define ENEMY_HIT 2
	%define FIRE_HEIGHT 15
	%define FIRE_WIDTH 15

;void delay(int cx:dx)
delay:
	push bp
	mov bp, sp

	push ax
	push cx
	push dx

	mov cx, [bp+6]
	mov dx, [bp+4]

	mov ah, 86h
	int 15h

	pop dx
	pop cx
	pop ax

	pop bp
ret 4

;void clrscr()
clrscr:
	push es
	push bx
	push cx

	mov bx, 0xA000
	mov es, bx
	xor bx, bx

	mov cx, 0xFA00
clr:
	mov word[es:bx], 0
	inc bx
	loop clr

	pop cx
	pop bx
	pop es
ret

;int strlen(str)
STRLEN:
	push bp
	mov bp, sp

	push es
	push di
	push ax
	push cx

	push cs
	pop  es
	mov  di, [bp+4]
	mov  cx, 0xffff
	xor  al, al
	repne scasb
	mov  ax, 0xffff
	sub  ax, cx
	dec  ax

	mov [bp+6], ax

	pop cx
	pop ax
	pop di
	pop es

	pop bp
ret 2

;void printStr(int x, int y, int attrib, int*str)
printStr:
	push bp
	mov bp, sp

	pusha

	xor bh, bh
	mov si, [bp+4]

	push 0
	push si
	call STRLEN
	pop cx

	mov dl, [bp+10]
	mov dh, [bp+8]
nextPrint:
	push cx

	;setting cursor
	mov ah, 0x2
	int 0x10

	mov al, [si]
	mov bl, [bp+6]
	mov cx, 1
	mov ah, 0x9
	int 0x10

	inc dl
	inc si
	pop cx
loop nextPrint

	popa

	pop bp
ret 8

;void printnum(int x, int y, int attrib, int num)
printnum:
	push bp
	mov  bp, sp

	pusha

	mov  ax, [bp+4]         ; load number in ax
	mov  bx, 10             ; use base 10 for division
	mov  cx, 0              ; initialize count of digits

nextdigit:
	mov  dx, 0              ; zero upper half of dividend
	div  bx                 ; divide by 10
	add  dl, 0x30           ; convert digit into ascii value
	push dx                 ; save ascii value on stack
	inc  cx                 ; increment count of values
	cmp  ax, 0              ; is the quotient zero
	jnz  nextdigit          ; if no divide it again

	mov  di, [bp+10]       	; point di to given x location of the screen

nextpos:
	pop  dx                 ; remove a digit from the stack

	mov [reserveChar], dl

	push di
	push word[bp+8]
	push word[bp+6]
	push reserveChar
	call printStr

	inc di
loop nextpos 		        ; repeat for all digits on stack

	popa

	pop  bp
ret  8

;void makeDot(int x, int y, int color)
makeDot:
	push bp
	mov bp, sp

	push ax
	push cx
	push dx

	mov al, [bp+4]	;loading color
	mov cx, [bp+8]	;setting x-coordinate
	mov dx, [bp+6]	;setting y-coordinate

	mov ah, 0Ch
	int 10h

	pop dx
	pop cx
	pop ax

	pop bp
ret 6

;void makeHLine(int x, int y, int point_type, int width, int color)	//point_type:	0:from left to right, 1:from right to left
makeHLine:
	push bp
	mov bp, sp

	pusha

	mov ax, [bp+12]	;x-coordinate
	mov bx, [bp+10]	;y-coordinate
	mov cx, [bp+6]	;width
	mov dx, [bp+4]	;color

	cmp cx, 0
	je skip4

	cmp word[bp+8], 1
	je HlineType2

HlineType1:
	push ax	;x-coordinate
	push bx	;y-coordinate
	push dx	;color
	call makeDot

	inc ax
loop HlineType1
	jmp skip4

HlineType2:
	push ax	;x-coordinate
	push bx	;y-coordinate
	push dx	;color
	call makeDot

	dec ax
loop HlineType2

skip4:
	popa

	pop bp
ret 10


;(x,y) adjustRecCoordinates(int x, int y, int coordinate_type, int width, int height)	// 0:top-left, 1:bottom-left, 2:bottom-right, 3:top-right
adjustRecCoordinates:
	push bp
	mov bp, sp

	pusha

	mov si, [bp+6]	;width
	mov di, [bp+4]	;height

	mov cx, [bp+8]
	cmp cx, 0
	je type1_1
	cmp cx, 1
	je type2_1
	cmp cx, 2
	je type3_1
	cmp cx, 3
	je type4_1

;for top left corner
type1_1:
	mov ax, [bp+12]	;x-coordinate
	mov bx, [bp+10]	;y-coordinate
jmp set_1

;for bottom left corner
type2_1:
	mov ax, [bp+12]	;x-coordinate

	;y-coordinate
	mov bx, [bp+10]
	sub bx, di
	inc bx

jmp set_1

;for bottom right corner
type3_1:
	;x-coordinate
	mov ax, [bp+12]
	sub ax, si
	inc ax

	;y-coordinate
	mov bx, [bp+10]
	sub bx, di
	inc bx
jmp set_1

;for top right corner
type4_1:
	;x-coordinate
	mov ax, [bp+12]
	sub ax, si
	inc ax

	mov bx, [bp+10]	;y-coordinate

set_1:
	mov [bp+16], ax
	mov [bp+14], bx

	popa

	pop bp
ret 10


;void makePole(int x, int y)
makePole:
	push bp
	mov bp, sp

	push ax
	push bx
	push cx

	push ax
	push bx
	push poleKnob
	call makeImg

	add ax, 3
	add bx, 8

	mov cx, 146
pl:
	push ax
	push bx
	push pole
	call makeImg

	inc bx
loop pl
	pop cx
	pop bx
	pop ax

	pop bp
ret 4


;void makeFlag(int x, int y)
makeFlag:
	push bp
	mov bp, sp

	push word[bp+6]
	push word[bp+4]
	push flag
	call makeImg

	pop bp
ret 4

;void makeGoal(int x, int y, int flagdowny)
makeGoal:
	push bp
	mov bp, sp

	push ax
	push bx
	push cx
	push dx

	push 0
	push 0
	push word[bp+8]
	push word[bp+6]
	push 1
	push 8
	push 170
	call adjustRecCoordinates
	pop bx
	pop ax

	sub ax, 3

	push ax
	push bx
	call makePole

	mov cx, ax
	sub cx, 13

	mov dx, bx
	add dx, 8
	add dx, [bp+4]

	push cx
	push dx
	call makeFlag

	sub ax, 4
	add bx, 154

	push ax
	push bx
	push block1
	call makeImg

	pop dx
	pop cx
	pop bx
	pop ax

	pop bp
ret 6

;void makeHurdle(int x, int y, int height)
makeHurdle:
	push bp
	mov bp, sp

	pusha

	mov di, [bp+4]
	shl di, 1
	add di, 16

	push 0
	push 0
	push word[bp+8]
	push word[bp+6]
	push 1
	push 28
	push di
	call adjustRecCoordinates
	pop bx
	pop ax

	sub ax, 2

	push ax
	push bx
	push pipeUpper1
	call makeImg

	add bx, 4

	mov cx, 5
ppu:
	push ax
	push bx
	push pipeUpper2
	call makeImg

	add bx, 2
loop ppu

	push ax
	push bx
	push pipeUpper3
	call makeImg

	add ax, 2
	inc bx

	push ax
	push bx
	push pipeLower1
	call makeImg

	inc bx
	mov cx, [bp+4]
ppl:
	push ax
	push bx
	push pipeLower2
	call makeImg

	add bx, 2
loop ppl

	popa

	pop bp
ret 6

;int getMarioWidth()
getMarioWidth:
	push bp
	mov bp, sp

	push dx

	mov dx, [pose]

	cmp dx, 0
	jne nextW1Cmp
	mov word[bp+4], 12
	jmp exitGetWidth

nextW1Cmp:
	cmp dx, 1
	jne nextW2Cmp
	mov word[bp+4], 16
	jmp exitGetWidth

nextW2Cmp:
	cmp dx, 2
	jne nextW3Cmp
	mov word[bp+4], 12
	jmp exitGetWidth

nextW3Cmp:
	cmp dx, 3
	jne nextW4Cmp
	mov word[bp+4], 11
	jmp exitGetWidth

nextW4Cmp:
	cmp dx, 4
	jne nextW5Cmp
	mov word[bp+4], 13
	jmp exitGetWidth

nextW5Cmp:
	cmp dx, 5
	jne nextW6Cmp
	mov word[bp+4], 16
	jmp exitGetWidth

nextW6Cmp:
	cmp dx, 6
	jne nextW7Cmp
	mov word[bp+4], 12
	jmp exitGetWidth

nextW7Cmp:
	cmp dx, 7
	jne nextW8Cmp
	mov word[bp+4], 16
	jmp exitGetWidth

nextW8Cmp:
	cmp dx, 8
	jne nextW9Cmp
	mov word[bp+4], 12
	jmp exitGetWidth

nextW9Cmp:
	cmp dx, 9
	jne nextW10Cmp
	mov word[bp+4], 11
	jmp exitGetWidth

nextW10Cmp:
	cmp dx, 10
	jne nextW11Cmp
	mov word[bp+4], 13
	jmp exitGetWidth

nextW11Cmp:
	cmp dx, 11
	jne exitGetWidth
	mov word[bp+4], 16
	jmp exitGetWidth

nextW12Cmp:
	cmp dx, 12
	jne exitGetWidth
	mov word[bp+4], 14
	jmp exitGetWidth

exitGetWidth:
	pop dx

	pop bp
ret

;int getMarioHeight()
getMarioHeight:
	push bp
	mov bp, sp

	push dx

	mov dx, [pose]

	cmp dx, 0
	jne nextH1Cmp
	mov word[bp+4], 16
	jmp exitGetHeight

nextH1Cmp:
	cmp dx, 1
	jne nextH2Cmp
	mov word[bp+4], 16
	jmp exitGetHeight

nextH2Cmp:
	cmp dx, 2
	jne nextH3Cmp
	mov word[bp+4], 16
	jmp exitGetHeight

nextH3Cmp:
	cmp dx, 3
	jne nextH4Cmp
	mov word[bp+4], 15
	jmp exitGetHeight

nextH4Cmp:
	cmp dx, 4
	jne nextH5Cmp
	mov word[bp+4], 16
	jmp exitGetHeight

nextH5Cmp:
	cmp dx, 5
	jne nextH6Cmp
	mov word[bp+4], 16
	jmp exitGetHeight

nextH6Cmp:
	cmp dx, 6
	jne nextH7Cmp
	mov word[bp+4], 16
	jmp exitGetHeight

nextH7Cmp:
	cmp dx, 7
	jne nextH8Cmp
	mov word[bp+4], 16
	jmp exitGetHeight

nextH8Cmp:
	cmp dx, 8
	jne nextH9Cmp
	mov word[bp+4], 16
	jmp exitGetHeight

nextH9Cmp:
	cmp dx, 9
	jne nextH10Cmp
	mov word[bp+4], 15
	jmp exitGetHeight

nextH10Cmp:
	cmp dx, 10
	jne nextH11Cmp
	mov word[bp+4], 16
	jmp exitGetHeight

nextH11Cmp:
	cmp dx, 11
	jne nextH12Cmp
	mov word[bp+4], 16
	jmp exitGetHeight

nextH12Cmp:
	cmp dx, 12
	jne exitGetHeight
	mov word[bp+4], 14
	jmp exitGetHeight

exitGetHeight:
	pop dx

	pop bp
ret

;void makeMario(int x, int y, int pose)
makeMario:
	push bp
	mov bp, sp

	pusha

	mov dx, [bp+4]

	cmp dx, 0
	jne nextPoseRunfCmp

	mov si, 12
	mov di, 16
	mov bx, idleMariof
	jmp setPose

nextPoseRunfCmp:
	cmp dx, 1
	jne nextPoseStepfCmp

	mov si, 16
	mov di, 16
	mov bx, runMariof
	jmp setPose

nextPoseStepfCmp:
	cmp dx, 2
	jne nextPoseStandfCmp

	mov si, 12
	mov di, 16
	mov bx, stepMariof
	jmp setPose

nextPoseStandfCmp:
	cmp dx, 3
	jne nextPoseShootfCmp

	mov si, 11
	mov di, 15
	mov bx, standMariof
	jmp setPose

nextPoseShootfCmp:
	cmp dx, 4
	jne nextPoseAirfCmp

	mov si, 13
	mov di, 16
	mov bx, shootMariof
	jmp setPose

nextPoseAirfCmp:
	cmp dx, 5
	jne nextPoseIdlebCmp

	mov si, 16
	mov di, 16
	mov bx, airMariof
	jmp setPose

nextPoseIdlebCmp:
	cmp dx, 6
	jne nextPoseRunbCmp

	mov si, 12
	mov di, 16
	mov bx, idleMariob
	jmp setPose

nextPoseRunbCmp:
	cmp dx, 7
	jne nextPoseStepbCmp

	mov si, 16
	mov di, 16
	mov bx, runMariob
	jmp setPose

nextPoseStepbCmp:
	cmp dx, 8
	jne nextPoseStandbCmp

	mov si, 12
	mov di, 16
	mov bx, stepMariob
	jmp setPose

nextPoseStandbCmp:
	cmp dx, 9
	jne nextPoseShootbCmp

	mov si, 11
	mov di, 15
	mov bx, standMariob
	jmp setPose

nextPoseShootbCmp:
	cmp dx, 10
	jne nextPoseAirbCmp

	mov si, 13
	mov di, 16
	mov bx, shootMariob
	jmp setPose

nextPoseAirbCmp:
	cmp dx, 11
	jne nextPoseOutCmp

	mov si, 16
	mov di, 16
	mov bx, airMariob
	jmp setPose

nextPoseOutCmp:
	cmp dx, 12
	jne setPose

	mov si, 14
	mov di, 14
	mov bx, outMario
	jmp setPose

setPose:
	push 0
	push 0
	push word[bp+8]
	push word[bp+6]
	push 1
	push si
	push di
	call adjustRecCoordinates
	pop cx
	pop ax

	push ax
	push cx
	push bx
	call makeImg

	popa

	pop bp
ret 6

;void makeGoomba(int x, int y, int status)	//0 - right pose, 1 - left pose, 2 - dead pose
makeGoomba:
	push bp
	mov bp, sp

	push dx
	push cx
	push bx
	push ax

	mov dx, [bp+4]

	cmp dx, 0
	jne leftGoomba

	mov bx, goombaRight
	jmp drawGoomba

leftGoomba:
	cmp dx, 1
	jne drawGoomba

	mov bx, goombaLeft
	jmp drawGoomba

drawGoomba:
	push 0
	push 0
	push word[bp+8]
	push word[bp+6]
	push 1
	push 16
	push 16
	call adjustRecCoordinates
	pop cx
	pop ax

	push ax
	push cx
	push bx
	call makeImg

	pop ax
	pop bx
	pop cx
	pop dx

	pop bp
ret 6

;void makeBowser(int x, int y, int status)
makeBowser:
	push bp
	mov bp, sp

	push ax
	push bx
	push cx
	push dx

	mov dx, [bp+4]

	cmp dx, 0
	jne fin2nd

	mov bx, fin1
	jmp drawBowser

fin2nd:
	cmp dx, 1
	jne fin3th

	mov bx, fin2
	jmp drawBowser

fin3th:
	cmp dx, 2
	jne fin4th

	mov bx, fin3
	jmp drawBowser

fin4th:
	cmp dx, 3
	jne fin5th

	mov bx, fin4
	jmp drawBowser

fin5th:
	cmp dx, 4
	jne drawBowser

	mov bx, fin2
	jmp drawBowser

drawBowser:

	push 0
	push 0
	push word[bp+8]
	push word[bp+6]
	push 1
	push 64
	push 88
	call adjustRecCoordinates
	pop cx
	pop ax

	push ax
	push cx
	push bowser
	call makeImg

	mov dx, [bp+8]
	add dx, 12
	push dx

	mov dx, [bp+6]
	inc dx
	push dx

	push bx
	call makeImg

	pop dx
	pop cx
	pop bx
	pop ax

	pop bp
ret 6

;void makeFireBall(int x, int y)
makeFireBall:
	push bp
	mov bp, sp

	push ax
	push cx

	push 0
	push 0
	push word[bp+6]
	push word[bp+4]
	push 1
	push 15
	push 15
	call adjustRecCoordinates
	pop cx
	pop ax

	push ax
	push cx
	push fireBall
	call makeImg

	pop cx
	pop ax

	pop bp
ret 4

;void makeCastle(int x, int y)
makeCastle:
	push bp
	mov bp, sp

	push ax
	push cx

	push 0
	push 0
	push word[bp+6]
	push word[bp+4]
	push 1
	push 47
	push 89
	call adjustRecCoordinates
	pop cx
	pop ax

	push ax
	push cx
	push castle
	call makeImg

	pop cx
	pop ax

	pop bp
ret 4

;void makeGround()
makeGround:
	push ax
	push cx

	xor ax, ax
	mov cx, 20
gl:
	push ax
	push 184
	push block2
	call makeImg

	push 130
	push 164
	push mount
	call makeImg

	push 40
	push 168
	push bush
	call makeImg

	add ax, 16
	loop gl

	pop cx
	pop ax
ret

;void makeSky()
makeSky:
	push ax
	push bx
	push cx
	push dx

	mov al, 0
	mov ah, 7
	mov cx, 0
	mov dx, 0x2439
	mov bh, 24
	int 0x10

	push 35
	push 15
	push cloud
	call makeImg

	push 180
	push 30
	push cloud
	call makeImg

	pop dx
	pop cx
	pop bx
	pop ax
ret

;playNote(int note)
playNote:
	push bp
	mov bp, sp

	push ax

	mov al,	10110110b
	out 43h, al

	mov ax, [bp+4] ; move our frequency value into ax.
	cmp ax, 0
	je ign
	cmp ax, -1
	je off

	; to turn on the speaker.
	out 42h, al
	mov al, ah
	out 42h, al
	in al, 61h
	or al, 00000011b
	out 61h, al

	jmp ign
off:
	; to turn off the speaker.
	in al, 61h
	and al,11111100b
	out 61h,al

ign:
	pop ax

	pop bp
ret 2

;void GameOver()
GameOver:
	call clrscr

	push 15
	push 11
	push 16
	push gameOverStr
	call printStr

	push 14
	push 13
	call printScore
ret

;void GameWin()
GameWin:
	call clrscr

	push 15
	push 11
	push 16
	push WinStr
	call printStr

	push 13
	push 13
	call printScore
ret

;void welcome()
welcome:
	call clrscr

	push 12
	push 9
	push 16
	push welcomeStr1
	call printStr

	push 10
	push 11
	push 16
	push welcomeStr2
	call printStr

	push 19
	push 13
	push 16
	push welcomeStr3
	call printStr

	push 14
	push 15
	push 16
	push welcomeStr4
	call printStr
ret

;void printScore(int x, int y)
printScore:
	push bp
	mov bp, sp

	push ax
	push bx

	mov ax, [bp+6]
	mov bx, [bp+4]

	push ax
	push bx
	push 16
	push scoreStr
	call printStr

	add ax, 7

	push ax
	push bx
	push 16
	push word[score]	; push the score number
	call printnum

	pop bx
	pop ax

	pop bp
ret 4

;void level()
level:
	pusha

	mov bx, 130
	mov cx, 200
	mov dx, TRUE
	mov di, TRUE
	xor bp, bp
l1:

	call makeSky
	call makeGround

	cmp word[goombaPoseCtrl], 6
	jne noSetGoombaPose

	sub word[score], 5

	mov word[goombaPoseCtrl], 0

	cmp bp, 1
	je 	setLeftGoombaPose
	mov bp, 1
	jmp noSetGoombaPose
setLeftGoombaPose:
	mov bp, 0
noSetGoombaPose:

	inc word[goombaPoseCtrl]

	push 0
	push word[goomba1_x]
	push GROUND_LEVEL
	push GOOMBA_WIDTH
	push hdlArr
	call detectXCollision
	pop si

	cmp si, TRUE
	jne	noReReverseGoomba_1

	cmp dx, 0
	je 	reverseGoomba_1
	mov dx, 0
	dec word[goomba1_x]
	jmp noReReverseGoomba_1
reverseGoomba_1:
	mov dx, 1
	inc word[goomba1_x]
noReReverseGoomba_1:

	cmp dx, 1
	je incXGoomba_1
	dec word[goomba1_x]
	jmp incXGoomba_1_skip
incXGoomba_1:
	inc word[goomba1_x]
incXGoomba_1_skip:

	push word[goomba1_x]
	push GROUND_LEVEL
	push bp
	call makeGoomba

	push 0
	push word[goomba2_x]
	push GROUND_LEVEL
	push GOOMBA_WIDTH
	push hdlArr
	call detectXCollision
	pop si

	cmp si, TRUE
	jne noReReverseGoomba_2

	cmp di, 0
	je 	reverseGoomba_2
	mov di, 0
	dec word[goomba2_x]
	jmp noReReverseGoomba_2
reverseGoomba_2:
	mov di, 1
	inc word[goomba2_x]
noReReverseGoomba_2:

	cmp di, 1
	je incXGoomba_2
	dec word[goomba2_x]
	jmp incXGoomba_2_skip
incXGoomba_2:
	inc word[goomba2_x]
incXGoomba_2_skip:

	push word[goomba2_x]
	push GROUND_LEVEL
	push bp
	call makeGoomba

	push HURDLE_1_X
	push GROUND_LEVEL
	push 12
	call makeHurdle

	push HURDLE_2_X
	push GROUND_LEVEL
	push 4
	call makeHurdle

	push HURDLE_3_X
	push GROUND_LEVEL
	push 8
	call makeHurdle


	push 255
	push GROUND_LEVEL
	call makeCastle

	push 310
	push GROUND_LEVEL
	push word[flagY]
	call makeGoal


	cmp word[bowserFin], 4
	jne noBowserFinPose

	mov word[bowserFin], 0

noBowserFinPose:

	inc word[bowserFin]

	cmp bp, 1
	je bowserUp
	dec word[bowserY]
	jmp bowserDown
bowserUp:
	inc word[bowserY]
bowserDown:

	cmp word[counter_delay], 23
	jb nofirevisibility
	mov word[fireVisible], TRUE
nofirevisibility:

	cmp word[fireVisible], FALSE
	jne fireaction

	push 0
	push word[bowserX]
	push word[bowserY]
	push 64
	push hdlArr
	call detectXCollision
	pop si

	cmp si, TRUE
	jne	noBackBowser

	cmp word[bowserVal], 0
	je 	backBowser
	mov word[bowserVal], 0
	dec word[bowserX]
	jmp noBackBowser
backBowser:
	mov word[bowserVal], 1
	inc word[bowserX]
noBackBowser:

	cmp word[bowserVal], 1
	je incXBowser
	sub word[bowserX], 3
	jmp incXBowser_skip
incXBowser:
	add word[bowserX], 3
incXBowser_skip:


	mov ax, [bowserX]
	add ax, 24
	mov word[fireX], ax

	mov ax, [bowserY]
	dec ax
	mov [fireY], ax

fireaction:
	cmp word[fireVisible], FALSE
	je noFire
	add word[fireY], 5
	push word[fireX]
	push word[fireY]
	call makeFireBall
noFire:
	push word[bowserX]
	push word[bowserY]
	push word[bowserFin]
	call makeBowser

	inc word[counter_delay]

	push word[mariox]
	push word[marioy]
	push word[pose]
	call makeMario

	push 28
	push 0
	call printScore

	push 0
	push 0xFFFF
	call delay

	cmp word[gameOver], TRUE
	jne noBreak1
	inc word[gameOverCount]
	cmp word[gameOverCount], 10
	ja marioDieDown
	mov word[pose], 12
	sub word[marioy], 5
	jmp noMarioDieDown
marioDieDown:
	add word[marioy], 10
noMarioDieDown:
	cmp word[gameOverCount], 40
	jb noBreak1

	push 0x0000
	push 0xFFFF
	call delay
	call GameOver
	jmp lvlEnd

noBreak1:

	cmp word[gameWin], TRUE
	jne noBreak2
	mov word[pose], 0
	inc word[gameWinCount]
	cmp word[gameWinCount], 25
	ja noFlagDown
flagDown:
	add word[flagY], 4
	jmp noBreak2
noFlagDown:
	push 0x0000
	push 0xFFFF
	call delay
	call GameWin
	jmp lvlEnd

noBreak2:

	push 0
	call getMarioWidth
	pop ax
	add ax, [mariox]
	cmp ax, 300
jb l1
	mov word[gameWin], TRUE
jmp l1

lvlEnd:

popa
ret


;bool detectGoombaXCollision(int spriteX, int spriteY, int spriteWidth, int* gmbaArr)
detectGoombaXCollision:
	push bp
	mov bp, sp

	pusha

	mov ax, [bp+10]
	mov dx, [bp+8]
	mov di, [bp+6]
	mov si, [bp+4]

	mov cx, [si]
	add si, 2
nxtGoomba:
	push cx

	mov cx, GROUND_LEVEL	;or change GROUND_LEVEL to Goomba_z Y-axis
	sub cx, GOOMBA_HEIGHT
	cmp dx, cx;
	jbe nogxcollide

	mov cx, di
	add cx, ax
	mov bx, [si]
	mov bx, [bx]
	cmp cx, bx
	jb nogxcollide

	mov bx, [si]
	mov bx, [bx]
	add bx, GOOMBA_WIDTH
	cmp ax, bx
	ja nogxcollide

	pop cx
	mov word[bp+12], TRUE
	jmp endColideGxCHK

nogxcollide:
	add si, 2
	pop cx
	loop nxtGoomba

	mov word[bp+12], FALSE
endColideGxCHK:
	popa

	pop bp
ret 8

;int detectFireDownCollision(int spriteX, int spriteY, int spriteWidth, int spriteHeight)
detectFireDownCollision:
	push bp
	mov bp, sp

	pusha

	mov ax, [bp+10]
	mov dx, [bp+8]
	mov di, [bp+6]

	push 0
	call getMarioHeight
	pop cx
	mov bx, [marioy]
	sub bx, cx
	cmp dx, bx
	jb nomariohit

	mov cx, dx
	sub cx, [bp+4]
	cmp cx, [marioy]
	ja nomariohit

	mov cx, ax
	add cx, [bp+6]
	cmp cx, [mariox]
	jb  nomariohit

	push 0
	call getMarioWidth
	pop cx
	add cx, [mariox]
	cmp ax, cx
	ja nomariohit

	mov word[bp+12], TRUE
	jmp endColidefxCHK
nomariohit:

	mov word[bp+12], FALSE
endColidefxCHK:
	popa

	pop bp
ret 8


;bool detectXCollision(int spriteX, int spriteY, int spriteWidth, int* hdlArr)
detectXCollision:
	push bp
	mov bp, sp

	pusha

	mov ax, [bp+10]
	mov dx, [bp+8]
	mov di, [bp+6]
	mov si, [bp+4]

	mov bx, ax
	add bx, di
	cmp bx, MAX_X
	ja extremeXCollide
	cmp ax, MIN_X
	jl extremeXCollide

	mov cx, [si]
	sub si, 2
nxtXhdl:
	push cx
	add si, 4

	cmp dx, [si];
	jbe noxcollide

	mov cx, di
	add cx, ax
	mov bx, [si+2]
	sub bx, HURDLE_TOP_MARGIN
	cmp cx, bx
	jb noxcollide

	mov bx, [si+2]
	add bx, HURDLE_WIDTH
	cmp ax, bx
	ja noxcollide

	pop cx
extremeXCollide:
	mov word[bp+12], TRUE
	jmp endColidexCHK

noxcollide:
	pop cx
	loop nxtXhdl

	mov word[bp+12], FALSE
endColidexCHK:
	popa

	pop bp
ret 8

;int detectDownCollision(int spriteX, int spriteY, int spriteWidth, int* hdlArr)
detectDownCollision:
	push bp
	mov bp, sp

	pusha

	mov ax, [bp+10]
	mov bx, [bp+8]
	mov di, [bp+6]
	mov si, [bp+4]

	mov cx, [si]
	sub si, 2
nxtdHdl:
	push cx
	add si, 4

	cmp bx, [si]
	jb nodcollide

	mov cx, di
	add cx, ax
	mov dx, [si+2]
	sub dx, HURDLE_TOP_MARGIN
	dec dx
	cmp cx, dx
	jbe nodcollide

	mov dx, [si+2]
	add dx, HURDLE_WIDTH
	inc dx
	cmp ax, dx
	jae nodcollide

	mov word[bp+12], TRUE
	pop cx
	jmp endColidedCHK

nodcollide:
	pop cx
	loop nxtdHdl

	cmp bx, GROUND_LEVEL
	jb	nogndcolide

	mov word[bp+12], TRUE
	jmp endColidedCHK

nogndcolide:
	mov word[bp+12], FALSE
endColidedCHK:
	popa

	pop bp
ret 8

kbisr:
	push ax
	push cx
	push dx

	in al, 0x60           ; read a char from keyboard port

	cmp word[gameOver], TRUE
	je 	nomovement
	cmp word[gameWin], TRUE
	je nomovement
nextKBRPCmp:
	cmp al, 77
	jne nextKBRRCmp

	add word[mariox], 1
norx:
	cmp word[upTouched], TRUE
	je	noreposer
	cmp word[pose], 4
	jne noshootragain
	mov word[pose], 1
noshootragain:
	cmp word[pose], 7
	jb	noshootr
	mov word[pose], 4
	jmp noUpRPose
noshootr:
	inc word[pose]
	cmp word[pose], 4
	jb noUpRPose
	mov word[pose], 1
	jmp noUpRPose
noreposer:
	mov word[pose], 5
noUpRPose:

	push 0
	push word[mariox]
	push word[marioy]
	push 0
	call getMarioWidth
	push hdlArr
	call detectXCollision
	pop ax

	cmp ax, TRUE
	jne	noxreverse
	sub word[mariox], 1
noxreverse:
jmp finishKevent

nomovement:
jmp noMovement

nextKBRRCmp:
	cmp al, 205
	jne nextKBLPCmp

	cmp word[upTouched], TRUE
	je norrReset
	mov word[pose], 0
norrReset:
jmp finishKevent

nextKBLPCmp:
	cmp al, 75
	jne nxtKBLRCmp

	cmp word[mariox], MIN_X
	jle nogoleft
	sub word[mariox], 1
nogoleft:

	cmp word[upTouched], TRUE
	je	noreposel
	cmp word[pose], 10
	jne noshootlagain
	mov word[pose], 7
noshootlagain:
	cmp word[pose], 5
	ja	noshootl
	cmp word[pose], 0
	je noshootl
	mov word[pose], 10
	jmp noUpLPose
noshootl:
	add word[pose], 1
	cmp word[pose], 10
	jb noUpLPose
	mov word[pose], 7
	jmp noUpRPose

nxtKBLRCmp:
	jmp nextKBLRCmp

noreposel:
	mov word[pose], 11
noUpLPose:

	push 0
	push word[mariox]
	push word[marioy]
	push 0
	call getMarioWidth
	push hdlArr
	call detectXCollision
	pop ax

	cmp ax, TRUE
	jne	nolreverse
	add word[mariox], 1
nolreverse:

jmp finishKevent

nxtKBUPCmp:
jmp nextKBUPCmp

nextKBLRCmp:
	cmp al, 203
	jne nextKBUPCmp

	mov ah,0ch
	mov al,0
	int 21h

	cmp word[upTouched], TRUE
	je	nolrReset
	mov word[pose], 6
nolrReset:
jmp finishKevent

nextKBUPCmp:
	cmp al, 72
	jne nextKBURCmp

	cmp word[upTouched], TRUE
	je	skipuprpose

	mov word[gravity], FALSE

	push 0
	call getMarioHeight
	pop cx
	mov ax, [marioy]
	sub ax, cx
	sub ax, 3
	cmp ax, MIN_Y
	jl nouy

	cmp word[up], MAX_UP
	jae	nouy
	add word[up], 3
	sub word[marioy], 3
	jmp noTouch
nouy:
	mov word[upTouched], TRUE
	mov word[gravity], TRUE
noTouch:
	cmp word[pose], 5
	jbe	uprpose
	mov word[pose], 11
	jmp skipuprpose
uprpose:
	mov word[pose], 5
skipuprpose:
jmp finishKevent

nextKBURCmp:
	cmp al, 200
	jne finishKevent

	mov word[upTouched], TRUE
	mov word[gravity], TRUE
	mov word[up], 0
jmp finishKevent
finishKevent:

noMovement:
	pop dx
	pop cx
	pop ax

jmp far [cs:oldkbisr]

tmisr:
	push bx

	cmp word[gameOver], TRUE
	je 	noEffect
	cmp word[gameWin], TRUE
	je noEffect


	push 0
	push word[fireX]
	push word[fireY]
	push FIRE_WIDTH
	push FIRE_HEIGHT
	call detectFireDownCollision
	pop bx

	cmp bx, TRUE
	jne nofirehit

	mov word[gameOver], TRUE
	sub word[score], 20000
	jmp noEffect

noEffect:
jmp noTimeEffect

nofirehit:
	cmp word[counter_delay], 50
	jb nofirehide
	mov word[fireVisible], FALSE
	mov word[counter_delay], 0
	jmp noEffect
nofirehide:

	push 0
	push word[mariox]
	push word[marioy]
	push 0
	call getMarioWidth
	push gmbaArr
	call detectGoombaXCollision
	pop bx

	cmp bx, TRUE
	jne noEnemyHit
	mov word[gameOver], TRUE
	sub word[score], 15000
	jmp noTimeEffect
noEnemyHit:

	cmp word[upTouched], TRUE
	je fGravity

	cmp word[gravity], FALSE
	je nogravity
fGravity:
	push 0
	push word[mariox]
	push word[marioy]
	push 0
	call getMarioWidth
	push hdlArr
	call detectDownCollision
	pop bx

	cmp bx, TRUE
	je	nogravity

	add word[marioy], 1
	mov word[upTouched], TRUE
noTimeEffect:
	jmp noUp
nogravity:
	cmp word[upTouched], FALSE
	je	noUp
	mov word[up], 0
	mov word[upTouched], FALSE
	cmp word[pose], 6
	jb	setRightUpPose
	mov word[pose], 6
	jmp noUp
setRightUpPose:
	mov word[pose], 0
noUp:
	pop bx
jmp far [cs:oldtmisr]     	  ; call the original ISR

fsttmisr:
	push bx

	inc byte[prevCount]

	cmp byte[prevCount], 49
	jbe	noNextNote
	cmp word[currentNote], NOTES_NOSS
	jbe	noReNote
	mov word[currentNote], 0
noReNote:
	mov bx, [currentNote]
	push word[mario_note+bx]
	call playNote
	add word[currentNote], 2
	mov byte[prevCount], 0
noNextNote:

	pop bx
jmp far [cs:oldfsttmisr]     	  ; call the original ISR

;void startGame()
startGame:
	push ax
	push bx
	push es

	xor ax, ax
	mov es, ax 				; point es to IVT base
	mov ax, [es:9*4]
	mov [oldkbisr], ax 		; save offset of old routine
	mov ax, [es:9*4+2]
	mov [oldkbisr+2], ax 		; save segment of old routine

	mov ax, [es:1Ch*4]
	mov [oldtmisr], ax 		; save offset of old timer routine
	mov ax, [es:1Ch*4+2]
	mov [oldtmisr+2], ax 	; save segment of old timer routine

	mov ax, [es:70h*4]
	mov [oldfsttmisr], ax 		; save offset of old timer routine
	mov ax, [es:70h*4+2]
	mov [oldfsttmisr+2], ax 	; save segment of old timer routine

	cli 					; disable interrupts
	mov word [es:9*4], kbisr; store offset at n*4
	mov [es:9*4+2], cs 		; store segment at n*4+2
	mov word [es:1Ch*4], tmisr ; store offset at n*4
	mov [es:1Ch*4+2], cs ; store segment at n*4+2

	mov word [es:70h*4], fsttmisr ; store offset at n*4
	mov [es:70h*4+2], cs ; store segment at n*4+2
	sti 					; enable interrupts

	call welcome
	push 0x2D
	push 0xC6C0
	call delay
	call level

	; to turn off the speaker.
	in al,61h
	and al,11111100b
	out 61h,al

	cli                     ; disable interrupts
	mov ax, [oldtmisr]        ; read old offset in ax
	mov bx, [oldtmisr+2]      ; read old segment in bx
	mov [es:1ch*4], ax      ; restore old offset from ax
	mov [es:1ch*4+2], bx    ; restore old segment from bx

	mov ax, [oldfsttmisr]        ; read old offset in ax
	mov bx, [oldfsttmisr+2]      ; read old segment in bx
	mov [es:70h*4], ax      ; restore old offset from ax
	mov [es:70h*4+2], bx    ; restore old segment from bx

	mov ax, [oldkbisr]      ; read old offset in ax
	mov bx, [oldkbisr+2]    ; read old segment in bx
	mov [es:9*4], ax        ; restore old offset from ax
	mov [es:9*4+2], bx      ; restore old segment from bx
	sti                     ; enable interrupts

	pop es
	pop bx
	pop ax
ret

;void makeImg(int x, int y, int*ptr)
makeImg:
	push bp
	mov bp, sp

	pusha

	mov di, [bp+8]
	mov cx, [bp+6]

	mov si, [bp+4]	;pointer to start of image data

	xor dh, dh
	xor bh, bh
rowloop:
	mov ax, di
colloop:
	cmp byte[si], -1
	je break

	mov dl,[si]		;color
	mov bl, [si+1]	;length

	add si, 2

	cmp dl, -2
	je transparent

	cmp cx, MAX_Y
	ja transparent
	cmp cx, MIN_Y
	jl transparent

	push ax
	push cx
	push 0
	push bx
	push dx
	call makeHLine

transparent:

	add ax, bx
	jmp colloop
break:

	inc si
	inc cx
	cmp byte[si], -1
	jne rowloop

	popa

	pop bp
ret 6

;void setPal()	//sets the palette of colors
setPal:
	pusha

	mov si, pal
	mov bx, 16
ll1:

	mov ax,1010h
	mov dh,[si]
	mov ch,[si+1]
	mov cl,[si+2]
	int 10h

	add si, 3
	inc bx

	cmp bx, 69
	jne ll1

	popa
ret

;void start()
start:
	;setting graphics mode
	mov al, 13h
	mov ah, 0
	int 10h

	;keyboard rate and delay
	mov ah, 03h
	mov al, 05h
	mov bl, 0
	mov bh, 0
	int 0x16

	call clrscr	; clearing screen

	call setPal

	call startGame

mov ah, 0x4c
int 0x21

oldkbisr: dd 0 ; space for saving old keyboard isr
oldtmisr: dd 0 ; space for saving old timer isr
oldfsttmisr: dd 0 ; space for saving old timer isr
mariox:	dw	1	;	x-axis of mario
marioy:	dw	GROUND_LEVEL	;	y-axis of mario
pose:	dw	0	;	pose of mario
gravity: dw 0
up: dw 0
upTouched:	dw 0
goombaPoseCtrl:	dw	0
currentNote:	dw	0
prevCount:	dw	0
goomba1_x:	dw	100
goomba2_x:	dw	150
gameOver:	dw	FALSE
gameWin:	dw	FALSE
gameOverStr:	db	'GAME  OVER',0
welcomeStr1:	db	'SUPER MARIO BROS.',0
welcomeStr2:	db	'Designed & Developed',0
welcomeStr3:	db	'by',0
welcomeStr4:	db	'Sameed Ahmad',0
WinStr:	db	'You  Win',0
bowserFin:	dw	0
hdlArr: dw 	3,	HURDLE_1_Y,	HURDLE_1_X,	HURDLE_2_Y,	HURDLE_2_X,	HURDLE_3_Y,	HURDLE_3_X
gmbaArr:	dw 	2,	goomba1_x,	goomba2_x
bowserX:	dw	236
bowserY:	dw	89
gameOverCount:	dw	0
gameWinCount:	dw	0
scoreStr:	dw	'Score: '
score:	dw	0xC350
reserveChar: db '0', 0
flagY:	dw	0
fireX:	dw	0
fireY:	dw	0
counter_delay:	dw	0
fireVisible:	dw FALSE
fireHitted: dw 	FALSE
bowserVal: dw 0

idleMariof:
db	-2,	3,	41,	5,	-1
db	-2,	2,	41,	9,	-1
db	-2,	2,	49,	3,	44,	2,	49,	1,	44,	1,	-1
db	-2,	1,	49,	1,	44,	1,	49,	1,	44,	3,	49,	1,	44,	3,	-1
db	-2,	1,	49,	1,	44,	1,	49,	2,	44,	3,	49,	1,	44,	3,	-1
db	-2,	1,	49,	2,	44,	4,	49,	4,	-1
db	-2,	3,	44,	7,	-1
db	-2,	2,	49,	2,	41,	1,	49,	3,	-1
db	-2,	1,	49,	3,	41,	1,	49,	2,	41,	1,	49,	3,	-1
db	49,	4,	41,	4,	49,	4,	-1
db	44,	2,	49,	1,	41,	1,	44,	1,	41,	2,	44,	1,	41,	1,	49,	1,	44,	2,	-1
db	44,	3,	41,	6,	44,	3,	-1
db	44,	2,	41,	8,	44,	2,	-1
db	-2,	2,	41,	3,	-2,	2,	41,	3,	-1
db	-2,	1,	49,	3,	-2,	4,	49,	3,	-1
db	49,	4,	-2,	4,	49,	4,	-1
db	-1

idleMariob:
db	-2,	4,	41,	5,	-1
db	-2,	1,	41,	9,	-1
db	-2,	3,	44,	1,	49,	1,	44,	2,	49,	3,	-1
db	-2,	1,	44,	3,	49,	1,	44,	3,	49,	1,	44,	1,	49,	1,	-1
db	44,	3,	49,	1,	44,	3,	49,	2,	44,	1,	49,	1,	-1
db	-2,	1,	49,	4,	44,	4,	49,	2,	-1
db	-2,	2,	44,	7,	-1
db	-2,	4,	49,	3,	41,	1,	49,	2,	-1
db	-2,	1,	49,	3,	41,	1,	49,	2,	41,	1,	49,	3,	-1
db	49,	4,	41,	4,	49,	4,	-1
db	44,	2,	49,	1,	41,	1,	44,	1,	41,	2,	44,	1,	41,	1,	49,	1,	44,	2,	-1
db	44,	3,	41,	6,	44,	3,	-1
db	44,	2,	41,	8,	44,	2,	-1
db	-2,	2,	41,	3,	-2,	2,	41,	3,	-1
db	-2,	1,	49,	3,	-2,	4,	49,	3,	-1
db	49,	4,	-2,	4,	49,	4,	-1
db	-1


standMariof:
db	-2,	2,	41,	5,	-1
db	-2,	1,	41,	9,	-1
db	-2,	1,	49,	3,	44,	2,	49,	1,	44,	1,	-1
db	49,	1,	44,	1,	49,	1,	44,	3,	49,	1,	44,	3,	-1
db	49,	1,	44,	1,	49,	2,	44,	3,	49,	1,	44,	3,	-1
db	49,	2,	44,	4,	49,	4,	-1
db	-2,	2,	44,	7,	-1
db	-2,	1,	49,	3,	41,	1,	49,	2,	-1
db	49,	4,	41,	2,	49,	2,	-1
db	49,	3,	41,	2,	44,	1,	41,	2,	-1
db	49,	4,	41,	4,	-1
db	41,	1,	49,	2,	44,	2,	41,	3,	-1
db	-2,	1,	41,	1,	49,	1,	44,	2,	41,	2,	-1
db	-2,	2,	41,	3,	49,	3,	-1
db	-2,	2,	49,	4,	-1
db	-1

standMariob:
db	-2,	4,	41,	5,	-1
db	-2,	1,	41,	9,	-1
db	-2,	3,	44,	1,	49,	1,	44,	2,	49,	3,	-1
db	-2,	1,	44,	3,	49,	1,	44,	3,	49,	1,	44,	1,	49,	1,	-1
db	44,	3,	49,	1,	44,	3,	49,	2,	44,	1,	49,	1,	-1
db	-2,	1,	49,	4,	44,	4,	49,	2,	-1
db	-2,	2,	44,	7,	-1
db	-2,	4,	49,	2,	41,	1,	49,	3,	-1
db	-2,	3,	49,	2,	41,	2,	49,	4,	-1
db	-2,	3,	41,	2,	44,	1,	41,	2,	49,	3,	-1
db	-2,	3,	41,	4,	49,	4,	-1
db	-2,	3,	41,	3,	44,	2,	49,	2,	41,	1,	-1
db	-2,	4,	41,	2,	44,	2,	49,	1,	41,	1,	-1
db	-2,	3,	49,	3,	41,	3,	-1
db	-2,	5,	49,	4,	-1
db	-1


stepMariof:
db	-2,	3,	41,	5,	-1
db	-2,	2,	41,	9,	-1
db	-2,	2,	49,	3,	44,	2,	49,	1,	44,	1,	-1
db	-2,	1,	49,	1,	44,	1,	49,	1,	44,	3,	49,	1,	44,	3,	-1
db	-2,	1,	49,	1,	44,	1,	49,	2,	44,	3,	49,	1,	44,	3,	-1
db	-2,	1,	49,	2,	44,	4,	49,	4,	-1
db	-2,	3,	44,	7,	-1
db	-2,	4,	49,	2,	41,	2,	49,	1,	-1
db	-2,	3,	49,	4,	41,	1,	49,	1,	44,	2,	-1
db	-2,	1,	44,	2,	49,	6,	44,	3,	-1
db	44,	3,	41,	1,	49,	5,	44,	2,	-1
db	-2,	1,	49,	2,	41,	7,	-1
db	-2,	1,	49,	1,	41,	8,	-1
db	49,	2,	41,	2,	-2,	2,	41,	3,	-1
db	49,	1,	-2,	4,	49,	3,	-1
db	-2,	6,	49,	3,	-1
db	-1

stepMariob:
db	-2,	4,	41,	5,	-1
db	-2,	1,	41,	9,	-1
db	-2,	3,	44,	1,	49,	1,	44,	2,	49,	3,	-1
db	-2,	1,	44,	3,	49,	1,	44,	3,	49,	1,	44,	1,	49,	1,	-1
db	44,	3,	49,	1,	44,	3,	49,	2,	44,	1,	49,	1,	-1
db	-2,	1,	49,	4,	44,	4,	49,	2,	-1
db	-2,	2,	44,	7,	-1
db	-2,	3,	49,	1,	41,	2,	49,	2,	-1
db	-2,	1,	44,	2,	49,	1,	41,	1,	49,	4,	-1
db	44,	3,	49,	6,	44,	2,	-1
db	-2,	1,	44,	2,	49,	5,	41,	1,	44,	3,	-1
db	-2,	2,	41,	7,	49,	2,	-1
db	-2,	2,	41,	8,	49,	1,	-1
db	-2,	3,	41,	3,	-2,	2,	41,	2,	49,	2,	-1
db	-2,	4,	49,	3,	-2,	4,	49,	1,	-1
db	-2,	3,	49,	3,	-1
db	-1


runMariof:
db	-2,	5,	41,	5,	-1
db	-2,	4,	41,	9,	-1
db	-2,	4,	49,	3,	44,	2,	49,	1,	44,	1,	-1
db	-2,	3,	49,	1,	44,	1,	49,	1,	44,	3,	49,	1,	44,	3,	-1
db	-2,	3,	49,	1,	44,	1,	49,	2,	44,	3,	49,	1,	44,	3,	-1
db	-2,	3,	49,	2,	44,	4,	49,	4,	-1
db	-2,	5,	44,	7,	-1
db	-2,	2,	49,	4,	41,	1,	49,	3,	41,	1,	-1
db	44,	2,	49,	4,	41,	2,	49,	3,	41,	1,	49,	1,	44,	3,	-1
db	44,	3,	-2,	1,	49,	2,	41,	6,	49,	2,	44,	2,	-1
db	44,	2,	-2,	2,	41,	3,	44,	1,	41,	3,	44,	1,	-2,	2,	49,	1,	-1
db	-2,	3,	41,	10,	49,	2,	-1
db	-2,	2,	41,	11,	49,	2,	-1
db	-2,	1,	49,	2,	41,	3,	-2,	4,	41,	3,	49,	2,	-1
db	-2,	1,	49,	3,	-1
db	-2,	2,	49,	3,	-1
db	-1

runMariob:
db	-2,	6,	41,	5,	-1
db	-2,	3,	41,	9,	-1
db	-2,	5,	44,	1,	49,	1,	44,	2,	49,	3,	-1
db	-2,	3,	44,	3,	49,	1,	44,	3,	49,	1,	44,	1,	49,	1,	-1
db	-2,	2,	44,	3,	49,	1,	44,	3,	49,	2,	44,	1,	49,	1,	-1
db	-2,	3,	49,	4,	44,	4,	49,	2,	-1
db	-2,	4,	44,	7,	-1
db	-2,	5,	41,	1,	49,	3,	41,	1,	49,	4,	-1
db	44,	3,	49,	1,	41,	1,	49,	3,	41,	2,	49,	4,	44,	2,	-1
db	44,	2,	49,	2,	41,	6,	49,	2,	-2,	1,	44,	3,	-1
db	-2,	1,	49,	1,	-2,	2,	44,	1,	41,	3,	44,	1,	41,	3,	-2,	2,	44,	2,	-1
db	-2,	1,	49,	2,	41,	10,	-1
db	-2,	1,	49,	2,	41,	11,	-1
db	-2,	1,	49,	2,	41,	3,	-2,	4,	41,	3,	49,	2,	-1
db	-2,	12,	49,	3,	-1
db	-2,	11,	49,	3,	-1
db	-1


shootMariof:
db	-2,	4,	41,	5,	-1
db	-2,	2,	49,	1,	41,	8,	-1
db	-2,	1,	49,	6,	44,	1,	49,	1,	44,	1,	-1
db	44,	2,	49,	1,	44,	2,	49,	1,	44,	6,	-1
db	44,	2,	49,	1,	44,	2,	49,	2,	44,	2,	49,	2,	44,	2,	-1
db	-2,	1,	44,	2,	49,	1,	44,	6,	49,	2,	-1
db	-2,	2,	41,	3,	49,	3,	41,	1,	44,	2,	-1
db	-2,	1,	41,	2,	44,	3,	49,	1,	41,	2,	49,	3,	-1
db	-2,	1,	41,	1,	49,	1,	44,	3,	49,	6,	-1
db	-2,	1,	41,	3,	44,	2,	49,	6,	-1
db	-2,	2,	41,	5,	49,	4,	-1
db	-2,	2,	41,	1,	49,	3,	41,	4,	-1
db	-2,	3,	49,	4,	41,	3,	-1
db	49,	1,	-2,	1,	49,	1,	41,	2,	49,	3,	41,	1,	-1
db	49,	5,	41,	1,	-1
db	-2,	1,	49,	4,	-1
db	-1

shootMariob:
db	-2,	4,	41,	5,	-1
db	-2,	2,	41,	8,	49,	1,	-1
db	-2,	3,	44,	1,	49,	1,	44,	1,	49,	6,	-1
db	-2,	1,	44,	6,	49,	1,	44,	2,	49,	1,	44,	2,	-1
db	44,	2,	49,	2,	44,	2,	49,	2,	44,	2,	49,	1,	44,	2,	-1
db	-2,	1,	49,	2,	44,	6,	49,	1,	44,	2,	-1
db	-2,	2,	44,	2,	41,	1,	49,	3,	41,	3,	-1
db	-2,	1,	49,	3,	41,	2,	49,	1,	44,	3,	41,	2,	-1
db	-2,	1,	49,	6,	44,	3,	49,	1,	41,	1,	-1
db	-2,	1,	49,	6,	44,	2,	41,	3,	-1
db	-2,	2,	49,	4,	41,	5,	-1
db	-2,	3,	41,	4,	49,	3,	41,	1,	-1
db	-2,	3,	41,	3,	49,	4,	-1
db	-2,	4,	41,	1,	49,	3,	41,	2,	49,	1,	-2,	1,	49,	1,	-1
db	-2,	7,	41,	1,	49,	5,	-1
db	-2,	8,	49,	4,	-1
db	-1


airMariof:
db	-2,	13,	44,	3,	-1
db	-2,	6,	41,	5,	-2,	2,	44,	3,	-1
db	-2,	5,	41,	9,	44,	2,	-1
db	-2,	5,	49,	3,	44,	2,	49,	1,	44,	1,	-2,	1,	49,	3,	-1
db	-2,	4,	49,	1,	44,	1,	49,	1,	44,	3,	49,	1,	44,	2,	49,	3,	-1
db	-2,	4,	49,	1,	44,	1,	49,	2,	44,	3,	49,	1,	44,	3,	49,	1,	-1
db	-2,	4,	49,	2,	44,	4,	49,	5,	-1
db	-2,	6,	44,	7,	49,	1,	-1
db	-2,	2,	49,	5,	41,	1,	49,	3,	41,	1,	49,	1,	-1
db	-2,	1,	49,	7,	41,	1,	49,	3,	41,	1,	-2,	2,	49,	1,	-1
db	44,	2,	49,	6,	41,	5,	-2,	2,	49,	1,	-1
db	44,	3,	-2,	1,	41,	2,	49,	1,	41,	2,	44,	1,	41,	2,	44,	1,	41,	1,	49,	2,	-1
db	-2,	1,	44,	1,	-2,	1,	49,	1,	41,	10,	49,	2,	-1
db	-2,	2,	49,	3,	41,	9,	49,	2,	-1
db	-2,	1,	49,	3,	41,	7,	-1
db	-2,	1,	49,	1,	-2,	2,	41,	4,	-1
db	-1

airMariob:
db	44,	3,	-1
db	44,	3,	-2,	2,	41,	5,	-1
db	44,	2,	41,	9,	-1
db	49,	3,	-2,	1,	44,	1,	49,	1,	44,	2,	49,	3,	-1
db	49,	3,	44,	2,	49,	1,	44,	3,	49,	1,	44,	1,	49,	1,	-1
db	49,	1,	44,	3,	49,	1,	44,	3,	49,	2,	44,	1,	49,	1,	-1
db	-2,	1,	49,	5,	44,	4,	49,	2,	-1
db	-2,	2,	49,	1,	44,	7,	-1
db	-2,	3,	49,	1,	41,	1,	49,	3,	41,	1,	49,	5,	-1
db	49,	1,	-2,	2,	41,	1,	49,	3,	41,	1,	49,	7,	-1
db	49,	1,	-2,	2,	41,	5,	49,	6,	44,	2,	-1
db	49,	2,	41,	1,	44,	1,	41,	2,	44,	1,	41,	2,	49,	1,	41,	2,	-2,	1,	44,	3,	-1
db	49,	2,	41,	10,	49,	1,	-2,	1,	44,	1,	-1
db	49,	2,	41,	9,	49,	3,	-1
db	-2,	5,	41,	7,	49,	3,	-1
db	-2,	8,	41,	4,	-2,	2,	49,	1,	-1
db	-1

outMario:
db	-2,	5,	41,	4,	-1
db	-2,	2,	44,	1,	-2,	1,	41,	6,	-2,	1,	44,	1,	-1
db	44,	3,	49,	1,	44,	1,	49,	1,	44,	2,	49,	1,	44,	1,	49,	1,	44,	3,	-1
db	44,	2,	49,	2,	44,	1,	49,	1,	44,	2,	49,	1,	44,	1,	49,	2,	44,	2,	-1
db	44,	2,	49,	3,	44,	4,	49,	3,	44,	2,	-1
db	-2,	2,	49,	4,	44,	2,	49,	2,	-1
db	-2,	3,	49,	1,	44,	1,	49,	4,	44,	1,	49,	1,	-1
db	-2,	3,	49,	1,	44,	6,	49,	1,	-1
db	-2,	2,	41,	3,	44,	4,	41,	3,	-1
db	-2,	1,	49,	2,	41,	2,	49,	4,	41,	2,	49,	2,	-1
db	-2,	1,	49,	3,	41,	2,	49,	2,	41,	2,	49,	3,	-1
db	-2,	1,	49,	3,	41,	1,	44,	1,	41,	2,	44,	1,	41,	1,	49,	3,	-1
db	-2,	1,	49,	3,	41,	6,	49,	3,	-1
db	-2,	2,	49,	2,	41,	6,	49,	2,	-1
db	-1

goombaRight:
db	-2,	6,	45,	4,	-1
db	-2,	5,	45,	6,	-1
db	-2,	4,	45,	8,	-1
db	-2,	3,	45,	10,	-1
db	-2,	2,	45,	1,	0,	2,	45,	6,	0,	2,	45,	1,	-1
db	-2,	1,	45,	3,	35,	1,	0,	1,	45,	4,	0,	1,	35,	1,	45,	3,	-1
db	-2,	1,	45,	3,	35,	1,	0,	6,	35,	1,	45,	3,	-1
db	45,	4,	35,	1,	0,	1,	35,	1,	45,	2,	35,	1,	0,	1,	35,	1,	45,	4,	-1
db	45,	4,	35,	3,	45,	2,	35,	3,	45,	4,	-1
db	45,	16,	-1
db	-2,	1,	45,	4,	35,	6,	45,	4,	-1
db	-2,	4,	35,	8,	-1
db	-2,	4,	35,	8,	0,	2,	-1
db	-2,	3,	0,	2,	35,	5,	0,	5,	-1
db	-2,	3,	0,	3,	35,	3,	0,	6,	-1
db	-2,	4,	0,	2,	-2,	2,	0,	6,	-1
db	-1

goombaLeft:
db	-2,	6,	45,	4,	-1
db	-2,	5,	45,	6,	-1
db	-2,	4,	45,	8,	-1
db	-2,	3,	45,	10,	-1
db	-2,	2,	45,	1,	0,	2,	45,	6,	0,	2,	45,	1,	-1
db	-2,	1,	45,	3,	35,	1,	0,	1,	45,	4,	0,	1,	35,	1,	45,	3,	-1
db	-2,	1,	45,	3,	35,	1,	0,	6,	35,	1,	45,	3,	-1
db	45,	4,	35,	1,	0,	1,	35,	1,	45,	2,	35,	1,	0,	1,	35,	1,	45,	4,	-1
db	45,	4,	35,	3,	45,	2,	35,	3,	45,	4,	-1
db	45,	16,	-1
db	-2,	1,	45,	4,	35,	6,	45,	4,	-1
db	-2,	4,	35,	8,	-1
db	-2,	2,	0,	2,	35,	8,	-1
db	-2,	1,	0,	5,	35,	5,	0,	2,	-1
db	-2,	1,	0,	6,	35,	3,	0,	3,	-1
db	-2,	2,	0,	6,	-2,	2,	0,	2,	-1
db	-1

bowser:
db	-2,	14,	0,	1,	-2,	8,	0,	1,	-2,	2,	0,	2,	-1
db	-2,	13,	0,	1,	16,	1,	0,	1,	-2,	6,	0,	1,	41,	1,	0,	1,	-2,	1,	0,	1,	16,	1,	0,	1,	-1
db	-2,	13,	0,	1,	16,	1,	0,	1,	-2,	3,	0,	1,	-2,	1,	0,	2,	41,	1,	0,	3,	16,	2,	0,	2,	-2,	2,	0,	1,	-1
db	-2,	12,	0,	1,	16,	2,	0,	1,	-2,	2,	0,	1,	41,	1,	0,	1,	41,	5,	0,	1,	16,	1,	51,	1,	0,	1,	41,	1,	0,	2,	41,	1,	0,	1,	-1
db	-2,	12,	0,	1,	16,	2,	57,	1,	0,	2,	41,	8,	0,	1,	16,	1,	51,	2,	0,	1,	41,	2,	0,	3,	-1
db	-2,	12,	0,	1,	16,	2,	57,	1,	42,	1,	0,	1,	41,	3,	0,	5,	16,	2,	51,	1,	57,	1,	0,	1,	41,	1,	0,	3,	41,	1,	0,	1,	-1
db	-2,	12,	0,	1,	16,	2,	42,	1,	0,	5,	58,	4,	42,	1,	16,	2,	51,	1,	57,	1,	0,	1,	41,	4,	0,	1,	-1
db	-2,	11,	0,	3,	42,	1,	0,	1,	58,	5,	0,	3,	58,	1,	42,	2,	51,	1,	57,	1,	0,	1,	41,	4,	0,	1,	-1
db	-2,	10,	0,	1,	41,	2,	0,	2,	58,	1,	57,	1,	58,	3,	0,	1,	41,	3,	0,	2,	42,	3,	0,	1,	41,	4,	0,	1,	-2,	1,	0,	1,	-1
db	-2,	9,	0,	1,	41,	3,	0,	1,	58,	1,	57,	1,	58,	3,	0,	1,	41,	6,	0,	1,	58,	3,	0,	1,	41,	4,	0,	1,	41,	1,	0,	1,	-2,	2,	16,	1,	-1
db	-2,	8,	0,	1,	41,	2,	42,	1,	41,	2,	0,	1,	58,	2,	0,	2,	41,	1,	42,	4,	41,	1,	0,	1,	58,	4,	0,	1,	41,	5,	0,	1,	-2,	3,	16,	1,	-1
db	-2,	9,	0,	1,	42,	1,	58,	1,	42,	1,	41,	2,	0,	2,	41,	2,	42,	1,	16,	2,	0,	5,	58,	4,	0,	1,	41,	4,	0,	1,	-2,	2,	16,	2,	-1
db	-2,	10,	0,	1,	58,	1,	16,	1,	42,	1,	41,	1,	0,	2,	41,	2,	42,	1,	16,	3,	0,	2,	41,	2,	0,	1,	58,	3,	0,	2,	41,	3,	0,	1,	-2,	2,	16,	2,	-1
db	-2,	10,	0,	1,	58,	1,	16,	3,	0,	2,	42,	2,	16,	3,	0,	2,	41,	1,	16,	2,	41,	1,	0,	1,	58,	2,	0,	1,	41,	5,	0,	1,	42,	1,	16,	2,	-2,	3,	16,	1,	-1
db	-2,	10,	0,	7,	16,	2,	57,	1,	58,	1,	0,	2,	41,	4,	16,	1,	41,	1,	0,	1,	58,	1,	0,	3,	41,	3,	0,	1,	42,	3,	-2,	2,	16,	1,	-2,	2,	16,	1,	-1
db	-2,	9,	0,	2,	41,	4,	0,	3,	16,	1,	58,	1,	0,	2,	41,	3,	42,	1,	41,	3,	0,	1,	58,	1,	0,	1,	16,	2,	0,	1,	41,	3,	0,	1,	42,	2,	-2,	1,	42,	1,	16,	1,	-2,	1,16,	2,	-1
db	-2,	8,	0,	2,	41,	1,	16,	1,	41,	5,	0,	4,	41,	2,	42,	1,	0,	2,	42,	1,	41,	2,	42,	1,	0,	1,	16,	2,	51,	2,	0,	2,	41,	1,	0,	3,	42,	2,	0,	1,	16,	3,	-1
db	-2,	8,	0,	1,	41,	1,	16,	1,	41,	11,	42,	1,	0,	1,	16,	1,	0,	1,	42,	1,	41,	2,	42,	1,	0,	1,	16,	2,	51,	2,	0,	4,	51,	2,	0,	2,	42,	1,	16,	2,	-1
db	-2,	7,	0,	2,	41,	1,	0,	2,	41,	3,	0,	2,	41,	4,	42,	1,	0,	4,	42,	1,	41,	1,	42,	2,	0,	1,	51,	3,	16,	3,	0,	2,	57,	2,	0,	1,	42,	3,	16,	1,	-1
db	-2,	7,	0,	1,	41,	3,	0,	1,	41,	3,	0,	1,	41,	5,	42,	1,	0,	2,	42,	2,	0,	1,	41,	1,	42,	2,	0,	1,	57,	1,	51,	5,	16,	2,	0,	1,	58,	1,	57,	1,	0,	1,	42,	3,	-2,	1,	16,	2,	-1
db	-2,	7,	0,	1,	41,	11,	42,	2,	0,	1,	16,	1,	42,	3,	0,	1,	41,	1,	42,	2,	0,	2,	57,	5,	51,	1,	16,	2,	0,	1,	58,	2,	0,	1,	42,	1,	0,	1,	42,	1,	16,	1,	-2,	3,	16,	2,	-1
db	-2,	7,	0,	1,	41,	10,	42,	2,	0,	3,	42,	1,	0,	2,	41,	1,	42,	2,	0,	7,	57,	2,	51,	1,	16,	2,	0,	1,	58,	2,	0,	3,	-2,	2,	16,	3,	-1
db	-2,	7,	0,	1,	42,	1,	41,	3,	42,	3,	41,	2,	42,	2,	0,	1,	16,	2,	42,	1,	0,	1,	41,	3,	42,	2,	0,	9,	57,	1,	51,	1,	16,	2,	0,	1,	58,	3,	0,	1,	42,	1,	16,	3,	-1
db	-2,	8,	0,	1,	42,	3,	0,	2,	42,	4,	0,	1,	16,	3,	42,	1,	0,	1,	41,	2,	42,	1,	0,	12,	57,	1,	51,	1,	16,	1,	0,	1,	58,	3,	0,	1,	42,	1,	16,	2,	-1
db	-2,	8,	0,	1,	16,	2,	0,	1,	-2,	2,	0,	4,	42,	1,	16,	3,	0,	1,	41,	3,	42,	1,	0,	6,	58,	4,	0,	3,	57,	1,	51,	1,	16,	1,	0,	1,	58,	2,	0,	1,	42,	2,	-1
db	-2,	9,	0,	1,	16,	1,	0,	1,	-2,	2,	0,	1,	42,	5,	16,	2,	0,	1,	41,	3,	0,	6,	58,	6,	0,	2,	57,	1,	51,	1,	16,	1,	0,	1,	58,	2,	0,	2,	42,	1,	-2,	1,	16,	3,	-1
db	-2,	10,	0,	2,	-2,	1,	0,	1,	16,	1,	0,	3,	42,	2,	16,	1,	0,	1,	41,	3,	42,	1,	0,	6,	58,	7,	0,	2,	57,	1,	51,	1,	16,	1,	0,	1,	58,	2,	0,	2,	16,	2,	-1
db	-2,	13,	0,	2,	41,	3,	0,	2,	41,	5,	0,	7,	58,	1,	0,	5,	58,	1,	0,	2,	57,	1,	51,	1,	16,	1,	0,	1,	58,	2,	0,	2,	-1
db	-2,	13,	0,	1,	41,	10,	0,	9,	58,	5,	0,	1,	58,	1,	0,	1,	57,	1,	51,	1,	16,	1,	0,	1,	58,	2,	0,	1,	42,	2,	16,	4,	-1
db	-2,	13,	0,	2,	41,	7,	0,	12,	58,	1,	0,	2,	58,	2,	0,	2,	57,	1,	51,	1,	16,	1,	0,	1,	58,	2,	0,	1,	42,	2,	16,	2,	-1
db	-2,	12,	0,	1,	51,	1,	0,	8,	58,	1,	0,	7,	51,	1,	0,	1,	57,	1,	51,	1,	0,	1,	51,	1,	58,	1,	0,	1,	58,	2,	0,	1,	57,	1,	51,	1,	16,	1,	0,	1,	58,	2,	0,	1,	42,	2,	-1
db	-2,	12,	0,	1,	57,	1,	58,	1,	0,	1,	57,	1,	58,	1,	0,	1,	57,	1,	58,	4,	0,	5,	58,	2,	0,	1,	57,	1,	58,	1,	0,	1,	57,	1,	58,	1,	0,	1,	58,	2,	0,	1,	57,	1,	51,	1,	16,	1,	0,	1,	58,	2,	0,	2,	-1
db	-2,	4,	0,	9,	58,	2,	0,	1,	58,	2,	0,	1,	58,	3,	0,	7,	58,	2,	0,	1,	58,	2,	0,	1,	58,	2,	0,	23,	-1
db	-2,	4,	0,	1,	16,	7,	0,	10,	57,	1,	16,	5,	0,	10,	57,	1,	16,	1,	51,	2,	16,	17,	0,	1,	-1
db	-2,	4,	0,	1,	58,	2,	57,	2,	51,	3,	0,	1,	16,	1,	41,	1,	0,	1,	16,	1,	41,	1,	0,	1,	16,	1,	41,	1,	0,	1,	57,	1,	51,	5,	0,	1,	16,	1,	41,	1,	0,	1,	16,	1,	41,	1,	0,	1,	16,	1,	41,	1,	0,	1,	58,	1,	51,	1,	57,	2,	51,	2,	57,	4,	58,	1,	57,	1,	58,	1,	57,	1,	58,	7,	0,	1,	-1
db	-2,	4,	0,	1,	58,	2,	57,	2,	51,	3,	16,	1,	0,	1,	41,	1,	0,	2,	41,	1,	0,	2,	41,	1,	0,	1,	57,	1,	51,	6,	0,	1,	41,	1,	0,	2,	41,	1,	0,	1,	41,	1,	0,	1,	58,	1,	57,	1,	51,	1,	57,	2,	51,	2,	57,	3,	58,	1,	57,	1,	58,	1,	57,	1,	58,	1,	57,	1,	58,	6,	0,	1,	-1
db	-2,	4,	0,	1,	58,	2,	57,	2,	51,	3,	16,	2,	0,	2,	57,	1,	0,	2,	57,	1,	0,	2,	57,	1,	51,	7,	0,	2,	57,	1,	0,	1,	58,	1,	0,	1,	58,	2,	57,	1,	51,	1,	57,	2,	51,	2,	57,	4,	58,	1,	57,	1,	58,	1,	57,	1,	58,	7,	0,	1,	-1
db	-2,	4,	0,	1,	58,	2,	57,	2,	51,	3,	16,	3,	57,	2,	16,	1,	57,	1,	16,	2,	57,	1,	16,	1,	51,	7,	57,	2,	16,	1,	57,	1,	58,	1,	57,	1,	58,	1,	57,	2,	51,	1,	57,	2,	51,	2,	57,	3,	58,	1,	57,	1,	58,	1,	57,	1,	58,	1,	57,	1,	58,	6,	0,	1,	-1
db	-2,	4,	0,	1,	58,	2,	57,	2,	51,	3,	16,	3,	51,	2,	16,	6,	51,	7,	57,	1,	51,	2,	57,	6,	51,	1,	57,	2,	51,	2,	57,	4,	58,	1,	57,	1,	58,	1,	57,	1,	58,	7,	0,	1,	-1
db	-2,	4,	0,	1,	58,	2,	57,	2,	51,	3,	16,	3,	51,	2,	16,	6,	51,	7,	57,	1,	51,	2,	57,	6,	51,	1,	57,	2,	51,	2,	57,	3,	58,	1,	57,	1,	58,	1,	57,	1,	58,	1,	57,	1,	58,	6,	0,	1,	-1
db	-2,	4,	0,	56,	-1
db	-2,	4,	0,	1,	16,	46,	51,	1,	16,	1,	51,	1,	16,	1,	51,	4,	0,	1,	-1
db	-2,	3,	0,	1,	16,	48,	51,	1,	16,	1,	51,	6,	0,	1,	-1
db	-2,	3,	0,	1,	16,	11,	0,	2,	16,	22,	0,	2,	16,	10,	51,	1,	16,	1,	51,	1,	16,	1,	51,	5,	0,	1,	-1
db	-2,	2,	0,	1,	16,	11,	0,	4,	16,	20,	0,	4,	16,	10,	51,	1,	16,	1,	51,	1,	16,	1,	51,	5,	0,	1,	-1
db	-2,	2,	0,	1,	16,	11,	0,	4,	16,	20,	0,	4,	16,	9,	51,	1,	16,	1,	51,	1,	16,	1,	51,	6,	0,	1,	-1
db	-2,	2,	0,	1,	16,	10,	0,	6,	16,	18,	0,	6,	16,	9,	51,	1,	16,	1,	51,	1,	16,	1,	51,	5,	0,	1,	-1
db	-2,	1,	0,	1,	16,	11,	0,	6,	16,	18,	0,	6,	16,	10,	51,	1,	16,	1,	51,	1,	16,	1,	51,	5,	0,	1,	-1
db	-2,	1,	0,	1,	16,	7,	42,	2,	16,	2,	0,	6,	16,	2,	42,	2,	16,	10,	42,	2,	16,	2,	0,	6,	16,	2,	42,	2,	16,	5,	51,	1,	16,	1,	51,	1,	16,	1,	51,	6,	0,	1,	-1
db	-2,	1,	0,	1,	16,	6,	42,	4,	16,	1,	0,	6,	16,	1,	42,	4,	16,	8,	42,	4,	16,	1,	0,	6,	16,	1,	42,	4,	16,	5,	51,	1,	16,	1,	51,	7,	0,	1,	-1
db	-2,	1,	0,	1,	16,	7,	42,	2,	16,	2,	0,	6,	16,	2,	42,	2,	16,	10,	42,	2,	16,	2,	0,	6,	16,	2,	42,	2,	16,	5,	51,	1,	16,	1,	51,	1,	16,	1,	51,	6,	0,	1,	-1
db	0,	1,	16,	12,	0,	6,	16,	18,	0,	6,	16,	10,	51,	1,	16,	1,	51,	1,	16,	1,	51,	6,	0,	1,	-1
db	0,	1,	16,	12,	0,	6,	16,	18,	0,	6,	16,	9,	51,	1,	16,	1,	51,	1,	16,	1,	51,	7,	0,	1,	-1
db	0,	1,	16,	13,	0,	4,	16,	20,	0,	4,	16,	11,	51,	1,	16,	1,	51,	8,	0,	1,	-1
db	0,	1,	16,	14,	0,	2,	16,	22,	0,	2,	16,	11,	51,	1,	16,	1,	51,	1,	16,	1,	51,	7,	0,	1,	-1
db	0,	1,	16,	50,	51,	1,	16,	1,	51,	1,	16,	1,	51,	1,	16,	1,	51,	6,	0,	1,	-1
db	0,	1,	16,	4,	0,	4,	16,	37,	0,	6,	51,	1,	16,	1,	51,	1,	16,	1,	51,	1,	16,	1,	51,	5,	0,	1,	-1
db	0,	1,	16,	3,	0,	1,	41,	4,	0,	2,	16,	33,	0,	2,	41,	5,	42,	1,	0,	2,	16,	1,	51,	8,	0,	1,	-1
db	0,	1,	16,	2,	0,	1,	41,	7,	0,	1,	16,	31,	0,	1,	41,	6,	42,	1,	41,	1,	42,	1,	41,	1,	0,	1,	51,	8,	0,	1,	-1
db	0,	1,	16,	1,	0,	1,	41,	9,	0,	1,	16,	29,	0,	1,	41,	8,	42,	1,	41,	1,	42,	1,	41,	1,	0,	1,	51,	7,	0,	1,	-1
db	0,	1,	16,	1,	0,	1,	41,	9,	0,	1,	16,	29,	0,	1,	41,	7,	42,	1,	41,	1,	42,	1,	41,	1,	42,	2,	0,	1,	51,	6,	0,	1,	-1
db	-2,	1,	0,	2,	41,	1,	0,	2,	41,	7,	0,	1,	16,	27,	0,	1,	41,	7,	42,	1,	0,	2,	41,	1,	42,	3,	0,	1,	51,	5,	0,	1,	-1
db	-2,	1,	0,	1,	41,	2,	0,	1,	41,	8,	0,	1,	16,	27,	0,	1,	41,	8,	42,	1,	0,	1,	42,	1,	41,	1,	42,	3,	0,	1,	51,	4,	0,	1,	-1
db	-2,	1,	0,	1,	41,	2,	0,	1,	41,	8,	0,	1,	16,	27,	0,	1,	41,	7,	42,	1,	41,	1,	0,	1,	41,	1,	42,	1,	41,	1,	42,	2,	0,	1,	51,	4,	0,	1,	-1
db	-2,	1,	0,	1,	41,	2,	0,	1,	41,	9,	0,	1,	16,	25,	0,	1,	41,	7,	42,	1,	41,	1,	42,	1,	0,	1,	42,	1,	41,	1,	42,	3,	0,	1,	51,	4,	0,	1,	-1
db	-2,	2,	0,	1,	41,	2,	0,	1,	41,	8,	0,	1,	16,	25,	0,	1,	41,	8,	42,	1,	0,	1,	42,	1,	41,	1,	42,	5,	0,	1,	51,	2,	0,	1,	-1
db	-2,	2,	0,	1,	41,	2,	0,	1,	41,	9,	0,	1,	16,	23,	0,	1,	41,	8,	42,	1,	41,	1,	0,	1,	41,	1,	42,	6,	0,	1,	51,	2,	0,	1,-1
db	-2,	2,	0,	1,	41,	2,	0,	1,	41,	10,	0,	1,	16,	21,	0,	1,	41,	8,	42,	1,	41,	1,	42,	1,	0,	1,	42,	1,	41,	1,	42,	5,	0,	1,	51,	2,	0,	1,	-1
db	-2,	3,	0,	1,	41,	2,	0,	1,	41,	10,	0,	2,	16,	17,	0,	2,	41,	8,	42,	1,	41,	1,	42,	1,	0,	1,	42,	1,	41,	1,	42,	6,	0,	1,	51,	1,	0,	1,	-1
db	-2,	3,	0,	1,	41,	2,	0,	1,	41,	12,	0,	3,	16,	11,	0,	3,	41,	9,	42,	1,	41,	1,	42,	1,	41,	1,	0,	1,	41,	1,	42,	6,	0,	1,	51,	2,	0,	1,	-1
db	-2,	4,	0,	1,	41,	2,	0,	1,	41,	14,	0,	11,	41,	13,	42,	1,	41,	1,	0,	1,	41,	1,	42,	7,	0,	1,	51,	1,	0,	1,	-1
db	-2,	4,	0,	1,	41,	2,	0,	1,	41,	37,	42,	1,	41,	1,	42,	1,	0,	1,	42,	1,	41,	1,	42,	5,	0,	1,	51,	2,	0,	1,	-1
db	-2,	5,	0,	1,	41,	2,	0,	1,	41,	33,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	0,	1,	42,	1,	41,	1,	42,	6,	0,	1,	51,	1,	0,	1,	-1
db	-2,	6,	0,	1,	41,	2,	0,	1,	41,	31,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	0,	1,	42,	1,	41,	1,	42,	6,	0,	1,	51,	1,	0,	1,	-1
db	-2,	6,	0,	1,	41,	3,	0,	1,	41,	31,	42,	1,	41,	1,	42,	1,	0,	1,	42,	1,	41,	1,	42,	7,	0,	1,	51,	1,	0,	1,	-1
db	-2,	7,	0,	1,	41,	3,	0,	1,	41,	27,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	0,	1,	42,	1,	41,	1,	42,	7,	0,	1,	51,	1,	0,	1,	-1
db	-2,	8,	0,	1,	41,	3,	0,	1,	41,	25,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	0,	1,	42,	1,	41,	1,	42,	8,	0,	2,	-1
db	-2,	9,	0,	1,	41,	3,	0,	2,	41,	22,	42,	1,	41,	1,	42,	1,	41,	1,	0,	2,	42,	1,	41,	1,	42,	8,	0,	2,	-1
db	-2,	10,	0,	1,	41,	4,	0,	2,	41,	17,	42,	1,	41,	1,	42,	1,	41,	1,	0,	3,	41,	1,	42,	11,	0,	1,	-1
db	-2,	11,	0,	1,	41,	5,	0,	4,	41,	12,	42,	1,	0,	4,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	9,	0,	1,	-1
db	-2,	12,	0,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	4,	0,	13,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	11,	0,	1,	-1
db	-2,	13,	0,	2,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	10,	0,	2,	-1
db	-2,	15,	0,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	12,	0,	1,	-1
db	-2,	16,	0,	2,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	13,	0,	2,	-1
db	-2,	18,	0,	2,	42,	3,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	1,	41,	1,	42,	12,	0,	2,	-1
db	-2,	20,	0,	3,	42,	18,	0,	3,	-1
db	-2,	23,	0,	4,	42,	10,	0,	4,	-1
db	-2,	27,	0,	10,	-1
db	-1

fin1:
db	-2,	4,	0,	8,	-2,	5,	0,	1,	16,	1,	58,	3,	0,	1,	-2,	5,	0,	8,	-1
db	-2,	2,	0,	2,	16,	2,	51,	1,	57,	1,	58,	4,	0,	3,	-2,	2,	0,	1,	16,	1,	58,	3,	0,	1,	-2,	2,	0,	3,	16,	4,	51,	1,	57,	1,	51,	1,	57,	1,	0,	2,	-1
db	-2,	1,	0,	1,	57,	1,	51,	1,	0,	1,	58,	1,	0,	1,	58,	1,	0,	1,	58,	1,	0,	1,	58,	4,	0,	3,	51,	1,	58,	3,	0,	3,	51,	1,	16,	2,	57,	1,	51,	1,	57,	1,	51,	1,	57,	1,	51,	1,	57,	1,	51,	1,	57,	1,	58,	1,	0,	1,	-1
db	0,	1,	58,	2,	0,	1,	58,	1,	0,	1,	58,	1,	0,	1,	58,	1,	0,	1,	58,	1,	0,	1,	58,	1,	0,	1,	58,	3,	0,	1,	57,	1,	58,	3,	0,	1,	57,	1,	51,	1,	57,	1,	51,	1,	57,	1,	51,	1,	57,	1,	51,	1,	57,	1,	51,	1,	57,	1,	51,	1,	57,	1,	58,	1,	57,	1,	58,	1,	0,	1,	-1
db	0,	1,	58,	1,	0,	1,	58,	1,	0,	1,	58,	1,	0,	1,	58,	1,	0,	1,	58,	1,	0,	1,	58,	1,	0,	1,	58,	1,	0,	1,	58,	2,	0,	1,	57,	1,	58,	3,	0,	1,	57,	12,	51,	1,	57,	1,	58,	1,	57,	1,	0,	1,	-1
db	-2,	1,	0,	1,	58,	1,	0,	1,	58,	1,	0,	1,	58,	1,	0,	1,	58,	1,	0,	1,	58,	1,	0,	1,	58,	1,	0,	1,	58,	1,	0,	3,	57,	1,	58,	3,	0,	3,	57,	11,	58,	1,	57,	1,	0,	1,	-1
db	-2,	2,	0,	3,	58,	1,	0,	1,	58,	1,	0,	1,	58,	1,	0,	1,	58,	1,	0,	3,	-2,	3,	0,	1,	57,	1,	58,	1,	0,	1,	-2,	3,	0,	3,	57,	8,	0,	2,	-1
db	-2,	4,	0,	8,	-2,	7,	0,	2,	-2,	7,	0,	8,	-1
db	-1

fin2:
db	-2,	12,	0,	3,	-2,	2,	0,	1,	57,	1,	58,	3,	0,	1,	-2,	2,	0,	3,	-1
db	-2,	10,	0,	2,	51,	1,	57,	1,	51,	1,	0,	3,	57,	1,	58,	3,	0,	3,	51,	1,	57,	1,	0,	2,	-1
db	-2,	9,	0,	1,	51,	1,	57,	1,	58,	3,	57,	1,	58,	1,	0,	2,	58,	3,	0,	1,	58,	1,	57,	1,	58,	1,	57,	1,	58,	1,	57,	1,	58,	1,	0,	1,	-1
db	-2,	8,	0,	1,	58,	10,	0,	1,	58,	2,	0,	1,	57,	1,	58,	1,	57,	1,	58,	1,	57,	1,	58,	1,	57,	1,	58,	1,	0,	1,	-1
db	-2,	8,	0,	1,	58,	10,	0,	1,	58,	2,	0,	1,	58,	1,	57,	1,	58,	1,	57,	1,	58,	1,	57,	1,	58,	1,	57,	1,	0,	1,	-1
db	-2,	9,	0,	1,	58,	7,	0,	2,	58,	3,	0,	1,	57,	1,	58,	1,	57,	1,	58,	1,	57,	1,	58,	1,	57,	1,	0,	1,	-1
db	-2,	10,	0,	2,	58,	3,	0,	2,	-2,	1,	0,	1,	57,	1,	58,	1,	0,	1,	-2,	1,	0,	2,	58,	1,	57,	1,	58,	1,	0,	2,	-1
db	-2,	12,	0,	3,	-2,	4,	0,	2,	-2,	4,	0,	3,	-1
db	-1

fin3:
db	-2,	18,	0,	1,	57,	1,	0,	2,	-1
db	-2,	17,	0,	3,	51,	1,	57,	1,	0,	1,	-1
db	-2,	17,	0,	2,	51,	1,	0,	3,	-1
db	-2,	17,	0,	1,	58,	1,	0,	1,	58,	1,	0,	2,	-1
db	-2,	17,	0,	1,	58,	1,	0,	1,	58,	1,	0,	2,	-1
db	-2,	18,	0,	4,	-1
db	-1

fin4:
db	-2,	11,	0,	3,	-2,	2,	0,	1,	58,	3,	57,	1,	0,	1,	-2,	2,	0,	3,	-1
db	-2,	9,	0,	2,	57,	1,	51,	2,	0,	3,	58,	3,	57,	1,	0,	3,	51,	1,	57,	1,	51,	1,	0,	2,	-1
db	-2,	8,	0,	1,	58,	1,	57,	1,	58,	1,	57,	1,	58,	1,	57,	1,	58,	1,	0,	1,	58,	3,	0,	2,	58,	1,	57,	1,	58,	3,	57,	1,	51,	1,	0,	1,	-1
db	-2,	7,	0,	1,	58,	1,	57,	1,	58,	1,	57,	1,	58,	1,	57,	1,	58,	1,	57,	1,	0,	1,	58,	2,	0,	1,	58,	10,	0,	1,	-1
db	-2,	7,	0,	1,	57,	1,	58,	1,	57,	1,	58,	1,	57,	1,	58,	1,	57,	1,	58,	1,	0,	1,	58,	2,	0,	1,	58,	10,	0,	1,	-1
db	-2,	8,	0,	1,	57,	1,	58,	1,	57,	1,	58,	1,	57,	1,	58,	1,	57,	1,	0,	1,	58,	3,	0,	2,	58,	7,	0,	2,	-1
db	-2,	9,	0,	2,	58,	1,	57,	1,	58,	1,	0,	2,	-2,	1,	0,	1,	58,	1,	57,	1,	0,	1,	-2,	1,	0,	2,	58,	3,	0,	2,	-1
db	-2,	11,	0,	3,	-2,	4,	0,	2,	-2,	4,	0,	3,	-1
db	-1

fireBall:
db	-2,	7,	45,	1,	-1
db	-2,	3,	45,	1,	-2,	2,	45,	3,	-2,	2,	45,	1,	-1
db	-2,	2,	45,	2,	-2,	1,	45,	5,	-2,	1,	45,	2,	-1
db	-2,	1,	45,	5,	48,	3,	45,	5,	-1
db	-2,	1,	45,	2,	48,	1,	45,	1,	48,	5,	45,	1,	48,	1,	45,	2,	-1
db	45,	2,	48,	4,	16,	3,	48,	4,	45,	2,	-1
db	45,	2,	48,	3,	16,	5,	48,	3,	45,	2,	-1
db	45,	2,	48,	3,	16,	5,	48,	3,	45,	2,	-1
db	45,	2,	48,	3,	16,	5,	48,	3,	45,	2,	-1
db	45,	3,	48,	3,	16,	3,	48,	3,	45,	3,	-1
db	-2,	1,	45,	3,	48,	7,	45,	3,	-1
db	-2,	1,	45,	3,	48,	7,	45,	3,	-1
db	-2,	2,	45,	4,	48,	3,	45,	4,	-1
db	-2,	3,	45,	9,	-1
db	-2,	5,	45,	5,	-1
db	-1

castle:
db	-2,	23,	48,	1,	-1
db	-2,	22,	48,	3,	-1
db	-2,	23,	48,	1,	-1
db	-2,	23,	41,	1,	16,	11,	-1
db	-2,	23,	41,	1,	16,	5,	41,	1,	16,	5,	-1
db	-2,	23,	41,	1,	16,	5,	41,	1,	16,	5,	-1
db	-2,	23,	41,	1,	16,	2,	41,	7,	16,	2,	-1
db	-2,	23,	41,	1,	16,	3,	41,	5,	16,	3,	-1
db	-2,	23,	41,	1,	16,	4,	41,	3,	16,	4,	-1
db	-2,	23,	41,	1,	16,	3,	41,	2,	16,	1,	41,	2,	16,	3,	-1
db	-2,	23,	41,	1,	16,	3,	41,	1,	16,	3,	41,	1,	16,	3,	-1
db	-2,	23,	41,	1,	16,	11,	-1
db	-2,	23,	41,	1,	-1
db	-2,	23,	41,	1,	-1
db	-2,	23,	41,	1,	-1
db	-2,	23,	41,	1,	-1
db	-2,	20,	35,	7,	-1
db	-2,	20,	35,	1,	45,	5,	35,	1,	-1
db	-2,	20,	35,	1,	45,	5,	35,	1,	-1
db	-2,	20,	35,	1,	45,	5,	35,	1,	-1
db	-2,	20,	35,	1,	45,	5,	35,	1,	-1
db	-2,	20,	35,	1,	45,	5,	35,	1,	-1
db	-2,	20,	35,	1,	0,	5,	35,	1,	-1
db	-2,	16,	45,	3,	0,	1,	45,	7,	0,	1,	45,	3,	-1
db	-2,	16,	45,	3,	0,	1,	45,	7,	0,	1,	45,	3,	-1
db	-2,	16,	45,	3,	0,	1,	45,	7,	0,	1,	45,	3,	-1
db	-2,	16,	0,	15,	-1
db	-2,	16,	45,	7,	0,	1,	45,	7,	-1
db	-2,	7,	35,	5,	-2,	4,	45,	3,	35,	9,	45,	3,	-2,	4,	35,	5,	-1
db	-2,	7,	45,	4,	35,	1,	-2,	4,	45,	3,	35,	1,	45,	7,	35,	1,	45,	3,	-2,	4,	35,	1,	45,	4,	-1
db	-2,	7,	45,	4,	35,	1,	-2,	4,	0,	3,	35,	1,	45,	7,	35,	1,	0,	3,	-2,	4,	35,	1,	45,	4,	-1
db	-2,	7,	45,	4,	35,	1,	-2,	4,	45,	3,	35,	1,	45,	7,	35,	1,	45,	3,	-2,	4,	35,	1,	45,	4,	-1
db	-2,	7,	45,	4,	35,	1,	-2,	4,	45,	3,	35,	1,	45,	7,	35,	1,	45,	3,	-2,	4,	35,	1,	45,	4,	-1
db	-2,	7,	45,	4,	35,	1,	-2,	4,	45,	3,	35,	1,	45,	7,	35,	1,	45,	3,	-2,	4,	35,	1,	45,	4,	-1
db	-2,	7,	45,	4,	35,	1,	-2,	4,	0,	3,	35,	1,	45,	7,	35,	1,	0,	3,	-2,	4,	35,	1,	45,	4,	-1
db	-2,	7,	0,	4,	35,	9,	0,	7,	35,	9,	0,	4,	-1
db	-2,	7,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	-1
db	-2,	7,	0,	1,	45,	5,	0,	7,	45,	3,	0,	1,	45,	3,	0,	7,	45,	5,	0,	1,	-1
db	-2,	7,	0,	1,	45,	5,	0,	7,	45,	3,	0,	1,	45,	3,	0,	7,	45,	5,	0,	1,	-1
db	-2,	7,	0,	33,	-1
db	-2,	7,	45,	4,	0,	1,	45,	1,	0,	7,	45,	7,	0,	7,	45,	1,	0,	1,	45,	4,	-1
db	-2,	7,	45,	4,	0,	1,	45,	1,	0,	7,	45,	7,	0,	7,	45,	1,	0,	1,	45,	4,	-1
db	-2,	7,	45,	4,	0,	1,	45,	1,	0,	7,	45,	7,	0,	7,	45,	1,	0,	1,	45,	4,	-1
db	-2,	7,	0,	33,	-1
db	-2,	7,	0,	1,	45,	5,	0,	7,	45,	3,	0,	1,	45,	3,	0,	7,	45,	5,	0,	1,	-1
db	-2,	7,	0,	1,	45,	5,	0,	7,	45,	3,	0,	1,	45,	3,	0,	7,	45,	5,	0,	1,	-1
db	-2,	7,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	-1
db	-2,	7,	0,	33,	-1
db	35,	4,	-2,	3,	45,	4,	35,	9,	45,	7,	35,	9,	45,	4,	-2,	3,	35,	4,	-1
db	45,	3,	35,	1,	-2,	3,	45,	4,	35,	1,	45,	7,	35,	1,	45,	7,	35,	1,	45,	7,	35,	1,	45,	4,	-2,	3,	35,	1,	45,	3,	-1
db	45,	3,	35,	1,	-2,	3,	45,	4,	35,	1,	45,	7,	35,	1,	45,	7,	35,	1,	45,	7,	35,	1,	45,	4,	-2,	3,	35,	1,	45,	3,	-1
db	45,	3,	35,	1,	-2,	3,	0,	4,	35,	1,	45,	7,	35,	1,	0,	7,	35,	1,	45,	7,	35,	1,	0,	4,	-2,	3,	35,	1,	45,	3,	-1
db	45,	3,	35,	1,	-2,	3,	0,	1,	45,	3,	35,	1,	45,	7,	35,	1,	45,	7,	35,	1,	45,	7,	35,	1,	45,	3,	0,	1,	-2,	3,	35,	1,	45,	3,	-1
db	45,	3,	35,	1,	-2,	3,	0,	1,	45,	3,	35,	1,	45,	7,	35,	1,	45,	7,	35,	1,	45,	7,	35,	1,	45,	3,	0,	1,	-2,	3,	35,	1,	45,	3,	-1
db	45,	3,	35,	1,	-2,	3,	0,	1,	45,	3,	35,	1,	45,	7,	35,	1,	45,	7,	35,	1,	45,	7,	35,	1,	45,	3,	0,	1,	-2,	3,	35,	1,	45,	3,	-1
db	0,	3,	35,	9,	0,	7,	35,	9,	0,	7,	35,	9,	0,	3,	-1
db	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	-1
db	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	-1
db	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	-1
db	0,	47,	-1
db	45,	3,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	3,	-1
db	45,	3,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	3,	-1
db	45,	3,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	7,	0,	1,	45,	3,	-1
db	0,	47,	-1
db	45,	7,	0,	1,	45,	7,	0,	1,	45,	5,	0,	5,	45,	5,	0,	1,	45,	7,	0,	1,	45,	7,	-1
db	45,	7,	0,	1,	45,	7,	0,	1,	45,	3,	0,	9,	45,	3,	0,	1,	45,	7,	0,	1,	45,	7,	-1
db	45,	7,	0,	1,	45,	7,	0,	1,	45,	2,	0,	11,	45,	2,	0,	1,	45,	7,	0,	1,	45,	7,	-1
db	0,	47,	-1
db	45,	3,	0,	1,	45,	7,	0,	1,	45,	5,	0,	13,	45,	5,	0,	1,	45,	7,	0,	1,	45,	3,	-1
db	45,	3,	0,	1,	45,	7,	0,	1,	45,	4,	0,	15,	45,	4,	0,	1,	45,	7,	0,	1,	45,	3,	-1
db	45,	3,	0,	1,	45,	7,	0,	1,	45,	4,	0,	15,	45,	4,	0,	1,	45,	7,	0,	1,	45,	3,	-1
db	0,	47,	-1
db	45,	7,	0,	1,	45,	7,	0,	17,	45,	7,	0,	1,	45,	7,	-1
db	45,	7,	0,	1,	45,	7,	0,	17,	45,	7,	0,	1,	45,	7,	-1
db	45,	7,	0,	1,	45,	7,	0,	17,	45,	7,	0,	1,	45,	7,	-1
db	0,	47,	-1
db	45,	3,	0,	1,	45,	7,	0,	1,	45,	3,	0,	17,	45,	3,	0,	1,	45,	7,	0,	1,	45,	3,	-1
db	45,	3,	0,	1,	45,	7,	0,	1,	45,	3,	0,	17,	45,	3,	0,	1,	45,	7,	0,	1,	45,	3,	-1
db	45,	3,	0,	1,	45,	7,	0,	1,	45,	3,	0,	17,	45,	3,	0,	1,	45,	7,	0,	1,	45,	3,	-1
db	0,	47,	-1
db	45,	7,	0,	1,	45,	7,	0,	17,	45,	7,	0,	1,	45,	7,	-1
db	45,	7,	0,	1,	45,	7,	0,	17,	45,	7,	0,	1,	45,	7,	-1
db	45,	7,	0,	1,	45,	7,	0,	17,	45,	7,	0,	1,	45,	7,	-1
db	0,	47,	-1
db	45,	3,	0,	1,	45,	7,	0,	1,	45,	3,	0,	17,	45,	3,	0,	1,	45,	7,	0,	1,	45,	3,	-1
db	45,	3,	0,	1,	45,	7,	0,	1,	45,	3,	0,	17,	45,	3,	0,	1,	45,	7,	0,	1,	45,	3,	-1
db	45,	3,	0,	1,	45,	7,	0,	1,	45,	3,	0,	17,	45,	3,	0,	1,	45,	7,	0,	1,	45,	3,	-1
db	0,	47,	-1
db	0,	47,	-1
db	-1

pipeUpper1:
db	0,	28,	-1
db	0,	1,	52,	26,	0,	1,	-1
db	0,	1,	52,	3,	53,	2,	52,	5,	53,	16,	0,	1,	-1
db	0,	1,	52,	3,	53,	2,	52,	5,	53,	1,	52,	2,	53,	7,	52,	1,	53,	1,	52,	1,	53,	1,	52,	2,	0,	1,	-1
db	-1

pipeUpper2:
db	0,	1,	52,	3,	53,	2,	52,	5,	53,	1,	52,	2,	53,	8,	52,	1,	53,	1,	52,	3,	0,	1,	-1
db	0,	1,	52,	3,	53,	2,	52,	5,	53,	1,	52,	2,	53,	7,	52,	1,	53,	1,	52,	1,	53,	1,	52,	2,	0,	1,	-1
db	-1

pipeUpper3:
db	0,	28,	-1
db	-1

pipeLower1:
db	0,	24,	-1
db	-1

pipeLower2:
db	0,	1,	52,	3,	53,	2,	52,	4,	53,	1,	52,	2,	53,	5,	52,	1,	53,	1,	52,	3,	0,	1,	-1
db	0,	1,	52,	3,	53,	2,	52,	4,	53,	1,	52,	2,	53,	6,	52,	1,	53,	1,	52,	2,	0,	1,	-1
db	-1

poleKnob:
db	-2,	2,	0,	4,	-1
db	-2,	1,	0,	1,	52,	1,	54,	3,	0,	1,	-1
db	0,	1,	52,	1,	54,	5,	0,	1,	-1
db	0,	1,	52,	1,	54,	5,	0,	1,	-1
db	0,	1,	54,	6,	0,	1,	-1
db	0,	1,	54,	6,	0,	1,	-1
db	-2,	1,	0,	1,	54,	4,	0,	1,	-1
db	-2,	2,	0,	4,	-1
db	-1

pole:
db	52,	2,	-1
db	-1

flag:
db	16,	16,	-1
db	-2,	1,	16,	8,	54,	5,	16,	2,	-1
db	-2,	2,	16,	6,	54,	2,	16,	1,	54,	1,	16,	1,	54,	2,	16,	1,	-1
db	-2,	3,	16,	5,	54,	1,	16,	2,	54,	1,	16,	2,	54,	1,	16,	1,	-1
db	-2,	4,	16,	4,	54,	1,	16,	1,	54,	3,	16,	1,	54,	1,	16,	1,	-1
db	-2,	5,	16,	3,	54,	3,	16,	1,	54,	3,	16,	1,	-1
db	-2,	6,	16,	2,	54,	7,	16,	1,	-1
db	-2,	7,	16,	3,	54,	3,	16,	3,	-1
db	-2,	8,	16,	8,	-1
db	-2,	9,	16,	7,	-1
db	-2,	10,	16,	6,	-1
db	-2,	11,	16,	5,	-1
db	-2,	12,	16,	4,	-1
db	-2,	13,	16,	3,	-1
db	-2,	14,	16,	2,	-1
db	-2,	15,	16,	1,	-1
db 	-1

cloud:
db	-2,	14,	0, 4,	-2,	12,	0, 4,	-1
db	-2,	13,	0,	1,	16,	4,	0,	1,	-2,	10,	0,	1,	16,	4,	0,	1,	-1
db	-2,	11,	0,	2,	16,	6,	0,	1,	-2,	7,	0,	2,	16,	6,	0,	1,	-1
db	-2,	10,	0,	1,	16,	8,	0,	1,	-2,	1,	0,	1,	-2,	4,	0,	1,	16,	8,	0,	1,	-2,	1,	0,	1,	-1
db	-2,	10,	0,	1,	16,	9,	0,	1,	16,	1,	0,	1,	-2,	3,	0,	1,	16,	9,	0,	1,	16,	1,	0,	1,	-1
db	-2,	10,	0,	1,	16,	6,	20,	1,	16,	5,	0,	1,	-2,	2,	0,	1,	16,	6,	20,	1,	16,	5,	0,	1,	-1
db	-2,	9,	0,	1,	16,	3,	20,	2,	16,	3,	20,	1,	16,	4,	0,	1,	-2,	1,	0,	1,	16,	3,	20,	2,	16,	3,	20,	1,	16,	4,	0,	1,	-1
db	-2,	8,	0,	1,	16,	3,	20,	1,	16,	10,	0,	1,	0,	1,	16,	3,	20,	1,	16,	10,	0,	1,	-1
db	-2,	5,	0,	3,	16,	32,	0,	1,	-2,	2,	0,	1,	-1
db	-2,	4,	0,	1,	16,	35,	0,	1,	-2,	1,	0,	1,	16,	1,	0,	1,	-1
db	-2,	3,	0,	1,	16,	37,	0,	1,	16,	2,	0,	1,	-1
db	-2,	3,	16,	41,	0,	1,	-2,	1,	0,	1,	-1
db	-2,	1,	0,	2,	16,	42,	0,	1,	16,	1,	0,	1,	-1
db	0,	1,	16,	46,	0,	1,	-1
db	0,	1,	16,	46,	0,	1,	-1
db	-2,	1,	0,	1,	16,	44,	0,	1,	-1
db	-2,	2,	0,	1,	16,	2,	20,	1,	16,	11,	20,	1,	16,	15,	20,	1,	16,	11,	0,	1,	-1
db	-2,	3,	0,	1,	16,	2,	20,	1,	16,	2,	20,	1,	16,	6,	20,	1,	16,	8,	20,	1,	16,	6,	20,	1,	16,	13,	0,	1,	-1
db	-2,	4,	0,	1,	16,	2,	20,	4,	16,	3,	20,	4,	16,	4,	20,	1,	16,	1,	20,	3,	16,	3,	20,	4,	16,	4,	20,	1,	16,	8,	0,	1,	-1
db	-2,	4,	0,	1,	16,	5,	20,	6,	16,	1,	20,	5,	16,	4,	20,	6,	16,	1,	20,	5,	16,	9,	-1
db	-2,	5,	0,	3,	16,	4,	20,	2,	16,	4,	20,	3,	16,	7,	20,	2,	16,	4,	20,	3,	16,	8,	0,	2,	-1
db	-2,	8,	0,	1,	16,	6,	0,	1,	16,	8,	0,	1,	16,	6,	0,	1,	16,	8,	0,	1,	16,	2,	0,	2,	-1
db	-2,	9,	0,	2,	16,	3,	0,	1,	-2,	1,	0,	2,	16,	4,	0,	2,	-2,	1,	0,	2,	16,	3,	0,	1,	-2,	1,	0,	2,	16,	4,	0,	2,	-2,	1,	0,	2,	-1
db	-2,	11,	0,	3,	-2,	4,	0,	4,	-2,	5,	0,	3,	-2,	4,	0,	4,	-1
db	-1


bush:
db	-2,	14,	0, 4,	-2,	12,	0, 4,	-1
db	-2,	13,	0,	1,	52,	4,	0,	1,	-2,	10,	0,	1,	52,	4,	0,	1,	-1
db	-2,	11,	0,	2,	52,	6,	0,	1,	-2,	7,	0,	2,	52,	6,	0,	1,	-1
db	-2,	10,	0,	1,	52,	8,	0,	1,	-2,	1,	0,	1,	-2,	4,	0,	1,	52,	8,	0,	1,	-2,	1,	0,	1,	-1
db	-2,	10,	0,	1,	52,	9,	0,	1,	52,	1,	0,	1,	-2,	3,	0,	1,	52,	9,	0,	1,	52,	1,	0,	1,	-1
db	-2,	10,	0,	1,	52,	6,	57,	1,	52,	5,	0,	1,	-2,	2,	0,	1,	52,	6,	57,	1,	52,	5,	0,	1,	-1
db	-2,	9,	0,	1,	52,	3,	57,	2,	52,	3,	57,	1,	52,	4,	0,	1,	-2,	1,	0,	1,	52,	3,	57,	2,	52,	3,	57,	1,	52,	4,	0,	1,	-1
db	-2,	8,	0,	1,	52,	3,	57,	1,	52,	10,	0,	1,	0,	1,	52,	3,	57,	1,	52,	10,	0,	1,	-1
db	-2,	5,	0,	3,	52,	32,	0,	1,	-2,	2,	0,	1,	-1
db	-2,	4,	0,	1,	52,	35,	0,	1,	-2,	1,	0,	1,	52,	1,	0,	1,	-1
db	-2,	3,	0,	1,	52,	37,	0,	1,	52,	2,	0,	1,	-1
db	-2,	3,	52,	41,	0,	1,	-2,	1,	0,	1,	-1
db	-2,	1,	0,	2,	52,	42,	0,	1,	52,	1,	0,	1,	-1
db	0,	1,	52,	46,	0,	1,	-1
db	0,	1,	52,	46,	0,	1,	-1
db	-2,	1,	0,	1,	52,	44,	0,	1,	-1
db	-1


mount:
db	-2,	22,	0,	6,	-1
db	-2,	19,	0,	3,	54,	6,	0,	3,	-1
db	-2,	17,	0,	2,	54,	12,	0,	2,	-1
db	-2,	16,	0,	1,	54,	13,	0,	1,	54,	2,	0,	1,	-1
db	-2,	15,	0,	1,	54,	13,	0,	3,	54,	2,	0,	1,	-1
db	-2,	14,	0,	1,	54,	14,	0,	3,	54,	3,	0,	1,	-1
db	-2,	13,	0,	1,	54,	15,	0,	3,	54,	4,	0,	1,	-1
db	-2,	12,	0,	1,	54,	13,	0,	2,	54,	1,	0,	3,	54,	5,	0,	1,	-1
db	-2,	11,	0,	1,	54,	14,	0,	2,	54,	2,	0,	1,	54,	7,	0,	1,	-1
db	-2,	10,	0,	1,	54,	15,	0,	2,	54,	11,	0,	1,	-1
db	-2,	9,	0,	1,	54,	16,	0,	2,	54,	12,	0,	1,	-1
db	-2,	8,	0,	1,	54,	32,	0,	1,	-1
db	-2,	7,	0,	1,	54,	34,	0,	1,	-1
db	-2,	6,	0,	1,	54,	36,	0,	1,	-1
db	-2,	5,	0,	1,	54,	38,	0,	1,	-1
db	-2,	4,	0,	1,	54,	40,	0,	1,	-1
db	-2,	3,	0,	1,	54,	42,	0,	1,	-1
db	-2,	2,	0,	1,	54,	44,	0,	1,	-1
db	-2,	1,	0,	1,	54,	46,	0,	1,	-1
db	0,	1,	54,	48,	0,	1,	-1
db	-1


block1:
db	45,	1,	35,	14,	0,	1,	-1
db	35,	1,	45,	1,	35,	12,	0,	2,	-1
db	35,	2,	45,	1,	35,	10,	0,	3,	-1
db	35,	3,	45,	1,	35,	8,	0,	4,	-1
db	35,	4,	45,	8,	0,	4,	-1
db	35,	4,	45,	8,	0,	4,	-1
db	35,	4,	45,	8,	0,	4,	-1
db	35,	4,	45,	8,	0,	4,	-1
db	35,	4,	45,	8,	0,	4,	-1
db	35,	4,	45,	8,	0,	4,	-1
db	35,	4,	45,	8,	0,	4,	-1
db	35,	4,	45,	8,	0,	4,	-1
db	35,	3,	0,	9,	45,	1,	0,	3,	-1
db	35,	2,	0,	11,	45,	1,	0,	2,	-1
db	35,	1,	0,	13,	45,	1,	0,	1,	-1
db	0,	15,	45,	1,	-1
db	-1

block2:
db	45,	1,	35,	8,	0,	1,	45,	1,	35,	4,	45,	1,	-1
db	35,	1,	45,	8,	0,	1,	35,	1,	45,	4,	0,	1,	-1
db	35,	1,	45,	8,	0,	1,	35,	1,	45,	4,	0,	1,	-1
db	35,	1,	45,	8,	0,	1,	35,	1,	45,	4,	0,	1,	-1
db	35,	1,	45,	8,	0,	1,	35,	1,	0,	1,	45,	3,	0,	1,	-1
db	35,	1,	45,	8,	0,	1,	45,	1,	0,	4,	45,	1,	-1
db	35,	1,	45,	8,	0,	1,	35,	5,	0,	1,	-1
db	35,	1,	45,	8,	0,	1,	35,	1,	45,	4,	0,	1,	-1
db	35,	1,	45,	8,	0,	1,	35,	1,	45,	4,	0,	1,	-1
db	35,	1,	45,	8,	0,	1,	35,	1,	45,	4,	0,	1,	-1
db	0,	2,	45,	6,	0,	1,	35,	1,	45,	5,	0,	1,	-1
db	35,	2,	0,	2,	45,	4,	0,	1,	35,	1,	45,	5,	0,	1,	-1
db	35,	1,	45,	1,	35,	2,	0,	4,	35,	1,	45,	6,	0,	1,	-1
db	35,	1,	45,	3,	35,	3,	0,	1,	35,	1,	45,	6,	0,	1,	-1
db	35,	1,	45,	6,	0,	1,	35,	1,	45,	5,	0,	2,	-1
db	45,	1,	0,	6,	45,	1,	35,	1,	0,	6,	45,	1,	-1
db	-1

;NES Color Palette RGB
pal:
db	62,	62,	62	;16
db	47,	47,	47	;17
db	31,	31,	31	;18
db	41,	57,	63	;19
db	15,	47,	63	;20
db	0,	30,	62	;21
db	0,	0,	63	;22
db	46,	46,	62	;23
db	26,	34,	63	;24
db	0,	22,	62	;25
db	0,	0,	47	;26
db	54,	46,	62	;27
db	38,	30,	62	;28
db	26,	17,	63	;29
db	17,	10,	47	;30
db	62,	46,	62	;31
db	62,	30,	62	;32
db	54,	0,	51	;33
db	37,	0,	33	;34
db	62,	41,	48	;35
db	62,	22,	38	;36
db	57,	0,	22	;37
db	42,	0,	8	;38
db	60,	52,	44	;39
db	62,	30,	22	;40
db	62,	14,	0	;41
db	42,	4,	0	;42
db	63,	56,	42	;43
db	63,	40,	17	;44
db	57,	23,	4	;45
db	34,	5,	0	;46
db	62,	54,	30	;47
db	62,	46,	0	;48
db	43,	31,	0	;49
db	20,	12,	0	;50
db	54,	62,	30	;51
db	46,	62,	6	;52
db	0,	46,	0	;53
db	0,	30,	0	;54
db	46,	62,	46	;55
db	22,	54,	21	;56
db	0,	42,	0	;57
db	0,	26,	0	;58
db	46,	62,	54	;59
db	22,	62,	38	;60
db	0,	42,	17	;61
db	0,	22,	0	;62
db	0,	63,	63	;63
db	0,	58,	54	;64
db	0,	34,	34	;65
db	0,	16,	22	;66
db	62,	54,	62	;67
db	30,	30,	30	;68


mario_note:
dw	0,	0,	0,	0,	0,	0,	0,	0,	1917,	0,	-1,	1917,	0,	-1,	0,	0
dw	0,	1917,	0,	-1,	0,	0,	0,	2415,	0,	-1,	1917,	0,	-1,	0,	0,	0
dw	1612,	0,	-1,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0
dw	0,	0,	0,	0,	0,	0,	0,	0,	2415,	0,	-1,	0,	0,	0,	0,	0
dw	0,	3224,	0,	-1,	0,	0,	0,	0,	0,	0,	3835,	0,	-1,	0,	0,	0
dw	0,	0,	0,	2873,	0,	-1,	0,	0,	0,	2559,	0,	-1,	0,	0,	0,	2711
dw	0,	-1,	2873,	0,	-1,	0,	0,	0,	3224,	0,	-1,	0,	1917,	0,	-1,	0
dw	1612,	0,	-1,	0,	1436,	0,	-1,	0,	0,	0,	1917,	0,	-1,	1612,	0,	-1
dw	0,	0,	0,	1917,	0,	-1,	0,	0,	0,	2415,	0,	-1,	2152,	0,	-1,	2559
dw	0,	-1,	0,	0,	0,	0,	0,	0,	2415,	0,	-1,	0,	0,	0,	0,	0
dw	0,	3224,	0,	-1,	0,	0,	0,	0,	0,	0,	3835,	0,	-1,	0,	0,	0
dw	0,	0,	0,	2873,	0,	-1,	0,	0,	0,	2559,	0,	-1,	0,	0,	0,	2711
dw	0,	-1,	2873,	0,	-1,	0,	0,	0,	3224,	0,	-1,	0,	1917,	0,	-1,	0
dw	1612,	0,	-1,	0,	1436,	0,	-1,	0,	0,	0,	1917,	0,	-1,	1612,	0,	-1
dw	0,	0,	0,	1917,	0,	-1,	0,	0,	0,	2415,	0,	-1,	2152,	0,	-1,	2559
dw	0,	-1,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	1612,	0
dw	-1,	1708,	0,	-1,	1917,	0,	-1,	2031,	0,	-1,	0,	0,	0,	1917,	0,	-1
dw	0,	0,	0,	3043,	0,	-1,	2873,	0,	-1,	2415,	0,	-1,	0,	0,	0,	2873
dw	0,	-1,	2415,	0,	-1,	2152,	0,	-1,	0,	0,	0,	0,	0,	0,	1612,	0
dw	-1,	1708,	0,	-1,	1917,	0,	-1,	2031,	0,	-1,	0,	0,	0,	1917,	0,	-1
dw	0,	0,	0,	1207,	0,	-1,	0,	0,	0,	1207,	0,	-1,	1207,	0,	-1,	0
dw	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	1612,	0
dw	-1,	1708,	0,	-1,	1917,	0,	-1,	2031,	0,	-1,	0,	0,	0,	1917,	0,	-1
dw	0,	0,	0,	3043,	0,	-1,	2873,	0,	-1,	2415,	0,	-1,	0,	0,	0,	2873
dw	0,	-1,	2415,	0,	-1,	2152,	0,	-1,	0,	0,	0,	0,	0,	0,	2031,	0
dw	-1,	0,	0,	0,	0,	0,	0,	2152,	0,	-1,	0,	0,	0,	0,	0,	0
dw	2415,	0,	-1,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0
dw	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	1612,	0
dw	-1,	1708,	0,	-1,	1917,	0,	-1,	2031,	0,	-1,	0,	0,	0,	1917,	0,	-1
dw	0,	0,	0,	3043,	0,	-1,	2873,	0,	-1,	2415,	0,	-1,	0,	0,	0,	2873
dw	0,	-1,	2415,	0,	-1,	2152,	0,	-1,	0,	0,	0,	0,	0,	0,	1612,	0
dw	-1,	1708,	0,	-1,	1917,	0,	-1,	2031,	0,	-1,	0,	0,	0,	1917,	0,	-1
dw	0,	0,	0,	1207,	0,	-1,	0,	0,	0,	1207,	0,	-1,	1207,	0,	-1,	0
dw	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	1612,	0
dw	-1,	1708,	0,	-1,	1917,	0,	-1,	2031,	0,	-1,	0,	0,	0,	1917,	0,	-1
dw	0,	0,	0,	3043,	0,	-1,	2873,	0,	-1,	2415,	0,	-1,	0,	0,	0,	2873
dw	0,	-1,	2415,	0,	-1,	2152,	0,	-1,	0,	0,	0,	0,	0,	0,	2031,	0
dw	-1,	0,	0,	0,	0,	0,	0,	2152,	0,	-1,	0,	0,	0,	0,	0,	0
dw	2415,	0,	-1,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0
dw	0,	0,	0,	0,	0,	0,	0,	0,	2415,	0,	-1,	2415,	0,	-1,	0,	0
dw	0,	2415,	0,	-1,	0,	0,	0,	2415,	0,	-1,	2152,	0,	-1,	0,	0,	0
dw	1917,	0,	-1,	2415,	0,	-1,	0,	0,	0,	2873,	0,	-1,	3224,	0,	-1,	0
dw	0,	0,	0,	0,	0,	0,	0,	0,	2415,	0,	-1,	2415,	0,	-1,	0,	0
dw	0,	2415,	0,	-1,	0,	0,	0,	2415,	0,	-1,	2152,	0,	-1,	1917,	0,	-1
dw	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0
dw	0,	0,	0,	0,	0,	0,	0,	0,	2415,	0,	-1,	2415,	0,	-1,	0,	0
dw	0,	2415,	0,	-1,	0,	0,	0,	2415,	0,	-1,	2152,	0,	-1,	0,	0,	0
dw	1917,	0,	-1,	2415,	0,	-1,	0,	0,	0,	2873,	0,	-1,	3224,	0,	-1,	0
dw	0,	0,	0,	0,	0,	0,	0,	0,	1917,	0,	-1,	1917,	0,	-1,	0,	0
dw	0,	1917,	0,	-1,	0,	0,	0,	2415,	0,	-1,	1917,	0,	-1,	0,	0,	0
dw	1612,	0,	-1,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0
dw	0,	0,	0,	0,	0,	0,	0,	0,	2415,	0,	-1,	0,	0,	0,	0,	0
dw	0,	3224,	0,	-1,	0,	0,	0,	0,	0,	0,	3835,	0,	-1,	0,	0,	0
dw	0,	0,	0,	2873,	0,	-1,	0,	0,	0,	2559,	0,	-1,	0,	0,	0,	2711
dw	0,	-1,	2873,	0,	-1,	0,	0,	0,	3224,	0,	-1,	0,	1917,	0,	-1,	0
dw	1612,	0,	-1,	0,	1436,	0,	-1,	0,	0,	0,	1917,	0,	-1,	1612,	0,	-1
dw	0,	0,	0,	1917,	0,	-1,	0,	0,	0,	2415,	0,	-1,	2152,	0,	-1,	2559
dw	0,	-1,	0,	0,	0,	0,	0,	0,	2415,	0,	-1,	0,	0,	0,	0,	0
dw	0,	3224,	0,	-1,	0,	0,	0,	0,	0,	0,	3835,	0,	-1,	0,	0,	0
dw	0,	0,	0,	2873,	0,	-1,	0,	0,	0,	2559,	0,	-1,	0,	0,	0,	2711
dw	0,	-1,	2873,	0,	-1,	0,	0,	0,	3224,	0,	-1,	0,	1917,	0,	-1,	0
dw	1612,	0,	-1,	0,	1436,	0,	-1,	0,	0,	0,	1917,	0,	-1,	1612,	0,	-1
dw	0,	0,	0,	1917,	0,	-1,	0,	0,	0,	2415,	0,	-1,	2152,	0,	-1,	2559
dw	0,	-1,	0,	0,	0,	0,	0,	0,	1917,	0,	-1,	2415,	0,	-1,	0,	0
dw	0,	3224,	0,	-1,	0,	0,	0,	0,	0,	0,	3043,	0,	-1,	0,	0,	0
dw	2873,	0,	-1,	1917,	0,	-1,	0,	0,	0,	1917,	0,	-1,	2873,	0,	-1,	0
dw	0,	0,	0,	0,	0,	0,	0,	0,	2559,	0,	-1,	0,	1436,	0,	-1,	0
dw	1436,	0,	-1,	0,	1436,	0,	-1,	0,	1612,	0,	-1,	0,	1917,	0,	-1,	0
dw	1917,	0,	-1,	2415,	0,	-1,	0,	0,	0,	2873,	0,	-1,	3224,	0,	-1,	0
dw	0,	0,	0,	0,	0,	0,	0,	0,	1917,	0,	-1,	2415,	0,	-1,	0,	0
dw	0,	3224,	0,	-1,	0,	0,	0,	0,	0,	0,	3043,	0,	-1,	0,	0,	0
dw	2873,	0,	-1,	1917,	0,	-1,	0,	0,	0,	1917,	0,	-1,	2873,	0,	-1,	0
dw	0,	0,	0,	0,	0,	0,	0,	0,	2559,	0,	-1,	1917,	0,	-1,	0,	0
dw	0,	1917,	0,	-1,	1917,	0,	-1,	0,	1917,	0,	-1,	0,	2152,	0,	-1,	0
dw	2415,	0,	-1,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0
dw	0,	0,	0,	0,	0,	0,	0,	0,	1917,	0,	-1,	2415,	0,	-1,	0,	0
dw	0,	3224,	0,	-1,	0,	0,	0,	0,	0,	0,	3043,	0,	-1,	0,	0,	0
dw	2873,	0,	-1,	1917,	0,	-1,	0,	0,	0,	1917,	0,	-1,	2873,	0,	-1,	0
dw	0,	0,	0,	0,	0,	0,	0,	0,	2559,	0,	-1,	0,	1436,	0,	-1,	0
dw	1436,	0,	-1,	0,	1436,	0,	-1,	0,	1612,	0,	-1,	0,	1917,	0,	-1,	0
dw	1917,	0,	-1,	2415,	0,	-1,	0,	0,	0,	2873,	0,	-1,	3224,	0,	-1,	0
dw	0,	0,	0,	0,	0,	0,	0,	0,	1917,	0,	-1,	2415,	0,	-1,	0,	0
dw	0,	3224,	0,	-1,	0,	0,	0,	0,	0,	0,	3043,	0,	-1,	0,	0,	0
dw	2873,	0,	-1,	1917,	0,	-1,	0,	0,	0,	1917,	0,	-1,	2873,	0,	-1,	0
dw	0,	0,	0,	0,	0,	0,	0,	0,	2559,	0,	-1,	1917,	0,	-1,	0,	0
dw	0,	1917,	0,	-1,	1917,	0,	-1,	0,	1917,	0,	-1,	0,	2152,	0,	-1,	0
dw	2415,	0,	-1,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0
dw	0,	0,	0,	0,	0,	0,	0,	0,	2415,	0,	-1,	2415,	0,	-1,	0,	0
dw	0,	2415,	0,	-1,	0,	0,	0,	2415,	0,	-1,	2152,	0,	-1,	0,	0,	0
dw	1917,	0,	-1,	2415,	0,	-1,	0,	0,	0,	2873,	0,	-1,	3224,	0,	-1,	0
dw	0,	0,	0,	0,	0,	0,	0,	0,	2415,	0,	-1,	2415,	0,	-1,	0,	0
dw	0,	2415,	0,	-1,	0,	0,	0,	2415,	0,	-1,	2152,	0,	-1,	1917,	0,	-1
dw	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0
dw	0,	0,	0,	0,	0,	0,	0,	0,	2415,	0,	-1,	2415,	0,	-1,	0,	0
dw	0,	2415,	0,	-1,	0,	0,	0,	2415,	0,	-1,	2152,	0,	-1,	0,	0,	0
dw	1917,	0,	-1,	2415,	0,	-1,	0,	0,	0,	2873,	0,	-1,	3224,	0,	-1,	0
dw	0,	0,	0,	0,	0,	0,	0,	0,	1917,	0,	-1,	1917,	0,	-1,	0,	0
dw	0,	1917,	0,	-1,	0,	0,	0,	2415,	0,	-1,	1917,	0,	-1,	0,	0,	0
dw	1612,	0,	-1,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0
dw	0,	0,	0,	0,	0,	0,	0,	0,	1917,	0,	-1,	2415,	0,	-1,	0,	0
dw	0,	3224,	0,	-1,	0,	0,	0,	0,	0,	0,	3043,	0,	-1,	0,	0,	0
dw	2873,	0,	-1,	1917,	0,	-1,	0,	0,	0,	1917,	0,	-1,	2873,	0,	-1,	0
dw	0,	0,	0,	0,	0,	0,	0,	0,	2559,	0,	-1,	0,	1436,	0,	-1,	0
dw	1436,	0,	-1,	0,	1436,	0,	-1,	0,	1612,	0,	-1,	0,	1917,	0,	-1,	0
dw	1917,	0,	-1,	2415,	0,	-1,	0,	0,	0,	2873,	0,	-1,	3224,	0,	-1,	0
dw	0,	0,	0,	0,	0,	0,	0,	0,	1917,	0,	-1,	2415,	0,	-1,	0,	0
dw	0,	3224,	0,	-1,	0,	0,	0,	0,	0,	0,	3043,	0,	-1,	0,	0,	0
dw	2873,	0,	-1,	1917,	0,	-1,	0,	0,	0,	1917,	0,	-1,	2873,	0,	-1,	0
dw	0,	0,	0,	0,	0,	0,	0,	0,	2559,	0,	-1,	1917,	0,	-1,	0,	0
dw	0,	1917,	0,	-1,	1917,	0,	-1,	0,	1917,	0,	-1,	0,	2152,	0,	-1,	0
dw	2415,	0,	-1,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0
dw	0,	0,	0,	0,	0,	0
