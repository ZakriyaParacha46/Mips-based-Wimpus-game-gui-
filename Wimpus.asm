#line 86
#$s4 for current game
#$s3 for Total games won
#$s2 for Total games played
#$s1 for players location
#$s0 for tresure location
#int input , 1,2 for up and down. 3,4 for left and right

.data
buffer: .space 0x40000

###parameters###
backgroundcol: .word 0xb3b3ff
foregroundcol: .word 0xcca300
delayaftergame: .word 0x000000
blockcol: .word 0xff0050
###parametersend###

userinput: .space 4
grid_pixels: .word 20600,20900,21240,102520, 102820,103160,184440,184740,185080
won_text: .asciiz "\nYou Won! ! ! !"
lose_text: .asciiz "\nYou Lose! ! ! !"
breeze_text: .asciiz "Stay Alert! ! ! ! "
breeze_text2: .asciiz " blocks away from tresure "
played_games: .asciiz "\nTotal Played games: "
won_games: .asciiz "\nTotal won games: "
line: .asciiz "\n================="
prompt: .asciiz "\nWhere to go?: "

#0 represent nothing, 1 (triangle) represent trap, 2 represents breeze,3 represent tresure and 4 represent wumpus
#  |0|3|1
#  |0|1|2
#  |0|2|4
game1: .word 0,3,1,0,1,2,0,2,4 
#  |0|4|1
#  |0|1|2
#  |0|2|3
game2: .word 0,4,1,0,1,2,0,2,3 
#  |1|0|1
#  |2|0|2
#  |4|1|3
game3: .word 1,0,1,2,0,2,4,1,3


#code
.text
la $s4,game1
jal game
j exit

game:
#takes gamearr as an input in $s4
#displaying background 
la $a1,buffer
lw $a0,backgroundcol
jal color
#displaying grid lines
la $a1,buffer
lw $a0,foregroundcol 
jal grid

move $a1,$s4
subi $sp,$sp,4
sw $ra,0($sp)
li $a0,4
jal search #return the pointer
move $s1,$v0

#search the victory
li $a0,3
jal search #return the pointer
move $s0,$v0 

#displaying the player at wumps block
lw $a0,blockcol #gray squre
move $a1,$s1 #placement
li $a2,3 #type
jal showtype

inputmove:
#prompt user for the movement
li $v0, 4
la $a0,prompt
syscall
#int input , 1,2 for up and down. 3,4 for left and right
li $v0, 5
syscall
#if invalid input
bge $v0, 5, inputmove
ble $v0, 0, inputmove
#moving the player
move $a0,$v0
jal playermove
j inputmove

lw $ra,0($sp)
addi $sp,$sp,4
jr $ra

playermove:
subi $sp,$sp,4
sw $ra,0($sp)
#take input $a0, as the user input 
#$v0 is the invalid flag 1 when turn is not taken.
#calculate the new position
#clear the players current location
#draw player at new location
beq $a0,1,up
beq $a0,2,down
beq $a0,3,left
beq $a0,4,right
j inputmove

left:
li $t6,3
div $s1,$t6
mfhi $t6
beqz $t6,inputmove
subi $t7,$s1,1 #moving left

j update
right:
li $t6,3
div $s1,$t6
mfhi $t6
beq $t6,2,inputmove
addi $t7,$s1,1 #moving right
j update

up:
blt $s1,3,inputmove
sub $t7,$s1,3 #t7 is the new position
j update

down:
bgt $s1,5,inputmove
add $t7,$s1,3 #t7 is the new position
update:

#clearing older background

lw $a0, backgroundcol
mul $a1,$s1,4
la $t1, grid_pixels
add $t1,$t1,$a1 #adding the offset
lw $t1,0($t1)
la $a1, buffer 
add $a1, $a1,$t1 
subi $a1, $a1, 13352 #removing  ofset
li $a2, 60 #aize 
jal squre

#reprinting old
move $a0, $s1
jal reveal

#printing player to new one.
lw $a0,blockcol #move to new block
move $a1,$t7 #placement
li $a2,3 #type
jal showtype
move $s1,$t7
#revealing the element on the given place
move $a0, $t7
li $t7,1
jal reveal
j movedone

movedone:
lw $ra,0($sp)
addi $sp,$sp,4
jr $ra


#helper functions
###############################################################
reveal:
subi $sp,$sp,4
sw $ra,($sp)
#takes int type in and print the respective item. 
#0 represent nothing, 1 represent trap, 2 represents breeze,3 represent tresure and 4 represent wumpus
beq $a0,$zero, nothing
#convering from index to ptrt
move $t1, $s4
mul $t0,$a0,4
add $t0,$t1,$t0
lw $t0,($t0)
li $t1,0 
#setting up for displaying the charecter
move $a1,$a0 #placemen
lw $a0,blockcol #move to new block

#a2=== 0=tresure, #1= breeze, #2= trap,#3 player
revealtrap: #switch 
bne $t0, 1,  revealbreeze
li $a2,2 #type trap
jal showtype
j lose

revealbreeze:
bne $t0, 2,  revealtreasure
li $a2,1 #type breeze
jal showtype

bne $t7,1, no_print
li $t7,0
li $t9, 3
sub $t8, $s1,$s0 #player - tresure
div $t8,$t9
mfhi $t9 #distance between tresure and player
mflo $t8
bge $t8,$zero,postive
mul $t8,$t8,-1
postive:
add $t9,$t8,$t9

#printing the breeze statement with the coun
li $v0, 4
la $a0,breeze_text
syscall
li $v0, 1
move $a0,$t9
syscall
li $v0, 4
la $a0,breeze_text2
syscall
no_print:

revealtreasure:
bne $t0, 3,  nothing
li $a2,0 #type treasure
jal showtype
j win

nothing:
lw $ra,($sp)
addi $sp,$sp,4
jr $ra

win:
addi $s2,$s2,1
addi $s3,$s3,1
li $v0, 4
la $a0,won_text
syscall
jal reset
jr $ra

lose:
addi $s2,$s2,1
li $v0, 4
la $a0,lose_text
syscall
jal reset
jr $ra

reset:
li $s0,0
li $s1,0

#selecting new game on the bases of total games played
li $t9,3 
div $s2,$t9
mfhi $t8

#switch
bne $t8,0,g1 
la $s4,game1
j skipall
g1:
bne $t8,1,g2
la $s4,game2
j skipall
g2:
la $s4,game3

skipall:
jal dispstats
jal delay
j game #gameloop
j exit
jr $ra


delay:
li $t0,0
lw $t1,delayaftergame
loopdelay:
beq $t0,$t1,enddelay
addi $t0,$t0,1
j loopdelay

enddelay:
jr $ra
search:
#takes a type (1,2,3,4) $a0 and array in $a1 and return its occurences in $v0.
li $t0,0
move $a1,$s4
move $t1,$a1
searchloop:
beq $t0,10,endsearchloop
lw $t3,($a1)
beq $t3,$a0,found
addi $t0,$t0 ,1
addi $a1,$a1,4
j searchloop
found:
move $v0,$t0
endsearchloop:
jr $ra


showtype:
#a0, have color  
#a1 ,have offset
#a2,have type #0=tresure, #1= breeze, #2= trap,#3 player

mul $a1,$a1,4
la $t1, grid_pixels
add $t1,$t1,$a1 #adding the offset
lw $t1,0($t1)

la $a1, buffer 
add $a1,$a1,$t1 #pointer
move $t3,$a2
li $a2, 30 #aize

beq $t3,0,squre 
beq $t3,1,breeze 
beq $t3,2,triangle
beq $t3,3,player
jr $ra

exit:
li $v0,10
syscall


#======================graphics================
dispstats:
#line
li $v0,4
la $a0,line
syscall
#totalplayed
la $a0,played_games
syscall
li $v0,1
move $a0,$s2
syscall
#total won
li $v0,4
la $a0, won_games
syscall
li $v0,1
move $a0,$s3
syscall
#line
li $v0,4
la $a0,line
syscall
jr $ra

breeze:
li $t6,5120 
mul $t3,$a2,4 
sub $t6,$t6,$t3 #offset
li $t0,0

loopbreeze:
bge $t0,$a2,endbreeze
li $t1,0
breeze_points:
bge $t1,$a2, breakbreezePoints
sw $a0,($a1) #storing color to the pixel
addi $a1,$a1,4
addi $t1,$t1,1
j breeze_points
breakbreezePoints:
add $a1,$a1,$t6
addi $t0,$t0,5
j loopbreeze
endbreeze:
jr $ra

#player is just a line

player:
addi $a1,$a1,20 #offset to print the player in center
subi $a2,$a2,20
move $t1,$a1

li $t0,0
looppla:
bge $t0,$a2,endpla
sw $a0,($t1) #storing color to the pixel
sw $a0,4($t1) #storing color to the pixel
sw $a0,8($t1) #storing color to the pixel
add $t1,$t1,1028
addi $t0,$t0,1
j looppla
endpla:
li $t0,0
move $t1,$a1
looppla2:
bge $t0,$a2,endpla2
sw $a0,($t1) #storing color to the pixel
sw $a0,4($t1) #storing color to the pixel
sw $a0,8($t1) #storing color to the pixel
add $t1,$t1,1020
addi $t0,$t0,1
j looppla2
endpla2:
jr $ra

squre:
li $t6,1024 
addi $a1,$a1, 12288
mul $t3,$a2,4 
sub $t6,$t6,$t3 #offset
li $t0,0
loopsqr:
bge $t0,$a2,endsqr
li $t1,0
sqr_points:
bge $t1,$a2, breaksqrPoints
sw $a0,($a1) #storing color to the pixel
addi $a1,$a1,4
addi $t1,$t1,1
j sqr_points
breaksqrPoints:
add $a1,$a1,$t6
addi $t0,$t0,1
j loopsqr
endsqr:
jr $ra

triangle:
addi $a1,$a1,5180 #shifting main point
li $t0,2 #points 
li $t6,1020 #offset
looptri:
bge $t0,$a2,endtri
#draw $t0 number of points
li $t1,0 #counter
T_points:
bge $t1,$t0, breakTPoints
sw $a0,($a1) #storing color to the pixel
addi $a1,$a1,4
addi $t1,$t1,1
j T_points
breakTPoints:
addi $t0,$t0, 2
subi $t6,$t6,8
add $a1,$a1,$t6
j looptri
endtri:
jr $ra

grid:
#create 3x3 grid
#$a0 have the color
#$a1 have the pointer to buffer
addi $t0,$a1,0x40000
addi $t1,$a1,340
#loop for horizontal
loopv:
bge $t1,$t0,horizontal
#thickness of two
sw $a0,($t1)
addi $t1,$t1,4
sw $a0,($t1)
#secondline
addi $t1,$t1,336
#thickness of two
sw $a0,($t1)
addi $t1,$t1,4
sw $a0,($t1)
addi $t1,$t1,680
j loopv

horizontal:
#loop for vertical1
addi $t1,$a1,87040
addi $t0,$t1, 2048 #two thickness line
looph1:
beq $t1,$t0,exit_h1
sw $a0,($t1)
addi $t1,$t1,4
j looph1
exit_h1:

addi $t1,$a1,174080
addi $t0,$t1, 2048 #two thickness line
#loop for vertical2
looph2:
beq $t1,$t0,exit_h2
sw $a0,($t1)
addi $t1,$t1,4
j looph2
exit_h2:
li $t0,0
li $t1,0
jr $ra

color:
#color whole buffer
#$a0 have the colot
#$a1 have the pointer to buffer
add $t0,$a1,0x40000
loop:
bge $a1,$t0,exit_color
sw $a0,($a1)
addi $a1,$a1,4
j loop
exit_color:
jr $ra

