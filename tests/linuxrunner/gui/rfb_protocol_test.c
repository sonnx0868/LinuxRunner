#include "app/LinuxRunner/RFBProtocol.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <limits.h>
int main(void){
    uint8_t wheel[LR_RFB_WHEEL_BYTES+16];memset(wheel,0xa5,sizeof wheel);
    assert(lr_rfb_wheel_packets(wheel,sizeof wheel,0x1234,0x5678,1,-1,1)==24);
    const uint8_t expected_wheel[]={5,9,0x12,0x34,0x56,0x78,5,1,0x12,0x34,0x56,0x78,
        5,65,0x12,0x34,0x56,0x78,5,1,0x12,0x34,0x56,0x78};
    assert(!memcmp(wheel,expected_wheel,sizeof expected_wheel));
    assert(lr_rfb_wheel_packets(wheel,sizeof wheel,0,0,7,INT_MIN,INT_MAX)==LR_RFB_WHEEL_BYTES);
    for(unsigned i=LR_RFB_WHEEL_BYTES;i<sizeof wheel;i++)assert(wheel[i]==0xa5);
    memset(wheel,0xa5,sizeof wheel);assert(!lr_rfb_wheel_packets(wheel,11,0,0,0,0,1));
    for(unsigned i=0;i<sizeof wheel;i++)assert(wheel[i]==0xa5);
    size_t bytes=0;assert(lr_rfb_dimensions(640,480,&bytes)&&bytes==1228800);
    assert(!lr_rfb_dimensions(0,1,&bytes));assert(!lr_rfb_dimensions(2561,1,&bytes));assert(!lr_rfb_dimensions(1,1601,&bytes));
    assert(lr_rfb_dimensions(2560,1600,&bytes)&&bytes==16384000);assert(lr_rfb_dimensions(824,1200,&bytes));  // Fit Screen / external displays
    uint8_t storage[4*4*4+32];memset(storage,0xa5,sizeof storage);uint8_t source[16];memset(source,0x42,sizeof source);
    assert(lr_rfb_apply_raw(storage+16,4,4,1,1,2,2,source,16));
    assert(storage[16+(1*4+1)*4]==0x42&&storage[16+(2*4+2)*4]==0x42&&storage[16]==0xa5);
    assert(!lr_rfb_apply_raw(storage+16,4,4,3,3,2,2,source,16));
    assert(!lr_rfb_apply_raw(storage+16,4,4,1,1,2,2,source,15));
    assert(!lr_rfb_rectangle(4,4,65535,0,1,1,&bytes));
    assert(!lr_rfb_rectangle(4,4,4,0,1,1,&bytes));
    assert(lr_rfb_reverse_bits(0x12)==0x48);
    for(size_t i=0;i<16;i++)assert(storage[i]==0xa5&&storage[sizeof(storage)-i-1]==0xa5);
    uint8_t color[4]={1,2,3,4};assert(lr_rfb_fill(storage+16,4,4,3,3,1,1,color));
    assert(storage[16+60]==1&&storage[16+63]==4);
    assert(!lr_rfb_fill(storage+16,4,4,3,3,2,1,color));
    assert(lr_rfb_fill(storage+16,4,4,4,4,0,0,color));
    assert(lr_rfb_fill(storage+16,4,4,0,0,4,4,storage+16+60));
    for(size_t i=0;i<64;i++)assert(storage[16+i]==color[i%4]);
    // Exhaust every valid source/destination on a small framebuffer against
    // a snapshot reference, including overlapping vertical/horizontal moves.
    uint8_t actual[6*5*4+32],before[6*5*4],expected[6*5*4];
    for(unsigned w=1;w<=6;w++)for(unsigned h=1;h<=5;h++)
    for(unsigned sy=0;sy+h<=5;sy++)for(unsigned sx=0;sx+w<=6;sx++)
    for(unsigned y=0;y+h<=5;y++)for(unsigned x=0;x+w<=6;x++){
        for(size_t i=0;i<sizeof before;i++)before[i]=(uint8_t)i;
        memset(actual,0xa5,sizeof actual);memcpy(actual+16,before,sizeof before);memcpy(expected,before,sizeof before);
        for(unsigned row=0;row<h;row++)memcpy(expected+((y+row)*6+x)*4,before+((sy+row)*6+sx)*4,w*4);
        assert(lr_rfb_copy_rect(actual+16,6,5,x,y,w,h,sx,sy));
        assert(!memcmp(actual+16,expected,sizeof expected));
        for(unsigned i=0;i<16;i++)assert(actual[i]==0xa5&&actual[sizeof actual-i-1]==0xa5);
    }
    assert(!lr_rfb_copy_rect(actual+16,6,5,0,0,3,3,4,0));
    assert(!lr_rfb_copy_rect(actual+16,6,5,5,4,2,1,0,0));
    for(size_t i=0;i<16;i++)assert(storage[i]==0xa5&&storage[sizeof(storage)-i-1]==0xa5);
    srand(47);for(unsigned i=0;i<50000;i++){
        uint16_t x=rand(),y=rand(),w=rand(),h=rand();
        if(lr_rfb_rectangle(640,480,x,y,w,h,&bytes))assert((size_t)x+w<=640&&(size_t)y+h<=480&&bytes<=1228800);
    }
    puts("RFB bounded rectangle, guard bytes, malformed dimensions and randomized bounds passed");
}
