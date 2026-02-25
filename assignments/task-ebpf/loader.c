#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <net/if.h>

#include <bpf/libbpf.h>
#include <bpf/bpf.h>
#include <linux/if_link.h>

static volatile sig_atomic_t stop;

static void on_sigint(int signo) { (void)signo; stop = 1; }

static void die(const char *msg)
{
    perror(msg);
    exit(1);
}


int main(int argc, char **argv)
{
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <iface> <xdp.bpf.o>\n", argv[0]);
        return 2;
    }

    const char *ifname = argv[1];
    const char *objfile = argv[2];

    int ifindex = if_nametoindex(ifname);
    if (ifindex == 0) die("if_nametoindex");

    libbpf_set_strict_mode(LIBBPF_STRICT_ALL);

    /* TODO:
        - Load BPF object file
        - Find program (function) by correct name
        - Connect map array
    */

    // TODO: Attach XDP
    __u32 xdp_flags = XDP_FLAGS_SKB_MODE;  // This maybe useful in virtual machines
 
    printf("Attached XDP on %s (ifindex=%d). Press Ctrl-C to stop.\n", ifname, ifindex);

    // Set signal handlers to detect Ctrl-C and gracefully terminate
    signal(SIGINT, on_sigint);
    signal(SIGTERM, on_sigint);

    while (!stop) {
        printf("TCP/443=%llu  UDP/443=%llu  ICMP=%llu  dropped:TCP/80=%llu\n",
                tcp_443,
                udp_443,
                icmp,
                tcp_80);

        sleep(1);
    }

    // TODO: clean up gracefully

    return 0;
}
