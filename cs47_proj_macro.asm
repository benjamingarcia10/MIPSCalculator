# Add you macro definition here - do not touch cs47_common_macro.asm"
#<------------------ MACRO DEFINITIONS ---------------------->#
.macro stack_save		# macro to save the stack (all saved variables in the frame)
	addi	$sp, $sp, -60
	sw	$fp, 60($sp)
	sw	$ra, 56($sp)
	sw	$a0, 52($sp)
	sw	$a1, 48($sp)
	sw	$a2, 44($sp)
	sw	$a3, 40($sp)
	sw	$s0, 36($sp)
	sw	$s1, 32($sp)
	sw	$s2, 28($sp)
	sw	$s3, 24($sp)
	sw	$s4, 20($sp)
	sw	$s5, 16($sp)
	sw	$s6, 12($sp)
	sw	$s7, 8($sp)
	addi	$fp, $sp, 60
.end_macro

.macro stack_restore		# macro to restore the stack (all saved variables in the frame) and jump return to return address
	lw	$fp, 60($sp)
	lw	$ra, 56($sp)
	lw	$a0, 52($sp)
	lw	$a1, 48($sp)
	lw	$a2, 44($sp)
	lw	$a3, 40($sp)
	lw	$s0, 36($sp)
	lw	$s1, 32($sp)
	lw	$s2, 28($sp)
	lw	$s3, 24($sp)
	lw	$s4, 20($sp)
	lw	$s5, 16($sp)
	lw	$s6, 12($sp)
	lw	$s7, 8($sp)
	addi	$sp, $sp, 60
	jr	$ra
.end_macro

.macro extract_nth_bit($regD, $regS, $regT)
	# $regD : will contain 0x0 or 0x1 depending on nth bit being 0 or 1
	# $regS: Source bit pattern
	# $regT: Bit position n (0-31)
	
	la $t0, ($regS)		# load bit pattern stored in $regS into $t0
	srav $t0, $t0, $regT	# right shift $t0 by value in $regT (bit position n)
	andi $regD, $t0, 1	# set $regD to result of AND function of $t0 and 1
.end_macro

.macro insert_to_nth_bit($regD, $regS, $regT, $maskReg)
	# $regD : This the bit pattern in which 1 to be inserted at nth position
	# $regS: Value n, from which position the bit to be inserted (0-31)
	# $regT: Register that contains 0x1 or 0x0 (bit value to insert)
	# $maskReg: Register to hold temporary mask
	
	li $maskReg, 1				# initialize mask at value 1 into $maskReg
	sllv $maskReg, $maskReg, $regS		# left shift $maskReg by value in $regS (value n, position to insert) and store in $maskReg
	not $maskReg, $maskReg			# invert mask and store back in $maskReg
	and $regD, $regD, $maskReg		# set $maskReg to result of AND function of $regD (bit pattern) and the mask (forces 0 into insertion position)
	sllv $regT, $regT, $regS			# set $regT to left shift on $regT of value in $regS
	or $regD, $regD, $regT			# set $regD to result of OR function of $regD and $regT
.end_macro
