/* system defines for our cpu
 *
 *
 */

 /* default system paremeters */
#define DEF_IMEM			4096			 // max number of instructions
#define DEF_IMEM_WIDTH			18
#define DEF_REGFILE			16	
#define DEF_OPCODE_WIDTH		5
#define DEF_REG_ADDR_WIDTH		4
#define DEF_IBASE			0
#define DEF_DMEM			256  // data memory size in bytes
#define DEF_DBASE			0

/* mnemonic opcode values */
#define xMOV			0x00
#define xADD 			0x06
#define xADC			0x07
#define xSUB			0x08
#define xSBB			0x09
#define xAND			0x0a
#define xOR			0x0b
#define xXOR			0x0c
#define xSHL			0x0d
#define xSHR			0x0e
#define xJMP			0x12
#define xJSB			0x13
#define xBRANZ			0x10
#define xBRAB			0x11
#define xHALT			0x1f
#define xLDM			0x01
#define xSTM      		0x03
#define xRET			0x18
