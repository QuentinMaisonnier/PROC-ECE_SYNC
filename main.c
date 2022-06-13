//#include <stdint.h>

#define uint32_t unsigned int

// adresses in data memory
#define AD_TOPleds    *((volatile uint32_t *)0x8000000c)
#define AD_DISPLAY1 *((volatile uint32_t *)0x80000004)   // MSB=Hex3, Hex2, Hex1, LSB=Hex0 (Hex described in DE10LITE User manual)
#define AD_DISPLAY2 *((volatile uint32_t *)0x80000008)   // MSB=X, X, Hex5, LSB=Hex4
//#define MASTER_CLK_RATE 50 * 1000000
//#define PLL_DIV  50
//#define CLK_RATE    MASTER_CLK_RATE/PLL_DIV
//#define MS_TICK    CLK_RATE/1000
//#define DISPLAY_NB 6

int getCode7Seg(int c)
{
	volatile int hexVal = 0;
    switch(c)
    {
        case 0 : hexVal = 192; break;
        case 1 : hexVal = 0xf9; break;
        case 2 : hexVal = 0xa4; break;
        case 3 : hexVal = 0xb0; break;
        case 4 : hexVal = 0x99; break;
        case 5 : hexVal = 0x92; break;
        case 6 : hexVal = 0x82; break;
        case 7 : hexVal = 0xf8; break;
        case 8 : hexVal = 0x80; break;
        case 9 : hexVal = 0x90; break;
        case 10 : hexVal = 0x88; break;
        case 11 : hexVal = 0x83; break;
        case 12 : hexVal = 0xc6; break;
        case 13 : hexVal = 0xa1; break;
        case 14 : hexVal = 0x86; break;
        case 15 : hexVal = 0x8e; break;
        
        default  : hexVal = 0x7f; break;
	}
    return hexVal;
}

int getCode7SegAlpha(int c)
{
	volatile uint32_t hexVal = 0;
    switch(c)
    {
        case '0' : hexVal = 0xc0; break;
        case '1' : hexVal = 0xf9; break;
        case '2' : hexVal = 0xa4; break;
        case '3' : hexVal = 0xb0; break;
        case '4' : hexVal = 0x99; break;
        case '5' : hexVal = 0x92; break;
        case '6' : hexVal = 0x82; break;
        case '7' : hexVal = 0xf8; break;
        case '8' : hexVal = 0x80; break;
        case '9' : hexVal = 0x90; break;
        case 'A' : hexVal = 0x88; break;
        case 'B' : hexVal = 0x83; break;
        case 'C' : hexVal = 0xc6; break;
        case 'D' : hexVal = 0xa1; break;
        case 'E' : hexVal = 0x86; break;
        case 'F' : hexVal = 0x8e; break;
        case 'G' : hexVal = 0xc2; break;
        case 'H' : hexVal = 0x8b; break;
        case 'I' : hexVal = 0xfb; break;
        case 'J' : hexVal = 0xe1; break;
        case 'K' : hexVal = 0x8a; break;
        case 'L' : hexVal = 0xc7; break;
        case 'M' : hexVal = 0xaa; break;
        case 'N' : hexVal = 0xab; break;
        case 'O' : hexVal = 0xc0; break;
        case 'P' : hexVal = 0x8c; break;
        case 'Q' : hexVal = 0x98; break;
        case 'R' : hexVal = 0xce; break;
        case 'S' : hexVal = 0x92; break;
        case 'T' : hexVal = 0x87; break;
        case 'U' : hexVal = 0xc1; break;
        case 'V' : hexVal = 0xb5; break;
        case 'W' : hexVal = 0x95; break;
        case 'X' : hexVal = 0x89; break;
        case 'Y' : hexVal = 0x91; break;
        case 'Z' : hexVal = 0xa4; break;
        case ' ' : hexVal = 0xff; break;
        case '.' : hexVal = 0x7f; break;
        case '-' : hexVal = 0xbf; break;
        case '_' : hexVal = 0xf7; break;
        default  : hexVal = 0x7f; break;
	}
    return hexVal;
}

void main(void){
	volatile uint32_t ledstate = 0;
	volatile int test=0;
	//char const * str = "PROCES";
	volatile uint32_t cycleblink = 20000;
    //volatile uint32_t len = 6;
	
	volatile int hexVal1=0xc6;
	volatile int hexVal2=0xc0;
	volatile int hexVal3=0xc1;
	volatile int hexVal4=0xc6;
	volatile int hexVal5=0xc0;
	volatile int hexVal6=0xc1;
	// int mask = 15; // 0000 1111
	// int displayBuffer=0;
	
	// int cyclBlkChar1 = ((cycleblink >> 12) & mask);
	// int cyclBlkChar2 = ((cycleblink >> 8) & mask);
	// int cyclBlkChar3 = ((cycleblink >> 4) & mask);
	// int cyclBlkChar4 = ( cycleblink & mask );
	
	// int segBlk4 = getCode7Seg(cyclBlkChar4);
	AD_DISPLAY2 = (hexVal1 << 8);
	AD_DISPLAY2 |= hexVal2;
	
	AD_DISPLAY1  = (hexVal3 << 24);
	AD_DISPLAY1 |= (hexVal4 << 16);
	AD_DISPLAY1 |= (hexVal5 << 8);
	AD_DISPLAY1 |= hexVal6;
	
	// *AD_DISPLAY1  = (segBlk1 << 24);
	// *AD_DISPLAY1 |= (segBlk2 << 16);
	// *AD_DISPLAY1 |= (segBlk3 << 8);
	// *AD_DISPLAY1 |= segBlk4;

	//*AD_DISPLAY1 = 2256963206;
	
	
	//AD_DISPLAY2 = 0xffff;
	//*led=0;
	
	for(int i=0; i<100; i++){
		test=0;
		for(int j=0; j<cycleblink; j++){
			if(test==j){
				test++;
			}
		}
		
		if(ledstate==0){
				//AD_DISPLAY1 = 4294951083;
				AD_TOPleds = 0x00000001;
				//*led=1;
				ledstate=1;
			}else{
				//AD_DISPLAY1 = 4290809486;
				AD_TOPleds = 0x00000000;
				//*led=0;
				ledstate=0;
		}
		
		
	}
	while(1)
	{}
}