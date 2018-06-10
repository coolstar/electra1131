TARGET  = jailbreakd
OUTDIR ?= bin

CC      = xcrun -sdk iphoneos cc -arch arm64
LDID    = ldid
CFLAGS  = -Wall -Wno-unused-variable -Wno-unused-function

.PHONY: all clean

all: $(OUTDIR)/$(TARGET)

DEBUG ?= 1
ifeq ($(DEBUG), 1)
    CFLAGS += -DJAILBREAKDDEBUG
else
    CFLAGS += -O2
endif

mach/jailbreak_daemonServer.c:
	rm -f mach/jailbreak_daemonServer.c
	rm -f mach/jailbreak_daemonUser.c
	mig -sheader mach/jailbreak_daemonServer.h -header mach/jailbreak_daemonUser.h mach/mig.defs
	mv jailbreak_daemonServer.c mach/
	mv jailbreak_daemonUser.c mach/

$(OUTDIR):
	mkdir -p $(OUTDIR)

$(OUTDIR)/$(TARGET): mach/jailbreak_daemonServer.c *.c *.m | $(OUTDIR)
	$(CC) -o $@ $^ -framework Foundation -framework IOKit -framework LocalAuthentication $(CFLAGS)
	$(LDID) -SEnt.plist $@

clean:
	rm -f $(OUTDIR)/$(TARGET)
