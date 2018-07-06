//
//  apfs_util.c
//  electra
//
//  Created by CoolStar on 2/26/18.
//  Copyright © 2018 Electra Team. All rights reserved.
//

#include "apfs_util.h"

#include <fcntl.h>
#include <sys/syscall.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/attr.h>
#include <sys/snapshot.h>
#include <mach/mach.h>
#include "IOKit.h"

const char *find_snapshot_with_ref(const char *vol, const char *ref) {
    int dirfd = get_dirfd(vol);
    
    if (dirfd < 0) {
        perror("get_dirfd");
        return NULL;
    }
    
    struct attrlist alist = { 0 };
    char abuf[2048];
    
    alist.commonattr = ATTR_BULK_REQUIRED;
    
    int count = fs_snapshot_list(dirfd, &alist, &abuf[0], sizeof (abuf), 0);
    close(dirfd);
    
    if (count < 0) {
        perror("fs_snapshot_list");
        return NULL;
    }
    
    char *p = &abuf[0];
    for (int i = 0; i < count; i++) {
        char *field = p;
        uint32_t len = *(uint32_t *)field;
        field += sizeof (uint32_t);
        attribute_set_t attrs = *(attribute_set_t *)field;
        field += sizeof (attribute_set_t);
        
        if (attrs.commonattr & ATTR_CMN_NAME) {
            attrreference_t ar = *(attrreference_t *)field;
            char *name = field + ar.attr_dataoffset;
            field += sizeof (attrreference_t);
            if (strstr(name, ref)) {
                return name;
            }
        }
        
        p += len;
    }
    
    return NULL;
}

const char *find_system_snapshot(const char *rootfsmnt) {
    char *bootHash = copyBootHash();
    char *system_snapshot = malloc(sizeof(char *) + (21 + strlen(bootHash)));
    bzero(system_snapshot, sizeof(char *) + (21 + strlen(bootHash)));
    
    if (!bootHash) {
        return NULL;
    }
    
    sprintf(system_snapshot, "com.apple.os.update-%s", bootHash);
    
    printf("System snapshot: %s\n", system_snapshot);
    
    return system_snapshot;
}

int do_create(const char *vol, const char *snap) {
    int dirfd = get_dirfd(vol);
    if (dirfd < 0) {
        perror("open");
        return -1;
    }
    
    int ret = fs_snapshot_create(dirfd, snap, 0);
    close(dirfd);
    if (ret != 0)
        perror("fs_snapshot_create");
    return (ret);
}

int do_delete(const char *vol, const char *snap) {
    int dirfd = get_dirfd(vol);
    if (dirfd < 0) {
        perror("open");
        return -1;
    }
    
    int ret = fs_snapshot_delete(dirfd, snap, 0);
    close(dirfd);
    if (ret != 0)
        perror("fs_snapshot_delete");
    return (ret);
}

int do_revert(const char *vol, const char *snap) {
    int dirfd = get_dirfd(vol);
    if (dirfd < 0) {
        perror("open");
        return -1;
    }
    
    int ret = fs_snapshot_revert(dirfd, snap, 0);
    close(dirfd);
    if (ret != 0)
        perror("fs_snapshot_revert");
    return (ret);
}

int do_rename(const char *vol, const char *snap, const char *nw) {
    int dirfd = get_dirfd(vol);
    if (dirfd < 0) {
        perror("open");
        return -1;
    }
    
    int ret = fs_snapshot_rename(dirfd, snap, nw, 0);
    close(dirfd);
    if (ret != 0)
        perror("fs_snapshot_rename");
    return (ret);
}

int do_mount(const char *vol, const char *snap, const char *mntpnt) {
    int dirfd = get_dirfd(vol);
    if (dirfd < 0) {
        perror("open");
        return -1;
    }
    
    int ret = fs_snapshot_mount(dirfd, mntpnt, snap, 0);
    close(dirfd);
    if (ret != 0) {
        perror("fs_snapshot_mount");
    } else {
        printf("mount_apfs: snapshot implicitly mounted readonly\n");
    }
    return (ret);
}

int list_snapshots(const char *vol)
{
    int dirfd = get_dirfd(vol);
    
    if (dirfd < 0) {
        perror("get_dirfd");
        return -1;
    }
    
    struct attrlist alist = { 0 };
    char abuf[2048];
    
    alist.commonattr = ATTR_BULK_REQUIRED;
    
    int count = fs_snapshot_list(dirfd, &alist, &abuf[0], sizeof (abuf), 0);
    close(dirfd);

    if (count < 0) {
        perror("fs_snapshot_list");
        return -1;
    }
    
    char *p = &abuf[0];
    for (int i = 0; i < count; i++) {
        char *field = p;
        uint32_t len = *(uint32_t *)field;
        field += sizeof (uint32_t);
        attribute_set_t attrs = *(attribute_set_t *)field;
        field += sizeof (attribute_set_t);
        
        if (attrs.commonattr & ATTR_CMN_NAME) {
            attrreference_t ar = *(attrreference_t *)field;
            char *name = field + ar.attr_dataoffset;
            field += sizeof (attrreference_t);
            (void) printf("%s\n", name);
        }
        
        p += len;
    }
    
    return (0);
}

int check_snapshot(const char *vol, const char *snap) {
    if (find_snapshot_with_ref(vol, snap))
        return 1;
    
    return 0;
}

char *copyBootHash(void) {
    unsigned char buf[1024];
    uint32_t length = 1024;
    io_registry_entry_t chosen = IORegistryEntryFromPath(kIOMasterPortDefault, "IODeviceTree:/chosen");
    
    if (!MACH_PORT_VALID(chosen)) {
        printf("Unable to get IODeviceTree:/chosen port\n");
        return NULL;
    }
    
    kern_return_t ret = IORegistryEntryGetProperty(chosen, "boot-manifest-hash", (void*)buf, &length);
    
    IOObjectRelease(chosen);
    
    if (ret != ERR_SUCCESS) {
        printf("Unable to read boot-manifest-hash\n");
        return NULL;
    }
    
    // Make a hex string out of the hash
    char manifestHash[length*2+1];
    bzero(manifestHash, sizeof(manifestHash));
    
    int i;
    for (i=0; i<length; i++) {
        sprintf(manifestHash+i*2, "%02X", buf[i]);
    }
    
    printf("Hash: %s\n", manifestHash);
    return strdup(manifestHash);
}
