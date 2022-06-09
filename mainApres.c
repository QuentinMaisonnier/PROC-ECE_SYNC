//#include <stdint.h>

#define uint32_t unsigned int

// adresses in data memory
//#define AD_CPT32    *((volatile uint32_t *)0x80000000)
//#define AD_DISPLAY1 *((volatile uint32_t *)0x80000004)   // MSB=Hex3, Hex2, Hex1, LSB=Hex0 (Hex described in DE10LITE User manual)
//#define AD_DISPLAY2 *((volatile uint32_t *)0x80000008)   // MSB=X, X, Hex5, LSB=Hex4
//#define MASTER_CLK_RATE 50 * 1000000
//#define PLL_DIV  50
//#define CLK_RATE    MASTER_CLK_RATE/PLL_DIV
//#define MS_TICK    CLK_RATE/1000
//#define DISPLAY_NB 6

void main(void){
    //uint8_t hexVal[] = {0x8c,0xce,0xc0,0xc6,0xbf,0x86,0xc6,0x86};
	volatile uint32_t ledstate = 0;
	volatile int test=0;
	volatile uint32_t *led = (uint32_t *)0x80000000;
	
	for(int i=0; i<50; i++){
		test=0;
		for(int j=0; j<200000; j++){
			if(test==j){
				test++;
			}
		}
		
		if(ledstate==0){
				*led=1;
				ledstate=1;
			}else{
				*led=0;
				ledstate=0;
		}
	}
}