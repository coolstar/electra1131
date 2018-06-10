#include "libjailbreak_mig.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <mach/mach.h>
#include "mach/jailbreak_daemonUser.h"
#include <dispatch/dispatch.h>

kern_return_t bootstrap_look_up(mach_port_t port, const char *service, mach_port_t *server_port);

#define JAILBREAKD_COMMAND_ENTITLE 1
#define JAILBREAKD_COMMAND_ENTITLE_AND_SIGCONT 2
#define JAILBREAKD_COMMAND_ENTITLE_AND_SIGCONT_FROM_XPCPROXY 3
#define JAILBREAKD_COMMAND_FIXUP_SETUID 4
struct __attribute__((__packed__)) jb_connection {
    mach_port_t jbd_port;
};

typedef void *jb_connection_t;

jb_connection_t jb_connect(void) {
    mach_port_t jbd_port;
    if (bootstrap_look_up(bootstrap_port, "org.coolstar.jailbreakd", &jbd_port) == 0) {
        struct jb_connection *conn = malloc(sizeof(struct jb_connection));
        conn->jbd_port = jbd_port;
        return (jb_connection_t)conn;
    }
    return NULL;
}

void jb_disconnect(jb_connection_t connection) {
    struct jb_connection *conn = (struct jb_connection *)connection;
    mach_port_deallocate(mach_task_self(), conn->jbd_port);
    free(conn);
}

void jb_entitle(jb_connection_t connection, pid_t pid, uint32_t what, jb_callback_t done) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0UL), ^{
        struct jb_connection *conn = (struct jb_connection *)connection;
        int response = jbd_call(conn->jbd_port, JAILBREAKD_COMMAND_ENTITLE, pid);
        done(response);
    });
}

void jb_fix_setuid(jb_connection_t connection, pid_t pid, jb_callback_t done) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0UL), ^{
        struct jb_connection *conn = (struct jb_connection *)connection;
        int response = jbd_call(conn->jbd_port, JAILBREAKD_COMMAND_FIXUP_SETUID, pid);

        done(response);
    });
}

int jb_entitle_now(jb_connection_t connection, pid_t pid, uint32_t what) {
    struct jb_connection *conn = (struct jb_connection *)connection;
    return jbd_call(conn->jbd_port, JAILBREAKD_COMMAND_ENTITLE, pid);
}

int jb_fix_setuid_now(jb_connection_t connection, pid_t pid) {   
    struct jb_connection *conn = (struct jb_connection *)connection;
    return jbd_call(conn->jbd_port, JAILBREAKD_COMMAND_FIXUP_SETUID, pid);
}

void jb_oneshot_entitle_now(pid_t pid, uint32_t what) {
    jb_connection_t c = jb_connect();
    jb_entitle_now(c, pid, what);
    jb_disconnect(c);
}

void jb_oneshot_fix_setuid_now(pid_t pid) {
    jb_connection_t c = jb_connect();
    jb_fix_setuid_now(c, pid);
    jb_disconnect(c);
}
