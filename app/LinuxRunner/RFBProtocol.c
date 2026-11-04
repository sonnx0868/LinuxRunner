#include "RFBProtocol.h"
#include <string.h>
bool lr_rfb_dimensions(uint16_t w,uint16_t h,size_t *bytes) {
    if(!w||!h||w>LR_RFB_MAX_WIDTH||h>LR_RFB_MAX_HEIGHT||!bytes)return false;
    *bytes=(size_t)w*h*4;return true;
}
bool lr_rfb_rectangle(uint16_t fw,uint16_t fh,uint16_t x,uint16_t y,uint16_t w,uint16_t h,size_t *bytes) {
    size_t total;
    if(!lr_rfb_dimensions(fw,fh,&total)||!bytes||x>fw||y>fh||w>fw-x||h>fh-y)return false;
    *bytes=(size_t)w*h*4;return true;
}
bool lr_rfb_apply_raw(uint8_t *frame,uint16_t fw,uint16_t fh,uint16_t x,uint16_t y,uint16_t w,uint16_t h,const uint8_t *source,size_t count) {
    size_t bytes;
    if(!frame||!source||!lr_rfb_rectangle(fw,fh,x,y,w,h,&bytes)||count!=bytes)return false;
    for(size_t row=0;row<h;row++)memcpy(frame+((size_t)(y+row)*fw+x)*4,source+row*w*4,(size_t)w*4);
    return true;
}
uint8_t lr_rfb_reverse_bits(uint8_t n){n=(n>>4)|(n<<4);n=((n&0xcc)>>2)|((n&0x33)<<2);return ((n&0xaa)>>1)|((n&0x55)<<1);}
size_t lr_rfb_wheel_packets(uint8_t *out,size_t capacity,uint16_t x,uint16_t y,uint8_t held,int horizontal,int vertical) {
    int dx=horizontal>32?32:horizontal< -32?-32:horizontal;
    int dy=vertical>32?32:vertical< -32?-32:vertical;
    size_t needed=(size_t)((dx<0?-dx:dx)+(dy<0?-dy:dy))*12;
    if(!out||capacity<needed)return 0;
    held&=7;size_t offset=0;
    for(unsigned axis=0;axis<2;axis++){
        int count=axis?dx:dy;
        uint8_t wheel=axis?(count>0?32:64):(count>0?8:16);
        for(int i=0;i<(count<0?-count:count);i++){
            uint8_t pair[12]={5,held|wheel,(uint8_t)(x>>8),(uint8_t)x,(uint8_t)(y>>8),(uint8_t)y,
                5,held,(uint8_t)(x>>8),(uint8_t)x,(uint8_t)(y>>8),(uint8_t)y};
            memcpy(out+offset,pair,sizeof pair);offset+=sizeof pair;
        }
    }
    return offset;
}
bool lr_rfb_copy_rect(uint8_t *frame,uint16_t fw,uint16_t fh,uint16_t x,uint16_t y,uint16_t w,uint16_t h,uint16_t sx,uint16_t sy) {
    size_t bytes;
    if(!frame||!lr_rfb_rectangle(fw,fh,x,y,w,h,&bytes)||
       !lr_rfb_rectangle(fw,fh,sx,sy,w,h,&bytes))return false;
    // Copy bottom-up when moving down so overlapping source rows survive.
    // memmove also handles horizontal overlap, without a rectangle scratch.
    for(size_t i=0;i<h;i++){
        size_t row=y>sy?h-1-i:i;
        memmove(frame+(((size_t)y+row)*fw+x)*4,
                frame+(((size_t)sy+row)*fw+sx)*4,(size_t)w*4);
    }
    return true;
}
bool lr_rfb_fill(uint8_t *frame,uint16_t fw,uint16_t fh,uint16_t x,uint16_t y,uint16_t w,uint16_t h,const uint8_t color[4]) {
    size_t bytes;
    if(!frame||!color||!lr_rfb_rectangle(fw,fh,x,y,w,h,&bytes))return false;
    if(!bytes)return true;
    uint8_t pixel[4];memcpy(pixel,color,4);
    uint8_t *first=frame+((size_t)y*fw+x)*4;
    for(size_t col=0;col<w;col++)memcpy(first+col*4,pixel,4);
    for(size_t row=1;row<h;row++)memcpy(first+row*fw*4,first,(size_t)w*4);
    return true;
}

#include <math.h>
bool lr_rfb_viewport_point(double x,double y,double left,double top,double rw,double rh,uint16_t w,uint16_t h,uint16_t *px,uint16_t *py){
 size_t bytes;if(!px||!py||!lr_rfb_dimensions(w,h,&bytes)||!isfinite(x)||!isfinite(y)||!isfinite(left)||!isfinite(top)||!isfinite(rw)||!isfinite(rh)||rw<=0||rh<=0)return false;
 double gx=(x-left)*w/rw,gy=(y-top)*h/rh;
 *px=(uint16_t)fmax(0,fmin(w-1,gx));*py=(uint16_t)fmax(0,fmin(h-1,gy));return true;
}
