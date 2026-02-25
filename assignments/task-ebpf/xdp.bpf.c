/* Generate vmlinux.h:
   bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h

   Compile (on a Mac / Parallels):
   clang -O2 -g -target bpf -D__TARGET_ARCH_x86   -I/usr/include -I/usr/include/$(uname -m)-linux-gnu -c xdp.bpf.c -o xdp.bpf.o
*/

#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>

// Some possible needed type identifiers for Ethernet frame
#define ETH_P_IP 0x0800  // IPv4
#define ETH_P_8021Q 0x8100  // IEEE 802.1Q VLAN
#define ETH_P_8021AD 0x88A8  // IEEE 802.1ad VLAN bridge 

// TODO: Define a map array struct for counting packets


SEC("xdp")
int xdp_count_and_filter(struct xdp_md *ctx)
{
    void *data     = (void *)(long)ctx->data;
    void *data_end = (void *)(long)ctx->data_end;

    // TODO: parse Ethernet header

    /* TODO: If IPv4, parse IPv4 header
       - If protocol in IPv4 header is TCP, parse TCP header
          - If destination port is 443, adjust counter, pass packet forward
          - If destination port is 80, adjust counter, drop packet
       - If protocol in IPv4 header is UDP, parse UDP header
          - If destination port is 443, adjust counter, pass packet forward
       - If protocol in IPv4 header is ICMP, adjust counter

       In all cases except TCP port 80, the packet should be passed forward
     */
}
