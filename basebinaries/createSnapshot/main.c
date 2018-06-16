#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/snapshot.h>
#include <unistd.h>

int do_create(int dirfd, const char *snap) {
    
    int ret = fs_snapshot_create(dirfd, snap, 0);
    if (ret != 0)
        perror("fs_snapshot_create");
    return (ret);
}

int main(int argc, char **argv) {
    int dirfd = open("/", O_RDONLY, 0);
    if (dirfd < 0) {
        perror("open");
        exit(1);
    }
    unlink("/createSnapshot");
    do_create(dirfd, "electra-prejailbreak");
    
    return (0);
}
