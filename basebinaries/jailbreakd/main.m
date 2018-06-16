#import <Foundation/Foundation.h>
#import <os/log.h>
#include <pthread.h>
#include <mach/mach.h>
#include <mach/error.h>
#include <mach/message.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "kexecute.h"
#include "kern_utils.h"
#include "patchfinder64.h"
#include "mach/jailbreak_daemonServer.h"

#define CS_OPS_STATUS       0   /* return status */

#define CS_GET_TASK_ALLOW    0x0000004    /* has get-task-allow entitlement */
#define CS_INSTALLER        0x0000008    /* has installer entitlement */

#define    CS_HARD            0x0000100    /* don't load invalid pages */
#define    CS_KILL            0x0000200    /* kill process if it becomes invalid */
#define CS_RESTRICT        0x0000800    /* tell dyld to treat restricted */

#define CS_PLATFORM_BINARY    0x4000000    /* this is a platform binary */

#define CS_DEBUGGED         0x10000000  /* process is currently or has previously been debugged and allowed to run with invalid pages */

int csops(pid_t pid, unsigned int  ops, void * useraddr, size_t usersize);

#define PROC_PIDPATHINFO_MAXSIZE  (1024)
int proc_pidpath(pid_t pid, void *buffer, uint32_t buffersize);

typedef boolean_t (*dispatch_mig_callback_t)(mach_msg_header_t *message, mach_msg_header_t *reply);
mach_msg_return_t dispatch_mig_server(dispatch_source_t ds, size_t maxmsgsz, dispatch_mig_callback_t callback);
kern_return_t bootstrap_check_in(mach_port_t bootstrap_port, const char *service, mach_port_t *server_port);

#define MEMORYSTATUS_CMD_SET_JETSAM_TASK_LIMIT 6
int memorystatus_control(uint32_t command, int32_t pid, uint32_t flags, void *buffer, size_t buffersize);

int remove_memory_limit(void) {
    // daemons run under launchd have a very stingy memory limit by default, we need
    // quite a bit more for patchfinder so disable it here
    // (note that we need the com.apple.private.memorystatus entitlement to do so)
    pid_t my_pid = getpid();
    return memorystatus_control(MEMORYSTATUS_CMD_SET_JETSAM_TASK_LIMIT, my_pid, 0, NULL, 0);
}

#define JAILBREAKD_COMMAND_ENTITLE 1
#define JAILBREAKD_COMMAND_ENTITLE_AND_SIGCONT 2
#define JAILBREAKD_COMMAND_ENTITLE_AND_SIGCONT_FROM_XPCPROXY 3
#define JAILBREAKD_COMMAND_FIXUP_SETUID 4

int is_valid_command(uint8_t command) {
    return (command == JAILBREAKD_COMMAND_ENTITLE ||
            command == JAILBREAKD_COMMAND_ENTITLE_AND_SIGCONT ||
            command == JAILBREAKD_COMMAND_ENTITLE_AND_SIGCONT_FROM_XPCPROXY ||
            command == JAILBREAKD_COMMAND_FIXUP_SETUID);
}

int handle_command(uint8_t command, uint32_t pid) {
    if (!is_valid_command(command)) {
        fprintf(stderr,"Invalid command recieved.\n");
        return 1;
    }
    
    if (command == JAILBREAKD_COMMAND_ENTITLE) {
#ifdef JAILBREAKDDEBUG
        fprintf(stderr,"JAILBREAKD_COMMAND_ENTITLE PID: %d\n", pid);
#endif
        setcsflagsandplatformize(pid);
    }
    
    if (command == JAILBREAKD_COMMAND_ENTITLE_AND_SIGCONT) {
#ifdef JAILBREAKDDEBUG
        fprintf(stderr,"JAILBREAKD_COMMAND_ENTITLE_AND_SIGCONT PID: %d\n", pid);
#endif
        setcsflagsandplatformize(pid);
        kill(pid, SIGCONT);
    }
    
    if (command == JAILBREAKD_COMMAND_ENTITLE_AND_SIGCONT_FROM_XPCPROXY) {
#ifdef JAILBREAKDDEBUG
        fprintf(stderr,"JAILBREAKD_COMMAND_ENTITLE_AND_SIGCONT_FROM_XPCPROXY PID: %d\n", pid);
#endif
        __block int PID = pid;
        
        dispatch_queue_t queue = dispatch_queue_create("org.coolstar.jailbreakd.delayqueue", NULL);
        dispatch_async(queue, ^{
            char pathbuf[PROC_PIDPATHINFO_MAXSIZE];
            bzero(pathbuf, sizeof(pathbuf));
            
            int tries = 0;
            int ret = proc_pidpath(PID, pathbuf, sizeof(pathbuf));
            while (ret > 0 && strcmp(pathbuf, "/usr/libexec/xpcproxy") == 0 && tries < 5000){
                proc_pidpath(PID, pathbuf, sizeof(pathbuf));
                usleep(100);
                tries++;
            }
            if (tries >= 5000){
                fprintf(stderr, "Warning: xpcproxy timer timed out for PID %d\n", pid);
            }
            
            uint32_t flags;
            csops(pid, CS_OPS_STATUS, &flags, 0);
#ifdef JAILBREAKDDEBUG
            fprintf(stderr, "Waiting for CSFlags to reset for PID %d...\n", pid);
#endif
            
            tries = 0;
            while ((flags & (CS_PLATFORM_BINARY | CS_INSTALLER | CS_GET_TASK_ALLOW | CS_DEBUGGED)) != 0 &&
                   (flags & (CS_RESTRICT | CS_HARD | CS_KILL)) == 0 &&
                   tries < 5000){
                csops(pid, CS_OPS_STATUS, &flags, 0);
                usleep(100);
                tries++;
            }
            
            if (tries >= 5000){
                fprintf(stderr, "Warning: CSFlag timer timed out for PID %d\n", pid);
            }
            
            setcsflagsandplatformize(PID);
            kill(PID, SIGCONT);
#ifdef JAILBREAKDDEBUG
            fprintf(stderr,"Called SIGCONT on pid %d from ENTITLE_AND_SIGCONT_FROM_XPCPROXY\n", PID);
#endif
        });
        dispatch_release(queue);
    }
    
    if (command == JAILBREAKD_COMMAND_FIXUP_SETUID) {
#ifdef JAILBREAKDDEBUG
        fprintf(stderr,"JAILBREAKD_FIXUP_SETUID PID: %d\n", pid);
#endif
        fixupsetuid(pid);
    }
    return 0;
}

kern_return_t jbd_call(mach_port_t server_port, uint8_t command, uint32_t pid) {
#ifdef JAILBREAKDDEBUG
    fprintf(stderr,"[Mach] New call from %x: command %x, pid %d\n", server_port, command, pid);
#endif
    return (handle_command(command, pid) == 0) ? KERN_SUCCESS : KERN_FAILURE;
}

mach_port_t tfpzero;
uint64_t kernel_base;
uint64_t kernel_slide;
extern unsigned offsetof_ip_kobject;

int main(int argc, char **argv, char **envp) {
    fprintf(stderr,"jailbreakd: start\n");

    unlink("/var/run/jailbreakd.pid");

    kernel_base = strtoull(getenv("KernelBase"), NULL, 16);
    remove_memory_limit();

    kern_return_t err = host_get_special_port(mach_host_self(), HOST_LOCAL_NODE, 4, &tfpzero);
    if (err != KERN_SUCCESS) {
        fprintf(stderr,"host_get_special_port 4: %s\n", mach_error_string(err));
        return 5;
    }

    init_kernel(kernel_base, NULL);
    // Get the slide
    kernel_slide = kernel_base - 0xFFFFFFF007004000;
    fprintf(stderr,"jailbreakd: slide: 0x%016llx\n", kernel_slide);

    // prime offset caches
    find_allproc();
    find_add_x0_x0_0x40_ret();
    find_OSBoolean_True();
    find_OSBoolean_False();
    find_zone_map_ref();
    find_osunserializexml();
    find_smalloc();
    init_kexecute();

    term_kernel();
    
    @autoreleasepool {
        // set up mach stuff
        mach_port_t server_port;
        
        if ((err = bootstrap_check_in(bootstrap_port, "org.coolstar.jailbreakd", &server_port))) {
            fprintf(stderr,"Failed to check in: %s\n", mach_error_string(err));
            return -1;
        }
        
        dispatch_source_t server = dispatch_source_create(DISPATCH_SOURCE_TYPE_MACH_RECV, server_port, 0, dispatch_get_main_queue());
        dispatch_source_set_event_handler(server, ^{
            dispatch_mig_server(server, jbd_jailbreak_daemon_subsystem.maxsize, jailbreak_daemon_server);
        });
        dispatch_resume(server);
        
        fprintf(stderr,"it never fails to strike its target, and the wounds it causes do not heal\n");
        fprintf(stderr,"in other words, MIG is online\n");
        
        int fd = open("/var/run/jailbreakd.pid", O_WRONLY | O_CREAT, 0600);
        char mmmm[8] = {0};
        int sz = snprintf(mmmm, 8, "%d", getpid());
        write(fd, mmmm, sz);
        close(fd);
        
        fprintf(stderr,"jailbreakd: dumped pid\n");
        
        dispatch_main();
    }

    return EXIT_FAILURE;
}
