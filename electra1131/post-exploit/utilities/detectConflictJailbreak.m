//
//  detectConflictJailbreak.c
//  electra1131
//
//  Created by Pwn20wnd on 6/29/18.
//  Copyright © 2018 Electra Team. All rights reserved.
//

#include "detectConflictJailbreak.h"
#include <Foundation/Foundation.h>
#include "file_utils.h"

bool detectConflictJailbreak(void) {
    NSMutableArray *bootstrap_file_list = [[NSMutableArray alloc] initWithObjects:
                                         @"/.installed_xiaolian",
                                         @"/xiaolian",
                                         @"/var/run/io.xiaolian.helper",
                                         @"/Library/LaunchDaemons/xiaolian.plist",
                                         nil];
    for (NSString *fileName in bootstrap_file_list) {
        if (file_exists([fileName UTF8String])) {
            return true;
        }
    }
    return false;
}
