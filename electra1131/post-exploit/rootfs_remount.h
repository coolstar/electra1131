//
//  rootfs_remount.h
//  electra1131
//
//  Created by CoolStar on 6/7/18.
//  Copyright © 2018 CoolStar. All rights reserved.
//

#ifndef rootfs_remount_h
#define rootfs_remount_h
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

bool getOffsets(uint64_t slide);
int remountRootAsRW(uint64_t slide, uint64_t kern_proc, uint64_t our_proc, int snapshot_success);
    
#ifdef __cplusplus
}
#endif

#endif /* rootfs_remount_h */
