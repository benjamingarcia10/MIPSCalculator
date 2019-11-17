.include "./cs47_proj_macro.asm"
.text
.globl au_logical
# TBD: Complete your project procedures
# Needed skeleton is given
#####################################################################
# Implement au_logical
# Argument:
# 	$a0: First number
#	$a1: Second number
#	$a2: operation code ('+':add, '-':sub, '*':mul, '/':div)
# Return:
#	$v0: ($a0+$a1) | ($a0-$a1) | ($a0*$a1):LO | ($a0 / $a1)
# 	$v1: ($a0 * $a1):HI | ($a0 % $a1)
# Notes:
#####################################################################
au_logical:
	beq $a2, '+', add_logical
	beq $a2, '-', sub_logical
	beq $a2, '*', mul_logical
	beq $a2, '/', div_logical

#------------------------START OF ADDITION LOGICAL PROCEDURE----------------------#
# returns $v0 = final sum and $v1 = carry out bit for completed procedure

# $s0 = index counter
# $v1 = carry in bit for upcoming addition (initalized to 0 for addition, 1 for subtraction)
# $s1 = constant (32) to compare against counter
# $s2 = nth bit from first argument
# $s3 = nth bit from second argument
# $s4 = result of A XOR B (bits for partial sum)
# $s5 = result of CI XOR A XOR B (result of partial addition)
# $s6 = A.B
# $s7 = CI.(A XOR B)
# $t9 = temporary register to use for mask
add_logical:
	stack_save				# call stack_save macro
	li $s0, 0				# initialize counter to 0
	li $v1, 0				# initialize carry in bit to 0
	li $v0, 0				# initialize final sum to 0
	jal full_adder_loop
	stack_restore				# call stack_restore macro
	
full_adder_loop:
	li $s1, 32				# max bit, to compare against counter
	beq $s0, $s1, exit_add_loop		# if $s0(counter) = $s1(32), jump to exit loop label
	extract_nth_bit($s2, $a0, $s0)		# get nth bit from first argument for partial calculation
	extract_nth_bit($s3, $a1, $s0)		# get nth bit from second argument for partial calculation
	xor $s4, $s2, $s3				# set $s4 to XOR of both bits that are being added
	xor $s5, $v1, $s4			# set $s5 to XOR of CI XOR A XOR B to get result of partial addition
	and $s6, $s2, $s3				# set $s6 to AND of A.B
	and $s7, $v1, $s4			# set $s7 to AND of CI.(A XOR B)
	or $v1, $s7, $s6			# set carry in to carry out of partial addition (OR Function of CI.(A XOR B) + A.B)
	insert_to_nth_bit($v0, $s0, $s5, $t9)	# insert result of partial addition (1 or 0) into $v0 (register holding final sum) at the index where the counter is
	addi $s0, $s0, 1			# increase counter by 1
	j full_adder_loop

exit_add_loop:
	jr $ra

#------------------------START OF SUBTRACTION LOGICAL PROCEDURE----------------------#
sub_logical:
	stack_save				# call stack_save macro
	la $s0, ($a0)				# load first argument into $s0 register
	la $a0, ($a1)				# load second argument into $a0 register to be 2's complemented
	jal twos_complement			# call two's complement on second argument
	la $a0, ($s0)				# load first argument back into $a0 register
	la $a1, ($v0)				# load new 2's complemented version of second argument into second argument for add_logical
	jal add_logical				# use add logical to add A + (-B)
	stack_restore				# call stack_restore macro
	
#--------------------START OF MULTIPLICATION LOGICAL PROCEDURE--------------------#
mul_logical:
# returns signed $v0 = lo and signed $v1 = hi

# $a0 = multiplicand MCND -> twos complement of multiplicand MCND
# $a1 = multiplier MPLR -> twos complement of multiplier MPLR
	stack_save				# call stack_save macro
	jal twos_complement_if_neg
	la $s0, ($v0)				# set $s0 to two's complement of $a0
	la $a0, ($a1)				# set $a0 to original $a1 for next two's complement procedure
	jal twos_complement_if_neg
	la $a0, ($s0)				# set $a0 to two's complement of original $a0
	la $a1, ($v0)				# set $a1 to two's complement of original $a1
mul_unsigned:
# unsigned multiplication of $a0 (MCND), $a1 (MPLR)
# $s0 = counter
# $s1 = unsigned lo
# $s2 = unsigned hi
# $s3 = MCND (save of $a0) to compare against
# $s4 = AND of MCND.1stBitOfMPLR
# $s5 = LSB of hi
# $s6 = CONSTANT (switches between 31 for bit insertion and 32 for comparison between counter)
# $t6 = XOR between $t7 and $t8 to determine sign of final value
# $t7 = MSB from original multiplicand MCND
# $t8 = MSB from original multiplier MPLR
# $t9 = temporary register to use for mask
	li $s0, 0				# initialize counter to 0
	la $s1, ($a1)				# initialize lo to $a1 (MPLR)
	li $s2, 0				# initialize hi at 0
	la $s3, ($a0)				# save MCND
extract_beginning_mplr:
	extract_nth_bit($a0, $s1, $zero)
	jal bit_replicator
	and $s4, $s3, $v0			# set $s4 to AND of MCND.1stBitOfMPLR
	la $a0, ($s2)				# set hi as first operand for addition
	la $a1, ($s4)				# set result of AND to second operand of addition
	jal add_logical
	la $s2, ($v0)				# set new hi as result of addition
	srl $s1, $s1, 1				# right shift MPLR by 1
	extract_nth_bit($s5, $s2, $zero)	# set $s5 to LSB of hi
	li $s6, 31				# set $s6 to 31 for bit insertion to lo
	insert_to_nth_bit($s1, $s6, $s5, $t9)	# set MSB of lo to LSB of hi
	srl $s2, $s2, 1				# right shift hi by 1
	addi $s0, $s0, 1			# increase counter by 1
	li $s6, 32				# set $s6 to 32 to compare to counter
	beq $s0, $s6, exit_mult
	j extract_beginning_mplr
exit_mult:
	la $v0, ($s1)				# sets $v0 to 32 bit lo
	la $v1, ($s2)				# sets $v1 to 32 bit hi
	lw $a0, 52($sp)
	lw $a1, 48($sp)
	li $s6, 31				# set $t9 to 31 for bit extraction
	extract_nth_bit($t7, $a0, $s6)		# get MSB from original multiplicand MCND
	extract_nth_bit($t8, $a1, $s6)		# get MSB from original multiplier MPLR
	xor $t6, $t7, $t8			# if result is 0, result is positive; if 1, result must be negative
	beqz $t6, return_mult
	la $a0, ($v0)				# load 32 bit lo result into $a0 to be two's complemented
	la $a1, ($v1)				# load 32 bit hi result into $a1 to be two's complemented
	jal twos_complement_64bit		# if result is 1, get two's complement of the 64 bit result
return_mult:
	stack_restore				# call stack_restore macro
	
#----------------------START OF DIVISION LOGICAL PROCEDURE------------------------#
div_logical:
# unsigned division of $a0 (dividend), $a1 (divisor)
# returns $v0 = quotient and $v1 = remainder
	stack_save		# call stack_save macro
	jal twos_complement_if_neg
	la $s0, ($v0)				# set $s0 to two's complement of $a0
	la $a0, ($a1)				# set $a0 to original $a1 for twos complement procedure
	jal twos_complement_if_neg
	la $a0, ($s0)				# set $a0 to two's complement of original $a0
	la $a1, ($v0)				# set $a1 to two's complement of original $a1
div_unsigned:
# $s0 = counter
# $s1 = quotient
# $s2 = divisor
# $s3 = remainder
# $s4 = constant (31 for bit extraction/32 for checking on counter)
# $s5 = MSB of quotient for insertion into LSB or remainder
# $s6 = 1 to be inserted into LSB of quotient if S < 0
# $t6 = XOR between $t7 and $t8 to determine sign of final value
# $t7 = MSB from original dividend
# $t8 = MSB from original divisor
# $t9 = temporary register to use for mask
	li $s0, 0				# initialize counter to 0
	la $s1, ($a0)				# initialize quotient to $a0 (dividend)
	la $s2, ($a1)				# save divisor
	li $s3, 0				# initialize remainder to 0
div_loop:
	li $s4, 31				# set $s4 to 31 for bit extraction
	sll $s3, $s3, 1				# left shift remainder by  1
	extract_nth_bit($s5, $s1, $s4)		# extract MSB of quotient for insertion into LSB of remainder
	insert_to_nth_bit($s3, $zero, $s5, $t9)	# insert extracted bit into LSB of remainder
	sll $s1, $s1, 1				# left shift quotient by 1
	la $a0, ($s3)				# set $a0 to remainder (1st operand in subtraction)
	la $a1, ($s2)				# set $a1 to divisor (2nd operand in subtraction)
	jal sub_logical				# $v0 will contain result of subtraction (contains S from S = R - D)
	bltz $v0, counter_increment		# if sign is negative (divisor greater than remainder) then increase counter
	la $s3, ($v0)				# set remainder = result of subtraction
	li $s6, 1				# set $s6 = 1 to be inserted into LSB of quotient
	insert_to_nth_bit($s1, $zero, $s6, $t9)	# insert 1 bit into LSB of quotient
counter_increment:
	addi $s0, $s0, 1			# increase counter by 1
	li $s4, 32
	beq $s0, $s4, div_exit
	j div_loop
div_exit:
	la $v0, ($s1)				# set $v0 = quotient
	la $v1, ($s3)				# set $v1 = remainder
	lw $a0, 52($sp)				# get original dividend
	lw $a1, 48($sp)				# get original divisor
	li $s4, 31				# set $s4 to 31 for bit extraction
	extract_nth_bit($t7, $a0, $t9)		# get MSB from original dividend
	extract_nth_bit($t8, $a1, $t9)		# get MSB from original divisor
	xor $t6, $t7, $t8			# if result is 0, quotient is positive; if 1, quotient must be negative
	beqz $t6, remainder_check		# if result is 0 then don't complement quotient, check if remainder needs to be complemented
	la $a0, ($s1)				# load quotient into $a0 for two's complement
	jal twos_complement
	la $s1, ($v0)				# set quotient to new 2's complemented version of quotient
remainder_check:
	beqz $t7, skip_second			# if dividend is positive, skip the second two's complement
	la $a0, ($s3)				# load remainder into $a0 for two's complement
	jal twos_complement
	la $s3, ($v0)				# set remainder to new 2's complemented version of remainder
skip_second:
	la $v0, ($s1)				# set $v0 = quotient
	la $v1, ($s3)				# set $v1 = remainder
	stack_restore				# call stack_restore macro



#------------------------------START OF UTILITY PROCEDURES------------------------#
# twos_complement_if_neg - returns complement if negative (twos_complement is helper function) -> returned in $v0
# twos_complement_64bit - returns complement of 64bit number stored by $a0 (lo), $a1 (hi) -> returns lo in $v0 and hi in $v1
# bit_replicator - replicate bit in $a0 to make 32 bits -> returns 0xFFFFFFFF or 0x00000000 in $v0)
twos_complement_if_neg:
	stack_save				# call stack_save macro
	bltz $a0, twos_complement_no_resave
	la $v0, ($a0)
	stack_restore				# call stack_restore macro
twos_complement:
	stack_save				# call stack_save macro
twos_complement_no_resave:
	not $a0, $a0				# set $a0 to inverse
	li $a1, 1				# set $a1 to 1
	jal add_logical				# add $a0 and $a1 using logical add procedure
	stack_restore				# call stack_restore macro

twos_complement_64bit:
	stack_save				# call stack_save macro
	not $a0, $a0				# invert $a0 (lo), first operand of addition for new lo
	not $a1, $a1				# invert $a1 (hi)
	la $a3, ($a1)				# set $a3 to inverted $a1
	li $a1, 1				# set $a1 to 1, second operand of addition for new lo
	jal add_logical				# add inverted lo with 1
	la $s0, ($v0)				# set $s0 to final sum of inverted lo + 1 (new lo that will be returned in $v0)
	la $a0, ($v1)				# set $a0 to carry out bit of last partial addition (first operand of addition for new hi)
	la $a1, ($a3)				# set $a1 to inverted hi (second operand of addition for new hi)
	jal add_logical				# add inverted hi with carry out bit of inverted lo + 1
	la $v1, ($v0)				# hi
	la $v0, ($s0)				# lo
	stack_restore				# call stack_restore macro

bit_replicator:
	stack_save
	beqz $a0, replicate_zero
	li $v0, 0xFFFFFFFF
	stack_restore
replicate_zero:
	li $v0, 0x00000000
	stack_restore