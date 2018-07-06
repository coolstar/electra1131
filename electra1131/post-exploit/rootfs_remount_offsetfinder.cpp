//
//  rootfs_remount_offsetfinder.cpp
//  electra1131
//
//  Created by CoolStar on 6/7/18.
//  Copyright © 2018 Electra Team. All rights reserved.
//

#include <stdint.h>
#include <stdio.h>
#include "rootfs_remount.h"
#include "liboffsetfinder64.hpp"

using namespace std;
using namespace tihmstar;

extern "C" uint64_t offset_vfs_context_current;
extern "C" uint64_t offset_vnode_lookup;
extern "C" uint64_t offset_vnode_put;

extern "C" bool getOffsets(uint64_t slide){
    printf("Initializing offsetfinder...\n");
    offsetfinder64 fi("/System/Library/Caches/com.apple.kernelcaches/kernelcache");
    printf("Initialized offsetfinder\n");
    
    try {
        offset_vfs_context_current = (uint64_t)fi.find_sym("_vfs_context_current");
        offset_vnode_lookup = (uint64_t)fi.find_sym("_vnode_lookup");
        offset_vnode_put = (uint64_t)fi.find_sym("_vnode_put");
        
        printf("vfs_context_current: %p\n", (void *)offset_vfs_context_current);
        printf("vnode_lookup: %p\n", (void *)offset_vnode_lookup);
        printf("vnode_put: %p\n", (void *)offset_vnode_put);
        
        offset_vfs_context_current += slide;
        offset_vnode_lookup += slide;
        offset_vnode_put += slide;
        return true;
    } catch (tihmstar::exception &e){
        printf("offsetfinder failure! %d (%s)\n", e.code(), e.what());
        return false;
    } catch (std::exception &e){
        printf("fatal offsetfinder failure! %s\n", e.what());
        return false;
    }
}
