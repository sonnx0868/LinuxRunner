#include "app/LinuxRunner/KeyboardPolicy.h"
#include "app/LinuxRunner/ScrollPolicy.h"
#include "app/LinuxRunner/PerformancePolicy.h"
#include "kernel/anon_budget.h"
#include <assert.h>
#include <limits.h>
#include <stdio.h>
#ifndef _WIN32
#include <pthread.h>
static _Atomic long concurrent_used;
static void *reserve_worker(void *unused) {
    (void)unused;
    for (int i=0;i<10000;i++) {
        while (!anon_budget_try_reserve(&concurrent_used, 3, 1)) {}
        assert(atomic_load(&concurrent_used)<=3);
        atomic_fetch_sub(&concurrent_used, 1);
    }
    return NULL;
}
#endif
int main(void) {
    for (unsigned i=0;i<26;i++) {
        assert(lr_hid_us_symbol(4+i,false)=='a'+i);
        assert(lr_hid_us_symbol(4+i,true)=='A'+i);
    }
    const char *plain="1234567890", *shifted="!@#$%^&*()";
    for(unsigned i=0;i<10;i++) {
        assert(lr_hid_us_symbol(30+i,false)==(unsigned)plain[i]);
        assert(lr_hid_us_symbol(30+i,true)==(unsigned)shifted[i]);
    }
    plain="-=[]\\#;'`,./";shifted="_+{}|~:\"~<>?";
    for(unsigned i=0;i<12;i++) {
        assert(lr_hid_us_symbol(45+i,false)==(unsigned)plain[i]);
        assert(lr_hid_us_symbol(45+i,true)==(unsigned)shifted[i]);
    }
    assert(lr_hid_us_symbol(57,false)==0xffe5);
    assert(lr_hid_us_symbol(44,false)==' ');
    assert(lr_hid_us_symbol(224,false)==0);
    assert(lr_hid_us_symbol(88,false)==0xff8d);
    assert(lr_hid_us_symbol(115,false)==0xffd5);
    double residual;
    assert(lr_scroll_steps(31,12,&residual)==2&&residual==7);
    assert(lr_scroll_steps(-31,12,&residual)==-2&&residual==-7);
    assert(lr_scroll_steps(7,12,&residual)==0&&residual==7);
    assert(lr_scroll_steps(10000,12,&residual)==32&&residual==4);
    assert(lr_scroll_steps(NAN,12,&residual)==0&&residual==0);
    assert(lr_scroll_steps(1,0,&residual)==0);
    assert(lr_m2_anonymous_budget(8*LR_GIB,7*LR_GIB)==4*LR_GIB);
    assert(lr_m2_anonymous_budget(16*LR_GIB,0)==4*LR_GIB);
    assert(lr_m2_anonymous_budget(16*LR_GIB,5*LR_GIB)==4*LR_GIB);
    assert(lr_m2_anonymous_budget(16*LR_GIB,7*LR_GIB)==6*LR_GIB);
    assert(lr_m2_anonymous_budget(16*LR_GIB,15*LR_GIB)==8*LR_GIB);
    assert(lr_external_frame_rate(true,true,false,120)==60);
    assert(lr_external_frame_rate(true,true,true,120)==30);
    assert(lr_external_frame_rate(true,false,false,60)==30);
    assert(lr_external_frame_rate(false,true,false,60)==30);
    assert(lr_external_frame_rate(true,true,false,24)==24);
    _Atomic long used=0;
    assert(anon_budget_try_reserve(&used,10,10));
    assert(!anon_budget_try_reserve(&used,10,1));
    assert(!anon_budget_try_reserve(&used,10,-1));
    assert(atomic_load(&used)==10);
    atomic_store(&used,LONG_MAX-1);
    assert(!anon_budget_try_reserve(&used,LONG_MAX,2));
    assert(anon_budget_try_reserve(&used,LONG_MAX,1));
#ifndef _WIN32
    pthread_t threads[8];
    for(unsigned i=0;i<8;i++)assert(!pthread_create(&threads[i],NULL,reserve_worker,NULL));
    for(unsigned i=0;i<8;i++)assert(!pthread_join(threads[i],NULL));
    assert(atomic_load(&concurrent_used)==0);
#endif
    puts("Keyboard, scroll, M2 memory/frame limits and atomic reservations passed");
}
