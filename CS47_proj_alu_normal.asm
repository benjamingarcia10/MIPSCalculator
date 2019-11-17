.include "./cs47_proj_macro.asm"
.text
.globl au_normal
# TBD: Complete your project procedures
# Needed skeleton is given
#####################################################################
# Implement au_normal
# Argument:
# 	$a0: First number
#	$a1: Second number
#	$a2: operation code ('+':add, '-':sub, '*':mul, '/':div)
# Return:
#	$v0: ($a0+$a1) | ($a0-$a1) | ($a0*$a1):LO | ($a0 / $a1)
# 	$v1: ($a0 * $a1):HI | ($a0 % $a1)
# Notes:
#####################################################################
au_normal:
	beq $a2, '+', add_op
	beq $a2, '-', sub_op
	beq $a2, '*', mul_op
	beq $a2, '/', div_op
	
add_op:
	stack_save		# call stack_save macro
	add $v0, $a0, $a1
	stack_restore		# call stack_restore macro
	
sub_op:
	stack_save		# call stack_save macro
	sub $v0, $a0, $a1
	stack_restore		# call stack_restore macro
	
mul_op:
	stack_save		# call stack_save macro
	mult $a0, $a1
	mflo $v0
	mfhi $v1
	stack_restore		# call stack_restore macro
	
div_op:
	stack_save		# call stack_save macro
	div $a0, $a1
	mflo $v0
	mfhi $v1
	stack_restore		# call stack_restore macro