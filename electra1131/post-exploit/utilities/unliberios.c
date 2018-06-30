//
//  unliberios.c
//  electra
//
//  Created by CoolStar on 2/12/18.
//  Copyright © 2018 Electra Team. All rights reserved.
//

#include "unliberios.h"
#include "file_utils.h"
#include <unistd.h>
#include <spawn.h>
#include <sys/wait.h>

bool checkLiberiOS(){
    if (file_exists("/jb"))
        return true;
    if (file_exists("/bin/zsh"))
        return true;
    if (file_exists("/etc/motd"))
        return true;
    return false;
}

void removeLiberiOS(){
//From removeMe.sh
    
    printf("Removing liberiOS...\n");
    
    unlink("/etc/motd");
    unlink("/.cydia_no_stash");
    
    rmdir("/Applications/Cydia.app");
    rmdir("/usr/share/terminfo");
    rmdir("/usr/local/bin");
    rmdir("/usr/local/lib");
    
    unlink("/bin/zsh");
    unlink("/etc/profile");
    unlink("/etc/zshrc");
    
    unlink("/usr/bin/scp"); //missing from removeMe.sh oddly

    rmdir("/jb");
}
