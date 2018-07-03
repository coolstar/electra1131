//
//  debug.h
//  electra1131
//
//  Created by Pwn20wnd on 7/3/18.
//  Copyright © 2018 Electra Team. All rights reserved.
//

#ifndef debug_h
#define debug_h

#include <stdio.h>

#define RAWLOG(fmt, args...) fprintf(stderr, fmt, ##args);
#define INFO(fmt, args...) RAWLOG("[INF] " fmt, ##args);
#undef DEBUG
#define DEBUG(fmt, args...) RAWLOG("[DBG] " fmt, ##args);
#define ERROR(fmt, args...) RAWLOG("[ERR] " fmt, ##args);

#endif /* debug_h */
