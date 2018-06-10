TARGET  = libjailbreak.dylib
OUTDIR ?= bin

CC      = xcrun -sdk iphoneos cc -arch arm64
# it is injected into trust cache by code
# which only supports sha-256 signatures
LDID    = ldid2
CFLAGS  = -Wall

.PHONY: all clean

all: $(OUTDIR)/$(TARGET)

DEBUG ?= 0
ifeq ($(DEBUG), 1)
    CFLAGS += -DLIBJAILBREAK_DEBUG
else
    CFLAGS += -O2
endif

$(OUTDIR):
	mkdir -p $(OUTDIR)

$(OUTDIR)/$(TARGET): mach/jailbreak_daemonUser.c libjailbreak_mig.m | $(OUTDIR)
	$(CC) -dynamiclib -o $@ $^ $(CFLAGS)
	$(LDID) -S $@

clean:
	rm -f $(OUTDIR)/$(TARGET)
