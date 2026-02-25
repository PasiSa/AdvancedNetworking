/* To compile: gcc -O2 -Wall loader.c -lbpf -o loader
   To run: sudo ./loader 
*/

#include <stdio.h>
#include <unistd.h>
#include <net/if.h>
#include <bpf/libbpf.h>
#include <bpf/bpf.h>
#include <linux/if_link.h>

enum counter_id {
    C_ALL_IP = 0,
    C_ICMP   = 1,
};

// Fetch a value from BPF map array that is updated by the BPF program
static __u64 count(int map_fd, __u32 key)
{
    __u64 value;
    if (bpf_map_lookup_elem(map_fd, &key, &value)) {
        fprintf(stderr, "error looking up element!\n");
        return 0;
    }
    return value;
}

int main()
{
    struct bpf_object *obj;
    struct bpf_program *prog;
    int ifindex;
    int prog_fd;

    // Network interface we attach the XDP program to. Change as needed.
    // (It would be good idea to make this a command line option).
    ifindex = if_nametoindex("enp0s5");
    if (!ifindex) {
        perror("if_nametoindex");
        return 1;
    }

    // Load the compiled BPF binary to kernel
    obj = bpf_object__open_file("xdp_prog.o", NULL);
    if (!obj) {
        fprintf(stderr, "Failed to open BPF object\n");
        return 1;
    }

    if (bpf_object__load(obj)) {
        fprintf(stderr, "Failed to load BPF object\n");
        return 1;
    }

    // Attach to the named function/program
    prog = bpf_object__find_program_by_name(obj, "xdp_drop_icmp");
    prog_fd = bpf_program__fd(prog);

    int flags = XDP_FLAGS_SKB_MODE;  // Using generic mode, works better in VM
    if (bpf_xdp_attach(ifindex, prog_fd, flags, NULL) < 0) {
        perror("bpf_set_link_xdp_fd");
        return 1;
    }

    // Get handle to the shared packet counters
    int counters_fd = bpf_object__find_map_fd_by_name(obj, "packet_cnt");
    if (counters_fd < 0) {
        perror("count not get BPF counter array");
        return 1;
    }

    printf("XDP program loaded.\n");

    sleep(10);

    printf("Number of IP packets: %llu -- Number of dropped ICMP packets: %llu\n",
            count(counters_fd, C_ALL_IP),
            count(counters_fd, C_ICMP));

    bpf_xdp_detach(ifindex, flags, NULL);
    return 0;
}
