#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <mach/mach.h>

#include "kmem.h"
#include "IOKit.h"
#include "offsets.h"

uint64_t task_port_kaddr = 0;
mach_port_t tfp0 = MACH_PORT_NULL;

void increase_limits() {
    struct rlimit lim = {0};
    int err = getrlimit(RLIMIT_NOFILE, &lim);
    if (err != 0) {
        printf("failed to get limits\n");
    }
    printf("rlim.cur: %lld\n", lim.rlim_cur);
    printf("rlim.max: %lld\n", lim.rlim_max);
    
    lim.rlim_cur = 10240;
    
    err = setrlimit(RLIMIT_NOFILE, &lim);
    if (err != 0) {
        printf("failed to set limits\n");
    }
    
    lim.rlim_cur = 0;
    lim.rlim_max = 0;
    err = getrlimit(RLIMIT_NOFILE, &lim);
    if (err != 0) {
        printf("failed to get limits\n");
    }
    printf("rlim.cur: %lld\n", lim.rlim_cur);
    printf("rlim.max: %lld\n", lim.rlim_max);
    
}

void prepare_for_rw_with_fake_tfp0(mach_port_t fake_tfp0) {
  tfp0 = fake_tfp0;
}

void wk32(uint64_t kaddr, uint32_t val) {
  if (tfp0 == MACH_PORT_NULL) {
    printf("attempt to write to kernel memory before any kernel memory write primitives available\n");
    sleep(3);
    return;
  }
  
  kern_return_t err;
  err = mach_vm_write(tfp0,
                      (mach_vm_address_t)kaddr,
                      (vm_offset_t)&val,
                      (mach_msg_type_number_t)sizeof(uint32_t));
  
  if (err != KERN_SUCCESS) {
    printf("tfp0 write failed: %s %x\n", mach_error_string(err), err);
    return;
  }
}

void wk64(uint64_t kaddr, uint64_t val) {
  uint32_t lower = (uint32_t)(val & 0xffffffff);
  uint32_t higher = (uint32_t)(val >> 32);
  wk32(kaddr, lower);
  wk32(kaddr+4, higher);
}

uint32_t rk32(uint64_t kaddr) {
  kern_return_t err;
  uint32_t val = 0;
  mach_vm_size_t outsize = 0;
  err = mach_vm_read_overwrite(tfp0,
                               (mach_vm_address_t)kaddr,
                               (mach_vm_size_t)sizeof(uint32_t),
                               (mach_vm_address_t)&val,
                               &outsize);
  if (err != KERN_SUCCESS){
    printf("tfp0 read failed %s addr: 0x%llx err:%x port:%x\n", mach_error_string(err), kaddr, err, tfp0);
    sleep(3);
    return 0;
  }
  
  if (outsize != sizeof(uint32_t)){
    printf("tfp0 read was short (expected %lx, got %llx\n", sizeof(uint32_t), outsize);
    sleep(3);
    return 0;
  }
  return val;
}

uint64_t rk64(uint64_t kaddr) {
  uint64_t lower = rk32(kaddr);
  uint64_t higher = rk32(kaddr+4);
  uint64_t full = ((higher<<32) | lower);
  return full;
}
