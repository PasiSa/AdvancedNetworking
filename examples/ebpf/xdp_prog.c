/* To compile:
clang -O2 -g -Wall -target bpf -I/usr/include -I/usr/include/$(uname -m)-linux-gnu -c xdp_prog.c -o xdp_prog.o
*/

#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>
#include <linux/if_ether.h>
#include <netinet/ip_icmp.h>

enum counter_id {
    C_ALL_IP = 0,
    C_ICMP   = 1,
    C_MAX    = 2,
};

// We use BPF map array to deliver information about packet counts to user space loader.
// The array has room for 2 items (for counting all IP packets and ICMP packets).
struct {
    __uint(type, BPF_MAP_TYPE_ARRAY);
    __uint(max_entries, C_MAX);
    __type(key, __u32);
    __type(value, __u64);
} packet_cnt SEC(".maps");

SEC("xdp")
int xdp_drop_icmp(struct xdp_md *ctx)
{
    void *data_end = (void *)(long)ctx->data_end;  // pointer to the end of incoming packet
    void *data = (void *)(long)ctx->data; // pointer to the beginning of incoming packet

    struct ethhdr *eth = data;

    // Verify that the data section in packet is long enough to contain Eth header
    // If not done, BPF verifier would raise error
    if ((void *)(eth + 1) > data_end)
        return XDP_PASS;

        // Does the Ethernet frame contain IPv4 packet? If not, let it pass through
        if (eth->h_proto != bpf_htons(ETH_P_IP))
        return XDP_PASS;

    // Verify that the data section in packet is long enough to contain IP header
    // If not done, BPF verifier would raise error
    struct iphdr *ip = (void *)(eth + 1);
    if ((void *)(ip + 1) > data_end)
        return XDP_PASS;

    /* count all IPv4 packets */
    __u32 key = C_ALL_IP;
    __u64 *value = bpf_map_lookup_elem(&packet_cnt, &key);
    if (value)
        // we must use this helper function to adjust the counter value
        __sync_fetch_and_add(value, 1);

    /* drop ICMP and count them, too */
    if (ip->protocol == IPPROTO_ICMP) {
        __u32 key = C_ICMP;
        __u64 *value = bpf_map_lookup_elem(&packet_cnt, &key);
        if (value)
            __sync_fetch_and_add(value, 1);
        return XDP_DROP;
    }

    return XDP_PASS;
}
