//
//  offsetfinder64.hpp
//  offsetfinder64
//
//  Created by tihmstar on 10.01.18.
//  Copyright © 2018 tihmstar. All rights reserved.
//

#ifndef offsetfinder64_hpp
#define offsetfinder64_hpp

#include <string>
#include <stdint.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>
#include <mach-o/dyld_images.h>
#include <vector>

#include <stdlib.h>

typedef uint64_t offset_t;


namespace tihmstar {
    
    class exception : public std::exception{
        std::string _err;
        int _code;
    public:
        exception(int code, std::string err) : _err(err), _code(code) {};
        exception(std::string err) : _err(err), _code(0) {};
        exception(int code) : _code(code) {};
        const char *what(){return _err.c_str();}
        int code(){return _code;}
    };
    namespace patchfinder64{
        typedef uint8_t* loc_t;
        
        class patch{
            bool _slideme;
            void(*_slidefunc)(class patch *patch, uint64_t slide);
        public:
            const loc_t _location;
            const void *_patch;
            const size_t _patchSize;
            patch(loc_t location, const void *patch, size_t patchSize, void(*slidefunc)(class patch *patch, uint64_t slide) = NULL) : _location(location), _patchSize(patchSize), _slidefunc(slidefunc){
                _patch = malloc(_patchSize);
                memcpy((void*)_patch, patch, _patchSize);
                _slideme = (_slidefunc) ? true : false;
            }
            patch(const patch& cpy) : _location(cpy._location), _patchSize(cpy._patchSize){
                _patch = malloc(_patchSize);
                memcpy((void*)_patch, cpy._patch, _patchSize);
                _slidefunc = cpy._slidefunc;
                _slideme = cpy._slideme;
            }
            void slide(uint64_t slide){
                if (!_slideme)
                    return;
                printf("sliding with %p\n",(void*)slide);
                _slidefunc(this,slide);
                _slideme = false; //only slide once
            }
            ~patch(){
                free((void*)_patch);
            }
            
        };
    }
    class offsetfinder64 {
    public:
        struct text_t{
            patchfinder64::loc_t map;
            size_t size;
            patchfinder64::loc_t base;
            bool isExec;
        };
        
    private:
        bool _freeKernel;
        uint8_t *_kdata;
        size_t _ksize;
        offset_t _kslide;
        patchfinder64::loc_t _kernel_entry;
        std::vector<text_t> _segments;
        
        struct symtab_command *__symtab;
        void loadSegments(uint64_t slide);
        __attribute__((always_inline)) struct symtab_command *getSymtab();
        
    public:
        offsetfinder64(const char *filename);
        offsetfinder64(void* buf, size_t size, uint64_t base);
        const void *kdata();
        patchfinder64::loc_t find_entry();
        const std::vector<text_t> &segments(){return _segments;};
        
        patchfinder64::loc_t memmem(const void *little, size_t little_len);
        
        patchfinder64::loc_t find_sym(const char *sym);
        patchfinder64::loc_t find_syscall0();
        uint64_t             find_register_value(patchfinder64::loc_t where, int reg, patchfinder64::loc_t startAddr = 0);
        
        /*------------------------ v0rtex -------------------------- */
        patchfinder64::loc_t find_zone_map();
        patchfinder64::loc_t find_kernel_map();
        patchfinder64::loc_t find_kernel_task();
        patchfinder64::loc_t find_realhost();
        patchfinder64::loc_t find_bzero();
        patchfinder64::loc_t find_bcopy();
        patchfinder64::loc_t find_copyout();
        patchfinder64::loc_t find_copyin();
        patchfinder64::loc_t find_ipc_port_alloc_special();
        patchfinder64::loc_t find_ipc_kobject_set();
        patchfinder64::loc_t find_ipc_port_make_send();
        patchfinder64::loc_t find_chgproccnt();
        patchfinder64::loc_t find_kauth_cred_ref();
        patchfinder64::loc_t find_osserializer_serialize();
        uint32_t             find_vtab_get_external_trap_for_index();
        uint32_t             find_vtab_get_retain_count();
        uint32_t             find_iouserclient_ipc();
        uint32_t             find_ipc_space_is_task();
        uint32_t             find_proc_ucred();
        uint32_t             find_task_bsd_info();
        uint32_t             find_vm_map_hdr();
        uint32_t             find_task_itk_self();
        uint32_t             find_task_itk_registered();
        uint32_t             find_sizeof_task();
        
        patchfinder64::loc_t find_rop_add_x0_x0_0x10();
        patchfinder64::loc_t find_rop_ldr_x0_x0_0x10();
        
        
        /*------------------------ kernelpatches -------------------------- */
        patchfinder64::patch find_i_can_has_debugger_patch_off();
        patchfinder64::patch find_lwvm_patch_offsets();
        patchfinder64::patch find_remount_patch_offset();
        std::vector<patchfinder64::patch> find_nosuid_off();
        patchfinder64::patch find_proc_enforce();
        patchfinder64::patch find_amfi_patch_offsets();
        patchfinder64::patch find_cs_enforcement_disable_amfi();
        patchfinder64::patch find_amfi_substrate_patch();
        //        patchfinder64::patch find_sandbox_patch();
        patchfinder64::loc_t find_sbops();
        patchfinder64::patch find_nonceEnabler_patch();
        
        
        /*------------------------ KPP bypass -------------------------- */
        patchfinder64::loc_t find_gPhysBase();
        patchfinder64::loc_t find_kernel_pmap();
        patchfinder64::loc_t find_cpacr_write();
        patchfinder64::loc_t find_idlesleep_str_loc();
        patchfinder64::loc_t find_deepsleep_str_loc();
        
        /*------------------------ Util -------------------------- */
        patchfinder64::loc_t find_rootvnode();
        
        ~offsetfinder64();
    };
    using segment_t = std::vector<tihmstar::offsetfinder64::text_t>;
    namespace patchfinder64{
        
        loc_t find_literal_ref(segment_t segemts, offset_t kslide, loc_t pos);
    }
}



#endif /* offsetfinder64_hpp */
