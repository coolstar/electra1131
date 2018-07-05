//
//  apfs_util.h
//  electra
//
//  Created by CoolStar on 2/26/18.
//  Copyright © 2018 Electra Team. All rights reserved.
//

#ifndef apfs_util_h
#define apfs_util_h

#define get_dirfd(vol) open(vol, O_RDONLY, 0)

const char *find_snapshot_with_ref(const char *vol, const char *ref);
const char *find_system_snapshot(const char *rootfsmnt);

int do_create(const char *vol, const char *snap);
int do_delete(const char *vol, const char *snap);
int do_revert(const char *vol, const char *snap);
int do_rename(const char *vol, const char *snap, const char *nw);
int do_mount(const char *vol, const char *snap, const char *mntpnt);
int list_snapshots(const char *vol);
int check_snapshot(const char *vol, const char *snap);
char *copyBootHash(void);

#endif /* apfs_util_h */
