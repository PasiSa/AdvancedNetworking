---
---

# Task: eBPF traffic monitoring

We will write a small eBPF/XDP program that performs simple traffic monitoring
on a few selected protocols on a Linux gateway. To set up the network
environment, we will use **[setup.sh](setup.sh)**, to
set up a namespace for running client applications. The root namespace does NAT
and forwards traffic between the namespace and public Internet.

Write XDP program that does the following:

- Count number of TCP packets to destination port 443 (i.e., HTTPS)
- Count number of UDP packets to destination port 443 (i.e., QUIC)
- Count number of ICMP packets (e.g., for ping)
- Drop TCP packets to destination port 80 (i.e., plaintext HTTP). Count also these packets

You will need to write two C source files. For example, the actual BPF C code
can be in file `xdp.bpf.c`, and the loader that installs the code source file
`loader.c`. In addition, the loader should collect packet counts and print them
to the output the current statistics on the terminal at one-second intervals
following the following format:

    TCP/443=0  UDP/443=0  ICMP=0  dropped:TCP/80=0

There are **[template C
sources](https://github.com/PasiSa/AdvancedNetworking/tree/main/assignments/task-ebpf)**
in the git repository that you can use as a basis. See also the course materials
for example that you can apply here.

Test the following in the ns1 namespace created by setup script, and report
output after each case. How do the counts in XDP loader output change? How do
the client applications behave? Do not shut down loader between the different
parts, but keep it running, so that the counter values are not reset between
tests.

- **(A)** `ping www.aalto.fi`
- **(B)** `curl -v -i http://www.aalto.fi/en/`
- **(C)** `curl -v -i https://www.aalto.fi/en/`
- **(D)** `MY_QUICHE_DIR/target/debug/quiche-client https://www.aalto.fi/en/`

If you shut down the loader and detach the XDP program, how does the behavior
of the client application change in case of (B)?

Upload your code (loader and BPF) to MyCourses.
