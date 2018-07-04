//
//  removePotentialJailbreak.c
//  electra1131
//
//  Created by Pwn20wnd on 6/24/18.
//  Copyright © 2018 Electra Team. All rights reserved.
//

#include "removePotentialJailbreak.h"
#include <unistd.h>

void removePotentialJailbreak(void) {
    
    rmdir("/jb");
    rmdir("/Applications/Filza.app");
    unlink("/etc/dropbear");
    rmdir("/var/LIB");
    rmdir("/var/ulb");
    rmdir("/var/bin");
    rmdir("/var/sbin");
    unlink("/var/profile");
    unlink("/var/motd");
    unlink("/var/dropbear");
    rmdir("/var/containers/Bundle/tweaksupport");
    rmdir("/var/containers/Bundle/iosbinpack64");
    rmdir("/var/containers/Bundle/dylibs");
    unlink("/var/log/testbin.log");
    unlink("/var/log/jailbreakd-stdout.log");
    unlink("/var/log/jailbreakd-stderr.log");
}
