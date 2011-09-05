	.imem 65536 32 
	.dmem 16384 
	.regfile 256 8 

	.define author "(c)2011 Scott McCain"
	.define url "http://www.thegadgetfool.com"
	
	.register r0 prev
	.register r1 next
	.register r2 value
	.register r3 count
	.register r4 total
	.register r5 increment
	.register r9 temp
	.register r10 pmem

start:
	MOV pmem, 0
	MOV count, 24 
	MOV value, 1
	MOV prev, -1
	MOV increment, 1
	MOV temp, 0
LOOP:
	ADD value, prev, total
	ADD value, temp, prev
	ADD total, temp, value
	STM pmem, value
	ADD pmem, increment, pmem
	SUB count, increment, count
	BRANZ count, LOOP

