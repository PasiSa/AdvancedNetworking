---
---

# Assignment: IP Tunnel

In this assignment we will get familiar with the Linux TUN network device that
can be used to implement IP tunnels between two end points, and play around with
it a bit. The assignment is split into five phases, each containing questions
that you should answer in MyCourses.

There is a Rust
**[task template](https://github.com/PasiSa/AdvancedNetworking/tree/main/assignments/task-tun)**
available, if you want to use the Rust **[tun crate](https://crates.io/crates/tun)**
to implement this task. The template has some placeholders for MIO event
multiplexing, but can use also other approach.

## Phase 1: Setting up namespace environment

Let's set up a simple network environment without Mininet this time on which we
will deploy the tunnel. Set up a network namespace using the provided
**[setup.sh](setup.sh)** script.

**Questions:**

- **(1):** What is the IP address at the network namespace side of the virtual
  Ethernet interface pair?

- **(2):** What is the IP address at the host side of the virtual Ethernet
  interface pair?

- **(3):** Test with ping from inside the namespace that the connection works
  over the veth pair. What command did you use to start ping inside the
  namespace?

## Phase 2: Plain UDP tunnel

Set up a TUN interface so that the local IP address at the namespace is
10.100.0.2 and in the host (root) system the IP address is 10.100.0.1. Implement
a program that reads IP packets from TUN interface and sends them in UDP
datagrams that are sent either to 192.168.76.1 (from namespace) or to
192.168.76.2 (from host). Implement also the opposite direction from UDP
datagrams into TUN device. If you use Rust, the
**[tun](https://crates.io/crates/tun)** crate is useful helper tool for this. If
you don't want to use the library, or you are using another programming
language, you will need to create the TUN interface manually, for example on the
command line. After this the TUN endpoint can be found in the Linux file system
at `/dev/net/tun` which you can read and write using normal I/O operations. In
this case you will also need to set the IP address and other interface
parameters to the created TUN interface by other means, for example using the
`ip` tool in command line shell.

![Network setup in assignment](/assignments/task-tun/namespaces.png "Network setup in assignment")

Note that you need to handle two input sources concurrently in your program: the
UDP socket, and the TUN device end point. You can apply any of the approaches
introduced earlier with TCP servers for this (I/O multiplexing, threads, etc.).

In your program, print the destination IP address, packet length and the
protocol identifier for each tunneled IP packet arriving from tunnel UDP socket.
You can assume that all packets are IPv4, and there are no IPv6 packets. You can
see the layout and byte offsets of IPv4 protocol fields in
**[RFC 791](https://datatracker.ietf.org/doc/html/rfc791)**, section 3.1.
If the IP packet contains UDP header (protocol ID 17) or TCP header (protocol ID
6), print also the destination port number. Remember that the port is a 16-bit
value stored in network byte order in the transport protocol header that follows
right after IP header in the packet. The TCP header is shown in
**[RFC 9293](https://datatracker.ietf.org/doc/html/rfc9293)**, section 3.1.
UDP is specified in **[RFC 768](https://datatracker.ietf.org/doc/html/rfc768)**.

Test by pinging address 10.100.0.1 from inside the namespace that the tunnel
works.

**Question:**

- **(4) and (5):** What is the protocol ID and packet length for the ping
  packets? Note that in addition to the ping packets, there may be also other
  traffic going over the tunnel, as sent by the operating system.

If ping works as expected, test TCP and UDP traffic using the _netcat_ tool.
Start server on one side of the tunnel, and client on the other side. Here are
the useful command line examples:

    nc -l 9000  # Start TCP server listening to port 9000
    nc 10.100.0.1 9000  # Connect to TCP server in IP address 10.100.0.1, port 9000
    nc -u -l 9000  # Same for UDP server
    nc -u 10.100.0.1 9000  # Same for UDP client

**Question:**

- **(6):** What is the shortest TCP packet you see? Those are common, for
  example when acknowledgments are generated for data that you send using
  _netcat_.

# Phase 3: Traffic limitations

Let's assume that you are elected as a leader of a great nation. As one of the
first steps you want to build a firewall that prevents access to content that
seems unnecessary to your citizens. You provide your UDP tunnel through the
firewall to give a (limited) access to the rest of the world, but want to
enforce certain limitations and policies on the traffic.

Modify your tunnel program in two ways:

1. If a packet that arrives from the UDP socket or the TUN device contains
   string "taylor", it will not be forwarded but just ignored (i.e., dropped).
   Print an output message to the terminal about this incident, in addition to
   the other packet header information implemented in previous phase. The string
   matching should be case insensitive, so for example "Taylor", "TAYLOR" or
   "TaYlOr" are not allowed either.

2. If a packet that arrives from the TUN device contains string "donald", it
   should be duplicated, i.e. forwarded as two similar UDP datagrams, to ensure
   more reliable delivery. Also in this case the string matching should be case
   insensitive.

To test your enhanced tunnel, start netcat **UDP server** at one end, and netcat
**UDP client** at another end, as shown in above examples, and type the
following lines at the client. Type the lines one by one, with small pause
between them (i.e., don't just copy-paste all the lines at once):

    hello
    Donald
    moi
    taylor
    travis
    TAYLOR
    bye

**Questions:**

- **(7):** Report the server output, i.e. what arrives over the tunnel, after
  typing the above lines

- **(8):** After this, start netcat server and client using TCP, and repeat the
  above input at client. Report the server output also in this case. Presumably
  the output is different in the two cases. Give you analysis about what happens
  after each line is sent to the socket, and why there is difference to UDP case
  (if there is difference).

# Phase 4: Connecting to the Internet

Let's connect our tunnel to the Internet, assuming that you are running this
assignment in environment with Internet connection, that you virtual (or native)
Linux machine can use the network.

In the host namespace, after starting the tunnel, we need to enable IP packet
forwarding and set up network address translation as iptables hook. When
forwarding packets between your tunnel and the Internet, the Linux NAT hook
replaces the tunnel IP address with the host machine IP address. In the common
case that you are running a virtual machine, you are likely having another NAT
in your system, translating the virtual machine IP into the actual IP you have
got for your machine from the Internet. We do not need to worry about that,
though. The NAT can be enabled as follows:

    sudo iptables -t nat -A POSTROUTING -s 10.100.0.0/24 -o enp0s5 -j MASQUERADE

You will need to change the network interface name after `-o` option into one
that your Linux system is using.

Enable IP forwarding in the host namespace:

    sudo sysctl -w net.ipv4.ip_forward=1

In the created `ns1` namespace you will need to add default route to the tunnel,
for all IP packets that do not have any more specific entry in the forwarding
table:

    sudo ip netns exec ns1 ip route add default via 10.100.0.1

In the `ns1` namespace, we will also need to configure the DNS server:

    mkdir -p /etc/netns/ns1
    bash -c 'echo "nameserver 8.8.8.8" > /etc/netns/ns1/resolv.conf'

At 8.8.8.8 there is a public DNS server maintained by Google. `resolv.conf` is
the location where nameservers are configured in Linux. Different network
namespaces can also have separate configuration domains, as we have here.

From inside the namespace, try a couple of HTTP requests using curl, assuming
that now all traffic is forwarded through your special tunnel:

    curl https://www.taylorswift.com
    curl https://en.wikipedia.org/wiki/Zachary_Taylor

Sometimes the TUN device may become slow or unresponsive after sending more
data. In such case it may help if you restart your tunnel interface and try
again. If you do that, you will probably need to reconfigure the default route
and NAT.

You could also try launching a web browser inside the namespace, to get more
graphical experience.

**Question:**

- **(9):** Report your observations, and your analysis about why HTTP delivery
  succeeded or did not succeed with above HTTP requests, given that the tunnel
  traffic limitations implemented in previous phase are applied.

# Phase 5: Encryption

Finally, you will take the role of a opposition leader and implement a simple
"encryption" to your tunneled traffic to counter the suspected traffic filtering
activities. The encryption algorithm is simple in this case: before sending data
to UDP socket, add 3 to the value of each `u8` byte read from the TUN device.
For the opposite direction, from UDP socket to the TUN device, you will
respectively need to decrement the value of each byte by 3, to decrypt the
traffic at the other side of the tunnel. To save time, you can use the same
implementation than in previous phases. In this case you should add "encryption"
before the string matching logic for filtering or duplicating content on certain
words.

Finally, upload your tunnel code to MyCourses.
