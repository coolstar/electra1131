//
//  file_utils.c
//  electra
//
//  Created by Jamie on 27/01/2018.
//  Copyright © 2018 Electra Team. All rights reserved.
//

#include "file_utils.h"
#include <sys/stat.h>
#include <sys/fcntl.h>
#include <unistd.h>
#include <errno.h>

int file_exists(const char *filename) {
    int r = access(filename, F_OK);
    return (r == 0);
}

