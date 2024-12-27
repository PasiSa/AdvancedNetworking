# Socket programming basics

_Warning: this section is still work in progress, and not yet complete._

Socket is the basic programming interface between user space applications and
operating system. Commonly, socket encapsulates one communication session
between the local application and a remote peer, for example in most common
case, one TCP connection. Sockets can, however, also be used as a control
interface between applications and kernel, for example to control network
routing behavior.

## Different types of sockets

The two most common socket types are **stream sockets** and **datagram sockets**.

**Stream socket** is used for transmitting reliable byte streams between two end
points. Stream socket is _connection oriented_: a connection needs to be
established first before data transmission can begin, to set up needed
communication state at both ends of the connection. Once connection is
established, either end of the connection can send and receive data. The data is
handled as bidirectional byte pipe: the bytes that are sent at one end of the
connection, are received in the same order at the other end of the connection.
The underlying transport protocol -- almost always TCP -- takes care of reliable
delivery of data: if packets are lost, they will be retransmitted, and data is
buffered at both ends of the connection, so that the bytes can be delivered in
order to the receiving application, without any data missing. The byte stream
abstraction means that application cannot see the packet boundaries, but just
continuous stream of bytes. Possible retransmission and congestion management
operations may cause significant delays in delivery of the bytes, however.

**Datagram socket** is used for transmitting datagrams of specific size to given
destination. Datagram socket is not connection oriented, but it can be connected
to a specific destination if one-to-one communication is desired. Datagram
sockets can also be used for one-to-many communication, for example based on
multicast or broadcast IP delivery. Unlike with stream sockets, datagram socket
preserves the boundaries of a datagram, and if datagram fits into single IP
packet, it will transmitted as a single packet over the network. However,
reliable delivery of datagram is not guaranteed: if a packet is lost in the
network, the datagram is lost as well. Commonly datagrams are transmitted over
UDP protocol, that is a very lightweight protocol without any buffering or other
connection-specific state. Therefore, when datagram is successfully delivered,
there typically are no additional delays, apart that what happens inside network
due to queueing and other behaviors.

The socket type to selected based on the needs of the application. Much of the
traditional internet traffic has consisted of transmitting files and data
objects of various types, these days commonly using web browsers and HTTP
protocol. For such transfers the stream sockets are more suitable alternative
for its properties (although recently, with HTTP/3, this is not anymore exactly
the case, but more about that later). Some internet transfers have stricter time
constraints, for example real-time video calls or many real-time multiplayer
games. In such cases loss of few packets may cause less harm than unbounded
delays on traffic due to network conditions, and therefore datagram socket is a
better alternative. It is good to remember, though, that even with datagram
sockets in internet traffic always has delays that cannot be controlled by the
end host.

There are also other, less commonly used, and is some cases system-specific
socket types: **Raw sockets** can be used when one needs to send packets over IP
protocol using some other protocol than TCP or UDP, for example ICMP or some of
the routing protocols. Linux has **Netlink sockets** that are not intended for
sending any data to network, but are used as a two-way configuration channel
between Linux kernel protocol stack and user-space applications. For example,
the routing tables and various network interface configurations can be managed
using Netlink sockets. Both these socket types require superuser rights.

## Addresses and names

### IP addressing

IP address identifies a host in internet communication. There are different
types of IP addresses, depending on the scope of intended communication, and
typically an end host (e.g. a laptop computer or mobile phone) can have multiple
IP addresses simultaneously in use. Furthermore, there are two versions of IP
protocol, with different length allocated for IP address. The traditional **IPv4
protocol** is still in wide-spread use, and has 32 bits allocated for IP
address. Later, **IPv6 protocol** was specified, with 128 bits allocated for IP
address, along with other changes. Despite its potential benefits over the older
protocol, adoption of IPv6 has taken its time. Therefore, these days the network
stacks in operating systems support these both protocol versions, and it is
possible to see traffic using either protocol, depending on the destination.

In the below material we use the **Classless Inter-Domain Routing (CIDR)** form
of describing IP address blocks. If you are not familiar with the concept, e.g.
[Wikipedia](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing) gives
a quick overview. Wikipedia is also a good initial source, if you are not
familiar with [IPv6 address](https://en.wikipedia.org/wiki/IPv6_address)
representations.

The different types of IP addresses are:

- **Host-local** (or loopback) addresses (e.g. in IPv4: 127.0.0.1, or in IPv6
  ::1), that are not forwarded outside of the local machine. These are useful,
  for example, when developing network applications, and testing their
  interoperation in local system.

- **Link-local addresses** are available for communication between the
  hosts in the same subnetwork, but are not routed forward by IP routers. They
  can be used, for example, by configuration or discovery protocols with a
  single office of an organization. The address blocks reserved for
  subnetwork-local addresses are 169.254.0.0/16 in IPv4, or fe80::/64 in IPv6.

- **Private addresses** are not intended for global internet communication, and
  must not be routed to the global internet, but can be used within
  organizational networks. The benefit for organizations for doing so is that
  these addresses do not need to be specifically allocated from network
  operators (which typically involves cost), but can be allocated by local
  decision. Private addresses are commonly seen also in home networks: often a
  home subscriber is allocated only a single global IP address. Because commonly
  there are multiple IP devices at home (computers, mobile devices,
  playstations, ...), the gateway allocates private addresses to these devices, and
  substitutes the address to a shared global address before forwarding packets
  to the Internet, i.e., performing **Network Address Translation (NAT)**. There
  are different private address spaces, for example in IPv4: 10.0.0.0/8,
  172.16.0.0/12, 192.168.0.0/16. In IPv6 addresses with prefix fc00::/7 and
  fd00::/8 are in such use.

There are also a few other special address ranges, which we omit for now, but
most addresses not in the above-mentioned ranges can be assumed to be global IP
addresses.

When a device joins a network, either wirelessly or through Ethernet cable, it
usually learns its IPv4 address (and some other configuration information) using
**[Dynamic Host Configuration Protocol
(DHCP)](https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol)**.
IPv6 supports stateless address autoconfiguration for this purpose, although
DHCP can also be used to manage IPv6 addresses. DHCP shows how broadcast address
(255.255.255.255) can be used in a discovery mechanism. The host first sends a
discovery message using UDP to a particular UDP port using the broadcast
message. If there is a DHCP server in the local network, it will respond by
offering an IP address, along with some other configuration information. The
DHCP server tracks which addresses are allocated and which are free, i.e., it is
stateful (and therefore a possible failure point in the network). The address
allocations have a lease time, after which they can be released to other use.
Therefore a client machine needs to refresh the allocation periodically.

### Name resolution

Applications rarely use IP addresses directly, but DNS names are used to map
more or less human-readable names into IP addresses. DNS is a distributed
database service traditionally built over UDP, although these days also other
protocols can be used. DNS is also often used as a tool for load balancing and
service distribution over larger content delivery networks. For now we do not go
into the DNS operation in more detail, but take a look at it from network
application programmer's perspective.

In classic socket programming, only IP addresses and transport ports are used to
identify sockets in binary socket address structures. Therefore, when given a
DNS name, a client application needs to take a separate step to resolve a given
name into IP address. DNS name resolution can take time, and it may give
multiple IP addresses in response to a name query. For a given name, there may
be address entries for both IPv4 and IPv6 addresses. If one of the addresses
does not respond, for example, because it is an IPv6 address, but local network
does not support IPv6 routing, a client application may need to try several of
the provided addresses before a connection succeeds.

### Transport-level addressing: ports

Because modern systems typically run several networked applications in parallel,
IP address is not sufficient to identify the socket where a packet and its data
is destined to. Therefore, in addition to IP address, a 16-bit port number is
needed to exactly identify the socket where data should be delivered. For
connection-oriented TCP, a connection can be identified with a four-tuple: all
packets belonging to same connection should have same source and destination IP
addresses, and source and destination ports.

In addition to their primary purpose of providing multiplexing of traffic
between hosts, ports are also used to identify different services at the server.
The **Internet Assigned Numbers Authority (IANA)** has allocated specific ports
for specific services in the Internet. For example, it is agreed that the _ssh_
protocol server listens to incoming TCP connections at port 22, non-secure HTTP
listens to connections at port 80, and TLS-secured HTTPS listens to connections
at port 443. Port numbers below 1024 are called **well-known ports** as being
allocated for widely deployed services. In most systems server has to be
executed with superuser permissions to be able to bind to use these ports. Port
numbers between 1024 and 49152 need to be registered with IANA for a particular
service, but are usually available without superuser permissions.

Also the client side of connection needs to allocate port, but the exact port
number is not important for the purpose of identifying a service. Unless
application specifically pick (i.e., "bind") a port, the system automatically
chooses an available number from the ephemeral ports, between 49152 and 65535.

## Traditional C sockets

Although many of the later examples will use _Rust_, it is useful to see a basic
C program that resolves name, opens a connection and writes and reads some data
to socket. In most operating systems, the native interface between applications
and kernel is defined in C language, that compiles to a binary interface between
the two parts, and therefore getting a view of how connection is established in
C helps in understanding how the application/OS interface works, also when using
higher-level interfaces in other programming languages.

We will only give a brief tutorial of socket programming in C. If you are
interested to learn more, for example the [Beej's
guide](https://beej.us/guide/bgnet/html/split/index.html) tells a little bit
more about the topic.

Next, we will walk through the C example that can be found in [the examples
directory](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/c/simple-client.c)
Assuming you have GNU C compiler in your system, you can compile the program on
your command line terminal by:

    gcc simple-client.c

And, assuming compile is successful, execute the program by:

    ./a.out <name/address> <service/port> <string>

To test the little program, you can use the netcat tool to play a TCP server
socket as follows, to listen for a TCP connection on port 2000:

    nc -l 2000

and then, on another terminal window run:

    ./a.out localhost 2000 hello

Type something on the netcat window to send back a string to the socket to
complete the program.

Next, we will walk through what the program does. The most interesting part
happens in `tcp_connect` function, that is called in the beginning of the `main`
function, after parsing command line arguments. The function resolves given DNS
name (or IP address) and service name (or TCP port) into a socket address
structure that contains needed information for the kernel to try establishing
TCP connection.

`tcp_connect` first calls the `getaddrinfo` function, that returns a linked list
of `addrinfo` structures. For a given name, there may be multiple IPv4 and IPv6
addresses in the DNS database, hence the `tcp_connect` function iterates through
each of these until connection is successful. This structure contains all
necessary parameters needed to create a socket and open a connection.

    if ( (n = getaddrinfo(host, serv, &hints, &res)) != 0) {
        fprintf(stderr, "Failure in name resolution\n");
        return -1;
    }

When creating a socket, `ai_family` in the returned `addrinfo` structure is the
address family, typically either AF_INET (IPv4) or AF_INET6 (IPv6).
`ai_socktype` tells whether the socket is stream or datagram socket. In this
case it is always a stream socket, i.e. TCP, because we specified that in
incoming hints parameter to the function. `ai_protocol` contains a more detailed
specification of transport protocol, in case it would not be TCP, that is the
default for stream sockets.

If socket creation is successful, the `connect` call establishes the connection.
This starts TCP three-way handshake, and the call completes when handshake is
completed. Note that this may take time in some cases: the TCP SYN segment may
be dropped in the network, in which case TCP tries to retransmit it -- multiple
times if necessary. If the destination is unreachable, by default TCP tries for
1-2 minutes before giving up, in which case the `connect` call would return an
error, so the execution of the program could block to this call for some time in
worst case.

The `ai_addr` parameter that is given to the `connect` call is a sockaddr
structure, more specifically, `sockaddr_in` in the case of AF_INET address
family and IPv4 address.

    struct sockaddr_in {
        short            sin_family;   // e.g. AF_INET
        unsigned short   sin_port;     // e.g. htons(3490)
        struct in_addr   sin_addr;     // see struct in_addr, below
        char             sin_zero[8];  // zero this if you want to
    };

    struct in_addr {
        unsigned long s_addr;  // load with inet_aton()
    };

Essentially, this structure contains 32-bit IPv4 address and 16-bit TCP port. A
common practice in Internet standardization is, that all binary number larger
than a byte are encoded in **big endian byte order**, also known as network byte
order. Most current systems, particularly Intel systems and current Mac
processors are little-endian, and therefore the byte order needs to be swapped
before values are passed to the function. In C, functions `ntohs` (for 16 bits)
and `ntohl` (for 32 bits) are intended for this purpose. For IPv4 addresses we
are accustomed to see the dotted decimal notation of four 8-bit decimal numbers
separated by dots, but this is just a representation format for a 32-bit value.

## Higher level network APIs

_TODO: C++ does not have specific socket support in standard library. But there
are library collections such as Boost or Qt that provide easier APIs._

_TODO: Rust example_

## Socket buffers and flow control

_TODO_