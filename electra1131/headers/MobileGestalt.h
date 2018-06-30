/*
 * libMobileGestalt header.
 * Mobile gestalt functions as a QA system. You ask it a question, and it gives you the answer! :)
 *
 * Copyright (c) 2013-2014 Cykey (David Murray)
 * All rights reserved.
 */

#ifndef LIBMOBILEGESTALT_H_
#define LIBMOBILEGESTALT_H_

#include <CoreFoundation/CoreFoundation.h>

CFPropertyListRef MGCopyAnswer(CFStringRef property);
static const CFStringRef kMGUniqueDeviceID = CFSTR("UniqueDeviceID");

#endif /* LIBMOBILEGESTALT_H_ */
