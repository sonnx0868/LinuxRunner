// macOS-only test interposer. Reject the second LOAD of a tagged test ELF.
#include <sys/mman.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
static void *deny_image(void *addr,size_t len,int prot,int flags,int fd,off_t off) {
    unsigned char ident[16];
    if(fd>=0&&off>=16384&&pread(fd,ident,sizeof ident,0)==sizeof ident
            &&!memcmp(ident,"\177ELF",4)&&!memcmp(ident+8,"LRDENY!!",8)) {
        errno=ENOMEM;return MAP_FAILED;
    }
    return mmap(addr,len,prot,flags,fd,off);
}
__attribute__((used,section("__DATA,__interpose")))
static const struct {const void *replacement,*original;} pair={(void *)deny_image,(void *)mmap};
