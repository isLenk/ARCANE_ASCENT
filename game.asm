#
#	ARCANE ASCENT by Yron Lance Talban
#	April 2023		
#
#	
# #####################################################################
#
# CSCB58 Winter 2023 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Yron Lance Talban, 1008372397, talbanyr
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4
# - Unit height in pixels: 4
# - Display width in pixels: 512
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1
# - Milestone 2
# - Milestone 3
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. Fail condition 	- Game over when you lose all your lives
# 2. Start Menu			- A and D to choose option, W or Space to select
# 3. Different Levels	- 10 Maps. Created using my map builder
# 4. Double Jump 		- Can only double jump if you jump prior to descending.
# 5. Health/Score 		- Hearts are drawn at the bottom right of the screen.
# 6. Pick-ups Effects 	- Vodka potion, Gravity potion, health restore, (key as well?)
# 7. Win Condition  - Complete all 10 levels.
#
# Link to video demonstration for final submission:
# - https://youtu.be/4cxd8GXdnaY
#
# Are you OK with us sharing the video with people outside course staff?
# - yes, and please share this project github link as well!
# LINK: https://github.com/isLenk/ARCANE_ASCENT
#
# Any additional information that the TA needs to know:
#
# - If you enter a falling state before jumping, you lose your double jump. No wall jumps because you are a mage, not a ninja
#
# - The movement mechanics are dash-like. You can do half-distance movements by holding Shift and pressing the direction
#		q and e are diagonal movements, there is no Q and E half-distance movements. Since the movement mechanics are
#		janky, I have decided to make gravity slow.
#
# - Pressing p kills you. You lose a life and restart the level.
#
# - To reduce computation, collisions are based on the middle and corner nodes of the players hitbox. While I have tried
#		minimizing the collide-failure during map design, there may be some occurences where you do not properly interact
#		with an instance. Try jumping on it.
#
# - Lastly, 3 hearts is default. If you like sufferring,change PLAYER_MAX_HEALTH to 1, but my friends died with 13 so, change up to your skill level.
#
# - In the starting menu, A and D control which option to pick, W or Space allow you to select that option.
# ####################################################################	
#

.eqv PLAYER_MAX_HEALTH		3		# How many lives you get.

# Player Movement Constants.
.eqv PLAYER_WS			0x00000010  	# Player Walk Speed
.eqv PLAYER_HALFWS		0x00000008	# Player Walk Speed
.eqv PLAYER_JP			0x00000C00	# Player Jump Power (6 Rows = 512*6 = 0xC00)
.eqv PLAYER_SECOND_JP		0x00000A00	# Second jump is slightly less powerful (3 Rows = 512 * 5 = 0xA00)

# Addresses and other information
.eqv BASE_ADDRESS 		0x10008000	# Topleft of frame buffer
.eqv END_ADDRESS		0x10014000	# Bottom right of game screen
.eqv UI_BASE_ADDRESS		0x10014400 	# 0x10014000	# Topleft of UI frame buffer
.eqv UI_END_ADDRESS		0x10018000	# Bottom right of frame buffer
.eqv PLAYER_BOTRIGHT		0x00000810	# Bottom right of player hitbox
.eqv PLAYER_MIDLEFT		0x00000400	# Middle left of player hitbox.
.eqv NEXT_ROW			512		# 4*(Units per Row)=4*128
.eqv PLAYER_WIDTH		16		# Width of the player.
.eqv PLAYER_HALFWIDTH		8		# Convenience in collision detection

# COLORS. Used to detect collisions.
.eqv	COLOUR_BG		0x00171616
.eqv	WALL_COLOR		0x005c5454
.eqv	UI_BG_COLOR		0x00eeeeee
.eqv	GATE_COLOR		0x005e3128
.eqv	OPEN_GATE_COLOR 	0x00ffffff
.eqv	SPIKE_COLOR 		0x009c9c9c
.eqv 	HEART_COLOR 		0x00fc4c4c
.eqv 	DISPLAY_TOOL_COLOR 	0x00eeeeee	# The color of the mips display simulator

# STATUS COLORS
# | Default - Normal status colors
.eqv	PLR_COLOR1		0x007d0028 		# Maroon Red
.eqv	PLR_COLOR2		0x00000000 		# Black
.eqv	PLR_EYECOL		0x00ffffff 		# White

# | Vodka Potion - Colors when you are VODKA
.eqv VODKA_PLR_COLOR1	0x00a86d32
.eqv VODKA_PLR_EYECOL	0x007d7d7d

# | Gravity Potion - Colors when you are upside down
.eqv GRAVITY_PLR_COLOR1 0x0045153a
.eqv GRAVITY_PLR_COLOR2 0x00000000
.eqv GRAVITY_PLR_EYECOL 0x00d2a2f2

# MENU SETTINGS
.eqv MENU_REFRESH_RATE	40
.eqv MENU_ANIM_RATE	100

# OTHER CONSTANTS
.eqv REFRESH_RATE 	20
.eqv COMPUTED_FPS	25	# Manually entered to reduce instructions
.eqv UPDATE_RATE	3	# How many frames must elapse to update data.
# -----------------------------------------------------
# Note, these addresses should only be called AFTER Load()
# 		Ensure saving the previous structs data prior to Loading a struct.
.eqv STRUCT_SIZE		36

# Vars for player_data struct
.eqv PLAYER_POS			$s0		# The players position on the display
.eqv PLAYER_xVEL		$s1		# horizontal velocity
.eqv PLAYER_yVEL		$s2		# vertical velocity
.eqv PLAYER_LASTINPUT	$s3		# Used to determine which sprite to load
.eqv JUMPS_LEFT			$s4		# Maximum 2 jumps. Resets when standing, 1 jump if not used prior to falling state
.eqv PLAYER_HEALTH		$s5		# The current health the player has. This does not reset during levels.
.eqv PLAYER_SPELLS		$s6		# Default two, only recharges via recharge pickups.

# Vars for world data
.eqv FRAMES_ELAPSED			$s0		# Increments every frame. Resets to zero when a second has elapsed.
.eqv SECONDS_ELAPSED		$s1		# Number of seconds that have elapsed since the game began.

# Vars for pickup array
.eqv PICKUP_SPACE			128		# The maximum size of the PICKUP_POINTER array. (Refer to .data section)
.eqv PICKUP_DATA_SIZE		8		# Each pickup reserves 8 bytes of data in the array

# Vars for level_data struct
.eqv CURRENT_LEVEL              $s0		# The players current level.
.eqv CURRENT_COLLIDE_WITH_PLR	$s1		# The current instance that the player is colliding with
.eqv GATE_POSITION				$s2		# The position of the gate in the current level
.eqv KEY_POSITION				$s3		# The position of the key in the current level
.eqv PICKUP_POINTER				$s4		# A pointer to an element in pickups_array. Defaults to zero, collision points to that entity
.eqv EFFECT_USED				$s5		# The current effect that is on the player
.eqv EFFECT_DURATION			$s6		# The amount of time left until the player restores normal state.

.eqv STARTING_LEVEL				0 		# For testing (0 = default)
.eqv WIN_AT_LEVEL				999		# For demonstration of win-state.

# States
.eqv PICKUP_COLLECTED		-1	# Do not update this pickup. Setting to anything below 0 is fine

# Collision IDs (DO NOT MODIFY.)
.eqv KEY_ID				1
.eqv SPIKE_ID			2
.eqv GATE_ID			3
.eqv HEALTH_RESTORE_ID	4	# vvv Pickup IDs
.eqv GRAVITY_POTION_ID 	5
.eqv FLIGHT_POTION_ID	6	# Not implemented for Demo
.eqv VODKA_POTION_ID	7
.eqv SPELL_RECHARGE_ID	8	# Not implemented for Demo


# *** DEFINE STRUCTS *****************************************
# Each pickup has the following data:
#	int position (-1 if collected)
#	int effect_id
# I have set the maximum number of pickups per level to 15. There is reserved space at the end of the array
# in case all fifteen pickups have not yet been collected. The end of the array cuts of where elements Position is 0
# 4 * (( CATCH + Number of Entities allowed on the map )* struct size ) => 4 * ( (15 + 1) * 2) = 128

.data
spacer: 		.space 32768 		# [or 36000] Reserve space for frame buffer
world_data: 		.space STRUCT_SIZE	# Stores frames elapsed and seconds elapsed.
player_data: 		.space STRUCT_SIZE	# Stores player information 
level_data: 		.space STRUCT_SIZE	# Stores level information
pickups_array: 		.space PICKUP_SPACE	# Stores pickups available on the current level

.text

main: j START_MENU

# $a0 - Starting address
# $a1 - Ending Address
# $a2 - Value to fill
FILL_ARRAY:
	move $t0, $a2			# Store zero into $t0
	lw $t0, 0($a0)			# Load zero into array
	addi $a0, $a0, 4		# Increment array
	blt $a0, $a1, FILL_ARRAY	# Check if reached end address, if not, loop
	jr $ra

# $a0 - starting address
# $a1 - Ending address
CLEAR_ARRAY:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	li $a2, 0			# Store zero into $t0
	jal FILL_ARRAY
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra				# Return to caller


# Clean what needs to be cleaned and then peacefully exit.
EXIT:
	# TODO ! CLEANUP
	li $v0, 10 # Terminate proram peacefully
	syscall

# The logic for the starting menu
START_MENU:
	# fill the background
	li $a0, BASE_ADDRESS
	li $a1, END_ADDRESS
	li $a2, NEXT_ROW
	li $a3, 0x0043bee0
	jal FILL

	# Initial Load
	li $a0, BASE_ADDRESS
	jal DRAW_START_MENU

	li $a0, BASE_ADDRESS
	jal DRAW_START_MENU_TITLE

	li $a0, BASE_ADDRESS
	jal DRAW_START_EXIT_WORDS

	li $a0, BASE_ADDRESS
	jal DRAW_START_MENU_PLAYER_FRAME1
	# SELECTION
	li $s0, 1		# 1 = START GAME, 0 = EXIT

	START_MENU_LOOP:
		# ------------------
		# Check Keyboard Input
		START_MENU_HANDLE_INPUT:
			li 	$s1, 0xffff0000
			lw	$s2, 0($s1)		# Verify input_is_new
			bne	$s2, 1, START_MENU_NO_RESPONSE
				
			# Determine what key was entered.
			lw $s1, 4($s1)							# Hex value of the key pressed

			beq $s1, 0x61, START_MENU_GOTO_EXIT		# Go to exit
			beq $s1, 0x64, START_MENU_GOTO_START	# Go to start
			beq $s1, 0x77, START_MENU_SELECT		# Select
			beq $s1, 0x20, START_MENU_SELECT		# Also select
			j START_MENU_NO_RESPONSE

		START_MENU_GOTO_EXIT:
			beq $s0, 0, START_MENU_NO_RESPONSE	# Dont draw if already on this state

			li $a0, BASE_ADDRESS
			jal DRAW_START_MENU
			li $a0, BASE_ADDRESS
			jal DRAW_START_EXIT_WORDS
			li $a0, BASE_ADDRESS
			jal DRAW_START_MENU_PLAYER_EXIT
			li $s0, 0
			j START_MENU_NO_RESPONSE

		START_MENU_GOTO_START:
			beq $s0, 1, START_MENU_NO_RESPONSE	# Dont draw if already on this state
			li $a0, BASE_ADDRESS
			jal DRAW_START_MENU
			li $a0, BASE_ADDRESS
			jal DRAW_START_EXIT_WORDS
			li $a0, BASE_ADDRESS
			jal DRAW_START_MENU_PLAYER_FRAME1
			li $s0, 1
			j START_MENU_NO_RESPONSE


		START_MENU_SELECT:
			j START_MENU_DO_SELECTION

		# ------------------

		START_MENU_NO_RESPONSE:
			# Slower menu refresh rate
			li $v0, 32
			li $a0, MENU_REFRESH_RATE
			syscall
			j START_MENU_LOOP

	START_MENU_DO_FRAMES:

		li $a0, BASE_ADDRESS
		jal DRAW_START_MENU

		li $a0, BASE_ADDRESS
		jal DRAW_START_EXIT_WORDS
		addi $s0, $s0, 1
		
		b START_MENU_CHECK_FRAME
		
		START_MENU_DO_FRAME2:
			li $a0, BASE_ADDRESS
			jal DRAW_START_MENU_PLAYER_FRAME2
			li $v0, 32
			li $a0, MENU_ANIM_RATE
			syscall
		
			b START_MENU_DO_FRAMES
			
		START_MENU_DO_FRAME3:
			li $a0, BASE_ADDRESS
			jal DRAW_START_MENU_PLAYER_FRAME3
			li $v0, 32
			li $a0, MENU_ANIM_RATE
			syscall
			b START_MENU_DO_FRAMES

		START_MENU_CHECK_FRAME:
			# Slower menu refresh rate
			li $v0, 32
			li $a0, 500
			syscall

			beq $s0, 2, START_MENU_DO_FRAME2
			beq $s0, 3, START_MENU_DO_FRAME3
			blt $s0, 4, START_MENU_DO_FRAMES

	jal CLEAR_SCREEN
	li $v0, 32
	li $a0, 200
	syscall
	j BEGIN_GAME

	START_MENU_DO_SELECTION:
		beq $s0, 1, START_MENU_DO_FRAMES
		jal CLEAR_SCREEN
		j EXIT

# Colors the entire display black.
CLEAR_SCREEN:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	li $a0, BASE_ADDRESS		# Fill entire screen with background color
	li $a1, UI_END_ADDRESS
	li $a2, NEXT_ROW
	li $a3, 0x00000000
	jal FILL

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Refill the screen with the background color
CLEAR_MAP:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	li $a0, BASE_ADDRESS		# Fill entire screen with background color
	li $a1, END_ADDRESS
	li $a2, NEXT_ROW
	jal FILL_BG

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Redraw the UI bar
CLEAR_UI:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $a0, END_ADDRESS
	li $a1, UI_BASE_ADDRESS
	li $a2, NEXT_ROW
	li $a3, DISPLAY_TOOL_COLOR
	jal FILL

	li $a0, UI_BASE_ADDRESS		# Fill the UI Background color
	li $a1, UI_END_ADDRESS
	li $a2, NEXT_ROW
	li $a3, UI_BG_COLOR
	jal FILL

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Draws the hearts on the UI
DRAW_HEARTS:		
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $a0, player_data			# Load the player_data struct
	jal LOAD_DATA

	move $t0, PLAYER_HEALTH
	li $t1, PLAYER_MAX_HEALTH
	sub $t1, $t1, $t0

	li $t2, 988
	DRAW_HEART_LOOP:
		addi $sp, $sp, -12
		sw $t2, 0($sp)
		sw $t0, 4($sp)
		sw $t1, 8($sp)

		li $a0, UI_BASE_ADDRESS		# Draw heart (x3)
		add $a0, $a0, $t2 

		bgtz $t1, DO_DRAW_EMPTY_HEART
		jal DRAW_HEART
		b DRAW_HEART_CONTINUE


		DO_DRAW_EMPTY_HEART:
			jal DRAW_EMPTY_HEART

		DRAW_HEART_CONTINUE:
		lw $t2, 0($sp)
		lw $t0, 4($sp)
		lw $t1, 8($sp)

		addi $sp, $sp, 12
		addi $t2, $t2, -40
		
		bgtz $t1, DRAW_HEART_DECREMENT_EMPTYHEART
		subi $t0, $t0, 1
		bgtz $t0, DRAW_HEART_LOOP

		DRAW_HEART_DECREMENT_EMPTYHEART:
		subi $t1, $t1, 1
		bgtz $t0, DRAW_HEART_LOOP

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
# Called when presented data such has health changes
REDRAW_UI:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	jal CLEAR_UI
	jal DRAW_HEARTS

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
# params $a0 = starting address of struct
# Assigns $s0-$s4
LOAD_DATA:	# Loads $a0 struct data into $s0-$s5
	lw $s0, 0($a0)
	lw $s1, 4($a0)
	lw $s2, 8($a0)
	lw $s3, 12($a0)
	lw $s4, 16($a0)
	lw $s5, 20($a0)
	lw $s6, 24($a0)
	lw $s7, 28($a0)
	jr $ra

SAVE_DATA: 	# Saves $s0-$s5 into $a0 struct 
	sw $s0, 0($a0)
	sw $s1, 4($a0)
	sw $s2, 8($a0)
	sw $s3, 12($a0)
	sw $s4, 16($a0)
	sw $s5, 20($a0)
	sw $s6, 24($a0)
	sw $s7, 28($a0)
	jr $ra

FILL_BG:	# Decorator to FILL, adds $a3 to be background color.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	li $a3, COLOUR_BG
	jal FILL
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra

# $a0 = Starting Address, $a1 = End Address, $a2 = Step, $a3 = Color
FILL:		# Fills section of framebuffer according to given arguments.
	move $t7, $a3
	li $t8, 0	# Current column index
	
	FILL_LOOP:
		bgt $a0, $a1, FILL_COMPLETE	# We have reached the end address
		sw $t7, 0($a0) 				# Color the cell
		addi $a0, $a0, 4			# Move up a cell
		addi $t8, $t8, 4			# Increment our returner
		ble $t8, $a2, FILL_LOOP		# Current column is not at step
		sub $a0, $a0, $t8			# Return to first cell of the start column
		addi $a0, $a0, NEXT_ROW		# Shift down a row
		li $t8, 0					# Reset our returner
		j FILL_LOOP
		
	FILL_COMPLETE: jr $ra

# $a0 = Starting Address, $a1 = End Address, $a2 = Step, $a3 = Target Address
# Uses $t8, $v0
COLLISION_CHECKER:		# Returns 1 if the target address is contained within the space
	li $t8, 0	# Current column index
	li $v0, 0	# Default, 0: Target not contained.
	COLLISION_LOOP:
		bgt $a0, $a1, COLLISION_NONE_FOUND	# We have reached the end address with no results
		beq $a0, $a3, COLLISION_TARGET_FOUND	# If the current cell is the address we are looking for. Done.
		addi $a0, $a0, 4			# Move to next cell
		addi $t8, $t8, 4			# Increment returner value
		ble $t8, $a2, COLLISION_LOOP		# We have not reached the last cell of our space, continue.
		sub $a0, $a0, $t8			# Return to beginning of row
		addi $a0, $a0, NEXT_ROW			# Drop down a row
		li $t8, 0				# Restart our counter
		j COLLISION_LOOP
	
	COLLISION_NONE_FOUND: b COLLISION_RETURN
	COLLISION_TARGET_FOUND: li $v0, 1
	COLLISION_RETURN: jr $ra

# Given the entity id ($a0), this will fill the section of
HIDE_ENTITY:
	addi	$sp, $sp, -4	# Push $ra to stack
	sw	$ra, 0($sp)

	beq $a0, KEY_ID, HIDE_ENTITY_KEY
	beq $a0, VODKA_POTION_ID, HIDE_POTION
	beq $a0, FLIGHT_POTION_ID, HIDE_POTION
	beq $a0, GRAVITY_POTION_ID, HIDE_POTION
	beq $a0, HEALTH_RESTORE_ID, HIDE_PICKUP_HEALTH

	HIDE_ENTITY_KEY:
		add $a0, KEY_POSITION, BASE_ADDRESS
		addi $a1, $a0, 1020
		li $a2, 20
		jal FILL_BG
		j HIDE_ENTITY_EXIT

	# Below are pickup collisions
	HIDE_POTION:
		lw $a0, 0(PICKUP_POINTER)
		add $a0, $a0, BASE_ADDRESS
		addi $a1, $a0, 1548
		li $a2, 12
		jal FILL_BG
		j HIDE_ENTITY_EXIT

	HIDE_PICKUP_HEALTH:
		lw $a0, 0(PICKUP_POINTER)
		add $a0, $a0, BASE_ADDRESS
		addi $a1, $a0, 1036
		li $a2, 12
		jal FILL_BG		
		j HIDE_ENTITY_EXIT

	HIDE_ENTITY_EXIT:
	lw	$ra, 0($sp)			# Return to sender.
	addi	$sp, $sp, 4	
	jr $ra

# Accepts $a0 as the topleft of an entity, $a1 as type of entity, $a2 as player topleft
# $v0 = 1 if collide, 0 otherwise
CHECK_PLAYER_COLLIDES_WITH:
	addi	$sp, $sp, -4	# Push $ra to stack
	sw	$ra, 0($sp)
	# This function prepares arguments for COLLISION_CHECKER
	# We can directly return the return value from the call.
	# -------------------------------------------
	# Store args into stack.
	addi	$sp, $sp, -12	# Reserve three word vars in stack.
	# Check for which entity player has collided with
	beq $a1, KEY_ID, CHECK_KEY_COLLISION
	beq $a1, GATE_ID, CHECK_GATE_COLLISION
	beq $a1, VODKA_POTION_ID, CHECK_POTION_COLLISION
	beq $a1, FLIGHT_POTION_ID, CHECK_POTION_COLLISION
	beq $a1, GRAVITY_POTION_ID, CHECK_POTION_COLLISION
	beq $a1, HEALTH_RESTORE_ID, CHECK_HEALTH_RESTORE_COLLISION

	j COLLISION_CHECKER_EXIT

	CHECK_KEY_COLLISION:
		# KEY DIMENSIONS (6, 2)
		addi $a1, $a0, 1020
		move $a3, $a2		# Store player address
		li $a2, 20
		j CHECK_COLLISION_RUN

	CHECK_GATE_COLLISION:
		# GATE DIMENSIONS (7, 8)
		addi $a1, $a0, 3612
		move $a3, $a2		# Store player address
		li $a2, 28
		j CHECK_COLLISION_RUN

	CHECK_POTION_COLLISION:
		# POTION DIMENSIONS (3, 4)
		addi $a1, $a0, 1548
		move $a3, $a2		# Store player address
		li $a2, 12
		j CHECK_COLLISION_RUN

	CHECK_HEALTH_RESTORE_COLLISION:
		# HEALTH RESTORE DIMENSIONS (3, 3)
		addi $a1, $a0, 1036
		move $a3, $a2		# Store player address
		li $a2, 12
		j CHECK_COLLISION_RUN

	CHECK_COLLISION_RUN:
		# STORE MODIFIED ARGUMENTS INTO STACK.
		sw	$a0, 0($sp)
		sw	$a1, 4($sp)
		sw	$a2, 8($sp)

	DO_CHECK_COLLISION_WITH_PLAYER:
		# Retrieve original arguments
		# Get edges
		move $t2, $a3				# Top Right	($t2)
		addi $t2, $t2, PLAYER_WIDTH		
		move $t4, $a3				# Middle Left	($t4)
		add $t4, $t4, PLAYER_MIDLEFT
		move $t5, $t4				# Middle Right	($t5)
		addi $t5, $t5, PLAYER_WIDTH
		move $t3, $a3				# Bottom Right	($t3)
		add $t3, $t3, PLAYER_BOTRIGHT
		move $t1, $t3				# Bottom Left	($t1)
		subi $t1, $t1, PLAYER_WIDTH
		move $t6, $t1				# Middle Bottom	($t6)
		addi $t6, $t6, PLAYER_HALFWIDTH

		lw $a0, 0($sp)
		lw $a1, 4($sp)
		lw $a2, 8($sp)
		move $a3, $t4
		jal COLLISION_CHECKER
		bnez $v0, COLLISION_CHECKER_EXIT
		lw $a0, 0($sp)
		lw $a1, 4($sp)
		lw $a2, 8($sp)
		move $a3, $t4
		jal COLLISION_CHECKER
		bnez $v0, COLLISION_CHECKER_EXIT
		lw $a0, 0($sp)
		lw $a1, 4($sp)
		lw $a2, 8($sp)
		move $a3, $t5
		jal COLLISION_CHECKER
		bnez $v0, COLLISION_CHECKER_EXIT
		lw $a0, 0($sp)
		lw $a1, 4($sp)
		lw $a2, 8($sp)
		move $a3, $t3
		jal COLLISION_CHECKER
		bnez $v0, COLLISION_CHECKER_EXIT
		lw $a0, 0($sp)
		lw $a1, 4($sp)
		lw $a2, 8($sp)
		move $a3, $t1
		jal COLLISION_CHECKER
		bnez $v0, COLLISION_CHECKER_EXIT
		lw $a0, 0($sp)
		lw $a1, 4($sp)
		lw $a2, 8($sp)
		move $a3, $t6
		jal COLLISION_CHECKER
		bnez $v0, COLLISION_CHECKER_EXIT

		b COLLISION_CHECKER_EXIT
	# -------------------------------------------

	COLLISION_CHECKER_EXIT:
		addi	$sp, $sp, 12	# Free three words from stack
		lw	$ra, 0($sp)			# Return to sender.
		addi	$sp, $sp, 4	
		jr $ra

# Assumes struct is open for modification.
PLAYER_COLLIDED_EVENT:
	# This method is called in the player update section of GAME_RENDER.
	addi	$sp, $sp, -4	# Push $ra to stack
	sw	$ra, 0($sp)

	addi	$sp, $sp, -4	# Push player topleft to stack
	sw	$a0, 0($sp)

	la $a0, player_data		# Save the player_data struct
	jal SAVE_DATA

	la $a0, level_data		# Load the player_data struct
	jal LOAD_DATA

	# Check if there has already been a collision handled. If so, do not recheck collision
	bnez CURRENT_COLLIDE_WITH_PLR, PLAYER_COLLIDED_EVENT_EXIT
	# -------------------------------------------

	# !TODO: MODIFY CONDITION TO GO TO NEXT CHECK
	bltz KEY_POSITION, PLAYER_COLLIDED_GATE_KEY

	PLAYER_COLLIDED_EVENT_KEY:
		add $a0, KEY_POSITION, BASE_ADDRESS
		li $a1, KEY_ID
		lw $a2, 0($sp) 			# The player topleft
		jal CHECK_PLAYER_COLLIDES_WITH

		# Check if hit. If not, go to next check
		beqz $v0, PLAYER_COLLIDED_GATE_KEY
		li $v0, KEY_ID
		j PLAYER_COLLIDED_EVENT_HIT

	PLAYER_COLLIDED_GATE_KEY:
		add $a0, GATE_POSITION, BASE_ADDRESS
		li $a1, GATE_ID
		lw $a2, 0($sp) 			# The player topleft
		jal CHECK_PLAYER_COLLIDES_WITH
		
		# Check if hit. If not, go to next check
		beqz $v0, PLAYER_COLLIDED_EVENT_SPIKE
		li $v0, GATE_ID
		j PLAYER_COLLIDED_EVENT_HIT

	PLAYER_COLLIDED_EVENT_SPIKE:
		li $t0, SPIKE_COLOR
		lw $t1, 0($sp) 			# The player topleft
		move $t7, $t1				# Store topleft again
		move $t2, $t1				# Top Right	($t2)
		addi $t2, $t2, PLAYER_WIDTH		
		move $t4, $t1				# Middle Left	($t4)
		add $t4, $t4, PLAYER_MIDLEFT
		move $t5, $t4				# Middle Right	($t5)
		addi $t5, $t5, PLAYER_WIDTH
		move $t3, $t1				# Bottom Right	($t3)
		add $t3, $t3, PLAYER_BOTRIGHT
		move $t1, $t3				# Bottom Left	($t1)
		subi $t1, $t1, PLAYER_WIDTH
		move $t6, $t1				# Middle Bottom	($t6)
		addi $t6, $t6, PLAYER_HALFWIDTH

		li $v0, SPIKE_ID	# Load spike id into v0 as default. If no checks below pass, then we clear this value.
		
		lw $t7, 0($t2)
		beq $t7, SPIKE_COLOR, PLAYER_COLLIDED_EVENT_HIT
		lw $t2, 0($t2)
		beq $t2, SPIKE_COLOR, PLAYER_COLLIDED_EVENT_HIT
		lw $t4, 0($t4)
		beq $t4, SPIKE_COLOR, PLAYER_COLLIDED_EVENT_HIT
		lw $t5, 0($t5)
		beq $t5, SPIKE_COLOR, PLAYER_COLLIDED_EVENT_HIT
		lw $t3, 0($t3)
		beq $t3, SPIKE_COLOR, PLAYER_COLLIDED_EVENT_HIT
		lw $t1, 0($t1)
		beq $t1, SPIKE_COLOR, PLAYER_COLLIDED_EVENT_HIT
		lw $t6, 0($t6)
		beq $t6, SPIKE_COLOR, PLAYER_COLLIDED_EVENT_HIT
		
		li $v0, 0

		j PLAYER_COLLIDED_PICKUP # Reached if no checks were successful

	PLAYER_COLLIDED_PICKUP:
		# TODO: Proximity check somewhere, or not, up to me
		PLAYER_COLLIDED_PICKUP_LOOP:
			
			lw $a0, 0(PICKUP_POINTER)	# Load the pickup positoin
			addi $a0, $a0, BASE_ADDRESS	# Shift pickup position to be relative to base address
			lw $a1, 4(PICKUP_POINTER)	# Load the pickup id
			lw $a2, 0($sp) 				# The player topleft

			jal CHECK_PLAYER_COLLIDES_WITH

			beqz $v0, PLAYER_COLLIDED_PICKUP_NEXT	# Nothing, I'm a bit sad now :c
			lw $v0, 4(PICKUP_POINTER)				# Store hit results ID into $v0
			j PLAYER_COLLIDED_EVENT_HIT

			PLAYER_COLLIDED_PICKUP_NEXT:
				add PICKUP_POINTER, PICKUP_POINTER, PICKUP_DATA_SIZE
				lw $t0, 0(PICKUP_POINTER)
				bnez $t0, PLAYER_COLLIDED_PICKUP_LOOP

		li $v0, 0	# all checks failed
		# Free registers are $t0, $t8, $t9
		# iterate through pickup array
		# Check if entity position is valid, if not, skip
		# If it is valid, set $v0 to the entity id (not really important but it is???)
		j PLAYER_COLLIDED_EVENT_EXIT

	# -------------------------------------------

	PLAYER_COLLIDED_EVENT_HIT:
		# Store the current colliding object
		move CURRENT_COLLIDE_WITH_PLR, $v0

	PLAYER_COLLIDED_EVENT_EXIT:
		la $a0, level_data		# Load the player_data struct
		jal SAVE_DATA

		la $a0, player_data
		jal LOAD_DATA

		addi	$sp, $sp, 4	# Pop player topleft off stack
		lw	$ra, 0($sp)			# Return to sender.
		addi	$sp, $sp, 4	

		jr $ra
# Display the winner screen and then return to the start menu.
WIN_STATE:
	jal DRAW_WINSCREEN
	jal CLEAR_SCREEN
	j START_MENU
# Display the game over screen and then return to the start menu
GAME_OVER: 
	jal CLEAR_SCREEN
	li $a0, BASE_ADDRESS
	jal DRAW_GAME_OVER
	jal CLEAR_SCREEN
	j START_MENU

# Decrease player health and reset
PLAYER_DEAD:
	# Load player data
	la $a0, player_data
	jal LOAD_DATA

	subi PLAYER_HEALTH, PLAYER_HEALTH, 1
	la $a0, player_data
	jal SAVE_DATA
	
	bgtz PLAYER_HEALTH, CONTINUE_GAME	# If this condition is false, we are dead.
	j GAME_OVER
	
	CONTINUE_GAME:
	j RELOAD_MAP


#   ___                     _                    
#  / __| __ _  _ __   ___  | |    ___  ___  _ __ 
# | (_ |/ _` || '  \ / -_) | |__ / _ \/ _ \| '_ \
#  \___|\__,_||_|_|_|\___| |____|\___/\___/| .__/
#                                          |_|   
# The main loop that processes the game.
GAME_RENDER:
	
	# -------------------
	#
	# HANDLE PLAYER UPDATE
	#
	# ------------------
	PLAYER_UPDATE:
		# Get status effect from level_data
		la $a0, level_data
		jal LOAD_DATA

		# Push status effect into stack
		addi $sp, $sp, -4
		sw EFFECT_USED, 0($sp)

		la $a0, player_data		# Load the player_data struct
		jal LOAD_DATA
		jal CLEAR_CHAR
		# ------------------
		# Check Keyboard Input
		HANDLE_INPUT:
			li 	$a0, 0xffff0000
			lw	$t0, 0($a0)		# Verify input_is_new
			bne	$t0, 1, HANDLE_PLAYER_MOVEMENT_Y
			jal ON_KEYDOWN
		# ------------------
		
		HANDLE_PLAYER_MOVEMENT_Y:
			# Compare players initial jump
			beqz PLAYER_yVEL, APPLY_GRAVITY
			# Apply y-velocity
			move $a0, PLAYER_POS	# $a0 is the destination position
			add $a0, $a0, PLAYER_yVEL
			li $a1, -NEXT_ROW	# $a1 is the step

			# STATUS EFFECT: GRAVITY (Jump downwards)
			lw $t0, 0($sp)	# $t0 is the current status effect
			beqz $t0, HANDLE_PLAYER_MOVEMENT_Y_NO_STATUS_EFFECT
			
			beq $t0, GRAVITY_POTION_ID, HANDLE_PLAYER_MOVEMENT_Y_GRAVITY_EFFECT

			j HANDLE_PLAYER_MOVEMENT_Y_NO_STATUS_EFFECT

			HANDLE_PLAYER_MOVEMENT_Y_GRAVITY_EFFECT:
				li $a1, NEXT_ROW
				move $a0, PLAYER_POS
				sub $a0, $a0, PLAYER_yVEL

			HANDLE_PLAYER_MOVEMENT_Y_NO_STATUS_EFFECT:
			jal CLAMP_MOVEMENT	# $v0 is the 0 < $v0 <= $a0
			move PLAYER_POS, $v0

			beq $v1, 1, CHECK_USED_JUMP	# No collisions were detected
			beq $v1, 0, CHECK_USED_JUMP

			addi	$sp, $sp, -4	# Push state to stack
			sw	$v1, 0($sp)

			move $a0, PLAYER_POS
			jal PLAYER_COLLIDED_EVENT

			lw	$v1, 0($sp)	# Pop state from stack back into $v1
			addi	$sp, $sp, 4	
			j CHECK_USED_JUMP

			# ------------------
			APPLY_GRAVITY:
				# $a0 is the destination position
				move $a0, PLAYER_POS
				addi $a0, $a0, NEXT_ROW
				li $a1, NEXT_ROW	# $a1 is the step

				# STATUS EFFECT: REVERSE GRAVITY (Gravity extra strong)
				lw $t0, 0($sp)	# $t0 is the current status effect
				beqz $t0, APPLY_GRAVITY_NO_STATUS_EFFECT

				beq $t0, GRAVITY_POTION_ID, APPLY_GRAVITY_GRAVITY_EFFECT
				j APPLY_GRAVITY_NO_STATUS_EFFECT

				APPLY_GRAVITY_GRAVITY_EFFECT:
					move $a0, PLAYER_POS
					subi $a0, $a0, NEXT_ROW
					subi $a0, $a0, NEXT_ROW
					li $a1, -NEXT_ROW

				APPLY_GRAVITY_NO_STATUS_EFFECT:

				jal CLAMP_MOVEMENT	# $v0 is the 0 < $v0 <= $a0

				move PLAYER_POS, $v0
				
				# If $v1 = 1, there was no collision.
				beq $v1, 1, CHECK_RESTORE_JUMPS 
				beq $v1, 0, CHECK_RESTORE_JUMPS
				
				addi	$sp, $sp, -4	# Push state to stack
				sw	$v1, 0($sp)
				
				bne $v1, 3, GRAVITY_CHECK_COLLISION	# $v1 == 2, grounded and collide. restore jump
				li JUMPS_LEFT, 2	# Leak down to GRAVITY_CHECK_COLLISION

				GRAVITY_CHECK_COLLISION:
					move $a0, PLAYER_POS
					jal PLAYER_COLLIDED_EVENT

					lw	$v1, 0($sp)	# Pop state from stack back into $v1
					addi	$sp, $sp, 4	

				CHECK_RESTORE_JUMPS:
					beqz $v1, CHECK_USED_JUMP	# $v1 == 0 -> Falling State
					beq $v1, 3, CHECK_USED_JUMP # $v1 == 3 -> Falling state + Collision (Handled earlier)
					li JUMPS_LEFT, 2

				b IGNORE_JUMP_RESTRICTION
				
			CHECK_USED_JUMP:
				# Prevent double jump if player did not use jump prior to falling state
				beqz JUMPS_LEFT, IGNORE_JUMP_RESTRICTION # Ensures JUMPS_LEFT = 0 doesn't get reset next line
				li JUMPS_LEFT, 1
			
			# CHECK IF WE ARE FALLING OUT OF SCREEN. YES => DEATH
			IGNORE_JUMP_RESTRICTION:
				addi $t0, PLAYER_POS, PLAYER_BOTRIGHT		# $t0 is the bottom right of player hitbox
				li $t1, END_ADDRESS							# If we are still on screen, skip fix
				blt $t0, $t1, HANDLE_PLAYER_MOVEMENT_X

				# Fall out of screen -> DEATH
				subi PLAYER_POS, PLAYER_POS, NEXT_ROW		# Keep above bottom of screen
				j PLAYER_DEAD
				bgt PLAYER_POS, BASE_ADDRESS, HANDLE_PLAYER_MOVEMENT_X

			HANDLE_PLAYER_MOVEMENT_X:
				# CLAMP SIDEWAYS MOVEMENT
				# $a0 is the destination position
				add $a0, PLAYER_POS, PLAYER_xVEL				# Apply velocity to player
				move $t2, PLAYER_xVEL								# Store players velocity
				lw $t0, 0($sp)									# Get Status Effect
				beqz $t0, HANDLE_PLAYER_MOVEMENT_X_NO_EFFECT	# There is no effects

				# STATUS EFFECT: Check if status effect is VODKA
				beq $t0, VODKA_POTION_ID, HANDLE_PLAYER_MOVEMENT_X_VODKA
				j HANDLE_PLAYER_MOVEMENT_X_NO_EFFECT

				HANDLE_PLAYER_MOVEMENT_X_VODKA:
					sub $t2, $zero, $t2 # Reverse velocity
					add $a0, PLAYER_POS, $t2 # Reverse movement

				HANDLE_PLAYER_MOVEMENT_X_NO_EFFECT:
					# $a1 is the step
					# Determine if left or right
					li $a1, 4
					bgtz $t2, CONT_X_CLAMP
					li $a1, -4
				CONT_X_CLAMP:
					jal CLAMP_MOVEMENT

					move PLAYER_POS, $v0
					
					beq $v1, 1, NO_HORIZONTAL_COLLIDE # Player has not collided with anything
					beq $v1, 0, NO_HORIZONTAL_COLLIDE
					# Player has collided. Specific states 2, 3 have same effect.
					move $a0, PLAYER_POS
					jal PLAYER_COLLIDED_EVENT

				NO_HORIZONTAL_COLLIDE:
					jal UPDATE_PLAYER_VEL
			
		
		# Pop status effect from stack
		addi $sp, $sp, 4

		# SAVE NEW PLAYER DATA
		la $a0, player_data		# Save the player_data struct
		jal SAVE_DATA
	# -------------------
	#
	# HANDLE WORLD UPDATE
	#
	# ------------------
	# Update world data
	WORLD_UPDATE:
		la $a0, world_data		# Load the world struct
		jal LOAD_DATA

		addi FRAMES_ELAPSED, FRAMES_ELAPSED, 1
		CHECK_ADD_SECOND:
			blt FRAMES_ELAPSED, COMPUTED_FPS, WORLD_UPDATE_FINISHED	# Not enough frames have elapsed
			addi SECONDS_ELAPSED, SECONDS_ELAPSED, 1
			li FRAMES_ELAPSED, 0
		WORLD_UPDATE_FINISHED:
			la $a0, world_data		# Save the world data
			jal SAVE_DATA
			
		move $t0, SECONDS_ELAPSED
		move $t1, FRAMES_ELAPSED
	# $t0 is passed as the current world seconds
	# $t1 is passed as the current frames elapsed
	# -------------------
	#
	# HANDLE ENTITY UPDATE
	#	
	# ------------------
	ENTITY_UPDATE:
		# Load Level Data
		la $a0, level_data
		jal LOAD_DATA

		# Check if player is under a status effect
		beqz EFFECT_USED, HANDLE_ENTITY_COLLIDE_EVENTS	# Skip b/c no effects

		bnez $t1, APPLY_EFFECT
		subi EFFECT_DURATION, EFFECT_DURATION, 1 # Subtract effect duration
		APPLY_EFFECT:
			# Check if status effect is finished
			blez EFFECT_DURATION, CANCEL_EFFECT
			
			DETERMINE_EFFECT:	# Check which effect the player is under
				j HANDLE_ENTITY_COLLIDE_EVENTS
				b CANCEL_EFFECT	# Unknown effect. remove it.

		CANCEL_EFFECT:
			li EFFECT_USED, 0	# Set effect used to NONE aka 0

		HANDLE_ENTITY_COLLIDE_EVENTS:
			beqz CURRENT_COLLIDE_WITH_PLR, ENTITY_UPDATE_EXIT	# No event happened
			beq CURRENT_COLLIDE_WITH_PLR, KEY_ID, PICKUP_KEY
			beq CURRENT_COLLIDE_WITH_PLR, SPIKE_ID, TOUCH_SPIKE
			beq CURRENT_COLLIDE_WITH_PLR, GATE_ID, TOUCH_GATE
			beq CURRENT_COLLIDE_WITH_PLR, HEALTH_RESTORE_ID, TOUCH_HEALTH_RESTORE
			beq CURRENT_COLLIDE_WITH_PLR, VODKA_POTION_ID, TOUCH_POTION_VODKA
			# beq CURRENT_COLLIDE_WITH_PLR, FLIGHT_POTION_ID, TOUCH_POTION_FLYING [ NOT IMPLEMENTED ]
			beq CURRENT_COLLIDE_WITH_PLR, GRAVITY_POTION_ID, TOUCH_POTION_GRAVITY
			j ENTITY_UPDATE_EXIT	# No known events, skip.

			# Event: Unlock the gate
			PICKUP_KEY:
				li $a0, KEY_ID
				jal HIDE_ENTITY
				li KEY_POSITION, -1
				j ENTITY_UPDATE_EXIT
			
			# Event: A brutal death smh
			TOUCH_SPIKE:
				li CURRENT_COLLIDE_WITH_PLR, 0	# Clear collider for reload
				la $a0, level_data
				jal SAVE_DATA
				j PLAYER_DEAD
			
			# Event: Go to next level if opened
			TOUCH_GATE:
				# Check if gate is opened.
				bgtz KEY_POSITION, ENTITY_UPDATE_EXIT
				j LOAD_NEXT_LEVEL
			# Event: Increase health by one
			TOUCH_HEALTH_RESTORE:
				la $a0, player_data		# Load player data to retrieve health
				jal LOAD_DATA
				move $t0, PLAYER_HEALTH	# Store players current health into $t0
				la $a0, level_data		# Reload level data
				jal LOAD_DATA
				bge $t0, PLAYER_MAX_HEALTH, ENTITY_UPDATE_EXIT # Does player have full health? Skip.
				la $a0, player_data		# Load player data to increase health
				jal LOAD_DATA
				addi PLAYER_HEALTH, PLAYER_HEALTH, 1
				la $a0, player_data		# Save changes
				jal SAVE_DATA
				jal REDRAW_UI			# Update UI
				la $a0, level_data		# Reload level data
				jal LOAD_DATA

				move $a0, CURRENT_COLLIDE_WITH_PLR 
				jal HIDE_ENTITY
				li $t0, PICKUP_COLLECTED		# Set pickup to collected state
				sw $t0, 0(PICKUP_POINTER)
				sw $t0, 4(PICKUP_POINTER)
				j ENTITY_UPDATE_EXIT
			# Event: I dont know my left from rights
			TOUCH_POTION_VODKA:
				li EFFECT_DURATION, 5
				j TOUCH_POTION_GENERIC
			# Event: I am flying! (Not implemented.)
			TOUCH_POTION_FLYING:
				li EFFECT_DURATION, 4
				j TOUCH_POTION_GENERIC
			# Event: Gravity reversed lol
			TOUCH_POTION_GRAVITY:
				li EFFECT_DURATION, 9
				j TOUCH_POTION_GENERIC
			# Event: Does pickup cleanup stuff
			TOUCH_POTION_GENERIC:
				move EFFECT_USED, CURRENT_COLLIDE_WITH_PLR
				move $a0, CURRENT_COLLIDE_WITH_PLR # Hide the pickup
				jal HIDE_ENTITY
				li $t0, PICKUP_COLLECTED		# Set pickup to collected state
				sw $t0, 0(PICKUP_POINTER)
				sw $t0, 4(PICKUP_POINTER)
				j ENTITY_UPDATE_EXIT

	ENTITY_UPDATE_EXIT:
		la PICKUP_POINTER, pickups_array	# Reposition pointer to beginning
		li CURRENT_COLLIDE_WITH_PLR, 0	# Clear collider
		# Load Level Data
		la $a0, level_data
		jal SAVE_DATA
	# -------------------
	#
	# NOW DRAW!!!
	#
	# ------------------
	HANDLE_RENDER:
		jal REDRAW_ENTITIES_MAP
		jal DRAW_CHAR
	# -------------------
	#
	# Nap time
	#
	# ------------------
	NAP:
		li $v0, 32
		li $a0, REFRESH_RATE
		syscall
	
	j GAME_RENDER

#   ___  _       _ __   __ ___  ___ 
#  | _ \| |     /_\\ \ / /| __|| _ \
#  |  _/| |__  / _ \\ V / | _| |   /
#  |_|  |____|/_/ \_\|_|  |___||_|_\
#
# Reserves $t0 to store position before update
UPDATE_PLAYER_VEL:
	addi	$sp, $sp, -4	# Push $ra to stack
	sw	$ra, 0($sp)
	
	beqz PLAYER_xVEL, UPDATE_yVEL		# No horizontal movement, so handle vertical movement
	bgtz PLAYER_xVEL, DECREASE_xVEL		# Horizontal movement right
	b INCREASE_xVEL				# Horizontal movement left
		
	# Handle updating the y-component
	UPDATE_yVEL:	beqz PLAYER_yVEL, UPDATE_PLAYER_VEL_RETURN
					bgtz PLAYER_yVEL, DECREASE_yVEL
					b INCREASE_yVEL

	# Adjust X Component
	DECREASE_xVEL:	sub PLAYER_xVEL, PLAYER_xVEL, 0x00000004
					b UPDATE_yVEL
	INCREASE_xVEL: 	add PLAYER_xVEL, PLAYER_xVEL, 0x00000004
					b UPDATE_yVEL	
	# Adjust Y Component
	DECREASE_yVEL:	subi PLAYER_yVEL, PLAYER_yVEL, NEXT_ROW#0x00000004
					b UPDATE_PLAYER_VEL_RETURN
	INCREASE_yVEL:	addi PLAYER_yVEL, PLAYER_yVEL, NEXT_ROW#0x00000004
					b UPDATE_PLAYER_VEL_RETURN


	UPDATE_PLAYER_VEL_RETURN:	jr $ra	
	

# PROCESS KEYBOARD INPUT
# Assumes player data is already loaded, determine action from given input, save player data.
ON_KEYDOWN:
	lw $t9, 4($a0)
	# Diagonal Movement
	beq $t9, 0x71, ON_KEYq
	beq $t9, 0x51, ON_KEYq	# Capital Q : Same movement
	beq $t9, 0x65, ON_KEYe
	beq $t9, 0x45, ON_KEYe	# Capital E : Same movement
	# Horizontal Momement
	beq $t9, 0x61, ON_KEYa	# Dash Left
	beq $t9, 0x41, ON_KEYA	# Walk Left
	beq $t9, 0x64, ON_KEYd	# Dash Right
	beq $t9, 0x44, ON_KEYD	# Walk Right
	# Vertical Movement
	beq $t9, 0x73, ON_KEYs	# Down. LANCE, REMOVE ME LATER
	beq $t9, 0x77, ON_KEYw	# Jump
	beq $t9, 0x57, ON_KEYW	# Jump as well
	beq $t9, 0x20, ON_KEYSPACE	# Another way to jump.
	beq $t9, 0x70, ON_KEYp
	jr $ra
	
	ON_KEYq:	li PLAYER_xVEL, -PLAYER_WS
			li PLAYER_LASTINPUT, -1
			j KEYSTROKE_TRYJUMP
	ON_KEYe:	li PLAYER_xVEL, PLAYER_WS
			li PLAYER_LASTINPUT, 1
			j KEYSTROKE_TRYJUMP
	ON_KEYa:	li PLAYER_xVEL, -PLAYER_WS
			li PLAYER_LASTINPUT, -1
			jr $ra
	ON_KEYA:	li PLAYER_xVEL, -PLAYER_HALFWS
			li PLAYER_LASTINPUT, -1
			jr $ra	
	ON_KEYs:	addi PLAYER_POS, PLAYER_POS, NEXT_ROW
			jr $ra
	ON_KEYd:	li PLAYER_xVEL, PLAYER_WS
			li PLAYER_LASTINPUT, 1
			jr $ra
	ON_KEYD:	li PLAYER_xVEL, PLAYER_HALFWS
			li PLAYER_LASTINPUT, 1
			jr $ra
	
	ON_KEYSPACE: 	b KEYSTROKE_TRYJUMP
	ON_KEYw:	b KEYSTROKE_TRYJUMP
	ON_KEYW:	b KEYSTROKE_TRYJUMP
	ON_KEYp:	j PLAYER_DEAD

	KEYSTROKE_TRYJUMP:
		blez JUMPS_LEFT, KEYSTROKE_RETURN
		subi JUMPS_LEFT, JUMPS_LEFT, 1
		beqz JUMPS_LEFT, KEYSTROKE_SECOND_JUMP	# 0 jumps left means we just used our second jump
		li PLAYER_yVEL, -PLAYER_JP
		b KEYSTROKE_RETURN

		KEYSTROKE_SECOND_JUMP:
		li PLAYER_yVEL, -PLAYER_SECOND_JP

	KEYSTROKE_RETURN: 	
	jr $ra
	
# Assumes player_data is loaded.
# Check all corners of the players hitbox
# $a0 = end-velocity, $a1 = step
# $v0 = Address of position before colliding with wall
# $v1 = 0 (falling), 1 (grounded), 2(grounded+collide), 3(!grounded+collide),
CLAMP_MOVEMENT:	
	lw $a3, 0($sp)		# Store the current status effect into $a3
	# Push $ra to stack
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)

	move $v0, PLAYER_POS	# Store return position at players current position
	li $t7, WALL_COLOR
	li $t9, COLOUR_BG
	li $v1, 0	# GROUNDED (Default False)
	# Note, using unused arg register due to lack of space.
	# I am avoiding stack as loading onto memory is slower
	li $a2, 0	# TOUCH NON BACKGROUND/WALL COLOR
	j CLAMP_MOVEMENT_LOOP

	# Reasoning,
	#		$a2
	# v1 | 0             | 1
	# 0 | Nothing       | Collide but not grounded 
	# 1 | Grounded     | Collide and Grounded
	CLAMP_MOVEMENT_LOOP:
		jal CLAMP_MOVEMENT_GETVARS	# Update scan nodes relative to player's projected position
		# --------------------------------------------------------------------------------------------------
		lw $t8, 0($t0)										# $t8 is top left color
		beqz $a3, CM_SCAN_NORMAL_TL							# Do normal check if there are no status effects
		bne $a3, GRAVITY_POTION_ID, CM_SCAN_NORMAL_TL		# Do gravity potion related checks. (Top nodes to detect grounded)

		CM_SCAN_GRAVITY_EFFECT_TL:	
		beq $t8, $t7, CM_SCAN_GRAVITY_EFFECT_TL_NO_COLLIDE		# The cell is wall
		beq $t8, $t9, CM_SCAN_GRAVITY_EFFECT_TL_NO_COLLIDE		# The cell is background
		li $a2, 1												# Above checks fail -> Unknown Color = Check collision
		CM_SCAN_GRAVITY_EFFECT_TL_NO_COLLIDE:					# Check if we are touching ceiling, give grounded.
						beq $t8, $t7, GROUNDED								

		CM_SCAN_NORMAL_TL:
			beq $t8, $t7, CM_SCAN_NO_COLLIDE_TL								# The cell is wall
			beq $t8, $t9, CM_SCAN_NO_COLLIDE_TL								# The cell is background
			li $a2, 1														# The cell is not a background, it is an unknown color
			CM_SCAN_NO_COLLIDE_TL:		beq $t8, $t7, CLAMP_MOVEMENT_HIT	# Check top left collides
		# --------------------------------	
		# Not enough registers. Shift $t0 by half width to get top middle
		addi $t0, $t0, PLAYER_HALFWIDTH
		lw $t8, 0($t0)										# $t8 is top middle color
		beqz $a3, CM_SCAN_NORMAL_TM							# Do normal check if there are no status effects
		bne $a3, GRAVITY_POTION_ID, CM_SCAN_NORMAL_TM		# Do gravity potion related checks. (Top nodes to detect grounded)

		CM_SCAN_GRAVITY_EFFECT_TM:	
		beq $t8, $t7, CM_SCAN_GRAVITY_EFFECT_TM_NO_COLLIDE		# The cell is wall
		beq $t8, $t9, CM_SCAN_GRAVITY_EFFECT_TM_NO_COLLIDE		# The cell is background
		li $a2, 1												# Above checks fail -> Unknown Color = Check collision
		CM_SCAN_GRAVITY_EFFECT_TM_NO_COLLIDE:					# Check if we are touching ceiling, give grounded.
						beq $t8, $t7, GROUNDED								

		CM_SCAN_NORMAL_TM:
			beq $t8, $t7, CM_SCAN_NO_COLLIDE_TM								# The cell is wall
			beq $t8, $t9, CM_SCAN_NO_COLLIDE_TM								# The cell is background
			li $a2, 1														# The cell is not a background, it is an unknown color
			CM_SCAN_NO_COLLIDE_TM:		beq $t8, $t7, CLAMP_MOVEMENT_HIT	# Check top left collides
		# --------------------------------		
		lw $t8, 0($t2)										# $t8 is top right color
		beqz $a3, CM_SCAN_NORMAL_TR							# Do normal check if there are no status effects
		bne $a3, GRAVITY_POTION_ID, CM_SCAN_NORMAL_TR		# Do gravity potion related checks. (Top nodes to detect grounded)

		CM_SCAN_GRAVITY_EFFECT_TR:	
		beq $t8, $t7, CM_SCAN_GRAVITY_EFFECT_TR_NO_COLLIDE		# The cell is wall
		beq $t8, $t9, CM_SCAN_GRAVITY_EFFECT_TR_NO_COLLIDE		# The cell is background
		li $a2, 1												# Above checks fail -> Unknown Color = Check collision
		CM_SCAN_GRAVITY_EFFECT_TR_NO_COLLIDE:					# Check if we are touching ceiling, give grounded.
						beq $t8, $t7, GROUNDED								

		CM_SCAN_NORMAL_TR:
			beq $t8, $t7, CM_SCAN_NO_COLLIDE_TR								# The cell is wall
			beq $t8, $t9, CM_SCAN_NO_COLLIDE_TR								# The cell is background
			li $a2, 1														# The cell is not a background, it is an unknown color
			CM_SCAN_NO_COLLIDE_TR:		beq $t8, $t7, CLAMP_MOVEMENT_HIT	# Check top right collides
		# --------------------------------

		lw $t8, 0($t4)
		beq $t8, $t7, CM_NO_COLLIDE_ML
		beq $t8, $t9, CM_NO_COLLIDE_ML
		li $a2, 1

		CM_NO_COLLIDE_ML:				# Check middle left collides
			beq $t8, $t7, CLAMP_MOVEMENT_HIT
		
		# --------------------------------
		lw $t8, 0($t5)
		beq $t8, $t7, CM_NO_COLLIDE_MR
		beq $t8, $t9, CM_NO_COLLIDE_MR
		li $a2, 1
		
		CM_NO_COLLIDE_MR:				# Check middle right collides
			beq $t8, $t7, CLAMP_MOVEMENT_HIT
		
		# --------------------------------
		lw $t8, 0($t1)
		beq $t8, $t7, CM_NO_COLLIDE_BL
		beq $t8, $t9, CM_NO_COLLIDE_BL
		li $a2, 1
		
		CM_NO_COLLIDE_BL:				# Check bottom left collides
			beq $t8, $t7, GROUNDED
		
		# --------------------------------
		lw $t8, 0($t3)
		beq $t8, $t7, CM_NO_COLLIDE_BR
		beq $t8, $t9, CM_NO_COLLIDE_BR
		li $a2, 1
		CM_NO_COLLIDE_BR:				# Check bottom right collides
			beq $t8, $t7, GROUNDED
		
		# --------------------------------
		lw $t8, 0($t6)
		beq $t8, $t7, CM_NO_COLLIDE_BM
		beq $t8, $t9, CM_NO_COLLIDE_BM
		li $a2, 1
		CM_NO_COLLIDE_BM:				# Check bottom middle collides
			beq $t8, $t7, GROUNDED

		# We did not collide with anything in this iteration
		# -------------------------------------------------------------------------------------------------- #
		beq $v0, $a0, CLAMP_MOVEMENT_DONE	# If we have reached the desired end position, exit.
		add $v0, $v0, $a1					# Add to our max end position
		j CLAMP_MOVEMENT_LOOP
		# -------------------------------------------------------------------------------------------------- #
		
		CLAMP_MOVEMENT_GETVARS:
			move $t0, $v0				# Top Left 	($t0)
			move $t2, $v0				# Top Right	($t2)
			addi $t2, $t2, PLAYER_WIDTH		
			move $t4, $v0				# Middle Left	($t4)
			add $t4, $t4, PLAYER_MIDLEFT
			move $t5, $t4				# Middle Right	($t5)
			addi $t5, $t5, PLAYER_WIDTH
			move $t3, $v0				# Bottom Right	($t3)
			add $t3, $t3, PLAYER_BOTRIGHT
			move $t1, $t3				# Bottom Left	($t1)
			subi $t1, $t1, PLAYER_WIDTH
			move $t6, $t1				# Middle Bottom	($t6)
			addi $t6, $t6, PLAYER_HALFWIDTH
			jr $ra
	GROUNDED:	li $v1, 1
	CLAMP_MOVEMENT_HIT:	
		sub $v0, $v0, $a1 # Revoke last step
		li $t7, 0x0000ff00
	CLAMP_MOVEMENT_DONE:
		move $t0, $v1		# Store $v1 original value to compare later

		# STATE CHECKS
		# $a2 == 0
		beqz $a2, CLAMP_MOVEMENT_RETURN		# $a2 == 0 -> We only get 0 or 1 e.g. grounded / not grounded
		# Given: $a2 = 1
		beq $v1, 1, CLAMP_MOVEMENT_RETURN 	# $a2 == 1 and $v1 == 1 -> Grounded and colliding
		# Given: $a2 = 1, $v1 = 0
		li $a2, 3 							# $a2 == 1 and $v1 == 0 -> Colliding but not grounded

		CLAMP_MOVEMENT_RETURN:
		add $v1, $v1, $a2	# Sum of grounded+collide gives us our return value.
		move $t0, $v0
		move $t1, $v1

		move $v0, $t0
		move $v1, $t1
		
		lw	$ra, 0($sp)
		addi	$sp, $sp, 4
		jr	$ra



#  ___                      _             
# |   \  _ _  __ _ __ __ __(_) _ _   __ _ 
# | |) || '_|/ _` |\ V  V /| || ' \ / _` |
# |___/ |_|  \__,_| \_/\_/ |_||_||_|\__, |
#                                   |___/ 
# Assumes player_data is loaded.
# a0 - The top-left position to begin drawing
CLEAR_CHAR:
	addi	$sp, $sp, -4		# Push $ra to stack
	sw	$ra, 0($sp)
	
	move $a0, PLAYER_POS
	move $a1, PLAYER_POS
	add $a1, $a1, PLAYER_BOTRIGHT
	li $a2, PLAYER_WIDTH
	jal FILL_BG
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra

# This function takes in the topleft position from $a0
DRAW_CHAR:
	move $t9, $ra
	
	la $a0, level_data
	jal LOAD_DATA
	move $t8, EFFECT_USED		# Store current status effect into $t9
	la $a0, player_data
	jal LOAD_DATA
	move $ra, $t9				# Restore $ra
	move $a0, PLAYER_POS		# load player postion into $a0

	li $t1, PLR_COLOR1
	li $t2, PLR_COLOR2
	li $t3, PLR_EYECOL
	li $t4, NEXT_ROW
	# Check Status Effects
	beqz $t8, DRAW_CHAR_BEGIN	# No status effect
	beq $t8, VODKA_POTION_ID, DRAW_VODKA_PLAYER
	beq $t8, GRAVITY_POTION_ID, DRAW_UPSIDE_DOWN_PLAYER
	j DRAW_CHAR_BEGIN

	DRAW_VODKA_PLAYER:
		li $t1, VODKA_PLR_COLOR1
		li $t3, VODKA_PLR_EYECOL
		j DRAW_CHAR_BEGIN

	DRAW_UPSIDE_DOWN_PLAYER:
		li $t1, GRAVITY_PLR_COLOR1
		li $t2, GRAVITY_PLR_COLOR2
		li $t3, GRAVITY_PLR_EYECOL
		li $t4, -NEXT_ROW
		# Shift player position down to compensave different direction
		addi $a0, $a0, NEXT_ROW
		addi $a0, $a0, NEXT_ROW
		addi $a0, $a0, NEXT_ROW
		addi $a0, $a0, NEXT_ROW
		j DRAW_CHAR_BEGIN
	DRAW_CHAR_BEGIN:
		beq PLAYER_LASTINPUT, 1, DRAW_RIGHT	# Draw sprite facing right if last input was such
	DRAW_LEFT:
		sw $t1, 0($a0)
		sw $t1, 4($a0)
		sw $t1, 8($a0)
		sw $t1, 12($a0)
		sw $t1, 16($a0)
		add $a0, $a0, $t4
		sw $t3, 0($a0)
		sw $t2, 4($a0)
		sw $t3, 8($a0)
		sw $t1, 12($a0)
		add $a0, $a0, $t4
		sw $t2, 0($a0)
		sw $t2, 4($a0)
		sw $t2, 8($a0)
		sw $t1, 12($a0)
		# --- Left Body
		add $a0, $a0, $t4
		sw $t1, 0($a0)
		sw $t1, 4($a0)
		sw $t1, 8($a0)
		sw $t1, 12($a0)
		add $a0, $a0, $t4
		sw $t1, 0($a0)
		sw $t1, 4($a0)
		sw $t1, 8($a0)
		sw $t1, 12($a0)
		jr $ra
	DRAW_RIGHT:
		sw $t1, 0($a0)
		sw $t1, 4($a0)
		sw $t1, 8($a0)
		sw $t1, 12($a0)
		sw $t1, 16($a0)
		add $a0, $a0, $t4
		sw $t1, 4($a0)
		sw $t3, 8($a0)
		sw $t2, 12($a0)
		sw $t3, 16($a0)
		add $a0, $a0, $t4
		sw $t1, 4($a0)
		sw $t2, 8($a0)
		sw $t2, 12($a0)
		sw $t2, 16($a0)
		# --- Right Body
		add $a0, $a0, $t4
		sw $t1, 4($a0)
		sw $t1, 8($a0)
		sw $t1, 12($a0)
		sw $t1, 16($a0)
		add $a0, $a0, $t4
		sw $t1, 4($a0)
		sw $t1, 8($a0)
		sw $t1, 12($a0)
		sw $t1, 16($a0)
		jr $ra


# This function takes in the topleft position from $a0
DRAW_KEY:
	li $t0, 0x00ffc107	# Dark yellow 
	li $t1, 0x00ffeb3b	# Bright Yellow
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	sw $t1, 8($a0)
	sw $t1, 12($a0)
	sw $t1, 16($a0)
	sw $t1, 20($a0)
	add $a0, $a0, NEXT_ROW
	sw $t1, 0($a0)
	sw $t1, 4($a0)
	sw $t0, 12($a0)
	sw $t0, 20($a0)
	jr $ra
	
# This function takes in the topleft position from $a0
DRAW_EMPTY_HEART:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	lw $t0, 0($sp)
	addi $t0, $t0, 516
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	li $a3, 0x00918e8e
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 528
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	li $a3, 0x00918e8e
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 1028
	move $a0, $t0
	addi $t0, $t0, 528
	move $a1, $t0
	li $a2, 12
	li $a3, 0x00918e8e
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 2056
	move $a0, $t0
	addi $t0, $t0, 8
	move $a1, $t0
	li $a2, 4
	li $a3, 0x00918e8e
	jal FILL
	addi	$sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra

# This function takes in the topleft position from $a0
DRAW_HEART:
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	
	li $t1, HEART_COLOR
	lw $t0, 0($sp)
	addi $t0, $t0, 4
	move $a0, $t0
	addi $t0, $t0, 8
	move $a1, $t0
	li $a2, 4
	li $a3, HEART_COLOR
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 16
	move $a0, $t0
	addi $t0, $t0, 8
	move $a1, $t0
	li $a2, 4
	li $a3, HEART_COLOR
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 512
	move $a0, $t0
	addi $t0, $t0, 540
	move $a1, $t0
	li $a2, 24
	li $a3, HEART_COLOR
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 1540
	move $a0, $t0
	addi $t0, $t0, 20
	move $a1, $t0
	li $a2, 16
	li $a3, HEART_COLOR
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 2056
	move $a0, $t0
	addi $t0, $t0, 12
	move $a1, $t0
	li $a2, 8
	li $a3, HEART_COLOR
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 2572
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	li $a3, HEART_COLOR
	jal FILL
	addi	$sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	
	
	


# Draws the restore heart pickup
DRAW_HEART_PICKUP:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	li $t0, 0x00ea4848
	sw $t0, 0($a0)
	sw $t0, 512($a0)
	sw $t0, 8($a0)
	sw $t0, 520($a0)
	sw $t0, 516($a0)
	sw $t0, 1028($a0)
	
	addi	$sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	
# Draws the gravity potion, whoopsies, now you cant go down.
DRAW_GRAVITY_POTION:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	li $t0, 0x00a5a5a5
	sw $t0, 4($a0)
	sw $t0, 516($a0)
	sw $t0, 1024($a0)
	sw $t0, 1032($a0)
	
	li $t0, 0x00f8ffff
	sw $t0, 1028($a0)
	sw $t0, 1540($a0)
	sw $t0, 1536($a0)
	sw $t0, 1544($a0)
	
	addi	$sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
# Draws the vodka potion, now you don't know your lefts from rights
DRAW_VODKA_POTION:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	li $t0, 0x00a5a5a5
	sw $t0, 4($a0)
	sw $t0, 516($a0)
	sw $t0, 1024($a0)
	sw $t0, 1032($a0)
	li $t0, 0x00f8ffff
	sw $t0, 1028($a0)
	sw $t0, 1540($a0)
	sw $t0, 1536($a0)
	sw $t0, 1544($a0)
	li $t0, 0x00967049
	sw $t0, 1536($a0)
	sw $t0, 1540($a0)
	sw $t0, 1544($a0)
	sw $t0, 1028($a0)
	addi	$sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	
# Draws the pickups that are currently on screen
DRAW_PICKUPS:
	addi	$sp, $sp, -4 	# Push return address to stack.
	sw	$ra, 0($sp)	

	la PICKUP_POINTER, pickups_array # Return to initial state.

	lw $t0, 0(PICKUP_POINTER)		# The position of the pickup
	lw $t1, 4(PICKUP_POINTER)		# The id of the pickup
	beqz $t0, DRAW_PICKUPS_EXIT		# There is nothing to draw.

	DRAW_PICKUPS_LOOP:
		addi $a0, $t0, BASE_ADDRESS
		bltz $t1, DRAW_PICKUPS_LOOP_NEXT				# This pickup has already been collected.
		beq $t1, HEALTH_RESTORE_ID, DRAW_PICKUPS_HEART	# This pickup is a heart
		beq $t1, VODKA_POTION_ID, 	DRAW_PICKUPS_VODKA_POTION
		beq $t1, GRAVITY_POTION_ID, DRAW_PICKUPS_GRAVITY_POTION
		b DRAW_PICKUPS_LOOP_NEXT

		DRAW_PICKUPS_HEART:		
			jal DRAW_HEART_PICKUP
			b DRAW_PICKUPS_LOOP_NEXT

		DRAW_PICKUPS_VODKA_POTION:
			jal DRAW_VODKA_POTION
			b DRAW_PICKUPS_LOOP_NEXT
		
		DRAW_PICKUPS_GRAVITY_POTION:
			jal DRAW_GRAVITY_POTION
			b DRAW_PICKUPS_LOOP_NEXT

		DRAW_PICKUPS_LOOP_NEXT:
			addi PICKUP_POINTER, PICKUP_POINTER, PICKUP_DATA_SIZE
			lw $t0, 0(PICKUP_POINTER)
			lw $t1, 4(PICKUP_POINTER)
			bnez $t0, DRAW_PICKUPS_LOOP

	DRAW_PICKUPS_EXIT:
			la PICKUP_POINTER, pickups_array # Restore
			lw	$ra, 0($sp)	# Return to sender.
			addi	$sp, $sp, 4
			jr	$ra

# THESE FUNCTIONS ARE USED WITHIN ALL OF THE MAPS.
REDRAW_ENTITIES_MAP:
	addi	$sp, $sp, -4 	# Push return address to stack.
	sw	$ra, 0($sp)
	
	# Load Level Data
	la $a0, level_data
	jal LOAD_DATA

	jal DRAW_PICKUPS

	# Check if gate is accessed
	bltz KEY_POSITION, DRAW_GATE

	# RANDOM KEY POSITION FOR NOW
	add $a0, KEY_POSITION, BASE_ADDRESS
	jal DRAW_KEY

	DRAW_GATE:
		beq KEY_POSITION, -1, DRAW_OPEN_GATE
		jal PLACE_EXIT_MAP

		j REDRAW_ENTITIES_MAP_EXIT

		DRAW_OPEN_GATE:
			jal PLACE_EXIT_MAP_OPEN

	REDRAW_ENTITIES_MAP_EXIT:
	lw	$ra, 0($sp)	# Return to sender.
	addi	$sp, $sp, 4
	jr	$ra
    
# Closed gate
PLACE_EXIT_MAP:
	li $t0, BASE_ADDRESS
	add $t0, $t0, GATE_POSITION
	move $a0, $t0
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)

	addi $sp, $sp, -4
	sw $a0, 0($sp)

	lw $t0, 0($sp)
	addi $t0, $t0, 512
	move $a0, $t0
	addi $t0, $t0, 2564
	move $a1, $t0
	li $a2, 0
	li $a3, 0x00191919
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 512
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	li $a3, 0x00191919
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 1536
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	li $a3, 0x00191919
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 512
	move $a0, $t0
	addi $t0, $t0, 2564
	move $a1, $t0
	li $a2, 0
	li $a3, 0x00373737
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 4
	move $a0, $t0
	addi $t0, $t0, 20
	move $a1, $t0
	li $a2, 16
	li $a3, 0x00373737
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 536
	move $a0, $t0
	addi $t0, $t0, 2564
	move $a1, $t0
	li $a2, 0
	li $a3, 0x00373737
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 3604
	move $a0, $t0
	addi $t0, $t0, 8
	move $a1, $t0
	li $a2, 4
	li $a3, 0x00373737
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 3584
	move $a0, $t0
	addi $t0, $t0, 8
	move $a1, $t0
	li $a2, 4
	li $a3, 0x00373737
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 516
	move $a0, $t0
	addi $t0, $t0, 2568
	move $a1, $t0
	li $a2, 4
	li $a3, 0x006b5b4a
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 528
	move $a0, $t0
	addi $t0, $t0, 2568
	move $a1, $t0
	li $a2, 4
	li $a3, 0x006b5b4a
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 524
	move $a0, $t0
	addi $t0, $t0, 3076
	move $a1, $t0
	li $a2, 0
	li $a3, 0x003a3734
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 3592
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	li $a3, 0x006b5b4a
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 3600
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	li $a3, 0x006b5b4a
	jal FILL
	addi	$sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra

# Opened gate
PLACE_EXIT_MAP_OPEN:
	li $t0, BASE_ADDRESS
	add $t0, $t0, GATE_POSITION
	move $a0, $t0
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	lw $t0, 0($sp)
	addi $t0, $t0, 3604
	move $a0, $t0
	addi $t0, $t0, 8
	move $a1, $t0
	li $a2, 4
	li $a3, 0x00ffee58
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 3584
	move $a0, $t0
	addi $t0, $t0, 8
	move $a1, $t0
	li $a2, 4
	li $a3, 0x00ffee58
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 4
	move $a0, $t0
	addi $t0, $t0, 20
	move $a1, $t0
	li $a2, 16
	li $a3, 0x00ffee58
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 536
	move $a0, $t0
	addi $t0, $t0, 2564
	move $a1, $t0
	li $a2, 0
	li $a3, 0x00ffee58
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 512
	move $a0, $t0
	addi $t0, $t0, 2564
	move $a1, $t0
	li $a2, 0
	li $a3, 0x00ffee58
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 516
	move $a0, $t0
	addi $t0, $t0, 2564
	move $a1, $t0
	li $a2, 0
	li $a3, 0x00212121
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 520
	move $a0, $t0
	addi $t0, $t0, 16
	move $a1, $t0
	li $a2, 12
	li $a3, 0x00212121
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 1044
	move $a0, $t0
	addi $t0, $t0, 2052
	move $a1, $t0
	li $a2, 0
	li $a3, 0x00212121
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 1032
	move $a0, $t0
	addi $t0, $t0, 2564
	move $a1, $t0
	li $a2, 0
	li $a3, 0x001a1a1a
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 1036
	move $a0, $t0
	addi $t0, $t0, 8
	move $a1, $t0
	li $a2, 4
	li $a3, 0x001a1a1a
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 1552
	move $a0, $t0
	addi $t0, $t0, 2052
	move $a1, $t0
	li $a2, 0
	li $a3, 0x001a1a1a
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 1548
	move $a0, $t0
	addi $t0, $t0, 2052
	move $a1, $t0
	li $a2, 0
	li $a3, 0x00141414
	jal FILL
	addi	$sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra



# Similar to the fill tool, will draw a series of L shapes to denote a spike
DRAW_SPIKES:
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)

	# Store the spike positional data
	move $t0, $a0
	move $t1, $a2
	
	# Store values
	# Fill entire section red.
	li $a3, SPIKE_COLOR
	jal FILL

	# Load back the spike positional data
	move $a0, $t0	# Topleft of spike
	add $a1, $a0, $t1	# Topleft + Step = Topright of spike.
	li $t0, COLOUR_BG
	# Clear every second tile to make spike appear as L
	DRAW_SPIKE_CLEAR_SECOND_TILE:
		bgt $a0, $a1, DRAW_SPIKE_EXIT	# We have passed topright
		sw $t0, 4($a0)					# Clear cell
		addi $a0, $a0, 8				# Move two cells right
		j DRAW_SPIKE_CLEAR_SECOND_TILE

	DRAW_SPIKE_EXIT:
		# Return to sender.
		lw	$ra, 0($sp)
		addi	$sp, $sp, 4
		jr	$ra

# Initialize required data and prepare the next map
BEGIN_GAME:
	# initialize player data
	la $a0, player_data		# Load the player_data struct
	jal LOAD_DATA
	# Initialize player data
	li PLAYER_xVEL, 0
	li PLAYER_yVEL, 0
	li PLAYER_HEALTH, PLAYER_MAX_HEALTH
	li JUMPS_LEFT, 2

	la $a0, player_data		# Save the player_data struct
	jal SAVE_DATA

	# initialize level data
	la $a0, level_data
	jal LOAD_DATA

	li CURRENT_LEVEL, STARTING_LEVEL		# Level 0 does not exist. But it will be incremented on LOAD_NEXT_LEVEL
	
	la $a0, level_data
	jal SAVE_DATA

	j LOAD_NEXT_LEVEL

# Prepare the next level
LOAD_NEXT_LEVEL:
	jal CLEAR_MAP
	jal REDRAW_UI

	la $a0, level_data
	jal LOAD_DATA

 	li EFFECT_USED, 0
	li EFFECT_DURATION, 0

	la PICKUP_POINTER, pickups_array
	li $a0, 0								# This will be overwritten during level load. Hopefully?
	sw $a0, 0(PICKUP_POINTER)

	addi CURRENT_LEVEL, CURRENT_LEVEL, 1
	
	jal LOAD_LEVEL_DATA

	j GAME_RENDER
# Clear the screen, redraw UI and reset player and world data.
RELOAD_MAP:
	jal CLEAR_MAP
	jal REDRAW_UI
	
	la $a0, level_data
	jal LOAD_DATA

	# Clear status effects.
	li EFFECT_DURATION, 0
	li EFFECT_USED, 0

	la $a0, pickups_array
	addi $a1, $a0, PICKUP_SPACE
	jal CLEAR_ARRAY

	jal LOAD_LEVEL_DATA

	j GAME_RENDER

# Takes in the current level at $a0 and loads the data accordingly.
LOAD_LEVEL_DATA:
	addi	$sp, $sp, -4	# Push $ra to stack
	sw	$ra, 0($sp)

	beq CURRENT_LEVEL, WIN_AT_LEVEL, WIN_STATE
	beq CURRENT_LEVEL, 1, LOAD_LEVEL_DATA_1
	beq CURRENT_LEVEL, 2, LOAD_LEVEL_DATA_2
	beq CURRENT_LEVEL, 3, LOAD_LEVEL_DATA_3
	beq CURRENT_LEVEL, 4, LOAD_LEVEL_DATA_4
	beq CURRENT_LEVEL, 5, LOAD_LEVEL_DATA_5
	beq CURRENT_LEVEL, 6, LOAD_LEVEL_DATA_6
	beq CURRENT_LEVEL, 7, LOAD_LEVEL_DATA_7
	beq CURRENT_LEVEL, 8, LOAD_LEVEL_DATA_8
	beq CURRENT_LEVEL, 9, LOAD_LEVEL_DATA_9
	beq CURRENT_LEVEL, 10, LOAD_LEVEL_DATA_10

	j WIN_STATE	# Congrats, you won

	LOAD_LEVEL_DATA_1:
		li GATE_POSITION, 27452
		li KEY_POSITION, 23144
		la $a0, level_data
		jal SAVE_DATA
		jal DRAW_MAP1
		j LOAD_LEVEL_DATA_EXIT

	LOAD_LEVEL_DATA_2:
		li GATE_POSITION, 28172
		li KEY_POSITION, 33244
		la $a0, level_data
		jal SAVE_DATA

		jal DRAW_MAP2
		j LOAD_LEVEL_DATA_EXIT

	LOAD_LEVEL_DATA_3:
		li GATE_POSITION, 36356
		li KEY_POSITION, 4548
		la $a0, level_data
		jal SAVE_DATA

		jal DRAW_MAP3
		j LOAD_LEVEL_DATA_EXIT

	LOAD_LEVEL_DATA_4:
		li KEY_POSITION, 8004
		li GATE_POSITION, 39716
		la $a0, level_data
		jal SAVE_DATA

		jal DRAW_MAP4
		j LOAD_LEVEL_DATA_EXIT

	LOAD_LEVEL_DATA_5:
		li KEY_POSITION, 40972
		li GATE_POSITION, 14348
		la $a0, level_data
		jal SAVE_DATA

		jal DRAW_MAP5
		j LOAD_LEVEL_DATA_EXIT
	LOAD_LEVEL_DATA_6:
		li KEY_POSITION, 6024
		li GATE_POSITION, 15380
		la $a0, level_data
		jal SAVE_DATA

		jal DRAW_MAP6
		j LOAD_LEVEL_DATA_EXIT
	LOAD_LEVEL_DATA_7:
		li KEY_POSITION, 20608
		li GATE_POSITION, 44060
		la $a0, level_data
		jal SAVE_DATA

		jal DRAW_MAP7
		j LOAD_LEVEL_DATA_EXIT
	LOAD_LEVEL_DATA_8:
		li KEY_POSITION, 18364
		li GATE_POSITION, 5428
		la $a0, level_data
		jal SAVE_DATA

		jal DRAW_MAP8
		j LOAD_LEVEL_DATA_EXIT
	LOAD_LEVEL_DATA_9:
		li KEY_POSITION, 45064
		li GATE_POSITION, 7176
		la $a0, level_data
		jal SAVE_DATA

		jal DRAW_MAP9
		j LOAD_LEVEL_DATA_EXIT
	LOAD_LEVEL_DATA_10:
		li KEY_POSITION, 41036
		li GATE_POSITION, 40664
		la $a0, level_data
		jal SAVE_DATA

		jal DRAW_MAP10
		j LOAD_LEVEL_DATA_EXIT	

	LOAD_LEVEL_DATA_EXIT:
		lw	$ra, 0($sp)	# Return to sender.
		addi	$sp, $sp, 4
		jr $ra


# -------------------------------------------------------------------------------------------------------------------
# 										 __  __    _    ___  ___ 
# 										|  \/  |  /_\  | _ \/ __|
# 										| |\/| | / _ \ |  _/\__ \
# 										|_|  |_|/_/ \_\|_|  |___/
#
#							THE FOLLOWING MAPS WERE GENERATED BY MY MAP MAKER
# -------------------------------------------------------------------------------------------------------------------
#
#  __  __                _ 
# |  \/  | __ _  _ __   / |
# | |\/| |/ _` || '_ \  | |
# |_|  |_|\__,_|| .__/  |_|
#               |_|      
#
DRAW_OVERLAY_MAP1:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	li $a3, 0x00323232
	lw $t0, 0($sp)
	addi $t0, $t0, 200
	move $a0, $t0
	addi $t0, $t0, 2108
	move $a1, $t0
	li $a2, 56
	jal FILL
	
	li $a3, 0x00282828
	lw $t0, 0($sp)
	addi $t0, $t0, 2760
	move $a0, $t0
	addi $t0, $t0, 1084
	move $a1, $t0
	li $a2, 56
	jal FILL
	
	li $a3, 0x001e1e1e
	lw $t0, 0($sp)
	addi $t0, $t0, 4296
	move $a0, $t0
	addi $t0, $t0, 2108
	move $a1, $t0
	li $a2, 56
	jal FILL
	
	li $a3, 0x00141414
	lw $t0, 0($sp)
	addi $t0, $t0, 6856
	move $a0, $t0
	addi $t0, $t0, 1596
	move $a1, $t0
	li $a2, 56
	jal FILL
	
	addi	$sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	
LOAD_SPIKES_MAP1: 
	jr $ra
PLACE_PLAYER_MAP1: 
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)

	la $a0, player_data
	jal LOAD_DATA

	li $t1, WALL_COLOR
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 28888
	move PLAYER_POS, $t0

	la $a0, player_data
	jal SAVE_DATA
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
DRAW_MAP1:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal PLACE_PLAYER_MAP1
	jal LOAD_SPIKES_MAP1
	li $t1, WALL_COLOR
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 0
	move $a0, $t0
	addi $t0, $t0, 48728
	move $a1, $t0
	li $a2, 84
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 88
	move $a0, $t0
	addi $t0, $t0, 17008
	move $a1, $t0
	li $a2, 108
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 17788
	move $a0, $t0
	addi $t0, $t0, 31364
	move $a1, $t0
	li $a2, 128
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 31320
	move $a0, $t0
	addi $t0, $t0, 17700
	move $a1, $t0
	li $a2, 288
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 24664
	move $a0, $t0
	addi $t0, $t0, 6220
	move $a1, $t0
	li $a2, 72
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 260
	move $a0, $t0
	addi $t0, $t0, 17148
	move $a1, $t0
	li $a2, 248
	li $a3, WALL_COLOR
	jal FILL
	li $a0, BASE_ADDRESS
	jal DRAW_OVERLAY_MAP1
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	

#
#  __  __                ___ 
# |  \/  | __ _  _ __   |_  )
# | |\/| |/ _` || '_ \   / / 
# |_|  |_|\__,_|| .__/  /___|
#               |_|          
#
LOAD_PICKUPS_MAP2:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	# Load Level Data
	la $a0, level_data
	jal LOAD_DATA
	li $t0, 10484
	li $t1, 4
	sw $t0, 0(PICKUP_POINTER)
	sw $t1, 4(PICKUP_POINTER)
	li $t0, 0
	sw $t0, 8(PICKUP_POINTER)
	sw $t0, 12(PICKUP_POINTER)
	la $a0, level_data
	jal SAVE_DATA
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra

LOAD_SPIKES_MAP2:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	li $t1, WALL_COLOR
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 47268
	move $a0, $t0
	addi $t0, $t0, 528
	move $a1, $t0
	li $a2, 12
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 29340
	move $a0, $t0
	addi $t0, $t0, 624
	move $a1, $t0
	li $a2, 108
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 14056
	move $a0, $t0
	addi $t0, $t0, 548
	move $a1, $t0
	li $a2, 32
	jal DRAW_SPIKES
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra

PLACE_PLAYER_MAP2:
	# LOAD PLAYER DATA
	addi	$sp, $sp, -4		# Push return address to stack.
	sw	$ra, 0($sp)
	
	la $a0, player_data		# Load the player_data struct
	jal LOAD_DATA

	# Move player
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 17940
	move PLAYER_POS, $t0

	# SAVE NEW DATA
	la $a0, player_data		# Save the player_data struct
	jal SAVE_DATA
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra			# Return to sender

DRAW_MAP2:
	addi	$sp, $sp, -4		# Push return address to stack.
	sw	$ra, 0($sp)

	jal PLACE_PLAYER_MAP2
	jal LOAD_SPIKES_MAP2
	jal LOAD_PICKUPS_MAP2

	li $t1, WALL_COLOR
	li $t0, BASE_ADDRESS
	addi $t0, $t0, -4
	move $a0, $t0
	addi $t0, $t0, 516
	move $a1, $t0
	li $a2, 512
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 512
	move $a0, $t0
	addi $t0, $t0, 48132
	move $a1, $t0
	li $a2, 0
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 1020
	move $a0, $t0
	addi $t0, $t0, 48132
	move $a1, $t0
	li $a2, 0
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 48132
	move $a0, $t0
	addi $t0, $t0, 688
	move $a1, $t0
	li $a2, 172
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 516
	move $a0, $t0
	addi $t0, $t0, 12392
	move $a1, $t0
	li $a2, 100
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 620
	move $a0, $t0
	addi $t0, $t0, 8732
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 648
	move $a0, $t0
	addi $t0, $t0, 4628
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 21508
	move $a0, $t0
	addi $t0, $t0, 2728
	move $a1, $t0
	li $a2, 164
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 27784
	move $a0, $t0
	addi $t0, $t0, 7700
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 32260
	move $a0, $t0
	addi $t0, $t0, 2640
	move $a1, $t0
	li $a2, 76
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 44548
	move $a0, $t0
	addi $t0, $t0, 3224
	move $a1, $t0
	li $a2, 148
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 42024
	move $a0, $t0
	addi $t0, $t0, 2204
	move $a1, $t0
	li $a2, 152
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 41260
	move $a0, $t0
	addi $t0, $t0, 1636
	move $a1, $t0
	li $a2, 96
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 35304
	move $a0, $t0
	addi $t0, $t0, 1044
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 36852
	move $a0, $t0
	addi $t0, $t0, 520
	move $a1, $t0
	li $a2, 4
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 992
	move $a0, $t0
	addi $t0, $t0, 18460
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 30364
	move $a0, $t0
	addi $t0, $t0, 624
	move $a1, $t0
	li $a2, 108
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 16620
	move $a0, $t0
	addi $t0, $t0, 536
	move $a1, $t0
	li $a2, 20
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 15052
	move $a0, $t0
	addi $t0, $t0, 1120
	move $a1, $t0
	li $a2, 92
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 24696
	move $a0, $t0
	addi $t0, $t0, 2608
	move $a1, $t0
	li $a2, 44
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 29060
	move $a0, $t0
	addi $t0, $t0, 1088
	move $a1, $t0
	li $a2, 60
	li $a3, WALL_COLOR
	jal FILL
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra



#
#  __  __                ____
# |  \/  | __ _  _ __   |__ /
# | |\/| |/ _` || '_ \   |_ \
# |_|  |_|\__,_|| .__/  |___/
#               |_|          
#
LOAD_PICKUPS_MAP3:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	# Load Level Data
	la $a0, level_data
	jal LOAD_DATA
	li $t0, 1616
	li $t1, 4
	sw $t0, 0(PICKUP_POINTER)
	sw $t1, 4(PICKUP_POINTER)
	li $t0, 22032
	li $t1, 7
	sw $t0, 8(PICKUP_POINTER)
	sw $t1, 12(PICKUP_POINTER)
	li $t0, 0
	sw $t0, 16(PICKUP_POINTER)
	sw $t0, 20(PICKUP_POINTER)
	la $a0, level_data
	jal SAVE_DATA
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	
PLACE_PLAYER_MAP3:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)	
	la $a0, player_data		# Load the player_data struct
	jal LOAD_DATA

	li $t0, BASE_ADDRESS
	addi $t0, $t0, 26592
	move PLAYER_POS, $t0
	# SAVE NEW DATA
	la $a0, player_data		# Save the player_data struct
	jal SAVE_DATA
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra

LOAD_SPIKES_MAP3:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	li $t1, WALL_COLOR
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 43384
	move $a0, $t0
	addi $t0, $t0, 564
	move $a1, $t0
	li $a2, 48
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 39172
	move $a0, $t0
	addi $t0, $t0, 580
	move $a1, $t0
	li $a2, 64
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 46112
	move $a0, $t0
	addi $t0, $t0, 716
	move $a1, $t0
	li $a2, 200
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 17360
	move $a0, $t0
	addi $t0, $t0, 536
	move $a1, $t0
	li $a2, 20
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 12132
	move $a0, $t0
	addi $t0, $t0, 540
	move $a1, $t0
	li $a2, 24
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 6120
	move $a0, $t0
	addi $t0, $t0, 532
	move $a1, $t0
	li $a2, 16
	jal DRAW_SPIKES
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra

DRAW_MAP3:
	addi	$sp, $sp, -4		# Push return address to stack.
	sw	$ra, 0($sp)

	jal PLACE_PLAYER_MAP3
	jal LOAD_SPIKES_MAP3
	jal LOAD_PICKUPS_MAP3

	li $t1, WALL_COLOR
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 0
	move $a0, $t0
	addi $t0, $t0, 512
	move $a1, $t0
	li $a2, 508
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 512
	move $a0, $t0
	addi $t0, $t0, 48132
	move $a1, $t0
	li $a2, 0
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 48644
	move $a0, $t0
	addi $t0, $t0, 508
	move $a1, $t0
	li $a2, 504
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 1020
	move $a0, $t0
	addi $t0, $t0, 47620
	move $a1, $t0
	li $a2, 0
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 29612
	move $a0, $t0
	addi $t0, $t0, 19024
	move $a1, $t0
	li $a2, 76
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 44408
	move $a0, $t0
	addi $t0, $t0, 4148
	move $a1, $t0
	li $a2, 48
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 34632
	move $a0, $t0
	addi $t0, $t0, 13872
	move $a1, $t0
	li $a2, 44
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 40196
	move $a0, $t0
	addi $t0, $t0, 8260
	move $a1, $t0
	li $a2, 64
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 34540
	move $a0, $t0
	addi $t0, $t0, 13848
	move $a1, $t0
	li $a2, 20
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 40452
	move $a0, $t0
	addi $t0, $t0, 7708
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 29784
	move $a0, $t0
	addi $t0, $t0, 1088
	move $a1, $t0
	li $a2, 60
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 31336
	move $a0, $t0
	addi $t0, $t0, 548
	move $a1, $t0
	li $a2, 32
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 47136
	move $a0, $t0
	addi $t0, $t0, 1228
	move $a1, $t0
	li $a2, 200
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 24580
	move $a0, $t0
	addi $t0, $t0, 8732
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 29216
	move $a0, $t0
	addi $t0, $t0, 3596
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 40480
	move $a0, $t0
	addi $t0, $t0, 2052
	move $a1, $t0
	li $a2, 0
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 7072
	move $a0, $t0
	addi $t0, $t0, 1116
	move $a1, $t0
	li $a2, 88
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 1004
	move $a0, $t0
	addi $t0, $t0, 1552
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 8624
	move $a0, $t0
	addi $t0, $t0, 1100
	move $a1, $t0
	li $a2, 72
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 10204
	move $a0, $t0
	addi $t0, $t0, 1056
	move $a1, $t0
	li $a2, 28
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 11752
	move $a0, $t0
	addi $t0, $t0, 7700
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 18372
	move $a0, $t0
	addi $t0, $t0, 1060
	move $a1, $t0
	li $a2, 32
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 19972
	move $a0, $t0
	addi $t0, $t0, 1036
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 516
	move $a0, $t0
	addi $t0, $t0, 18964
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 536
	move $a0, $t0
	addi $t0, $t0, 4660
	move $a1, $t0
	li $a2, 48
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 5656
	move $a0, $t0
	addi $t0, $t0, 3104
	move $a1, $t0
	li $a2, 28
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 716
	move $a0, $t0
	addi $t0, $t0, 6680
	move $a1, $t0
	li $a2, 20
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 14028
	move $a0, $t0
	addi $t0, $t0, 1052
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 15572
	move $a0, $t0
	addi $t0, $t0, 3088
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 19616
	move $a0, $t0
	addi $t0, $t0, 2604
	move $a1, $t0
	li $a2, 40
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 14648
	move $a0, $t0
	addi $t0, $t0, 1084
	move $a1, $t0
	li $a2, 56
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 14628
	move $a0, $t0
	addi $t0, $t0, 528
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 13080
	move $a0, $t0
	addi $t0, $t0, 1128
	move $a1, $t0
	li $a2, 100
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 6072
	move $a0, $t0
	addi $t0, $t0, 552
	move $a1, $t0
	li $a2, 36
	li $a3, WALL_COLOR
	jal FILL
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	

#  __  __                _ _  
# |  \/  | __ _  _ __   | | | 
# | |\/| |/ _` || '_ \  |_  _|
# |_|  |_|\__,_|| .__/    |_| 
#               |_|          
LOAD_PICKUPS_MAP4:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	# Load Level Data
	la $a0, level_data
	jal LOAD_DATA
	li $t0, 44252
	li $t1, GRAVITY_POTION_ID
	sw $t0, 0(PICKUP_POINTER)
	sw $t1, 4(PICKUP_POINTER)
	li $t0, 12856
	li $t1, HEALTH_RESTORE_ID
	sw $t0, 8(PICKUP_POINTER)
	sw $t1, 12(PICKUP_POINTER)
	li $t0, 0
	sw $t0, 16(PICKUP_POINTER)
	sw $t0, 20(PICKUP_POINTER)
	la $a0, level_data
	jal SAVE_DATA
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	

PLACE_PLAYER_MAP4:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	la $a0, player_data
	jal LOAD_DATA
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 43032
	move PLAYER_POS, $t0
	la $a0, player_data
	jal SAVE_DATA
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
LOAD_SPIKES_MAP4:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 45648
	move $a0, $t0
	addi $t0, $t0, 572
	move $a1, $t0
	li $a2, 56
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 38832
	move $a0, $t0
	addi $t0, $t0, 576
	move $a1, $t0
	li $a2, 60
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 47440
	move $a0, $t0
	addi $t0, $t0, 608
	move $a1, $t0
	li $a2, 92
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 27140
	move $a0, $t0
	addi $t0, $t0, 548
	move $a1, $t0
	li $a2, 32
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 29260
	move $a0, $t0
	addi $t0, $t0, 536
	move $a1, $t0
	li $a2, 20
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 10848
	move $a0, $t0
	addi $t0, $t0, 540
	move $a1, $t0
	li $a2, 24
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 9412
	move $a0, $t0
	addi $t0, $t0, 544
	move $a1, $t0
	li $a2, 28
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 35584
	move $a0, $t0
	addi $t0, $t0, 536
	move $a1, $t0
	li $a2, 20
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 20672
	move $a0, $t0
	addi $t0, $t0, 580
	move $a1, $t0
	li $a2, 64
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 19332
	move $a0, $t0
	addi $t0, $t0, 540
	move $a1, $t0
	li $a2, 24
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 22896
	move $a0, $t0
	addi $t0, $t0, 532
	move $a1, $t0
	li $a2, 16
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 10524
	move $a0, $t0
	addi $t0, $t0, 536
	move $a1, $t0
	li $a2, 20
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 23300
	move $a0, $t0
	addi $t0, $t0, 560
	move $a1, $t0
	li $a2, 44
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 10524
	move $a0, $t0
	addi $t0, $t0, 536
	move $a1, $t0
	li $a2, 20
	jal DRAW_SPIKES
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra


DRAW_MAP4:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal PLACE_PLAYER_MAP4
	jal LOAD_SPIKES_MAP4
	jal LOAD_PICKUPS_MAP4
	li $t1, WALL_COLOR
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 0
	move $a0, $t0
	addi $t0, $t0, 512
	move $a1, $t0
	li $a2, 508
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 512
	move $a0, $t0
	addi $t0, $t0, 48132
	move $a1, $t0
	li $a2, 0
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 1008
	move $a0, $t0
	addi $t0, $t0, 47120
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 39856
	move $a0, $t0
	addi $t0, $t0, 8256
	move $a1, $t0
	li $a2, 60
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 45572
	move $a0, $t0
	addi $t0, $t0, 3148
	move $a1, $t0
	li $a2, 72
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 41612
	move $a0, $t0
	addi $t0, $t0, 7228
	move $a1, $t0
	li $a2, 56
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 36608
	move $a0, $t0
	addi $t0, $t0, 12312
	move $a1, $t0
	li $a2, 20
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 43800
	move $a0, $t0
	addi $t0, $t0, 5176
	move $a1, $t0
	li $a2, 52
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 912
	move $a0, $t0
	addi $t0, $t0, 5216
	move $a1, $t0
	li $a2, 92
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 516
	move $a0, $t0
	addi $t0, $t0, 4192
	move $a1, $t0
	li $a2, 92
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 28164
	move $a0, $t0
	addi $t0, $t0, 4168
	move $a1, $t0
	li $a2, 68
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 30284
	move $a0, $t0
	addi $t0, $t0, 3628
	move $a1, $t0
	li $a2, 40
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 46672
	move $a0, $t0
	addi $t0, $t0, 2108
	move $a1, $t0
	li $a2, 56
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 24324
	move $a0, $t0
	addi $t0, $t0, 5680
	move $a1, $t0
	li $a2, 44
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 25908
	move $a0, $t0
	addi $t0, $t0, 1084
	move $a1, $t0
	li $a2, 56
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 23920
	move $a0, $t0
	addi $t0, $t0, 3104
	move $a1, $t0
	li $a2, 28
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 27524
	move $a0, $t0
	addi $t0, $t0, 5136
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 26160
	move $a0, $t0
	addi $t0, $t0, 1560
	move $a1, $t0
	li $a2, 20
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 11872
	move $a0, $t0
	addi $t0, $t0, 3100
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 8900
	move $a0, $t0
	addi $t0, $t0, 2592
	move $a1, $t0
	li $a2, 28
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 20356
	move $a0, $t0
	addi $t0, $t0, 3100
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 32740
	move $a0, $t0
	addi $t0, $t0, 1548
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 21696
	move $a0, $t0
	addi $t0, $t0, 8260
	move $a1, $t0
	li $a2, 64
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 13948
	move $a0, $t0
	addi $t0, $t0, 1056
	move $a1, $t0
	li $a2, 28
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 9524
	move $a0, $t0
	addi $t0, $t0, 1588
	move $a1, $t0
	li $a2, 48
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 40452
	move $a0, $t0
	addi $t0, $t0, 4624
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 22168
	move $a0, $t0
	addi $t0, $t0, 2088
	move $a1, $t0
	li $a2, 36
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 28772
	move $a0, $t0
	addi $t0, $t0, 1044
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 34488
	move $a0, $t0
	addi $t0, $t0, 1060
	move $a1, $t0
	li $a2, 32
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 5124
	move $a0, $t0
	addi $t0, $t0, 8736
	move $a1, $t0
	li $a2, 28
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 5156
	move $a0, $t0
	addi $t0, $t0, 3104
	move $a1, $t0
	li $a2, 28
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 612
	move $a0, $t0
	addi $t0, $t0, 1608
	move $a1, $t0
	li $a2, 68
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 6604
	move $a0, $t0
	addi $t0, $t0, 7716
	move $a1, $t0
	li $a2, 32
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 14820
	move $a0, $t0
	addi $t0, $t0, 5644
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 840
	move $a0, $t0
	addi $t0, $t0, 1608
	move $a1, $t0
	li $a2, 68
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 48464
	move $a0, $t0
	addi $t0, $t0, 688
	move $a1, $t0
	li $a2, 172
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 9456
	move $a0, $t0
	addi $t0, $t0, 2096
	move $a1, $t0
	li $a2, 44
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 10528
	move $a0, $t0
	addi $t0, $t0, 2068
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 8956
	move $a0, $t0
	addi $t0, $t0, 28
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 24756
	move $a0, $t0
	addi $t0, $t0, 2572
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	

# 
#  __  __               ___ 
# |  \/  | __ _  _ __  | __|
# | |\/| |/ _` || '_ \ |__ \
# |_|  |_|\__,_|| .__/ |___/
#               |_|         
#

PLACE_PLAYER_MAP5:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	la $a0, player_data
	jal LOAD_DATA
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 42848
	move PLAYER_POS, $t0
	la $a0, player_data
	jal SAVE_DATA
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	


LOAD_SPIKES_MAP5:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 41096
	move $a0, $t0
	addi $t0, $t0, 532
	move $a1, $t0
	li $a2, 20
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 12232
	move $a0, $t0
	addi $t0, $t0, 540
	move $a1, $t0
	li $a2, 28
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 45248
	move $a0, $t0
	addi $t0, $t0, 528
	move $a1, $t0
	li $a2, 16
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 9464
	move $a0, $t0
	addi $t0, $t0, 516
	move $a1, $t0
	li $a2, 4
	jal DRAW_SPIKES
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	
LOAD_PICKUPS_MAP5:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	# Load Level Data
	la $a0, level_data
	jal LOAD_DATA
	li $t0, 9156
	li $t1, HEALTH_RESTORE_ID
	sw $t0, 0(PICKUP_POINTER)
	sw $t1, 4(PICKUP_POINTER)
	li $t0, 38372
	li $t1, GRAVITY_POTION_ID
	sw $t0, 8(PICKUP_POINTER)
	sw $t1, 12(PICKUP_POINTER)
	li $t0, 0
	sw $t0, 16(PICKUP_POINTER)
	sw $t0, 20(PICKUP_POINTER)
	la $a0, level_data
	jal SAVE_DATA
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	


	jr $ra
DRAW_MAP5:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal PLACE_PLAYER_MAP5
	jal LOAD_SPIKES_MAP5
	jal LOAD_PICKUPS_MAP5
	li $t1, WALL_COLOR
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 45372
	move $a0, $t0
	addi $t0, $t0, 1632
	move $a1, $t0
	li $a2, 92
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 47428
	move $a0, $t0
	addi $t0, $t0, 592
	move $a1, $t0
	li $a2, 76
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 43480
	move $a0, $t0
	addi $t0, $t0, 1060
	move $a1, $t0
	li $a2, 32
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 45024
	move $a0, $t0
	addi $t0, $t0, 1052
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 0
	move $a0, $t0
	addi $t0, $t0, 512
	move $a1, $t0
	li $a2, 508
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 512
	move $a0, $t0
	addi $t0, $t0, 48132
	move $a1, $t0
	li $a2, 0
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 1020
	move $a0, $t0
	addi $t0, $t0, 48132
	move $a1, $t0
	li $a2, 0
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 15924
	move $a0, $t0
	addi $t0, $t0, 1128
	move $a1, $t0
	li $a2, 100
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 17476
	move $a0, $t0
	addi $t0, $t0, 584
	move $a1, $t0
	li $a2, 68
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 18436
	move $a0, $t0
	addi $t0, $t0, 1148
	move $a1, $t0
	li $a2, 120
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 19972
	move $a0, $t0
	addi $t0, $t0, 1636
	move $a1, $t0
	li $a2, 96
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 22020
	move $a0, $t0
	addi $t0, $t0, 13328
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 22036
	move $a0, $t0
	addi $t0, $t0, 9264
	move $a1, $t0
	li $a2, 44
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 672
	move $a0, $t0
	addi $t0, $t0, 4444
	move $a1, $t0
	li $a2, 344
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 5452
	move $a0, $t0
	addi $t0, $t0, 1200
	move $a1, $t0
	li $a2, 172
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 7144
	move $a0, $t0
	addi $t0, $t0, 7188
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 13240
	move $a0, $t0
	addi $t0, $t0, 1072
	move $a1, $t0
	li $a2, 44
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 14792
	move $a0, $t0
	addi $t0, $t0, 564
	move $a1, $t0
	li $a2, 48
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 15856
	move $a0, $t0
	addi $t0, $t0, 5644
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 624
	move $a0, $t0
	addi $t0, $t0, 2608
	move $a1, $t0
	li $a2, 44
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 516
	move $a0, $t0
	addi $t0, $t0, 6680
	move $a1, $t0
	li $a2, 20
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 540
	move $a0, $t0
	addi $t0, $t0, 1620
	move $a1, $t0
	li $a2, 80
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 2616
	move $a0, $t0
	addi $t0, $t0, 3596
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 2628
	move $a0, $t0
	addi $t0, $t0, 1564
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 2604
	move $a0, $t0
	addi $t0, $t0, 2572
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 2592
	move $a0, $t0
	addi $t0, $t0, 1036
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 14972
	move $a0, $t0
	addi $t0, $t0, 548
	move $a1, $t0
	li $a2, 32
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 12200
	move $a0, $t0
	addi $t0, $t0, 544
	move $a1, $t0
	li $a2, 28
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 43524
	move $a0, $t0
	addi $t0, $t0, 556
	move $a1, $t0
	li $a2, 40
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 44548
	move $a0, $t0
	addi $t0, $t0, 544
	move $a1, $t0
	li $a2, 28
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 45572
	move $a0, $t0
	addi $t0, $t0, 3084
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 42532
	move $a0, $t0
	addi $t0, $t0, 540
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 42120
	move $a0, $t0
	addi $t0, $t0, 588
	move $a1, $t0
	li $a2, 72
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 22084
	move $a0, $t0
	addi $t0, $t0, 5656
	move $a1, $t0
	li $a2, 20
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 43160
	move $a0, $t0
	addi $t0, $t0, 560
	move $a1, $t0
	li $a2, 44
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 44196
	move $a0, $t0
	addi $t0, $t0, 4628
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 46264
	move $a0, $t0
	addi $t0, $t0, 28
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 46776
	move $a0, $t0
	addi $t0, $t0, 1040
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 5352
	move $a0, $t0
	addi $t0, $t0, 4624
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 5368
	move $a0, $t0
	addi $t0, $t0, 1576
	move $a1, $t0
	li $a2, 36
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 5436
	move $a0, $t0
	addi $t0, $t0, 4624
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 10564
	move $a0, $t0
	addi $t0, $t0, 2056
	move $a1, $t0
	li $a2, 4
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 10464
	move $a0, $t0
	addi $t0, $t0, 544
	move $a1, $t0
	li $a2, 28
	li $a3, WALL_COLOR
	jal FILL
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
#
#  __  __                __ 
# |  \/  | __ _  _ __   / / 
# | |\/| |/ _` || '_ \ / _ \
# |_|  |_|\__,_|| .__/ \___/
#               |_|         
#
LOAD_PICKUPS_MAP6:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	# Load Level Data
	la $a0, level_data
	jal LOAD_DATA
	li $t0, 23644
	li $t1, HEALTH_RESTORE_ID
	sw $t0, 0(PICKUP_POINTER)
	sw $t1, 4(PICKUP_POINTER)
	li $t0, 35184
	li $t1, VODKA_POTION_ID
	sw $t0, 8(PICKUP_POINTER)
	sw $t1, 12(PICKUP_POINTER)
	li $t0, 0
	sw $t0, 16(PICKUP_POINTER)
	sw $t0, 20(PICKUP_POINTER)
	la $a0, level_data
	jal SAVE_DATA
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	


	jr $ra


PLACE_PLAYER_MAP6:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	la $a0, player_data
	jal LOAD_DATA
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 8248
	move PLAYER_POS, $t0
	la $a0, player_data
	jal SAVE_DATA
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	

LOAD_SPIKES_MAP6:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 28232
	move $a0, $t0
	addi $t0, $t0, 552
	move $a1, $t0
	li $a2, 36
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 22344
	move $a0, $t0
	addi $t0, $t0, 532
	move $a1, $t0
	li $a2, 16
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 46336
	move $a0, $t0
	addi $t0, $t0, 540
	move $a1, $t0
	li $a2, 24
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 37852
	move $a0, $t0
	addi $t0, $t0, 544
	move $a1, $t0
	li $a2, 28
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 14828
	move $a0, $t0
	addi $t0, $t0, 528
	move $a1, $t0
	li $a2, 12
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 31268
	move $a0, $t0
	addi $t0, $t0, 520
	move $a1, $t0
	li $a2, 4
	jal DRAW_SPIKES
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
DRAW_MAP6:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal PLACE_PLAYER_MAP6
	jal LOAD_SPIKES_MAP6
	jal LOAD_PICKUPS_MAP6
	li $t1, WALL_COLOR
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 0
	move $a0, $t0
	addi $t0, $t0, 512
	move $a1, $t0
	li $a2, 508
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 1020
	move $a0, $t0
	addi $t0, $t0, 48132
	move $a1, $t0
	li $a2, 0
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 512
	move $a0, $t0
	addi $t0, $t0, 48132
	move $a1, $t0
	li $a2, 0
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 10756
	move $a0, $t0
	addi $t0, $t0, 1636
	move $a1, $t0
	li $a2, 96
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 516
	move $a0, $t0
	addi $t0, $t0, 9768
	move $a1, $t0
	li $a2, 36
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 19460
	move $a0, $t0
	addi $t0, $t0, 1656
	move $a1, $t0
	li $a2, 116
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 21616
	move $a0, $t0
	addi $t0, $t0, 8204
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 21508
	move $a0, $t0
	addi $t0, $t0, 1096
	move $a1, $t0
	li $a2, 68
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 23044
	move $a0, $t0
	addi $t0, $t0, 7188
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 45632
	move $a0, $t0
	addi $t0, $t0, 3088
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 45648
	move $a0, $t0
	addi $t0, $t0, 1132
	move $a1, $t0
	li $a2, 104
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 18620
	move $a0, $t0
	addi $t0, $t0, 28228
	move $a1, $t0
	li $a2, 64
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 47184
	move $a0, $t0
	addi $t0, $t0, 1792
	move $a1, $t0
	li $a2, 252
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 29256
	move $a0, $t0
	addi $t0, $t0, 552
	move $a1, $t0
	li $a2, 36
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 30724
	move $a0, $t0
	addi $t0, $t0, 1056
	move $a1, $t0
	li $a2, 28
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 32284
	move $a0, $t0
	addi $t0, $t0, 3600
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 35372
	move $a0, $t0
	addi $t0, $t0, 1040
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 23064
	move $a0, $t0
	addi $t0, $t0, 532
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 40592
	move $a0, $t0
	addi $t0, $t0, 4652
	move $a1, $t0
	li $a2, 40
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 28284
	move $a0, $t0
	addi $t0, $t0, 1560
	move $a1, $t0
	li $a2, 20
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 20652
	move $a0, $t0
	addi $t0, $t0, 1552
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 784
	move $a0, $t0
	addi $t0, $t0, 2796
	move $a1, $t0
	li $a2, 232
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 712
	move $a0, $t0
	addi $t0, $t0, 1608
	move $a1, $t0
	li $a2, 68
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 556
	move $a0, $t0
	addi $t0, $t0, 3688
	move $a1, $t0
	li $a2, 100
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 660
	move $a0, $t0
	addi $t0, $t0, 1568
	move $a1, $t0
	li $a2, 28
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 12884
	move $a0, $t0
	addi $t0, $t0, 1052
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 14428
	move $a0, $t0
	addi $t0, $t0, 524
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 12804
	move $a0, $t0
	addi $t0, $t0, 6160
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 12820
	move $a0, $t0
	addi $t0, $t0, 2084
	move $a1, $t0
	li $a2, 32
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 12856
	move $a0, $t0
	addi $t0, $t0, 532
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 3932
	move $a0, $t0
	addi $t0, $t0, 21020
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 23356
	move $a0, $t0
	addi $t0, $t0, 1568
	move $a1, $t0
	li $a2, 28
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 34048
	move $a0, $t0
	addi $t0, $t0, 2092
	move $a1, $t0
	li $a2, 40
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 36608
	move $a0, $t0
	addi $t0, $t0, 5140
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 38836
	move $a0, $t0
	addi $t0, $t0, 2120
	move $a1, $t0
	li $a2, 68
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 41432
	move $a0, $t0
	addi $t0, $t0, 1060
	move $a1, $t0
	li $a2, 32
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 42988
	move $a0, $t0
	addi $t0, $t0, 6160
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 25444
	move $a0, $t0
	addi $t0, $t0, 2608
	move $a1, $t0
	li $a2, 44
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 28528
	move $a0, $t0
	addi $t0, $t0, 1556
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 17356
	move $a0, $t0
	addi $t0, $t0, 2608
	move $a1, $t0
	li $a2, 44
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 20452
	move $a0, $t0
	addi $t0, $t0, 4120
	move $a1, $t0
	li $a2, 20
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 25072
	move $a0, $t0
	addi $t0, $t0, 2572
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 15832
	move $a0, $t0
	addi $t0, $t0, 1060
	move $a1, $t0
	li $a2, 32
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 8056
	move $a0, $t0
	addi $t0, $t0, 1080
	move $a1, $t0
	li $a2, 52
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 3960
	move $a0, $t0
	addi $t0, $t0, 2056
	move $a1, $t0
	li $a2, 4
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 4052
	move $a0, $t0
	addi $t0, $t0, 1064
	move $a1, $t0
	li $a2, 36
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 5612
	move $a0, $t0
	addi $t0, $t0, 4112
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 9592
	move $a0, $t0
	addi $t0, $t0, 7180
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 9604
	move $a0, $t0
	addi $t0, $t0, 3100
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 3892
	move $a0, $t0
	addi $t0, $t0, 4648
	move $a1, $t0
	li $a2, 36
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 9036
	move $a0, $t0
	addi $t0, $t0, 4112
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 22708
	move $a0, $t0
	addi $t0, $t0, 6664
	move $a1, $t0
	li $a2, 4
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 17096
	move $a0, $t0
	addi $t0, $t0, 1072
	move $a1, $t0
	li $a2, 44
	li $a3, WALL_COLOR
	jal FILL
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
#  __  __               ____ 
# |  \/  | __ _  _ __  |__  |
# | |\/| |/ _` || '_ \   / / 
# |_|  |_|\__,_|| .__/  /_/  
#               |_|          
PLACE_PLAYER_MAP7:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	la $a0, player_data
	jal LOAD_DATA
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 20440
	move PLAYER_POS, $t0
	la $a0, player_data
	jal SAVE_DATA
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	

LOAD_SPIKES_MAP7:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 46832
	move $a0, $t0
	addi $t0, $t0, 776
	move $a1, $t0
	li $a2, 264
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 28700
	move $a0, $t0
	addi $t0, $t0, 560
	move $a1, $t0
	li $a2, 48
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 31348
	move $a0, $t0
	addi $t0, $t0, 532
	move $a1, $t0
	li $a2, 20
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 12712
	move $a0, $t0
	addi $t0, $t0, 544
	move $a1, $t0
	li $a2, 32
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 22852
	move $a0, $t0
	addi $t0, $t0, 524
	move $a1, $t0
	li $a2, 12
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 46668
	move $a0, $t0
	addi $t0, $t0, 552
	move $a1, $t0
	li $a2, 40
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 13372
	move $a0, $t0
	addi $t0, $t0, 524
	move $a1, $t0
	li $a2, 12
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 22684
	move $a0, $t0
	addi $t0, $t0, 524
	move $a1, $t0
	li $a2, 12
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 12972
	move $a0, $t0
	addi $t0, $t0, 556
	move $a1, $t0
	li $a2, 44
	jal DRAW_SPIKES
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	

LOAD_PICKUPS_MAP7:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	# Load Level Data
	la $a0, level_data
	jal LOAD_DATA
	li $t0, 41452
	li $t1, VODKA_POTION_ID
	sw $t0, 0(PICKUP_POINTER)
	sw $t1, 4(PICKUP_POINTER)
	li $t0, 10712
	li $t1, HEALTH_RESTORE_ID
	sw $t0, 8(PICKUP_POINTER)
	sw $t1, 12(PICKUP_POINTER)
	li $t0, 42108
	li $t1, GRAVITY_POTION_ID
	sw $t0, 16(PICKUP_POINTER)
	sw $t1, 20(PICKUP_POINTER)
	li $t0, 8728
	li $t1, HEALTH_RESTORE_ID
	sw $t0, 24(PICKUP_POINTER)
	sw $t1, 28(PICKUP_POINTER)
	li $t0, 0
	sw $t0, 32(PICKUP_POINTER)
	sw $t0, 36(PICKUP_POINTER)
	la $a0, level_data
	jal SAVE_DATA
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	


	jr $ra


DRAW_MAP7:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal PLACE_PLAYER_MAP7
	jal LOAD_SPIKES_MAP7
	jal LOAD_PICKUPS_MAP7
	li $t1, WALL_COLOR
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 0
	move $a0, $t0
	addi $t0, $t0, 512
	move $a1, $t0
	li $a2, 508
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 512
	move $a0, $t0
	addi $t0, $t0, 48132
	move $a1, $t0
	li $a2, 0
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 1020
	move $a0, $t0
	addi $t0, $t0, 48132
	move $a1, $t0
	li $a2, 0
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 22968
	move $a0, $t0
	addi $t0, $t0, 1604
	move $a1, $t0
	li $a2, 64
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 13996
	move $a0, $t0
	addi $t0, $t0, 9316
	move $a1, $t0
	li $a2, 96
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 23776
	move $a0, $t0
	addi $t0, $t0, 4724
	move $a1, $t0
	li $a2, 112
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 48148
	move $a0, $t0
	addi $t0, $t0, 556
	move $a1, $t0
	li $a2, 40
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 47856
	move $a0, $t0
	addi $t0, $t0, 1292
	move $a1, $t0
	li $a2, 264
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 44004
	move $a0, $t0
	addi $t0, $t0, 1048
	move $a1, $t0
	li $a2, 20
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 23756
	move $a0, $t0
	addi $t0, $t0, 2580
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 26840
	move $a0, $t0
	addi $t0, $t0, 9736
	move $a1, $t0
	li $a2, 4
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 28896
	move $a0, $t0
	addi $t0, $t0, 3092
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 516
	move $a0, $t0
	addi $t0, $t0, 5712
	move $a1, $t0
	li $a2, 76
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 16656
	move $a0, $t0
	addi $t0, $t0, 6676
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 944
	move $a0, $t0
	addi $t0, $t0, 6220
	move $a1, $t0
	li $a2, 72
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 836
	move $a0, $t0
	addi $t0, $t0, 3692
	move $a1, $t0
	li $a2, 104
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 596
	move $a0, $t0
	addi $t0, $t0, 2288
	move $a1, $t0
	li $a2, 236
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 14340
	move $a0, $t0
	addi $t0, $t0, 4168
	move $a1, $t0
	li $a2, 68
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 6660
	move $a0, $t0
	addi $t0, $t0, 3600
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 3156
	move $a0, $t0
	addi $t0, $t0, 1588
	move $a1, $t0
	li $a2, 48
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 7660
	move $a0, $t0
	addi $t0, $t0, 7696
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 18948
	move $a0, $t0
	addi $t0, $t0, 10264
	move $a1, $t0
	li $a2, 20
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 29700
	move $a0, $t0
	addi $t0, $t0, 2160
	move $a1, $t0
	li $a2, 108
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 32360
	move $a0, $t0
	addi $t0, $t0, 2608
	move $a1, $t0
	li $a2, 44
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 13732
	move $a0, $t0
	addi $t0, $t0, 1096
	move $a1, $t0
	li $a2, 68
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 47692
	move $a0, $t0
	addi $t0, $t0, 1068
	move $a1, $t0
	li $a2, 40
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 32332
	move $a0, $t0
	addi $t0, $t0, 7196
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 37724
	move $a0, $t0
	addi $t0, $t0, 1100
	move $a1, $t0
	li $a2, 72
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 32304
	move $a0, $t0
	addi $t0, $t0, 4124
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 32260
	move $a0, $t0
	addi $t0, $t0, 1580
	move $a1, $t0
	li $a2, 40
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 34308
	move $a0, $t0
	addi $t0, $t0, 6160
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 34324
	move $a0, $t0
	addi $t0, $t0, 3612
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 23708
	move $a0, $t0
	addi $t0, $t0, 1584
	move $a1, $t0
	li $a2, 44
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 10756
	move $a0, $t0
	addi $t0, $t0, 3128
	move $a1, $t0
	li $a2, 52
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 39272
	move $a0, $t0
	addi $t0, $t0, 564
	move $a1, $t0
	li $a2, 48
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 40316
	move $a0, $t0
	addi $t0, $t0, 3080
	move $a1, $t0
	li $a2, 4
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 40324
	move $a0, $t0
	addi $t0, $t0, 1040
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 25048
	move $a0, $t0
	addi $t0, $t0, 4644
	move $a1, $t0
	li $a2, 32
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 25036
	move $a0, $t0
	addi $t0, $t0, 2572
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 30184
	move $a0, $t0
	addi $t0, $t0, 5652
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 22660
	move $a0, $t0
	addi $t0, $t0, 1560
	move $a1, $t0
	li $a2, 20
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 18972
	move $a0, $t0
	addi $t0, $t0, 3096
	move $a1, $t0
	li $a2, 20
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 22556
	move $a0, $t0
	addi $t0, $t0, 2060
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 28916
	move $a0, $t0
	addi $t0, $t0, 1600
	move $a1, $t0
	li $a2, 60
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 30924
	move $a0, $t0
	addi $t0, $t0, 1036
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 15292
	move $a0, $t0
	addi $t0, $t0, 2096
	move $a1, $t0
	li $a2, 44
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 15852
	move $a0, $t0
	addi $t0, $t0, 2576
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	

#  __  __               ___ 
# |  \/  | __ _  _ __  ( _ )
# | |\/| |/ _` || '_ \ / _ \
# |_|  |_|\__,_|| .__/ \___/
#               |_|         
PLACE_PLAYER_MAP8:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	la $a0, player_data
	jal LOAD_DATA
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 40932
	move PLAYER_POS, $t0
	la $a0, player_data
	jal SAVE_DATA
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	

LOAD_SPIKES_MAP8:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 41740
	move $a0, $t0
	addi $t0, $t0, 528
	move $a1, $t0
	li $a2, 16
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 28260
	move $a0, $t0
	addi $t0, $t0, 624
	move $a1, $t0
	li $a2, 112
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 44716
	move $a0, $t0
	addi $t0, $t0, 540
	move $a1, $t0
	li $a2, 28
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 40792
	move $a0, $t0
	addi $t0, $t0, 540
	move $a1, $t0
	li $a2, 28
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 34060
	move $a0, $t0
	addi $t0, $t0, 576
	move $a1, $t0
	li $a2, 64
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 39968
	move $a0, $t0
	addi $t0, $t0, 536
	move $a1, $t0
	li $a2, 24
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 15372
	move $a0, $t0
	addi $t0, $t0, 536
	move $a1, $t0
	li $a2, 24
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 11400
	move $a0, $t0
	addi $t0, $t0, 528
	move $a1, $t0
	li $a2, 16
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 11468
	move $a0, $t0
	addi $t0, $t0, 524
	move $a1, $t0
	li $a2, 12
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 10460
	move $a0, $t0
	addi $t0, $t0, 524
	move $a1, $t0
	li $a2, 12
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 19256
	move $a0, $t0
	addi $t0, $t0, 524
	move $a1, $t0
	li $a2, 12
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 28272
	move $a0, $t0
	addi $t0, $t0, 588
	move $a1, $t0
	li $a2, 76
	jal DRAW_SPIKES
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	


LOAD_PICKUPS_MAP8:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	# Load Level Data
	la $a0, level_data
	jal LOAD_DATA
	li $t0, 24204
	li $t1, HEALTH_RESTORE_ID
	sw $t0, 0(PICKUP_POINTER)
	sw $t1, 4(PICKUP_POINTER)
	li $t0, 16800
	li $t1, VODKA_POTION_ID
	sw $t0, 8(PICKUP_POINTER)
	sw $t1, 12(PICKUP_POINTER)
	li $t0, 24596
	li $t1, VODKA_POTION_ID
	sw $t0, 16(PICKUP_POINTER)
	sw $t1, 20(PICKUP_POINTER)
	li $t0, 9384
	li $t1, VODKA_POTION_ID
	sw $t0, 24(PICKUP_POINTER)
	sw $t1, 28(PICKUP_POINTER)
	li $t0, 0
	sw $t0, 32(PICKUP_POINTER)
	sw $t0, 36(PICKUP_POINTER)
	la $a0, level_data
	jal SAVE_DATA
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	
DRAW_MAP8:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal PLACE_PLAYER_MAP8
	jal LOAD_SPIKES_MAP8
	jal LOAD_PICKUPS_MAP8
	li $t1, WALL_COLOR
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 43960
	move $a0, $t0
	addi $t0, $t0, 1096
	move $a1, $t0
	li $a2, 68
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 45508
	move $a0, $t0
	addi $t0, $t0, 1084
	move $a1, $t0
	li $a2, 56
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 47068
	move $a0, $t0
	addi $t0, $t0, 2084
	move $a1, $t0
	li $a2, 32
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 0
	move $a0, $t0
	addi $t0, $t0, 512
	move $a1, $t0
	li $a2, 508
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 512
	move $a0, $t0
	addi $t0, $t0, 48132
	move $a1, $t0
	li $a2, 0
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 1020
	move $a0, $t0
	addi $t0, $t0, 42500
	move $a1, $t0
	li $a2, 0
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 35064
	move $a0, $t0
	addi $t0, $t0, 1652
	move $a1, $t0
	li $a2, 112
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 37140
	move $a0, $t0
	addi $t0, $t0, 1100
	move $a1, $t0
	li $a2, 72
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 38688
	move $a0, $t0
	addi $t0, $t0, 10280
	move $a1, $t0
	li $a2, 36
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 38728
	move $a0, $t0
	addi $t0, $t0, 6160
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 42732
	move $a0, $t0
	addi $t0, $t0, 2100
	move $a1, $t0
	li $a2, 48
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 41684
	move $a0, $t0
	addi $t0, $t0, 568
	move $a1, $t0
	li $a2, 52
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 29284
	move $a0, $t0
	addi $t0, $t0, 1648
	move $a1, $t0
	li $a2, 108
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 31344
	move $a0, $t0
	addi $t0, $t0, 608
	move $a1, $t0
	li $a2, 92
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 32400
	move $a0, $t0
	addi $t0, $t0, 3120
	move $a1, $t0
	li $a2, 44
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 13924
	move $a0, $t0
	addi $t0, $t0, 7280
	move $a1, $t0
	li $a2, 108
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 43012
	move $a0, $t0
	addi $t0, $t0, 5800
	move $a1, $t0
	li $a2, 164
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 45740
	move $a0, $t0
	addi $t0, $t0, 3104
	move $a1, $t0
	li $a2, 28
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 38404
	move $a0, $t0
	addi $t0, $t0, 4124
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 40992
	move $a0, $t0
	addi $t0, $t0, 1632
	move $a1, $t0
	li $a2, 92
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 24068
	move $a0, $t0
	addi $t0, $t0, 13840
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 21908
	move $a0, $t0
	addi $t0, $t0, 2664
	move $a1, $t0
	li $a2, 100
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 41816
	move $a0, $t0
	addi $t0, $t0, 1056
	move $a1, $t0
	li $a2, 28
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 25052
	move $a0, $t0
	addi $t0, $t0, 3616
	move $a1, $t0
	li $a2, 28
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 24996
	move $a0, $t0
	addi $t0, $t0, 1592
	move $a1, $t0
	li $a2, 52
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 29164
	move $a0, $t0
	addi $t0, $t0, 4112
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 21792
	move $a0, $t0
	addi $t0, $t0, 1140
	move $a1, $t0
	li $a2, 112
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 34128
	move $a0, $t0
	addi $t0, $t0, 552
	move $a1, $t0
	li $a2, 36
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 42720
	move $a0, $t0
	addi $t0, $t0, 1036
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 45312
	move $a0, $t0
	addi $t0, $t0, 1056
	move $a1, $t0
	li $a2, 28
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 20544
	move $a0, $t0
	addi $t0, $t0, 1572
	move $a1, $t0
	li $a2, 32
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 18508
	move $a0, $t0
	addi $t0, $t0, 1560
	move $a1, $t0
	li $a2, 20
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 27668
	move $a0, $t0
	addi $t0, $t0, 1040
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 32380
	move $a0, $t0
	addi $t0, $t0, 1556
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 516
	move $a0, $t0
	addi $t0, $t0, 8232
	move $a1, $t0
	li $a2, 36
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 556
	move $a0, $t0
	addi $t0, $t0, 1636
	move $a1, $t0
	li $a2, 96
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 2604
	move $a0, $t0
	addi $t0, $t0, 3628
	move $a1, $t0
	li $a2, 40
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 2648
	move $a0, $t0
	addi $t0, $t0, 1572
	move $a1, $t0
	li $a2, 32
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 9220
	move $a0, $t0
	addi $t0, $t0, 4120
	move $a1, $t0
	li $a2, 20
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 13828
	move $a0, $t0
	addi $t0, $t0, 4104
	move $a1, $t0
	li $a2, 4
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 852
	move $a0, $t0
	addi $t0, $t0, 12968
	move $a1, $t0
	li $a2, 164
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 656
	move $a0, $t0
	addi $t0, $t0, 1220
	move $a1, $t0
	li $a2, 192
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 9520
	move $a0, $t0
	addi $t0, $t0, 4132
	move $a1, $t0
	li $a2, 32
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 11484
	move $a0, $t0
	addi $t0, $t0, 2132
	move $a1, $t0
	li $a2, 80
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 12424
	move $a0, $t0
	addi $t0, $t0, 1108
	move $a1, $t0
	li $a2, 80
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 2320
	move $a0, $t0
	addi $t0, $t0, 1604
	move $a1, $t0
	li $a2, 64
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 2252
	move $a0, $t0
	addi $t0, $t0, 580
	move $a1, $t0
	li $a2, 64
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 20264
	move $a0, $t0
	addi $t0, $t0, 1236
	move $a1, $t0
	li $a2, 208
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 14036
	move $a0, $t0
	addi $t0, $t0, 4120
	move $a1, $t0
	li $a2, 20
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 27860
	move $a0, $t0
	addi $t0, $t0, 2076
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 14276
	move $a0, $t0
	addi $t0, $t0, 1592
	move $a1, $t0
	li $a2, 52
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 16348
	move $a0, $t0
	addi $t0, $t0, 3616
	move $a1, $t0
	li $a2, 28
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 18760
	move $a0, $t0
	addi $t0, $t0, 1104
	move $a1, $t0
	li $a2, 76
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 14060
	move $a0, $t0
	addi $t0, $t0, 2092
	move $a1, $t0
	li $a2, 40
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 18436
	move $a0, $t0
	addi $t0, $t0, 532
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 16396
	move $a0, $t0
	addi $t0, $t0, 1564
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 19460
	move $a0, $t0
	addi $t0, $t0, 524
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 16984
	move $a0, $t0
	addi $t0, $t0, 1036
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 32328
	move $a0, $t0
	addi $t0, $t0, 1588
	move $a1, $t0
	li $a2, 48
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 33340
	move $a0, $t0
	addi $t0, $t0, 524
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra

#  __  __               ___ 
# |  \/  | __ _  _ __  / _ \
# | |\/| |/ _` || '_ \ \_, /
# |_|  |_|\__,_|| .__/  /_/ 
#               |_|         
#
PLACE_PLAYER_MAP9:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	la $a0, player_data
	jal LOAD_DATA
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 34780
	move PLAYER_POS, $t0
	la $a0, player_data
	jal SAVE_DATA
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	

LOAD_SPIKES_MAP9:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 39032
	move $a0, $t0
	addi $t0, $t0, 540
	move $a1, $t0
	li $a2, 28
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 22836
	move $a0, $t0
	addi $t0, $t0, 544
	move $a1, $t0
	li $a2, 32
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 47232
	move $a0, $t0
	addi $t0, $t0, 668
	move $a1, $t0
	li $a2, 156
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 47136
	move $a0, $t0
	addi $t0, $t0, 540
	move $a1, $t0
	li $a2, 28
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 27720
	move $a0, $t0
	addi $t0, $t0, 524
	move $a1, $t0
	li $a2, 12
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 44608
	move $a0, $t0
	addi $t0, $t0, 536
	move $a1, $t0
	li $a2, 24
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 42424
	move $a0, $t0
	addi $t0, $t0, 548
	move $a1, $t0
	li $a2, 36
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 10812
	move $a0, $t0
	addi $t0, $t0, 528
	move $a1, $t0
	li $a2, 16
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 10860
	move $a0, $t0
	addi $t0, $t0, 536
	move $a1, $t0
	li $a2, 24
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 14044
	move $a0, $t0
	addi $t0, $t0, 528
	move $a1, $t0
	li $a2, 16
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 14100
	move $a0, $t0
	addi $t0, $t0, 524
	move $a1, $t0
	li $a2, 12
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 44380
	move $a0, $t0
	addi $t0, $t0, 552
	move $a1, $t0
	li $a2, 40
	jal DRAW_SPIKES
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 44440
	move $a0, $t0
	addi $t0, $t0, 540
	move $a1, $t0
	li $a2, 28
	jal DRAW_SPIKES
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	


LOAD_PICKUPS_MAP9:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	# Load Level Data
	la $a0, level_data
	jal LOAD_DATA
	li $t0, 29976
	li $t1, HEALTH_RESTORE_ID
	sw $t0, 0(PICKUP_POINTER)
	sw $t1, 4(PICKUP_POINTER)
	li $t0, 20664
	li $t1, HEALTH_RESTORE_ID
	sw $t0, 8(PICKUP_POINTER)
	sw $t1, 12(PICKUP_POINTER)
	li $t0, 42684
	li $t1, GRAVITY_POTION_ID
	sw $t0, 16(PICKUP_POINTER)
	sw $t1, 20(PICKUP_POINTER)
	li $t0, 13728
	li $t1, HEALTH_RESTORE_ID
	sw $t0, 24(PICKUP_POINTER)
	sw $t1, 28(PICKUP_POINTER)
	li $t0, 0
	sw $t0, 32(PICKUP_POINTER)
	sw $t0, 36(PICKUP_POINTER)
	la $a0, level_data
	jal SAVE_DATA
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	

DRAW_OVERLAY_MAP9:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	# Drawing Layer 1
	# Drawing Layer 2
	li $a3, 0x00141414
	lw $t0, 0($sp)
	addi $t0, $t0, 3584
	move $a0, $t0
	addi $t0, $t0, 1536
	move $a1, $t0
	li $a2, 508
	jal FILL
	
	li $a3, 0x001e1b1b
	lw $t0, 0($sp)
	addi $t0, $t0, 2048
	move $a0, $t0
	addi $t0, $t0, 1536
	move $a1, $t0
	li $a2, 508
	jal FILL
	
	li $a3, 0x002d2727
	lw $t0, 0($sp)
	addi $t0, $t0, 0
	move $a0, $t0
	addi $t0, $t0, 2048
	move $a1, $t0
	li $a2, 508
	jal FILL
	
	addi	$sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	


DRAW_MAP9:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal PLACE_PLAYER_MAP9
	jal LOAD_SPIKES_MAP9
	jal LOAD_PICKUPS_MAP9
	li $t1, WALL_COLOR
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 5120
	move $a0, $t0
	addi $t0, $t0, 43524
	move $a1, $t0
	li $a2, 0
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 48132
	move $a0, $t0
	addi $t0, $t0, 1016
	move $a1, $t0
	li $a2, 500
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 37288
	move $a0, $t0
	addi $t0, $t0, 1108
	move $a1, $t0
	li $a2, 80
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 38844
	move $a0, $t0
	addi $t0, $t0, 1088
	move $a1, $t0
	li $a2, 60
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 40416
	move $a0, $t0
	addi $t0, $t0, 2588
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 43500
	move $a0, $t0
	addi $t0, $t0, 4624
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 11268
	move $a0, $t0
	addi $t0, $t0, 1080
	move $a1, $t0
	li $a2, 52
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 12804
	move $a0, $t0
	addi $t0, $t0, 2592
	move $a1, $t0
	li $a2, 28
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 5628
	move $a0, $t0
	addi $t0, $t0, 43524
	move $a1, $t0
	li $a2, 0
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 15876
	move $a0, $t0
	addi $t0, $t0, 7188
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 6580
	move $a0, $t0
	addi $t0, $t0, 9288
	move $a1, $t0
	li $a2, 68
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 16340
	move $a0, $t0
	addi $t0, $t0, 7208
	move $a1, $t0
	li $a2, 36
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 24036
	move $a0, $t0
	addi $t0, $t0, 4632
	move $a1, $t0
	li $a2, 20
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 42092
	move $a0, $t0
	addi $t0, $t0, 5652
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 40020
	move $a0, $t0
	addi $t0, $t0, 1604
	move $a1, $t0
	li $a2, 64
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 42112
	move $a0, $t0
	addi $t0, $t0, 2064
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 42076
	move $a0, $t0
	addi $t0, $t0, 3088
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 38484
	move $a0, $t0
	addi $t0, $t0, 1060
	move $a1, $t0
	li $a2, 32
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 15016
	move $a0, $t0
	addi $t0, $t0, 3212
	move $a1, $t0
	li $a2, 136
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 23556
	move $a0, $t0
	addi $t0, $t0, 15372
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 39428
	move $a0, $t0
	addi $t0, $t0, 3080
	move $a1, $t0
	li $a2, 4
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 18640
	move $a0, $t0
	addi $t0, $t0, 4708
	move $a1, $t0
	li $a2, 96
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 23780
	move $a0, $t0
	addi $t0, $t0, 4672
	move $a1, $t0
	li $a2, 60
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 28916
	move $a0, $t0
	addi $t0, $t0, 3108
	move $a1, $t0
	li $a2, 32
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 23844
	move $a0, $t0
	addi $t0, $t0, 2100
	move $a1, $t0
	li $a2, 48
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 16316
	move $a0, $t0
	addi $t0, $t0, 4632
	move $a1, $t0
	li $a2, 20
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 6488
	move $a0, $t0
	addi $t0, $t0, 3164
	move $a1, $t0
	li $a2, 88
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 27988
	move $a0, $t0
	addi $t0, $t0, 1592
	move $a1, $t0
	li $a2, 52
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 26428
	move $a0, $t0
	addi $t0, $t0, 1060
	move $a1, $t0
	li $a2, 32
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 16256
	move $a0, $t0
	addi $t0, $t0, 1084
	move $a1, $t0
	li $a2, 56
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 32520
	move $a0, $t0
	addi $t0, $t0, 1088
	move $a1, $t0
	li $a2, 60
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 34068
	move $a0, $t0
	addi $t0, $t0, 4640
	move $a1, $t0
	li $a2, 28
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 34100
	move $a0, $t0
	addi $t0, $t0, 1548
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 45344
	move $a0, $t0
	addi $t0, $t0, 2764
	move $a1, $t0
	li $a2, 200
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 28712
	move $a0, $t0
	addi $t0, $t0, 1072
	move $a1, $t0
	li $a2, 44
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 23700
	move $a0, $t0
	addi $t0, $t0, 1616
	move $a1, $t0
	li $a2, 76
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 46596
	move $a0, $t0
	addi $t0, $t0, 1052
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 45632
	move $a0, $t0
	addi $t0, $t0, 2092
	move $a1, $t0
	li $a2, 40
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 11836
	move $a0, $t0
	addi $t0, $t0, 2668
	move $a1, $t0
	li $a2, 104
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 14908
	move $a0, $t0
	addi $t0, $t0, 2064
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 12836
	move $a0, $t0
	addi $t0, $t0, 7192
	move $a1, $t0
	li $a2, 20
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 14964
	move $a0, $t0
	addi $t0, $t0, 1588
	move $a1, $t0
	li $a2, 48
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 22644
	move $a0, $t0
	addi $t0, $t0, 572
	move $a1, $t0
	li $a2, 56
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 23684
	move $a0, $t0
	addi $t0, $t0, 1040
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 33296
	move $a0, $t0
	addi $t0, $t0, 1052
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 34832
	move $a0, $t0
	addi $t0, $t0, 2064
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 31348
	move $a0, $t0
	addi $t0, $t0, 2112
	move $a1, $t0
	li $a2, 60
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 33944
	move $a0, $t0
	addi $t0, $t0, 540
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 30344
	move $a0, $t0
	addi $t0, $t0, 556
	move $a1, $t0
	li $a2, 40
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 30900
	move $a0, $t0
	addi $t0, $t0, 2580
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 18616
	move $a0, $t0
	addi $t0, $t0, 1048
	move $a1, $t0
	li $a2, 20
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 44316
	move $a0, $t0
	addi $t0, $t0, 576
	move $a1, $t0
	li $a2, 60
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 43448
	move $a0, $t0
	addi $t0, $t0, 1588
	move $a1, $t0
	li $a2, 48
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 6372
	move $a0, $t0
	addi $t0, $t0, 1652
	move $a1, $t0
	li $a2, 112
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 10140
	move $a0, $t0
	addi $t0, $t0, 2072
	move $a1, $t0
	li $a2, 20
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 10128
	move $a0, $t0
	addi $t0, $t0, 1036
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 15232
	move $a0, $t0
	addi $t0, $t0, 532
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 6300
	move $a0, $t0
	addi $t0, $t0, 584
	move $a1, $t0
	li $a2, 68
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 9808
	move $a0, $t0
	addi $t0, $t0, 1564
	move $a1, $t0
	li $a2, 24
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 6148
	move $a0, $t0
	addi $t0, $t0, 32
	move $a1, $t0
	li $a2, 28
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 10376
	move $a0, $t0
	addi $t0, $t0, 1056
	move $a1, $t0
	li $a2, 28
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 12456
	move $a0, $t0
	addi $t0, $t0, 2080
	move $a1, $t0
	li $a2, 28
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 13512
	move $a0, $t0
	addi $t0, $t0, 1044
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 19800
	move $a0, $t0
	addi $t0, $t0, 6152
	move $a1, $t0
	li $a2, 4
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 25440
	move $a0, $t0
	addi $t0, $t0, 2072
	move $a1, $t0
	li $a2, 20
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 17812
	move $a0, $t0
	addi $t0, $t0, 1576
	move $a1, $t0
	li $a2, 36
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 19876
	move $a0, $t0
	addi $t0, $t0, 2064
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 22444
	move $a0, $t0
	addi $t0, $t0, 1544
	move $a1, $t0
	li $a2, 4
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 13604
	move $a0, $t0
	addi $t0, $t0, 1048
	move $a1, $t0
	li $a2, 20
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 18768
	move $a0, $t0
	addi $t0, $t0, 532
	move $a1, $t0
	li $a2, 16
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 19796
	move $a0, $t0
	addi $t0, $t0, 1028
	move $a1, $t0
	li $a2, 0
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 21856
	move $a0, $t0
	addi $t0, $t0, 3080
	move $a1, $t0
	li $a2, 4
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 13040
	move $a0, $t0
	addi $t0, $t0, 1572
	move $a1, $t0
	li $a2, 32
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 41348
	move $a0, $t0
	addi $t0, $t0, 536
	move $a1, $t0
	li $a2, 20
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 42376
	move $a0, $t0
	addi $t0, $t0, 2576
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 5124
	move $a0, $t0
	addi $t0, $t0, 1016
	move $a1, $t0
	li $a2, 500
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 6244
	move $a0, $t0
	addi $t0, $t0, 528
	move $a1, $t0
	li $a2, 12
	li $a3, WALL_COLOR
	jal FILL
	li $a0, BASE_ADDRESS
	jal DRAW_OVERLAY_MAP9
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra




#  __  __               _   __  
# |  \/  | __ _  _ __  / | /  \ 
# | |\/| |/ _` || '_ \ | || () |
# |_|  |_|\__,_|| .__/ |_| \__/ 
#               |_|             
PLACE_PLAYER_MAP10:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	la $a0, player_data
	jal LOAD_DATA
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 41844
	move PLAYER_POS, $t0
	la $a0, player_data
	jal SAVE_DATA
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra

LOAD_PICKUPS_MAP10:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	# Load Level Data
	la $a0, level_data
	jal LOAD_DATA
	li $t0, 0
	sw $t0, 0(PICKUP_POINTER)
	sw $t0, 4(PICKUP_POINTER)
	la $a0, level_data
	jal SAVE_DATA
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	



	
DRAW_OVERLAY_MAP10:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	# Drawing Layer 1
	li $a3, 0x005c4ba0
	lw $t0, 0($sp)
	addi $t0, $t0, 0
	move $a0, $t0
	addi $t0, $t0, 29696
	move $a1, $t0
	li $a2, 508
	jal FILL
	
	li $a3, 0x005C5454
	lw $t0, 0($sp)
	addi $t0, $t0, 40448
	move $a0, $t0
	addi $t0, $t0, 8248
	move $a1, $t0
	li $a2, 52
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 39380
	move $a0, $t0
	addi $t0, $t0, 9772
	move $a1, $t0
	li $a2, 40
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 37792
	move $a0, $t0
	addi $t0, $t0, 11316
	move $a1, $t0
	li $a2, 48
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 37404
	move $a0, $t0
	addi $t0, $t0, 2588
	move $a1, $t0
	li $a2, 24
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 45624
	move $a0, $t0
	addi $t0, $t0, 3432
	move $a1, $t0
	li $a2, 356
	jal FILL
	
	li $a3, 0x00726659
	lw $t0, 0($sp)
	addi $t0, $t0, 36308
	move $a0, $t0
	addi $t0, $t0, 2604
	move $a1, $t0
	li $a2, 40
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 36256
	move $a0, $t0
	addi $t0, $t0, 1076
	move $a1, $t0
	li $a2, 48
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 34208
	move $a0, $t0
	addi $t0, $t0, 1580
	move $a1, $t0
	li $a2, 40
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 37888
	move $a0, $t0
	addi $t0, $t0, 2076
	move $a1, $t0
	li $a2, 24
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 33808
	move $a0, $t0
	addi $t0, $t0, 3596
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 33820
	move $a0, $t0
	addi $t0, $t0, 3100
	move $a1, $t0
	li $a2, 24
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 33848
	move $a0, $t0
	addi $t0, $t0, 872
	move $a1, $t0
	li $a2, 356
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 32860
	move $a0, $t0
	addi $t0, $t0, 824
	move $a1, $t0
	li $a2, 308
	jal FILL
	
	# Drawing Layer 2
	li $a3, 0x00293624
	lw $t0, 0($sp)
	addi $t0, $t0, 29696
	move $a0, $t0
	addi $t0, $t0, 3072
	move $a1, $t0
	li $a2, 508
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 32768
	move $a0, $t0
	addi $t0, $t0, 604
	move $a1, $t0
	li $a2, 88
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 33172
	move $a0, $t0
	addi $t0, $t0, 620
	move $a1, $t0
	li $a2, 104
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 34252
	move $a0, $t0
	addi $t0, $t0, 1588
	move $a1, $t0
	li $a2, 48
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 33792
	move $a0, $t0
	addi $t0, $t0, 3600
	move $a1, $t0
	li $a2, 12
	jal FILL
	
	li $a3, 0x006757aa
	lw $t0, 0($sp)
	addi $t0, $t0, 10752
	move $a0, $t0
	addi $t0, $t0, 18608
	move $a1, $t0
	li $a2, 172
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 18608
	move $a0, $t0
	addi $t0, $t0, 11088
	move $a1, $t0
	li $a2, 332
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 9048
	move $a0, $t0
	addi $t0, $t0, 9384
	move $a1, $t0
	li $a2, 164
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 16616
	move $a0, $t0
	addi $t0, $t0, 1648
	move $a1, $t0
	li $a2, 108
	jal FILL
	
	# Drawing Layer 3
	li $a3, 0x006d5daf
	lw $t0, 0($sp)
	addi $t0, $t0, 21504
	move $a0, $t0
	addi $t0, $t0, 6656
	move $a1, $t0
	li $a2, 508
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 16236
	move $a0, $t0
	addi $t0, $t0, 5268
	move $a1, $t0
	li $a2, 144
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 16896
	move $a0, $t0
	addi $t0, $t0, 4224
	move $a1, $t0
	li $a2, 124
	jal FILL
	
	li $a3, 0x005b7550
	lw $t0, 0($sp)
	addi $t0, $t0, 28160
	move $a0, $t0
	addi $t0, $t0, 1536
	move $a1, $t0
	li $a2, 508
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 29696
	move $a0, $t0
	addi $t0, $t0, 1084
	move $a1, $t0
	li $a2, 56
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 30120
	move $a0, $t0
	addi $t0, $t0, 2136
	move $a1, $t0
	li $a2, 84
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 29836
	move $a0, $t0
	addi $t0, $t0, 536
	move $a1, $t0
	li $a2, 20
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 29976
	move $a0, $t0
	addi $t0, $t0, 1100
	move $a1, $t0
	li $a2, 72
	jal FILL
	
	# Drawing Layer 4
	li $a3, 0x001c1c27
	lw $t0, 0($sp)
	addi $t0, $t0, 26328
	move $a0, $t0
	addi $t0, $t0, 1676
	move $a1, $t0
	li $a2, 136
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 24420
	move $a0, $t0
	addi $t0, $t0, 3680
	move $a1, $t0
	li $a2, 92
	jal FILL
	
	li $a3, 0x00292a47
	lw $t0, 0($sp)
	addi $t0, $t0, 20932
	move $a0, $t0
	addi $t0, $t0, 7228
	move $a1, $t0
	li $a2, 56
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 22884
	move $a0, $t0
	addi $t0, $t0, 1120
	move $a1, $t0
	li $a2, 92
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 24792
	move $a0, $t0
	addi $t0, $t0, 1164
	move $a1, $t0
	li $a2, 136
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 27304
	move $a0, $t0
	addi $t0, $t0, 560
	move $a1, $t0
	li $a2, 44
	jal FILL
	
	li $a3, 0x009093dc
	lw $t0, 0($sp)
	addi $t0, $t0, 5472
	move $a0, $t0
	addi $t0, $t0, 4644
	move $a1, $t0
	li $a2, 32
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 6532
	move $a0, $t0
	addi $t0, $t0, 2600
	move $a1, $t0
	li $a2, 36
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 6988
	move $a0, $t0
	addi $t0, $t0, 2068
	move $a1, $t0
	li $a2, 16
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 14908
	move $a0, $t0
	addi $t0, $t0, 548
	move $a1, $t0
	li $a2, 32
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 15916
	move $a0, $t0
	addi $t0, $t0, 1612
	move $a1, $t0
	li $a2, 72
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 2212
	move $a0, $t0
	addi $t0, $t0, 1600
	move $a1, $t0
	li $a2, 60
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 4248
	move $a0, $t0
	addi $t0, $t0, 1604
	move $a1, $t0
	li $a2, 64
	jal FILL
	
	li $a3, 0x00ac9ad5
	lw $t0, 0($sp)
	addi $t0, $t0, 9548
	move $a0, $t0
	addi $t0, $t0, 532
	move $a1, $t0
	li $a2, 16
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 10592
	move $a0, $t0
	addi $t0, $t0, 552
	move $a1, $t0
	li $a2, 36
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 9604
	move $a0, $t0
	addi $t0, $t0, 540
	move $a1, $t0
	li $a2, 24
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 6296
	move $a0, $t0
	addi $t0, $t0, 580
	move $a1, $t0
	li $a2, 64
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 4752
	move $a0, $t0
	addi $t0, $t0, 2056
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 16420
	move $a0, $t0
	addi $t0, $t0, 1544
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17964
	move $a0, $t0
	addi $t0, $t0, 580
	move $a1, $t0
	li $a2, 64
	jal FILL
	
	li $a3, 0x00121212
	lw $t0, 0($sp)
	addi $t0, $t0, 29384
	move $a0, $t0
	addi $t0, $t0, 56
	move $a1, $t0
	li $a2, 52
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 28880
	move $a0, $t0
	addi $t0, $t0, 40
	move $a1, $t0
	li $a2, 36
	jal FILL
	
	# Drawing Layer 5
	li $a3, 0x00b5b1c9
	lw $t0, 0($sp)
	addi $t0, $t0, 6676
	move $a0, $t0
	addi $t0, $t0, 528
	move $a1, $t0
	li $a2, 12
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 6180
	move $a0, $t0
	addi $t0, $t0, 516
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 4620
	move $a0, $t0
	addi $t0, $t0, 12
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 5132
	move $a0, $t0
	addi $t0, $t0, 1544
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 6164
	move $a0, $t0
	addi $t0, $t0, 8
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 3600
	move $a0, $t0
	addi $t0, $t0, 532
	move $a1, $t0
	li $a2, 16
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 4132
	move $a0, $t0
	addi $t0, $t0, 516
	move $a1, $t0
	li $a2, 0
	jal FILL
	
	# Drawing Layer 6
	li $a3, 0x00b5b1c9
	lw $t0, 0($sp)
	addi $t0, $t0, 5424
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17048
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 5212
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17332
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 5088
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 24600
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 13568
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17188
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	jal FILL
	
	li $a3, 0x00c0b4a1
	lw $t0, 0($sp)
	addi $t0, $t0, 27372
	move $a0, $t0
	addi $t0, $t0, 516
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 27348
	move $a0, $t0
	addi $t0, $t0, 516
	move $a1, $t0
	li $a2, 0
	jal FILL
	
	li $a3, 0x00887e6e
	lw $t0, 0($sp)
	addi $t0, $t0, 28396
	move $a0, $t0
	addi $t0, $t0, 1028
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 28372
	move $a0, $t0
	addi $t0, $t0, 1028
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 27344
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 27376
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	jal FILL
	
	addi	$sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	


DRAW_MAP10:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal PLACE_PLAYER_MAP10
	jal LOAD_PICKUPS_MAP10
	li $t1, WALL_COLOR
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 36408
	move $a0, $t0
	addi $t0, $t0, 7692
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 36756
	move $a0, $t0
	addi $t0, $t0, 7692
	move $a1, $t0
	li $a2, 8
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 42052
	move $a0, $t0
	addi $t0, $t0, 2108
	move $a1, $t0
	li $a2, 56
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 36692
	move $a0, $t0
	addi $t0, $t0, 1088
	move $a1, $t0
	li $a2, 60
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 38260
	move $a0, $t0
	addi $t0, $t0, 1056
	move $a1, $t0
	li $a2, 28
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 34872
	move $a0, $t0
	addi $t0, $t0, 1384
	move $a1, $t0
	li $a2, 356
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 44600
	move $a0, $t0
	addi $t0, $t0, 872
	move $a1, $t0
	li $a2, 356
	li $a3, WALL_COLOR
	jal FILL
	li $t0, BASE_ADDRESS
	addi $t0, $t0, 36420
	move $a0, $t0
	addi $t0, $t0, 1060
	move $a1, $t0
	li $a2, 32
	li $a3, WALL_COLOR
	jal FILL
	li $a0, BASE_ADDRESS
	jal DRAW_OVERLAY_MAP10
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	
# __   __                                 
# \ \ / /___  _  _  __ __ __ ___  _ _     
#  \ V // _ \| || | \ V  V // _ \| ' \ 
#   |_| \___/ \_,_|  \_/\_/ \___/|_||_|
CHECK_RESTART_PRESSED:			# Shared between WIN and LOSE screens
	# Check restart
	li 	$s1, 0xffff0000
	lw	$s2, 0($s1)		# Verify input_is_new
	bne	$s2, 1, CHECK_RESTART_NONE
	
	# Determine what key was entered.
	lw $s1, 4($s1)								# Hex value of the key pressed
	beq $s1, 0x70, CHECK_RESTART_ON_KEYp
	
	CHECK_RESTART_NONE:
		li $v0, 0
		jr $ra									# No key, return to caller

	CHECK_RESTART_ON_KEYp:	
		li $v0, 1
		jr $ra

DRAW_WINSCREEN:
	li $s0, 250
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	li $a0, BASE_ADDRESS	# Color background
	li $a1, UI_END_ADDRESS
	li $a2, NEXT_ROW
	li $a3, 0x005c4ba0
	jal FILL

	li $a0, BASE_ADDRESS
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	jal DRAW_WINSCREEN_BACKGROUND
	WINSCREEN_LOOP:
		jal CHECK_RESTART_PRESSED
		bnez $v0, DRAW_WINSCREEN_RETURN

		lw $a0, 0($sp)
		
		beq $s0, 230, DRAW_WS_TITLE
		beq $s0, 200, DRAW_WS_SUBTITLE
		beq $s0, 150, CHECK_DRAW_LITTLESUB 
		b DRAW_WS_CHECK_TWINKLE

		DRAW_WS_TITLE: 			jal DRAW_WINSCREEN_TEXT_WIN
								b DRAW_WS_CHECK_TWINKLE
		DRAW_WS_SUBTITLE: 		jal DRAW_WINSCREEN_TEXT_ASCENDED
								b DRAW_WS_CHECK_TWINKLE
		CHECK_DRAW_LITTLESUB:	jal DRAW_WINSCREEN_SUB
			
		DRAW_WS_CHECK_TWINKLE:
			li $t0, 20		# See if time to twinkle hehe
			div $s0, $t0
			mfhi $t0

			blt $t0, 2, DRAW_WS_TWINKLE

			b DRAW_NORMAL_STAR

		DRAW_WS_TWINKLE:
			jal DRAW_WINSCREEN_STARS2
			j WINSCREEN_LOOP_ITERATE
			DRAW_NORMAL_STAR:
				jal DRAW_WINSCREEN_STARS1

		WINSCREEN_LOOP_ITERATE:
			subi $s0, $s0, 1
			li $v0, 32
			li $a0, 20
			syscall
			bgtz $s0, WINSCREEN_LOOP

	DRAW_WINSCREEN_RETURN:
		addi $sp, $sp, 4
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra
	
DRAW_WINSCREEN_SUB:
	lw $a0, 0($sp)
	li $t0, 0x00dacdf7
	sw $t0, 22336($a0)
	sw $t0, 22848($a0)
	sw $t0, 23360($a0)
	sw $t0, 23872($a0)
	sw $t0, 24384($a0)
	sw $t0, 22320($a0)
	sw $t0, 22324($a0)
	sw $t0, 22328($a0)
	sw $t0, 22840($a0)
	sw $t0, 23352($a0)
	sw $t0, 23864($a0)
	sw $t0, 22832($a0)
	sw $t0, 23344($a0)
	sw $t0, 23856($a0)
	sw $t0, 24368($a0)
	sw $t0, 24372($a0)
	sw $t0, 24376($a0)
	sw $t0, 22340($a0)
	sw $t0, 22344($a0)
	sw $t0, 23364($a0)
	sw $t0, 23368($a0)
	sw $t0, 22356($a0)
	sw $t0, 22360($a0)
	sw $t0, 22364($a0)
	sw $t0, 22872($a0)
	sw $t0, 23384($a0)
	sw $t0, 23896($a0)
	sw $t0, 24408($a0)
	sw $t0, 22372($a0)
	sw $t0, 22884($a0)
	sw $t0, 23396($a0)
	sw $t0, 23908($a0)
	sw $t0, 24420($a0)
	sw $t0, 23400($a0)
	sw $t0, 22380($a0)
	sw $t0, 22892($a0)
	sw $t0, 23404($a0)
	sw $t0, 23916($a0)
	sw $t0, 24428($a0)
	sw $t0, 22388($a0)
	sw $t0, 22392($a0)
	sw $t0, 22396($a0)
	sw $t0, 22320($a0)
	sw $t0, 22324($a0)
	sw $t0, 22328($a0)
	sw $t0, 22328($a0)
	sw $t0, 22840($a0)
	sw $t0, 23352($a0)
	sw $t0, 22840($a0)
	sw $t0, 23352($a0)
	sw $t0, 23864($a0)
	sw $t0, 22832($a0)
	sw $t0, 23344($a0)
	sw $t0, 23856($a0)
	sw $t0, 24368($a0)
	sw $t0, 24372($a0)
	sw $t0, 24376($a0)
	sw $t0, 22336($a0)
	sw $t0, 22848($a0)
	sw $t0, 23360($a0)
	sw $t0, 23872($a0)
	sw $t0, 24384($a0)
	sw $t0, 22340($a0)
	sw $t0, 22344($a0)
	sw $t0, 23364($a0)
	sw $t0, 23368($a0)
	sw $t0, 22356($a0)
	sw $t0, 22360($a0)
	sw $t0, 22364($a0)
	sw $t0, 22368($a0)
	sw $t0, 22356($a0)
	sw $t0, 22360($a0)
	sw $t0, 22364($a0)
	sw $t0, 22872($a0)
	sw $t0, 23384($a0)
	sw $t0, 23896($a0)
	sw $t0, 24408($a0)
	sw $t0, 22372($a0)
	sw $t0, 22884($a0)
	sw $t0, 23396($a0)
	sw $t0, 23908($a0)
	sw $t0, 22372($a0)
	sw $t0, 22884($a0)
	sw $t0, 23396($a0)
	sw $t0, 23908($a0)
	sw $t0, 24420($a0)
	sw $t0, 23400($a0)
	sw $t0, 22380($a0)
	sw $t0, 22892($a0)
	sw $t0, 23404($a0)
	sw $t0, 23916($a0)
	sw $t0, 24428($a0)
	sw $t0, 22388($a0)
	sw $t0, 22392($a0)
	sw $t0, 22396($a0)
	sw $t0, 22900($a0)
	sw $t0, 23412($a0)
	sw $t0, 23924($a0)
	sw $t0, 24436($a0)
	sw $t0, 23416($a0)
	sw $t0, 23420($a0)
	sw $t0, 24440($a0)
	sw $t0, 24444($a0)
	sw $t0, 22408($a0)
	sw $t0, 22920($a0)
	sw $t0, 23432($a0)
	sw $t0, 23944($a0)
	sw $t0, 24456($a0)
	sw $t0, 24460($a0)
	sw $t0, 24464($a0)
	sw $t0, 23952($a0)
	sw $t0, 22412($a0)
	sw $t0, 22416($a0)
	sw $t0, 22928($a0)
	sw $t0, 22424($a0)
	sw $t0, 22936($a0)
	sw $t0, 23448($a0)
	sw $t0, 23960($a0)
	sw $t0, 24472($a0)
	sw $t0, 22428($a0)
	sw $t0, 22432($a0)
	sw $t0, 22944($a0)
	sw $t0, 23456($a0)
	sw $t0, 23968($a0)
	sw $t0, 24480($a0)
	sw $t0, 23452($a0)
	sw $t0, 22440($a0)
	sw $t0, 22952($a0)
	sw $t0, 23464($a0)
	sw $t0, 23976($a0)
	sw $t0, 24488($a0)
	sw $t0, 24492($a0)
	sw $t0, 22448($a0)
	sw $t0, 22960($a0)
	sw $t0, 23472($a0)
	sw $t0, 23984($a0)
	sw $t0, 24496($a0)
	sw $t0, 22456($a0)
	sw $t0, 22968($a0)
	sw $t0, 23480($a0)
	sw $t0, 23992($a0)
	sw $t0, 24504($a0)
	sw $t0, 24508($a0)
	sw $t0, 24512($a0)
	sw $t0, 23484($a0)
	sw $t0, 23488($a0)
	sw $t0, 22460($a0)
	sw $t0, 22464($a0)
	sw $t0, 22300($a0)
	sw $t0, 22304($a0)
	sw $t0, 22308($a0)
	sw $t0, 22816($a0)
	sw $t0, 23328($a0)
	sw $t0, 23840($a0)
	sw $t0, 24352($a0)
	sw $t0, 22292($a0)
	sw $t0, 22804($a0)
	sw $t0, 23316($a0)
	sw $t0, 23828($a0)
	sw $t0, 24340($a0)
	sw $t0, 24336($a0)
	sw $t0, 22284($a0)
	sw $t0, 22796($a0)
	sw $t0, 23308($a0)
	sw $t0, 23820($a0)
	sw $t0, 24332($a0)
	sw $t0, 22276($a0)
	sw $t0, 22788($a0)
	sw $t0, 23300($a0)
	sw $t0, 23812($a0)
	sw $t0, 24324($a0)
	sw $t0, 24320($a0)
	sw $t0, 22272($a0)
	sw $t0, 22268($a0)
	sw $t0, 22780($a0)
	sw $t0, 23292($a0)
	sw $t0, 23804($a0)
	sw $t0, 24316($a0)
	sw $t0, 24296($a0)
	sw $t0, 24288($a0)
	sw $t0, 24280($a0)
	jr $ra

DRAW_WINSCREEN_STARS1:
	# ------------------------------
	# DRAW STARS
	# ------------------------------
	
	lw $a0, 0($sp)
	
	# STARS
	li $t0, 0x00e8ddff
	sw $t0, 32536($a0)
	sw $t0, 33048($a0)
	sw $t0, 33560($a0)
	sw $t0, 33044($a0)
	sw $t0, 33052($a0)
	sw $t0, 27452($a0)
	sw $t0, 44776($a0)
	sw $t0, 5248($a0)
	sw $t0, 5760($a0)
	sw $t0, 6272($a0)
	sw $t0, 5764($a0)
	sw $t0, 5756($a0)
	
	# STARS
	li $t0, 0x00c5b4ec
	sw $t0, 9888($a0)
	sw $t0, 8776($a0)
	sw $t0, 2852($a0)
	sw $t0, 13644($a0)
	sw $t0, 12704($a0)
	sw $t0, 35372($a0)
	jr $ra
DRAW_WINSCREEN_STARS2:
	# ------------------------------
	# DRAW STARS
	# ------------------------------
	
	lw $a0, 0($sp)
	
	# STARS
	li $t0, 0x007A6ABA
	sw $t0, 32536($a0)
	sw $t0, 33048($a0)
	sw $t0, 33560($a0)
	sw $t0, 33044($a0)
	sw $t0, 33052($a0)
	sw $t0, 27452($a0)
	sw $t0, 44776($a0)
	sw $t0, 5248($a0)
	sw $t0, 5760($a0)
	sw $t0, 6272($a0)
	sw $t0, 5764($a0)
	sw $t0, 5756($a0)
	
	# STARS
	li $t0, 0x006757AA
	sw $t0, 9888($a0)
	sw $t0, 8776($a0)
	sw $t0, 2852($a0)
	sw $t0, 13644($a0)
	sw $t0, 12704($a0)
	sw $t0, 35372($a0)
	jr $ra
DRAW_WINSCREEN_TEXT_ASCENDED:
	# Push address
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)

	li $a0, BASE_ADDRESS
	li $a3, 0x00ffffff
	lw $t0, 0($sp)
	addi $t0, $t0, 16968
	move $a0, $t0
	addi $t0, $t0, 1032
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 18504
	move $a0, $t0
	addi $t0, $t0, 536
	move $a1, $t0
	li $a2, 20
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 16984
	move $a0, $t0
	addi $t0, $t0, 1032
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 19536
	move $a0, $t0
	addi $t0, $t0, 1544
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17000
	move $a0, $t0
	addi $t0, $t0, 4104
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17008
	move $a0, $t0
	addi $t0, $t0, 516
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 20592
	move $a0, $t0
	addi $t0, $t0, 516
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17012
	move $a0, $t0
	addi $t0, $t0, 4104
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17024
	move $a0, $t0
	addi $t0, $t0, 4104
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 20616
	move $a0, $t0
	addi $t0, $t0, 516
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17036
	move $a0, $t0
	addi $t0, $t0, 4104
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17068
	move $a0, $t0
	addi $t0, $t0, 4104
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 19124
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17080
	move $a0, $t0
	addi $t0, $t0, 4104
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17092
	move $a0, $t0
	addi $t0, $t0, 4104
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17100
	move $a0, $t0
	addi $t0, $t0, 516
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 19148
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17104
	move $a0, $t0
	addi $t0, $t0, 4104
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17116
	move $a0, $t0
	addi $t0, $t0, 4104
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 20708
	move $a0, $t0
	addi $t0, $t0, 516
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17128
	move $a0, $t0
	addi $t0, $t0, 3592
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17140
	move $a0, $t0
	addi $t0, $t0, 4104
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17148
	move $a0, $t0
	addi $t0, $t0, 520
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 20732
	move $a0, $t0
	addi $t0, $t0, 520
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 19196
	move $a0, $t0
	addi $t0, $t0, 8
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17172
	move $a0, $t0
	addi $t0, $t0, 4104
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17180
	move $a0, $t0
	addi $t0, $t0, 516
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 19228
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17184
	move $a0, $t0
	addi $t0, $t0, 4104
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17196
	move $a0, $t0
	addi $t0, $t0, 2056
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17204
	move $a0, $t0
	addi $t0, $t0, 12
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 18744
	move $a0, $t0
	addi $t0, $t0, 2568
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 21292
	move $a0, $t0
	addi $t0, $t0, 12
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 18740
	move $a0, $t0
	addi $t0, $t0, 516
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17220
	move $a0, $t0
	addi $t0, $t0, 4104
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17228
	move $a0, $t0
	addi $t0, $t0, 516
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 20812
	move $a0, $t0
	addi $t0, $t0, 516
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17232
	move $a0, $t0
	addi $t0, $t0, 1544
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 19792
	move $a0, $t0
	addi $t0, $t0, 1544
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17244
	move $a0, $t0
	addi $t0, $t0, 4104
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17252
	move $a0, $t0
	addi $t0, $t0, 520
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 19300
	move $a0, $t0
	addi $t0, $t0, 8
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 20836
	move $a0, $t0
	addi $t0, $t0, 520
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17264
	move $a0, $t0
	addi $t0, $t0, 4104
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17272
	move $a0, $t0
	addi $t0, $t0, 516
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17276
	move $a0, $t0
	addi $t0, $t0, 4104
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17288
	move $a0, $t0
	addi $t0, $t0, 4104
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17296
	move $a0, $t0
	addi $t0, $t0, 8
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17812
	move $a0, $t0
	addi $t0, $t0, 3080
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 21392
	move $a0, $t0
	addi $t0, $t0, 8
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17312
	move $a0, $t0
	addi $t0, $t0, 4104
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17320
	move $a0, $t0
	addi $t0, $t0, 520
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 20904
	move $a0, $t0
	addi $t0, $t0, 520
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 19368
	move $a0, $t0
	addi $t0, $t0, 8
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17332
	move $a0, $t0
	addi $t0, $t0, 4104
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17340
	move $a0, $t0
	addi $t0, $t0, 8
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 21436
	move $a0, $t0
	addi $t0, $t0, 8
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17856
	move $a0, $t0
	addi $t0, $t0, 3080
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 24512
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	jal FILL	
	addi $sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra

DRAW_WINSCREEN_TEXT_WIN:	
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)

	li $a0, BASE_ADDRESS
	li $a3, 0x00f6f7cb
	lw $t0, 0($sp)
	addi $t0, $t0, 9948
	move $a0, $t0
	addi $t0, $t0, 4616
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 15068
	move $a0, $t0
	addi $t0, $t0, 544
	move $a1, $t0
	li $a2, 28
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 9972
	move $a0, $t0
	addi $t0, $t0, 4616
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 9960
	move $a0, $t0
	addi $t0, $t0, 4616
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 9984
	move $a0, $t0
	addi $t0, $t0, 5640
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 9996
	move $a0, $t0
	addi $t0, $t0, 5640
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 10004
	move $a0, $t0
	addi $t0, $t0, 532
	move $a1, $t0
	li $a2, 16
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 11040
	move $a0, $t0
	addi $t0, $t0, 4616
	move $a1, $t0
	li $a2, 4
	jal FILL
	addi $sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
DRAW_WINSCREEN_BACKGROUND:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)

	addi $sp, $sp, -4
	sw $a0, 0($sp)
	
	# --------------------------------
	# DRAW BACKGROUND AND STUFF
	# -------------------------------
	DRAW_WS_SECTION_BACKGROUND:
		# Drawing Layer 1
		li $a3, 0x006757aa
		lw $t0, 0($sp)
		addi $t0, $t0, 17316
		move $a0, $t0
		addi $t0, $t0, 8796
		move $a1, $t0
		li $a2, 88
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 25600
		move $a0, $t0
		addi $t0, $t0, 30208
		move $a1, $t0
		li $a2, 508
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 19968
		move $a0, $t0
		addi $t0, $t0, 5752
		move $a1, $t0
		li $a2, 116
		jal FILL
		
		li $a3, 0x006d5daf
		lw $t0, 0($sp)
		addi $t0, $t0, 50600
		move $a0, $t0
		addi $t0, $t0, 516
		move $a1, $t0
		li $a2, 0
		jal FILL
		
		li $a3, 0x009093dc
		lw $t0, 0($sp)
		addi $t0, $t0, 2868
		move $a0, $t0
		addi $t0, $t0, 9268
		move $a1, $t0
		li $a2, 48
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 4456
		move $a0, $t0
		addi $t0, $t0, 6748
		move $a1, $t0
		li $a2, 88
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 5380
		move $a0, $t0
		addi $t0, $t0, 4656
		move $a1, $t0
		li $a2, 44
		jal FILL
		
		# Drawing Layer 2
		li $a3, 0x006d5daf
		lw $t0, 0($sp)
		addi $t0, $t0, 31232
		move $a0, $t0
		addi $t0, $t0, 10752
		move $a1, $t0
		li $a2, 508
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 29696
		move $a0, $t0
		addi $t0, $t0, 1688
		move $a1, $t0
		li $a2, 148
		jal FILL
		
		li $a3, 0x009093dc
		lw $t0, 0($sp)
		addi $t0, $t0, 20564
		move $a0, $t0
		addi $t0, $t0, 3092
		move $a1, $t0
		li $a2, 16
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 21608
		move $a0, $t0
		addi $t0, $t0, 2112
		move $a1, $t0
		li $a2, 60
		jal FILL
		
		li $a3, 0x00ac9ad5
		lw $t0, 0($sp)
		addi $t0, $t0, 23624
		move $a0, $t0
		addi $t0, $t0, 1072
		move $a1, $t0
		li $a2, 44
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 21584
		move $a0, $t0
		addi $t0, $t0, 2052
		move $a1, $t0
		li $a2, 0
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 9988
		move $a0, $t0
		addi $t0, $t0, 1072
		move $a1, $t0
		li $a2, 44
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 11048
		move $a0, $t0
		addi $t0, $t0, 2572
		move $a1, $t0
		li $a2, 8
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 12084
		move $a0, $t0
		addi $t0, $t0, 1588
		move $a1, $t0
		li $a2, 48
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 11112
		move $a0, $t0
		addi $t0, $t0, 1608
		move $a1, $t0
		li $a2, 68
		jal FILL
		
		# Drawing Layer 3
		li $a3, 0x007a6aba
		lw $t0, 0($sp)
		addi $t0, $t0, 38912
		move $a0, $t0
		addi $t0, $t0, 1724
		move $a1, $t0
		li $a2, 184
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 40448
		move $a0, $t0
		addi $t0, $t0, 11776
		move $a1, $t0
		li $a2, 508
		jal FILL
		
		# Drawing Layer 4
		li $a3, 0x00292a47
		lw $t0, 0($sp)
		addi $t0, $t0, 41724
		move $a0, $t0
		addi $t0, $t0, 11528
		move $a1, $t0
		li $a2, 260
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 39200
		move $a0, $t0
		addi $t0, $t0, 2784
		move $a1, $t0
		li $a2, 220
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 38300
		move $a0, $t0
		addi $t0, $t0, 1124
		move $a1, $t0
		li $a2, 96
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 33228
		move $a0, $t0
		addi $t0, $t0, 5172
		move $a1, $t0
		li $a2, 48
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 45640
		move $a0, $t0
		addi $t0, $t0, 4280
		move $a1, $t0
		li $a2, 180
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 50176
		move $a0, $t0
		addi $t0, $t0, 2120
		move $a1, $t0
		li $a2, 68
		jal FILL
		
		li $a3, 0x00293624
		lw $t0, 0($sp)
		addi $t0, $t0, 52224
		move $a0, $t0
		addi $t0, $t0, 13824
		move $a1, $t0
		li $a2, 508
		jal FILL
		
		# Drawing Layer 5
		li $a3, 0x001c1c27
		lw $t0, 0($sp)
		addi $t0, $t0, 44820
		move $a0, $t0
		addi $t0, $t0, 7864
		move $a1, $t0
		li $a2, 180
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 49736
		move $a0, $t0
		addi $t0, $t0, 2764
		move $a1, $t0
		li $a2, 200
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 50688
		move $a0, $t0
		addi $t0, $t0, 1608
		move $a1, $t0
		li $a2, 68
		jal FILL
		
		li $a3, 0x005b7550
		lw $t0, 0($sp)
		addi $t0, $t0, 52224
		move $a0, $t0
		addi $t0, $t0, 4608
		move $a1, $t0
		li $a2, 508
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 56724
		move $a0, $t0
		addi $t0, $t0, 2668
		move $a1, $t0
		li $a2, 104
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 56592
		move $a0, $t0
		addi $t0, $t0, 4640
		move $a1, $t0
		li $a2, 28
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 56368
		move $a0, $t0
		addi $t0, $t0, 3220
		move $a1, $t0
		li $a2, 144
		jal FILL
		
		# Drawing Layer 6
		li $a3, 0x0087486d
		lw $t0, 0($sp)
		addi $t0, $t0, 44184
		move $a0, $t0
		addi $t0, $t0, 9264
		move $a1, $t0
		li $a2, 44
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 45200
		move $a0, $t0
		addi $t0, $t0, 8200
		move $a1, $t0
		li $a2, 4
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 47244
		move $a0, $t0
		addi $t0, $t0, 6148
		move $a1, $t0
		li $a2, 0
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 39060
		move $a0, $t0
		addi $t0, $t0, 5684
		move $a1, $t0
		li $a2, 48
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 38024
		move $a0, $t0
		addi $t0, $t0, 1084
		move $a1, $t0
		li $a2, 56
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 39044
		move $a0, $t0
		addi $t0, $t0, 2064
		move $a1, $t0
		li $a2, 12
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 39548
		move $a0, $t0
		addi $t0, $t0, 2572
		move $a1, $t0
		li $a2, 8
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 41072
		move $a0, $t0
		addi $t0, $t0, 1036
		move $a1, $t0
		li $a2, 8
		jal FILL
		
		li $a3, 0x00121212
		lw $t0, 0($sp)
		addi $t0, $t0, 54552
		move $a0, $t0
		addi $t0, $t0, 1096
		move $a1, $t0
		li $a2, 68
		jal FILL
		
		li $a3, 0x00181716
		lw $t0, 0($sp)
		addi $t0, $t0, 53016
		move $a0, $t0
		addi $t0, $t0, 1608
		move $a1, $t0
		li $a2, 68
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 53600
		move $a0, $t0
		addi $t0, $t0, 2056
		move $a1, $t0
		li $a2, 4
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 53520
		move $a0, $t0
		addi $t0, $t0, 2056
		move $a1, $t0
		li $a2, 4
		jal FILL	

		# HOOD RIGHT SIDE
		li $a3, 0x001b1b1b
		lw $t0, 0($sp)
		addi $t0, $t0, 40608
		move $a0, $t0
		addi $t0, $t0, 3108
		move $a1, $t0
		li $a2, 32
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 44196
		move $a0, $t0
		addi $t0, $t0, 32
		move $a1, $t0
		li $a2, 28
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 40100
		move $a0, $t0
		addi $t0, $t0, 28
		move $a1, $t0
		li $a2, 24
		jal FILL
	

	
	# ------------------------------
	# DRAW LADDER
	# ------------------------------
	DRAW_WS_SECTION_LADDER:
		li $a3, 0x00887e6e
		lw $t0, 0($sp)
		addi $t0, $t0, 54600
		move $a0, $t0
		addi $t0, $t0, 520
		move $a1, $t0
		li $a2, 4
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 54564
		move $a0, $t0
		addi $t0, $t0, 520
		move $a1, $t0
		li $a2, 4
		jal FILL
		
		li $a3, 0x00ab9f8d
		lw $t0, 0($sp)
		addi $t0, $t0, 53576
		move $a0, $t0
		addi $t0, $t0, 520
		move $a1, $t0
		li $a2, 4
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 53540
		move $a0, $t0
		addi $t0, $t0, 520
		move $a1, $t0
		li $a2, 4
		jal FILL

		li $a3, 0x00c0b4a1
		lw $t0, 0($sp)
		addi $t0, $t0, 49480
		move $a0, $t0
		addi $t0, $t0, 3592
		move $a1, $t0
		li $a2, 4
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 49444
		move $a0, $t0
		addi $t0, $t0, 3592
		move $a1, $t0
		li $a2, 4
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 48928
		move $a0, $t0
		addi $t0, $t0, 12
		move $a1, $t0
		li $a2, 8
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 48968
		move $a0, $t0
		addi $t0, $t0, 12
		move $a1, $t0
		li $a2, 8
		jal FILL
	# ------------------------------
	# DRAW EYES
	# ------------------------------
	DRAW_WS_EYES:
		lw $a0, 0($sp)
		# Drawing Layer 8
		li $a3, 0x00eaeaea
		lw $t0, 0($sp)
		addi $t0, $t0, 41128
		move $a0, $t0
		addi $t0, $t0, 1032
		move $a1, $t0
		li $a2, 4
		jal FILL
		lw $t0, 0($sp)
		addi $t0, $t0, 41148
		move $a0, $t0
		addi $t0, $t0, 1032
		move $a1, $t0
		li $a2, 4
		jal FILL
	# ------------------------------
	# DRAW TEXT
	# ------------------------------
	
	
	# ------------------------------
	# END OF DRAWING
	# ------------------------------
	addi	$sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	

                                         



#    ___					  __
#  / __| __ _  _ __   ___   / _ \ __ __ ___  _ _ 
# | (_ |/ _` || '  \ / -_) | (_) |\ V // -_)| '_|
#  \___|\__,_||_|_|_|\___|  \___/  \_/ \___||_|  
#      
DRAW_GAME_OVER:

	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)

	addi $sp, $sp, -4	# Push current starting address
	sw $a0, 0($sp)
	# Color screen dark gray
	li $a0, BASE_ADDRESS
	li $a1, UI_END_ADDRESS
	li $a2, NEXT_ROW
	li $a3, 0x00141414
	jal FILL
	lw $a0, 0($sp)
	addi $sp, $sp, 4	# Pop starting address

	li $t9, 20
	addi $sp, $sp, -4	# Store tick into address
	sw $t9, 0($sp)

	j GAME_OVER_ANIM
	GAME_OVER_ANIM_SLOW_WAIT:	# Called on first iteration
		addi $sp, $sp, -4
		sw $a0, 0($sp)
		addi $sp, $sp, -4
		sw $t0, 0($sp)
		li $t0, 100
		GAME_OVER_ANIM_SLOW_WAIT_LOOP:
			li $v0, 32
			li $a0, 20
			syscall
			jal CHECK_RESTART_PRESSED
			bnez $v0, DRAW_GAME_OVER_FREE_AND_RETURN
			subi $t0, $t0, 1
			bgtz $t0, GAME_OVER_ANIM_SLOW_WAIT_LOOP
		
		lw $t0, 0($sp)
		addi $sp, $sp, 4

		lw $a0, 0($sp)
		addi $sp, $sp, 4
		

		j GAME_OVER_ANIM
		DRAW_GAME_OVER_FREE_AND_RETURN:
			addi $sp, $sp, 12
			j DRAW_GAME_OVER_RETURN


	GAME_OVER_ANIM:

		addi $sp, $sp, -4	# Push current starting address
		sw $a0, 0($sp)

		# Color screen dark gray
		li $a0, BASE_ADDRESS	# Cuts off at UI-section, allows bleed-effect
		li $a1, END_ADDRESS
		li $a2, NEXT_ROW
		li $a3, 0x00141414
		jal FILL

		GAME_OVER_TEXT1:
			lw $a0, 0($sp)
			li $t0, 0x00e13735
			sw $t0, 41092($a0)
			sw $t0, 41604($a0)
			sw $t0, 42116($a0)
			sw $t0, 42628($a0)
			sw $t0, 43144($a0)
			sw $t0, 43148($a0)
			sw $t0, 41104($a0)
			sw $t0, 41616($a0)
			sw $t0, 42128($a0)
			sw $t0, 42640($a0)
			sw $t0, 41116($a0)
			sw $t0, 41628($a0)
			sw $t0, 42140($a0)
			sw $t0, 42652($a0)
			sw $t0, 43164($a0)
			sw $t0, 42144($a0)
			sw $t0, 42148($a0)
			sw $t0, 41128($a0)
			sw $t0, 41640($a0)
			sw $t0, 42152($a0)
			sw $t0, 42664($a0)
			sw $t0, 43176($a0)
			sw $t0, 41656($a0)
			sw $t0, 42168($a0)
			sw $t0, 42680($a0)
			sw $t0, 41148($a0)
			sw $t0, 41152($a0)
			sw $t0, 43196($a0)
			sw $t0, 43200($a0)
			sw $t0, 41668($a0)
			sw $t0, 42180($a0)
			sw $t0, 42692($a0)
			sw $t0, 41164($a0)
			sw $t0, 41676($a0)
			sw $t0, 42188($a0)
			sw $t0, 42700($a0)
			sw $t0, 43212($a0)
			sw $t0, 42192($a0)
			sw $t0, 42196($a0)
			sw $t0, 41176($a0)
			sw $t0, 41688($a0)
			sw $t0, 42200($a0)
			sw $t0, 42712($a0)
			sw $t0, 43224($a0)
			sw $t0, 43236($a0)
			sw $t0, 41200($a0)
			sw $t0, 41712($a0)
			sw $t0, 42224($a0)
			sw $t0, 42736($a0)
			sw $t0, 43248($a0)
			sw $t0, 43252($a0)
			sw $t0, 43256($a0)
			sw $t0, 43260($a0)
			sw $t0, 41732($a0)
			sw $t0, 42244($a0)
			sw $t0, 42756($a0)
			sw $t0, 43272($a0)
			sw $t0, 43276($a0)
			sw $t0, 41744($a0)
			sw $t0, 42256($a0)
			sw $t0, 42768($a0)
			sw $t0, 41224($a0)
			sw $t0, 41228($a0)
			sw $t0, 41752($a0)
			sw $t0, 42264($a0)
			sw $t0, 42776($a0)
			sw $t0, 43292($a0)
			sw $t0, 43296($a0)
			sw $t0, 41244($a0)
			sw $t0, 41248($a0)
			sw $t0, 41764($a0)
			sw $t0, 42276($a0)
			sw $t0, 42788($a0)
			sw $t0, 41260($a0)
			sw $t0, 41772($a0)
			sw $t0, 42284($a0)
			sw $t0, 42796($a0)
			sw $t0, 43308($a0)
			sw $t0, 42288($a0)
			sw $t0, 41780($a0)
			sw $t0, 41272($a0)
			sw $t0, 42804($a0)
			sw $t0, 43320($a0)
			sw $t0, 41792($a0)
			sw $t0, 41284($a0)
			sw $t0, 41288($a0)
			sw $t0, 41292($a0)
			sw $t0, 42308($a0)
			sw $t0, 42312($a0)
			sw $t0, 42828($a0)
			sw $t0, 43328($a0)
			sw $t0, 43332($a0)
			sw $t0, 43336($a0)
			sw $t0, 41304($a0)
			sw $t0, 41816($a0)
			sw $t0, 42328($a0)
			sw $t0, 42840($a0)
			sw $t0, 43352($a0)
			sw $t0, 43356($a0)
			sw $t0, 43360($a0)
			sw $t0, 43364($a0)
			sw $t0, 41324($a0)
			sw $t0, 41328($a0)
			sw $t0, 41332($a0)
			sw $t0, 41840($a0)
			sw $t0, 42352($a0)
			sw $t0, 42864($a0)
			sw $t0, 43372($a0)
			sw $t0, 43376($a0)
			sw $t0, 43380($a0)
			sw $t0, 41340($a0)
			sw $t0, 41852($a0)
			sw $t0, 42364($a0)
			sw $t0, 42876($a0)
			sw $t0, 43388($a0)
			sw $t0, 42368($a0)
			sw $t0, 41860($a0)
			sw $t0, 41352($a0)
			sw $t0, 42884($a0)
			sw $t0, 43400($a0)
			sw $t0, 41360($a0)
			sw $t0, 41872($a0)
			sw $t0, 42384($a0)
			sw $t0, 42896($a0)
			sw $t0, 43408($a0)
			sw $t0, 43412($a0)
			sw $t0, 43416($a0)
			sw $t0, 43420($a0)
			sw $t0, 42388($a0)
			sw $t0, 42392($a0)
			sw $t0, 41364($a0)
			sw $t0, 41368($a0)
			sw $t0, 41372($a0)
		GAME_OVER_TEXT2:
			li $t0, 0x00e13737
			sw $t0, 44140($a0)
			sw $t0, 44652($a0)
			sw $t0, 45168($a0)
			sw $t0, 45172($a0)
			sw $t0, 45176($a0)
			sw $t0, 44156($a0)
			sw $t0, 44668($a0)
			sw $t0, 45684($a0)
			sw $t0, 46196($a0)
			sw $t0, 44676($a0)
			sw $t0, 45188($a0)
			sw $t0, 45700($a0)
			sw $t0, 46216($a0)
			sw $t0, 46220($a0)
			sw $t0, 44168($a0)
			sw $t0, 44172($a0)
			sw $t0, 44688($a0)
			sw $t0, 45200($a0)
			sw $t0, 45712($a0)
			sw $t0, 44184($a0)
			sw $t0, 44696($a0)
			sw $t0, 45208($a0)
			sw $t0, 45720($a0)
			sw $t0, 46236($a0)
			sw $t0, 46240($a0)
			sw $t0, 44196($a0)
			sw $t0, 44708($a0)
			sw $t0, 45220($a0)
			sw $t0, 45732($a0)
			sw $t0, 44728($a0)
			sw $t0, 44220($a0)
			sw $t0, 44224($a0)
			sw $t0, 44228($a0)
			sw $t0, 45244($a0)
			sw $t0, 45248($a0)
			sw $t0, 45764($a0)
			sw $t0, 46264($a0)
			sw $t0, 46268($a0)
			sw $t0, 46272($a0)
			sw $t0, 44756($a0)
			sw $t0, 45268($a0)
			sw $t0, 45780($a0)
			sw $t0, 46292($a0)
			sw $t0, 44236($a0)
			sw $t0, 44240($a0)
			sw $t0, 44244($a0)
			sw $t0, 44248($a0)
			sw $t0, 44252($a0)
			sw $t0, 44772($a0)
			sw $t0, 45284($a0)
			sw $t0, 45796($a0)
			sw $t0, 44264($a0)
			sw $t0, 44268($a0)
			sw $t0, 44784($a0)
			sw $t0, 45296($a0)
			sw $t0, 45808($a0)
			sw $t0, 46312($a0)
			sw $t0, 46316($a0)
			sw $t0, 44280($a0)
			sw $t0, 44792($a0)
			sw $t0, 45304($a0)
			sw $t0, 45816($a0)
			sw $t0, 46328($a0)
			sw $t0, 44284($a0)
			sw $t0, 44288($a0)
			sw $t0, 45308($a0)
			sw $t0, 45312($a0)
			sw $t0, 44804($a0)
			sw $t0, 44300($a0)
			sw $t0, 44812($a0)
			sw $t0, 45324($a0)
			sw $t0, 45836($a0)
			sw $t0, 46348($a0)
			sw $t0, 44304($a0)
			sw $t0, 44308($a0)
			sw $t0, 45328($a0)
			sw $t0, 45332($a0)
			sw $t0, 44824($a0)
			sw $t0, 44320($a0)
			sw $t0, 44832($a0)
			sw $t0, 45344($a0)
			sw $t0, 45856($a0)
			sw $t0, 46368($a0)
			sw $t0, 46372($a0)
			sw $t0, 46376($a0)
			sw $t0, 46380($a0)
			sw $t0, 44324($a0)
			sw $t0, 44328($a0)
			sw $t0, 44332($a0)
			sw $t0, 45348($a0)
			sw $t0, 45352($a0)
			sw $t0, 44340($a0)
			sw $t0, 44852($a0)
			sw $t0, 45364($a0)
			sw $t0, 45876($a0)
			sw $t0, 46388($a0)
			sw $t0, 44344($a0)
			sw $t0, 44348($a0)
			sw $t0, 46392($a0)
			sw $t0, 46396($a0)
			sw $t0, 44864($a0)
			sw $t0, 45376($a0)
			sw $t0, 45888($a0)
			sw $t0, 44364($a0)
			sw $t0, 44876($a0)
			sw $t0, 45388($a0)
			sw $t0, 45900($a0)
			sw $t0, 46412($a0)
			sw $t0, 46416($a0)
			sw $t0, 46420($a0)
			sw $t0, 44380($a0)
			sw $t0, 44384($a0)
			sw $t0, 44388($a0)
			sw $t0, 44896($a0)
			sw $t0, 45408($a0)
			sw $t0, 45920($a0)
			sw $t0, 46428($a0)
			sw $t0, 46432($a0)
			sw $t0, 46436($a0)
			sw $t0, 44396($a0)
			sw $t0, 44908($a0)
			sw $t0, 45424($a0)
			sw $t0, 45936($a0)
			sw $t0, 46452($a0)
			sw $t0, 45432($a0)
			sw $t0, 45944($a0)
			sw $t0, 44412($a0)
			sw $t0, 44924($a0)
			sw $t0, 44420($a0)
			sw $t0, 44424($a0)
			sw $t0, 44428($a0)
			sw $t0, 44936($a0)
			sw $t0, 45448($a0)
			sw $t0, 45960($a0)
			sw $t0, 46468($a0)
			sw $t0, 46472($a0)
			sw $t0, 46476($a0)
			sw $t0, 44436($a0)
			sw $t0, 44948($a0)
			sw $t0, 45460($a0)
			sw $t0, 45972($a0)
			sw $t0, 46484($a0)
			sw $t0, 44952($a0)
			sw $t0, 45468($a0)
			sw $t0, 44448($a0)
			sw $t0, 44960($a0)
			sw $t0, 45472($a0)
			sw $t0, 45984($a0)
			sw $t0, 46496($a0)
			sw $t0, 44968($a0)
			sw $t0, 45480($a0)
			sw $t0, 45992($a0)
			sw $t0, 46508($a0)
			sw $t0, 46512($a0)
			sw $t0, 44460($a0)
			sw $t0, 44464($a0)
			sw $t0, 45488($a0)
			sw $t0, 45492($a0)
			sw $t0, 46004($a0)
		DRAW_GAME_OVER_SKULL:
			li $a3, 0x00ffffff
			lw $t0, 0($sp)
			addi $t0, $t0, 6328
			move $a0, $t0
			addi $t0, $t0, 5788
			move $a1, $t0
			li $a2, 152
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 12456
			move $a0, $t0
			addi $t0, $t0, 696
			move $a1, $t0
			li $a2, 180
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 13556
			move $a0, $t0
			addi $t0, $t0, 4636
			move $a1, $t0
			li $a2, 24
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 18664
			move $a0, $t0
			addi $t0, $t0, 2612
			move $a1, $t0
			li $a2, 48
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 16188
			move $a0, $t0
			addi $t0, $t0, 5156
			move $a1, $t0
			li $a2, 32
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 13620
			move $a0, $t0
			addi $t0, $t0, 2092
			move $a1, $t0
			li $a2, 40
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 13480
			move $a0, $t0
			addi $t0, $t0, 2092
			move $a1, $t0
			li $a2, 40
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 16040
			move $a0, $t0
			addi $t0, $t0, 5156
			move $a1, $t0
			li $a2, 32
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 21672
			move $a0, $t0
			addi $t0, $t0, 1208
			move $a1, $t0
			li $a2, 180
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 23232
			move $a0, $t0
			addi $t0, $t0, 1596
			move $a1, $t0
			li $a2, 56
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 23308
			move $a0, $t0
			addi $t0, $t0, 1600
			move $a1, $t0
			li $a2, 60
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 25292
			move $a0, $t0
			addi $t0, $t0, 1652
			move $a1, $t0
			li $a2, 112
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 29912
			move $a0, $t0
			addi $t0, $t0, 2068
			move $a1, $t0
			li $a2, 16
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 27352
			move $a0, $t0
			addi $t0, $t0, 2140
			move $a1, $t0
			li $a2, 88
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 29984
			move $a0, $t0
			addi $t0, $t0, 2068
			move $a1, $t0
			li $a2, 16
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 29948
			move $a0, $t0
			addi $t0, $t0, 1552
			move $a1, $t0
			li $a2, 12
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 33448
			move $a0, $t0
			addi $t0, $t0, 4616
			move $a1, $t0
			li $a2, 4
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 33456
			move $a0, $t0
			addi $t0, $t0, 528
			move $a1, $t0
			li $a2, 12
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 37552
			move $a0, $t0
			addi $t0, $t0, 528
			move $a1, $t0
			li $a2, 12
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 34496
			move $a0, $t0
			addi $t0, $t0, 2568
			move $a1, $t0
			li $a2, 4
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 33488
			move $a0, $t0
			addi $t0, $t0, 4616
			move $a1, $t0
			li $a2, 4
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 33496
			move $a0, $t0
			addi $t0, $t0, 536
			move $a1, $t0
			li $a2, 20
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 37592
			move $a0, $t0
			addi $t0, $t0, 536
			move $a1, $t0
			li $a2, 20
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 35544
			move $a0, $t0
			addi $t0, $t0, 524
			move $a1, $t0
			li $a2, 8
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 33536
			move $a0, $t0
			addi $t0, $t0, 532
			move $a1, $t0
			li $a2, 16
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 34552
			move $a0, $t0
			addi $t0, $t0, 3592
			move $a1, $t0
			li $a2, 4
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 34580
			move $a0, $t0
			addi $t0, $t0, 3592
			move $a1, $t0
			li $a2, 4
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 35584
			move $a0, $t0
			addi $t0, $t0, 532
			move $a1, $t0
			li $a2, 16
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 33572
			move $a0, $t0
			addi $t0, $t0, 544
			move $a1, $t0
			li $a2, 28
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 34608
			move $a0, $t0
			addi $t0, $t0, 3592
			move $a1, $t0
			li $a2, 4
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 33612
			move $a0, $t0
			addi $t0, $t0, 4616
			move $a1, $t0
			li $a2, 4
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 35668
			move $a0, $t0
			addi $t0, $t0, 524
			move $a1, $t0
			li $a2, 8
			jal FILL
			lw $t0, 0($sp)
			addi $t0, $t0, 33632
			move $a0, $t0
			addi $t0, $t0, 4616
			move $a1, $t0
			li $a2, 4
			jal FILL
		# Little delay
		li $v0, 32
		li $a0, 20
		syscall

		lw 		$a0, 0($sp)	# Pop base address of stack to modify
		addi	$sp, $sp, 4

		lw $t9, 0($sp)		# Retrieve current tick
		addi $sp, $sp, 4

		subi $t9, $t9, 1	# Decrement tick
		
		jal CHECK_RESTART_PRESSED
		bnez $v0, DRAW_GAME_OVER_RETURN

		addi $sp, $sp, -4	# Store current tick
		sw $t9, 0($sp)

		addi $a0, $a0, NEXT_ROW

		# Wait two seconds if JUST appeared.
		beq $t9, 19, GAME_OVER_ANIM_SLOW_WAIT
		bnez $t9, GAME_OVER_ANIM


	li $v0, 32
	li $a0, 2000
	syscall
	addi $sp, $sp, 4	# Free space taken from tick
	DRAW_GAME_OVER_RETURN:
		# Return to sender.
		lw	$ra, 0($sp)
		addi	$sp, $sp, 4
		jr	$ra


#  ___  _               _     __  __                 
# / __|| |_  __ _  _ _ | |_  |  \/  | ___  _ _  _  _ 
# \__ \|  _|/ _` || '_||  _| | |\/| |/ -_)| ' \| || |
# |___/ \__|\__,_||_|   \__| |_|  |_|\___||_||_|\_,_|
DRAW_START_EXIT_WORDS:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	li $a3, 0x00000000
	lw $t0, 0($sp)
	addi $t0, $t0, 44052
	move $a0, $t0
	addi $t0, $t0, 20
	move $a1, $t0
	li $a2, 16
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 46100
	move $a0, $t0
	addi $t0, $t0, 20
	move $a1, $t0
	li $a2, 16
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 44564
	move $a0, $t0
	addi $t0, $t0, 1028
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 45080
	move $a0, $t0
	addi $t0, $t0, 8
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 44076
	move $a0, $t0
	addi $t0, $t0, 516
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 45104
	move $a0, $t0
	addi $t0, $t0, 12
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 45612
	move $a0, $t0
	addi $t0, $t0, 516
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 45628
	move $a0, $t0
	addi $t0, $t0, 516
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 44092
	move $a0, $t0
	addi $t0, $t0, 516
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 44100
	move $a0, $t0
	addi $t0, $t0, 12
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 44616
	move $a0, $t0
	addi $t0, $t0, 1028
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 46148
	move $a0, $t0
	addi $t0, $t0, 12
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 44116
	move $a0, $t0
	addi $t0, $t0, 20
	move $a1, $t0
	li $a2, 16
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 44636
	move $a0, $t0
	addi $t0, $t0, 1540
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 44824
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 44316
	move $a0, $t0
	addi $t0, $t0, 16
	move $a1, $t0
	li $a2, 12
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 45340
	move $a0, $t0
	addi $t0, $t0, 12
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 45864
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 46360
	move $a0, $t0
	addi $t0, $t0, 16
	move $a1, $t0
	li $a2, 12
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 44336
	move $a0, $t0
	addi $t0, $t0, 20
	move $a1, $t0
	li $a2, 16
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 44856
	move $a0, $t0
	addi $t0, $t0, 1540
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 44872
	move $a0, $t0
	addi $t0, $t0, 1540
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 44364
	move $a0, $t0
	addi $t0, $t0, 12
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 44888
	move $a0, $t0
	addi $t0, $t0, 1540
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 45388
	move $a0, $t0
	addi $t0, $t0, 12
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 44384
	move $a0, $t0
	addi $t0, $t0, 2052
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 44388
	move $a0, $t0
	addi $t0, $t0, 16
	move $a1, $t0
	li $a2, 12
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 44916
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 45412
	move $a0, $t0
	addi $t0, $t0, 16
	move $a1, $t0
	li $a2, 12
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 45932
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 46448
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 44412
	move $a0, $t0
	addi $t0, $t0, 20
	move $a1, $t0
	li $a2, 16
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 44932
	move $a0, $t0
	addi $t0, $t0, 1540
	move $a1, $t0
	li $a2, 0
	jal FILL
	
	addi	$sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	
DRAW_START_MENU_PLAYER_EXIT:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	li $a3, PLR_COLOR1
	lw $t0, 0($sp)
	addi $t0, $t0, 48656
	move $a0, $t0
	addi $t0, $t0, 552
	move $a1, $t0
	li $a2, 36
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 49704
	move $a0, $t0
	addi $t0, $t0, 1544
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 51728
	move $a0, $t0
	addi $t0, $t0, 2592
	move $a1, $t0
	li $a2, 28
	jal FILL
	
	li $a3, PLR_COLOR2
	lw $t0, 0($sp)
	addi $t0, $t0, 49688
	move $a0, $t0
	addi $t0, $t0, 520
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 50704
	move $a0, $t0
	addi $t0, $t0, 536
	move $a1, $t0
	li $a2, 20
	jal FILL
	
	li $a3, PLR_EYECOL
	lw $t0, 0($sp)
	addi $t0, $t0, 49680
	move $a0, $t0
	addi $t0, $t0, 520
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 49696
	move $a0, $t0
	addi $t0, $t0, 520
	move $a1, $t0
	li $a2, 4
	jal FILL
	
	addi	$sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	
DRAW_START_MENU_PLAYER_FRAME1:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	li $a3, PLR_COLOR1
	lw $t0, 0($sp)
	addi $t0, $t0, 48436
	move $a0, $t0
	addi $t0, $t0, 552
	move $a1, $t0
	li $a2, 36
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 49468
	move $a0, $t0
	addi $t0, $t0, 1544
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 51516
	move $a0, $t0
	addi $t0, $t0, 2592
	move $a1, $t0
	li $a2, 28
	jal FILL
	
	li $a3, PLR_COLOR2
	lw $t0, 0($sp)
	addi $t0, $t0, 49484
	move $a0, $t0
	addi $t0, $t0, 520
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 50500
	move $a0, $t0
	addi $t0, $t0, 536
	move $a1, $t0
	li $a2, 20
	jal FILL
	
	li $a3, PLR_EYECOL
	lw $t0, 0($sp)
	addi $t0, $t0, 49476
	move $a0, $t0
	addi $t0, $t0, 520
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 49492
	move $a0, $t0
	addi $t0, $t0, 520
	move $a1, $t0
	li $a2, 4
	jal FILL
	
	addi	$sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
DRAW_START_MENU_PLAYER_FRAME2:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	li $a3, PLR_COLOR1
	lw $t0, 0($sp)
	addi $t0, $t0, 44908
	move $a0, $t0
	addi $t0, $t0, 552
	move $a1, $t0
	li $a2, 36
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 45940
	move $a0, $t0
	addi $t0, $t0, 1544
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 47988
	move $a0, $t0
	addi $t0, $t0, 2592
	move $a1, $t0
	li $a2, 28
	jal FILL
	
	li $a3, PLR_COLOR2
	lw $t0, 0($sp)
	addi $t0, $t0, 45956
	move $a0, $t0
	addi $t0, $t0, 520
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 46972
	move $a0, $t0
	addi $t0, $t0, 536
	move $a1, $t0
	li $a2, 20
	jal FILL
	
	li $a3, PLR_EYECOL
	lw $t0, 0($sp)
	addi $t0, $t0, 45948
	move $a0, $t0
	addi $t0, $t0, 520
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 45964
	move $a0, $t0
	addi $t0, $t0, 520
	move $a1, $t0
	li $a2, 4
	jal FILL
	
	addi	$sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra

DRAW_START_MENU_PLAYER_FRAME3:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	li $a3, PLR_COLOR1
	lw $t0, 0($sp)
	addi $t0, $t0, 53156
	move $a0, $t0
	addi $t0, $t0, 2568
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 54168
	move $a0, $t0
	addi $t0, $t0, 524
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 54148
	move $a0, $t0
	addi $t0, $t0, 1556
	move $a1, $t0
	li $a2, 16
	jal FILL
	
	li $a3, PLR_COLOR2
	lw $t0, 0($sp)
	addi $t0, $t0, 55192
	move $a0, $t0
	addi $t0, $t0, 524
	move $a1, $t0
	li $a2, 8
	jal FILL
	
	li $a3, PLR_EYECOL
	lw $t0, 0($sp)
	addi $t0, $t0, 55708
	move $a0, $t0
	addi $t0, $t0, 8
	move $a1, $t0
	li $a2, 4
	jal FILL
	
	addi	$sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	
	
	
DRAW_START_MENU_TITLE:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	li $a3, 0x00fdffce
	lw $t0, 0($sp)
	addi $t0, $t0, 7768
	move $a0, $t0
	addi $t0, $t0, 7180
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 7804
	move $a0, $t0
	addi $t0, $t0, 7180
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 6244
	move $a0, $t0
	addi $t0, $t0, 1048
	move $a1, $t0
	li $a2, 20
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 8804
	move $a0, $t0
	addi $t0, $t0, 1048
	move $a1, $t0
	li $a2, 20
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 6284
	move $a0, $t0
	addi $t0, $t0, 8716
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 6296
	move $a0, $t0
	addi $t0, $t0, 1060
	move $a1, $t0
	li $a2, 32
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 7868
	move $a0, $t0
	addi $t0, $t0, 1032
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 8856
	move $a0, $t0
	addi $t0, $t0, 1060
	move $a1, $t0
	li $a2, 32
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 10408
	move $a0, $t0
	addi $t0, $t0, 1036
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 11956
	move $a0, $t0
	addi $t0, $t0, 1548
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 14016
	move $a0, $t0
	addi $t0, $t0, 1036
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 7888
	move $a0, $t0
	addi $t0, $t0, 5644
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 6364
	move $a0, $t0
	addi $t0, $t0, 1056
	move $a1, $t0
	li $a2, 28
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 7928
	move $a0, $t0
	addi $t0, $t0, 1032
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 14044
	move $a0, $t0
	addi $t0, $t0, 1056
	move $a1, $t0
	li $a2, 28
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 13048
	move $a0, $t0
	addi $t0, $t0, 520
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 7944
	move $a0, $t0
	addi $t0, $t0, 7180
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 6420
	move $a0, $t0
	addi $t0, $t0, 1048
	move $a1, $t0
	li $a2, 20
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 7980
	move $a0, $t0
	addi $t0, $t0, 7180
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 6516
	move $a0, $t0
	addi $t0, $t0, 1076
	move $a1, $t0
	li $a2, 48
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 14196
	move $a0, $t0
	addi $t0, $t0, 1076
	move $a1, $t0
	li $a2, 48
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 8052
	move $a0, $t0
	addi $t0, $t0, 5644
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 9088
	move $a0, $t0
	addi $t0, $t0, 1040
	move $a1, $t0
	li $a2, 12
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 8980
	move $a0, $t0
	addi $t0, $t0, 1048
	move $a1, $t0
	li $a2, 20
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 6460
	move $a0, $t0
	addi $t0, $t0, 8716
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 7496
	move $a0, $t0
	addi $t0, $t0, 520
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 8528
	move $a0, $t0
	addi $t0, $t0, 1036
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 10076
	move $a0, $t0
	addi $t0, $t0, 520
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 6500
	move $a0, $t0
	addi $t0, $t0, 8716
	move $a1, $t0
	li $a2, 8
	jal FILL
	
	li $a3, 0x00ffffff
	lw $t0, 0($sp)
	addi $t0, $t0, 17568
	move $a0, $t0
	addi $t0, $t0, 4104
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 16552
	move $a0, $t0
	addi $t0, $t0, 528
	move $a1, $t0
	li $a2, 12
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17592
	move $a0, $t0
	addi $t0, $t0, 4100
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 18088
	move $a0, $t0
	addi $t0, $t0, 528
	move $a1, $t0
	li $a2, 12
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17600
	move $a0, $t0
	addi $t0, $t0, 520
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 18120
	move $a0, $t0
	addi $t0, $t0, 528
	move $a1, $t0
	li $a2, 12
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 19160
	move $a0, $t0
	addi $t0, $t0, 1540
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 21184
	move $a0, $t0
	addi $t0, $t0, 536
	move $a1, $t0
	li $a2, 20
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 16584
	move $a0, $t0
	addi $t0, $t0, 532
	move $a1, $t0
	li $a2, 16
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17636
	move $a0, $t0
	addi $t0, $t0, 3080
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 21228
	move $a0, $t0
	addi $t0, $t0, 532
	move $a1, $t0
	li $a2, 16
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 20732
	move $a0, $t0
	addi $t0, $t0, 8
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 16620
	move $a0, $t0
	addi $t0, $t0, 532
	move $a1, $t0
	li $a2, 16
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17660
	move $a0, $t0
	addi $t0, $t0, 520
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 16648
	move $a0, $t0
	addi $t0, $t0, 5128
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 16656
	move $a0, $t0
	addi $t0, $t0, 532
	move $a1, $t0
	li $a2, 16
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 18192
	move $a0, $t0
	addi $t0, $t0, 520
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 21264
	move $a0, $t0
	addi $t0, $t0, 532
	move $a1, $t0
	li $a2, 16
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 16680
	move $a0, $t0
	addi $t0, $t0, 5128
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17200
	move $a0, $t0
	addi $t0, $t0, 516
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 18228
	move $a0, $t0
	addi $t0, $t0, 8
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 18748
	move $a0, $t0
	addi $t0, $t0, 516
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 16704
	move $a0, $t0
	addi $t0, $t0, 5128
	move $a1, $t0
	li $a2, 4
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 16716
	move $a0, $t0
	addi $t0, $t0, 544
	move $a1, $t0
	li $a2, 28
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 17752
	move $a0, $t0
	addi $t0, $t0, 4104
	move $a1, $t0
	li $a2, 4
	jal FILL
	
	addi	$sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	                                                                                   
DRAW_START_MENU:
	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)

	addi $sp, $sp, -4
	sw $a0, 0($sp)

	li $a3, 0x0085dbe8
	lw $t0, 0($sp)
	addi $t0, $t0, 25088
	move $a0, $t0
	addi $t0, $t0, 11876
	move $a1, $t0
	li $a2, 96
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 37376
	move $a0, $t0
	addi $t0, $t0, 14848
	move $a1, $t0
	li $a2, 508
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 33612
	move $a0, $t0
	addi $t0, $t0, 3764
	move $a1, $t0
	li $a2, 176
	jal FILL
	
	li $a3, 0x001b574b
	lw $t0, 0($sp)
	addi $t0, $t0, 58880
	move $a0, $t0
	addi $t0, $t0, 6656
	move $a1, $t0
	li $a2, 508
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 55956
	move $a0, $t0
	addi $t0, $t0, 2608
	move $a1, $t0
	li $a2, 44
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 57540
	move $a0, $t0
	addi $t0, $t0, 1148
	move $a1, $t0
	li $a2, 120
	jal FILL
	
	li $a3, 0x005ab375
	lw $t0, 0($sp)
	addi $t0, $t0, 53252
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 52224
	move $a0, $t0
	addi $t0, $t0, 6292
	move $a1, $t0
	li $a2, 144
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 52372
	move $a0, $t0
	addi $t0, $t0, 3268
	move $a1, $t0
	li $a2, 192
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 56004
	move $a0, $t0
	addi $t0, $t0, 1148
	move $a1, $t0
	li $a2, 120
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 57152
	move $a0, $t0
	addi $t0, $t0, 1728
	move $a1, $t0
	li $a2, 188
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 52692
	move $a0, $t0
	addi $t0, $t0, 3116
	move $a1, $t0
	li $a2, 40
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 52568
	move $a0, $t0
	addi $t0, $t0, 1148
	move $a1, $t0
	li $a2, 120
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 54104
	move $a0, $t0
	addi $t0, $t0, 532
	move $a1, $t0
	li $a2, 16
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 54216
	move $a0, $t0
	addi $t0, $t0, 524
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 56284
	move $a0, $t0
	addi $t0, $t0, 548
	move $a1, $t0
	li $a2, 32
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 56128
	move $a0, $t0
	addi $t0, $t0, 548
	move $a1, $t0
	li $a2, 32
	jal FILL
	
	li $a3, 0x004f4f4f
	lw $t0, 0($sp)
	addi $t0, $t0, 56164
	move $a0, $t0
	addi $t0, $t0, 632
	move $a1, $t0
	li $a2, 116
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 55240
	move $a0, $t0
	addi $t0, $t0, 524
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 55128
	move $a0, $t0
	addi $t0, $t0, 536
	move $a1, $t0
	li $a2, 20
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 54124
	move $a0, $t0
	addi $t0, $t0, 92
	move $a1, $t0
	li $a2, 88
	jal FILL
	
	li $a3, 0x00353535
	lw $t0, 0($sp)
	addi $t0, $t0, 54636
	move $a0, $t0
	addi $t0, $t0, 92
	move $a1, $t0
	li $a2, 88
	jal FILL
	
	li $a3, 0x00202020
	lw $t0, 0($sp)
	addi $t0, $t0, 55152
	move $a0, $t0
	addi $t0, $t0, 600
	move $a1, $t0
	li $a2, 84
	jal FILL
	
	addi	$sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	

	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)

	addi $sp, $sp, -4
	sw $a0, 0($sp)

	li $a3, 0x0085dbe8
	lw $t0, 0($sp)
	addi $t0, $t0, 25088
	move $a0, $t0
	addi $t0, $t0, 11876
	move $a1, $t0
	li $a2, 96
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 37376
	move $a0, $t0
	addi $t0, $t0, 14848
	move $a1, $t0
	li $a2, 508
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 33612
	move $a0, $t0
	addi $t0, $t0, 3764
	move $a1, $t0
	li $a2, 176
	jal FILL
	
	li $a3, 0x001b574b
	lw $t0, 0($sp)
	addi $t0, $t0, 58880
	move $a0, $t0
	addi $t0, $t0, 6656
	move $a1, $t0
	li $a2, 508
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 55956
	move $a0, $t0
	addi $t0, $t0, 2608
	move $a1, $t0
	li $a2, 44
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 57540
	move $a0, $t0
	addi $t0, $t0, 1148
	move $a1, $t0
	li $a2, 120
	jal FILL
	
	li $a3, 0x005ab375
	lw $t0, 0($sp)
	addi $t0, $t0, 53252
	move $a0, $t0
	addi $t0, $t0, 4
	move $a1, $t0
	li $a2, 0
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 52224
	move $a0, $t0
	addi $t0, $t0, 6292
	move $a1, $t0
	li $a2, 144
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 52372
	move $a0, $t0
	addi $t0, $t0, 3268
	move $a1, $t0
	li $a2, 192
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 56004
	move $a0, $t0
	addi $t0, $t0, 1148
	move $a1, $t0
	li $a2, 120
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 57152
	move $a0, $t0
	addi $t0, $t0, 1728
	move $a1, $t0
	li $a2, 188
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 52692
	move $a0, $t0
	addi $t0, $t0, 3116
	move $a1, $t0
	li $a2, 40
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 52568
	move $a0, $t0
	addi $t0, $t0, 1148
	move $a1, $t0
	li $a2, 120
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 54104
	move $a0, $t0
	addi $t0, $t0, 532
	move $a1, $t0
	li $a2, 16
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 54216
	move $a0, $t0
	addi $t0, $t0, 524
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 56284
	move $a0, $t0
	addi $t0, $t0, 548
	move $a1, $t0
	li $a2, 32
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 56128
	move $a0, $t0
	addi $t0, $t0, 548
	move $a1, $t0
	li $a2, 32
	jal FILL
	
	li $a3, 0x004f4f4f
	lw $t0, 0($sp)
	addi $t0, $t0, 56164
	move $a0, $t0
	addi $t0, $t0, 632
	move $a1, $t0
	li $a2, 116
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 55240
	move $a0, $t0
	addi $t0, $t0, 524
	move $a1, $t0
	li $a2, 8
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 55128
	move $a0, $t0
	addi $t0, $t0, 536
	move $a1, $t0
	li $a2, 20
	jal FILL
	lw $t0, 0($sp)
	addi $t0, $t0, 54124
	move $a0, $t0
	addi $t0, $t0, 92
	move $a1, $t0
	li $a2, 88
	jal FILL
	
	li $a3, 0x00353535
	lw $t0, 0($sp)
	addi $t0, $t0, 54636
	move $a0, $t0
	addi $t0, $t0, 92
	move $a1, $t0
	li $a2, 88
	jal FILL
	
	li $a3, 0x00202020
	lw $t0, 0($sp)
	addi $t0, $t0, 55152
	move $a0, $t0
	addi $t0, $t0, 600
	move $a1, $t0
	li $a2, 84
	jal FILL
	
	addi	$sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	
