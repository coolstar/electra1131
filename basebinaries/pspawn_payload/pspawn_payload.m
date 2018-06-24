#include <dlfcn.h>
#include <stdio.h>
#include <mach/mach.h>
#include <mach/error.h>
#include <mach/message.h>
#include <string.h>
#include <unistd.h>
#include <spawn.h>
#include <sys/types.h>
#include <errno.h>
#include <stdlib.h>
#include <sys/sysctl.h>
#include <dlfcn.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <pthread.h>
#include <Foundation/Foundation.h>
#include "fishhook.h"
#include "mach/jailbreak_daemonUser.h"

int file_exist(const char *filename) {
    struct stat buffer;
    int r = stat(filename, &buffer);
    return (r == 0);
}

#ifdef PSPAWN_PAYLOAD_DEBUG
#define LAUNCHD_LOG_PATH "/tmp/pspawn_payload_launchd.log"
// XXX multiple xpcproxies opening same file
// XXX not closing logfile before spawn
#define XPCPROXY_LOG_PATH "/tmp/pspawn_payload_xpcproxy.log"
FILE *log_file;
#define DEBUGLOG(fmt, args...)\
do {\
if (log_file == NULL) {\
log_file = fopen((current_process == PROCESS_LAUNCHD) ? LAUNCHD_LOG_PATH : XPCPROXY_LOG_PATH, "a"); \
if (log_file == NULL) break; \
} \
fprintf(log_file, fmt "\n", ##args); \
fflush(log_file); \
} while(0)
#else
#define DEBUGLOG(fmt, args...)
#endif

#define PSPAWN_PAYLOAD_DYLIB "/electra/pspawn_payload.dylib"
#define AMFID_PAYLOAD_DYLIB "/electra/amfid_payload.dylib"
#define SBINJECT_PAYLOAD_DYLIB "/usr/lib/TweakInject.dylib"

// since this dylib should only be loaded into launchd and xpcproxy
// it's safe to assume that we're in xpcproxy if getpid() != 1
enum currentprocess {
    PROCESS_LAUNCHD,
    PROCESS_XPCPROXY,
};

int current_process = PROCESS_XPCPROXY;

#define JAILBREAKD_COMMAND_ENTITLE_AND_SIGCONT 2
#define JAILBREAKD_COMMAND_ENTITLE_AND_SIGCONT_FROM_XPCPROXY 3

kern_return_t bootstrap_look_up(mach_port_t port, const char *service, mach_port_t *server_port);

mach_port_t jbd_port;

const char* xpcproxy_blacklist[] = {
    "com.apple.diagnosticd",  // syslog
    "MTLCompilerService",     // ?_?
    "mapspushd",              // stupid Apple Maps
    "OTAPKIAssetTool",        // h_h
    "cfprefsd",               // o_o
    "jailbreakd",             // don't inject into jbd since we'd have to call to it
    NULL
};

typedef int (*pspawn_t)(pid_t * pid, const char* path, const posix_spawn_file_actions_t *file_actions, posix_spawnattr_t *attrp, char const* argv[], const char* envp[]);

pspawn_t old_pspawn, old_pspawnp;

int fake_posix_spawn_common(pid_t * pid, const char* path, const posix_spawn_file_actions_t *file_actions, posix_spawnattr_t *attrp, char const* argv[], const char* envp[], pspawn_t old) {
    DEBUGLOG("We got called (fake_posix_spawn)! %s", path);
    
    const char *inject_me = NULL;
    
    if (current_process == PROCESS_LAUNCHD) {
        if (strcmp(path, "/usr/libexec/xpcproxy") == 0) {
            inject_me = PSPAWN_PAYLOAD_DYLIB;
            
            const char* startd = argv[1];
            if (startd != NULL) {
                const char **blacklist = xpcproxy_blacklist;
                
                while (*blacklist) {
                    if (strcmp(startd, *blacklist) == 0) {
                        DEBUGLOG("xpcproxy for '%s' which is in blacklist, not injecting", startd);
                        inject_me = NULL;
                        break;
                    }
                    
                    ++blacklist;
                }
            }
        }
    } else if (current_process == PROCESS_XPCPROXY) {
        // XXX inject both SBInject & amfid payload into amfid?
        // note: DYLD_INSERT_LIBRARIES=libfoo1.dylib:libfoo2.dylib
        if (strcmp(path, "/usr/libexec/amfid") == 0) {
            DEBUGLOG("Starting amfid -- special handling");
            inject_me = AMFID_PAYLOAD_DYLIB;
        } else {
            inject_me = SBINJECT_PAYLOAD_DYLIB;
        }
    }
    
    // XXX log different err on inject_me == NULL and nonexistent inject_me
    if (inject_me == NULL || !file_exist(inject_me)) {
        DEBUGLOG("Nothing to inject");
        return old(pid, path, file_actions, attrp, argv, envp);
    }
    
    DEBUGLOG("Injecting %s into %s", inject_me, path);
    
#ifdef PSPAWN_PAYLOAD_DEBUG
    if (argv != NULL){
        DEBUGLOG("Args: ");
        const char** currentarg = argv;
        while (*currentarg != NULL){
            DEBUGLOG("\t%s", *currentarg);
            currentarg++;
        }
    }
#endif
    
    int envcount = 0;
    
    if (envp != NULL){
        DEBUGLOG("Env: ");
        const char** currentenv = envp;
        while (*currentenv != NULL){
            DEBUGLOG("\t%s", *currentenv);
            if (strstr(*currentenv, "DYLD_INSERT_LIBRARIES") == NULL) {
                envcount++;
            }
            currentenv++;
        }
    }
    
    char const** newenvp = malloc((envcount+2) * sizeof(char **));
    int j = 0;
    for (int i = 0; i < envcount; i++){
        if (strstr(envp[j], "DYLD_INSERT_LIBRARIES") != NULL){
            continue;
        }
        newenvp[i] = envp[j];
        j++;
    }
    
    char *envp_inject = malloc(strlen("DYLD_INSERT_LIBRARIES=") + strlen(inject_me) + 1);
    
    envp_inject[0] = '\0';
    strcat(envp_inject, "DYLD_INSERT_LIBRARIES=");
    strcat(envp_inject, inject_me);
    
    newenvp[j] = envp_inject;
    newenvp[j+1] = NULL;
    
#if PSPAWN_PAYLOAD_DEBUG
    DEBUGLOG("New Env:");
    const char** currentenv = newenvp;
    while (*currentenv != NULL){
        DEBUGLOG("\t%s", *currentenv);
        currentenv++;
    }
#endif
    
    posix_spawnattr_t attr;
    
    posix_spawnattr_t *newattrp = &attr;
    
    if (attrp) {
        newattrp = attrp;
        short flags;
        posix_spawnattr_getflags(attrp, &flags);
        flags |= POSIX_SPAWN_START_SUSPENDED;
        posix_spawnattr_setflags(attrp, flags);
    } else {
        posix_spawnattr_init(&attr);
        posix_spawnattr_setflags(&attr, POSIX_SPAWN_START_SUSPENDED);
    }
    
    int origret;
    
#define FLAG_ATTRIBUTE_XPCPROXY (1 << 17)
    
    if (current_process == PROCESS_XPCPROXY) {
        // dont leak logging fd into execd process
#ifdef PSPAWN_PAYLOAD_DEBUG
        if (log_file != NULL) {
            fclose(log_file);
            log_file = NULL;
        }
#endif
        jbd_call(jbd_port, JAILBREAKD_COMMAND_ENTITLE_AND_SIGCONT_FROM_XPCPROXY, getpid());
        // dont leak jbd fd into execd process
        origret = old(pid, path, file_actions, newattrp, argv, newenvp);
    } else {
        int gotpid;
        origret = old(&gotpid, path, file_actions, newattrp, argv, newenvp);
        
        if (origret == 0) {
            if (pid != NULL) *pid = gotpid;
            jbd_call(jbd_port, JAILBREAKD_COMMAND_ENTITLE_AND_SIGCONT, gotpid);
        }
    }
    
    return origret;
}


int fake_posix_spawn(pid_t * pid, const char* file, const posix_spawn_file_actions_t *file_actions, posix_spawnattr_t *attrp, const char* argv[], const char* envp[]) {
    return fake_posix_spawn_common(pid, file, file_actions, attrp, argv, envp, old_pspawn);
}

int fake_posix_spawnp(pid_t * pid, const char* file, const posix_spawn_file_actions_t *file_actions, posix_spawnattr_t *attrp, const char* argv[], const char* envp[]) {
    return fake_posix_spawn_common(pid, file, file_actions, attrp, argv, envp, old_pspawnp);
}


void rebind_pspawns(void) {
    struct rebinding rebindings[] = {
        {"posix_spawn", (void *)fake_posix_spawn, (void **)&old_pspawn},
        {"posix_spawnp", (void *)fake_posix_spawnp, (void **)&old_pspawnp},
    };
    
    rebind_symbols(rebindings, 2);
}

void* thd_func(void* arg){
    NSLog(@"In a new thread!");
    rebind_pspawns();
    return NULL;
}

__attribute__ ((constructor))
static void ctor(void) {
    if (getpid() == 1) {
        if (host_get_special_port(mach_host_self(), HOST_LOCAL_NODE, 15, &jbd_port)) {
            DEBUGLOG("Can't get hgsp15 :(");
            return;
        }
        DEBUGLOG("Got jbd port: %x", jbd_port);
        
        current_process = PROCESS_LAUNCHD;
        pthread_t thd;
        pthread_create(&thd, NULL, thd_func, NULL);
    } else {
        if (bootstrap_look_up(bootstrap_port, "org.coolstar.jailbreakd", &jbd_port)) {
            DEBUGLOG("Can't get bootstrap port :(");
            return;
        }
        DEBUGLOG("Got jbd port: %x", jbd_port);
        
        current_process = PROCESS_XPCPROXY;
        rebind_pspawns();
    }
}
