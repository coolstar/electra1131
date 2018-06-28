#ifndef kutils_h
#define kutils_h

#include <mach/mach.h>
#include "IOKit.h"

uint64_t task_self_addr(void);
uint64_t ipc_space_kernel(void);
uint64_t find_kernel_base(void);

mach_port_t fake_host_priv(void);

size_t kread(uint64_t where, void *p, size_t size);
size_t kwrite(uint64_t where, const void *p, size_t size);
uint64_t kalloc(vm_size_t size);
uint64_t kalloc_wired(uint64_t size);
void kfree(mach_vm_address_t address, vm_size_t size);
uint64_t zm_fix_addr(uint64_t addr);
void set_csblob(uint64_t proc);

uint32_t find_pid_of_proc(const char *proc_name);
uint64_t get_proc_struct_for_pid(pid_t proc_pid);

#endif /* kutils_h */
