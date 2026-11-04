// Link the actual host kernel: signal tracing must work while sys_kill holds
// pids_lock, preserve target groups, and never trace failed/probe requests.
#include <assert.h>
#include <stdio.h>
#include <string.h>
#include "kernel/init.h"
#include "kernel/calls.h"
#include "fs/real.h"

extern void (*runtime_fault_context)(const char *);
static unsigned recorded;
static char evidence[640];
static void observe(const char *line) {
    if (!strncmp(line, "PROCESS_SIGNAL ", 15)) {
        recorded++;
        snprintf(evidence, sizeof evidence, "%s", line);
    }
}
int main(void) {
    assert(mount_root(&realfs, "/") == 0 && become_first_process() == 0);
    struct task *parent = current;
    assert(become_new_init_child() == 0);
    struct task *target = current;
    assert(target->group->pgid == target->pid);
    current = parent;
    assert(become_new_init_child() == 0);
    struct task *other = current;
    assert(other->group->pgid == other->pid);
    current = parent;
    runtime_fault_context = observe;
    assert((int)sys_kill(target->pid, 0) == 0 && recorded == 0);
    assert((int)sys_kill(MAX_PID + 1, SIGKILL_) == _ESRCH && recorded == 0);
    current->uid = current->euid = 1000;
    assert((int)sys_kill(target->pid, SIGKILL_) == _EPERM && recorded == 0);
    current->uid = current->euid = 0;
    assert((int)sys_kill(-target->pid, SIGKILL_) == 0 && recorded == 1);
    assert(sigset_has(target->pending, SIGKILL_));
    assert(!sigset_has(other->pending, SIGKILL_) && !sigset_has(parent->pending, SIGKILL_));
    char expected[80];
    snprintf(expected, sizeof expected, "tid=%d tgid=%d target_tid=%d target_tgid=%d signal=9", parent->pid, parent->tgid, target->pid, target->tgid);
    assert(strstr(evidence, expected) && strstr(evidence, "sender_pid=1 "));
    assert((int)sys_kill(other->pid, SIGTERM_) == 0 && recorded == 2);
    assert(sigset_has(other->pending, SIGTERM_));
    runtime_fault_context = NULL;
    task_discard_unstarted(target);
    task_discard_unstarted(other);
    puts("SIGNAL_EVIDENCE_PASS: actual kernel sender/target, group scope, no pids-lock recursion, probe/ESRCH/EPERM excluded");
    return 0;
}
