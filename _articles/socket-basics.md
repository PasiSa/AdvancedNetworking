---
title: Socket programming basics
---

Socket is the basic programming interface between user space applications and
operating system. Commonly, socket encapsulates one communication session
between the local application and a remote peer, for example in most common
case, one TCP connection. Sockets can, however, also be used as a control
interface between applications and kernel, for example to control network
routing behavior.

This section covers the following topics, some of which may be familiar already
from earlier courses:

- We shortly discuss **different types of sockets** and what they are used for.

- We discuss the basic aspects of **IP addressing, DNS naming and port allocation**,
  that need to be understood when developing network applications.

- We start by discussing the basic **C-level Posix socket API** that is how
  communication sockets have been originally specified, and which the other
  programming languages are based on.

- We discuss similar basic **Rust socket APIs**, which are based on the Posix
  API, with some convenience helpers to make programming little bit easier.

- We cover **byte order and alignment aspects** in systems-level network
  programming, that are important to be understood when writing portable
  networking code that needs to be understood by different system architectures
  across the Internet.

- We discuss how **buffering and flow control** affects the dynamics of
  application-level socket programming.

Finally, you may try the related assignment, "**[Simple
Client](../assignments/task-cli/)**".

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
of our GitHub repository.
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

```c
if ( (n = getaddrinfo(host, serv, &hints, &res)) != 0) {
    fprintf(stderr, "Failure in name resolution\n");
    return -1;
}
```

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

```c
struct sockaddr_in {
    short            sin_family;   // e.g. AF_INET
    unsigned short   sin_port;     // e.g. htons(3490)
    struct in_addr   sin_addr;     // see struct in_addr, below
    char             sin_zero[8];  // zero this if you want to
};

struct in_addr {
    unsigned long s_addr;  // load with inet_aton()
};
```

Essentially, this structure contains a 32-bit IPv4 address and a 16-bit TCP
port. A common practice in Internet standardization is, that all binary numbers
larger than a byte are encoded in **big endian byte order**, also known as
**network byte order**. Most current systems, particularly Intel processors and
current Apple processors are little-endian, and therefore the byte order needs to
be swapped before values are passed to the function. In C, functions `ntohs`
(for 16 bits) and `ntohl` (for 32 bits) are intended for this purpose. These
functions do the byte order swapping, if program is compiled on a little-endian
system, or they do nothing, if the program is compiled in a big-endian system.
For IPv4 addresses we are accustomed to see the dotted decimal notation of four
8-bit decimal numbers separated by dots, but this is just a representation
format for a 32-bit value.

After `tcp_connect` has established the connection, the `main` function writes a
string that has been given as command line argument to the TCP connection. The
return value of the `write` function call tells how many bytes were written, or
-1 if there was an error. In network programming it is well possible that not
all of the data can be written with a single write call, especially when writing
larger amounts of data. In this case, because we know that there are less than
160 bytes to write, that should not happen however, because the data should fit
into single TCP segment, and the socket send buffers are empty. What `write`
actually does, is that it just copies the data to the kernel-side socket
buffers, from where the TCP starts working on the data, taking congestion
control and retransmissions into account. The `write` call may block, if the
socket send buffer is full, until more space becomes available (i.e., the
receiver TCP has acknowledged it has received some data).

Finally the program reads data from the same socket and prints it to the
terminal. Again, if there are much data to read, a single `read` call may not
read all the content in single call. There are delays in network transmission,
and possibly retransmissions, which may cause the data delivery to pause for the
moment, because TCP promises to deliver all data in correct order. The `read`
call may also block indefinitely, if there is no data to read in the socket
receive buffer.

## Network programming in Rust

Now we will take a look similar program than above, but implemented in Rust. The
program is available at [the examples
directory](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/rust/simple-client/src/main.rs)
of our GitHub repository (you may want to open the code in parallel window while
reading this section). In Rust, like many other modern languages, the network
API is a little easier to use than the original Posix API in C. TCP socket is
encapsulated in `TcpStream` class, and the `connect` function can be used to
create a new socket instance. The `connect` function combines name resolution
and TCP connection establishment, similarly as we implemented ourselves in the C
example. Otherwise `read` and `write` calls have similar semantics than in the C
API: data is copied to and from the socket buffers, and it is possible that the
functions only read or write part of the expected data, and therefore one needs
to be prepared to call them repeatedly until all data is read or written.

In Rust, the data read and written to socket is passed as `u8` array that
contains the data as 8-bit unsigned integers. If we assume that the data is
actually text, and we would like to operate it as string, the data needs to be
explicitly converted into string, and vice versa, because Rust is specific about
data types. In our example program, function `as_bytes()` converts a string into
a byte slice (a reference to a byte array) that can be passed as an argument to
`write` call. Conversely, to convert an array of bytes into string, we can use
`std::str::from_utf8`, assuming UTF-8 encoding. Note that the program needs to
prepare for the situation that the conversion is not successful. In our example
we are optimistic: `unwrap` causes the program to terminate in panic in such
case. Usually in production code, one should process the errors in more robust
way.

The `main` function returns a
**[Result](https://doc.rust-lang.org/book/ch09-02-recoverable-errors-with-result.html)**
type that is commonly used in Rust.
It can have two variants: an `Ok` type return value when function is successful
or `Err` type return value if there has been an error. No need to use a specific
integer value, such as -1 to indicate errors anymore! The question mark at the
end of a function call statement propagates a possible error value to the
upper-layer function interrupting the current function. In this case it
terminates the main function and the program execution.

As of now, the standard C++ does not have any object-oriented convenience
methods for network programming, but the same Posix API is used as with C. There
are libraries, however, that provide easier methods for network programming, such
as **[Boost Asio](https://think-async.com/Asio/)** or
**[Qt](https://doc.qt.io/qt-6/qtnetwork-programming.html)**.

## Byte order conversion and data alignment

As discussed above, 16-, 32- and 64-byte number values can be encoded either in
big-endian or little-endian byte order in a computer system. While currently the
little-endian byte order is prevalent in commonly used computers, this was not
always so earlier, and by common agreement in most protocol specifications these
values are encoded in big-endian byte order, also known as network byte order.

In Rust, the byte order conversions between big-endian and little-endian
integers can be done using `from_le_bytes`, `from_be_bytes`, `to_le_bytes` and
`to_be_bytes` functions. When writing a portable program, you generally cannot
assume whether it is compiled in little-endian or big-endian architecture.
Therefore there are also functions `to_ne_bytes` and `from_ne_bytes`, to
represent "native byte order". For example,
**[here](https://doc.rust-lang.org/std/primitive.u32.html#method.from_be_bytes)**
you can find documentation and examples for these functions for unsigned 32-bit
integers.

In addition to byte order, systems may differ in how they place variables in
memory, especially in data structures. For example, when writing a binary
protocol header into network, one might just make a structure and write its
contents as such. However, when there are fields of different lengths inside a
data structure, there maybe be empty padding spaces between the fields to force
the larger number values at word boundaries in computer memory, to make their
processing more efficient. Below picture illustrates the situation.

![Data struct alignment](/images/struct-alignment.png "Data struct alignment")

A simple, but inefficient, way to write such structure could be to do it field
by field as separate write calls. However, both Rust and C have a way to tell the
compiler that padding is not desired for a particular structure, but the fields
should be "packed" to have no such spaces between them. Therefore, a more
efficient way is to declare a packed structure and write its contents in a single
write call to the network after necessary byte order conversions.

Take a look at a simple example
"**[tcpheader](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/rust/tcpheader/src/main.rs)**",
that introduces the TCP header fields in a Rust structure, and then converts it
to a `u8` byte array that can be written to the network, and vice versa. In Rust one
can use `#[repr(C, packed)]` in front of the structure, to tell that it should
be built to be compatible with C binary interface, and that the fields should be
packed to not have padding. Later the code uses the byte order conversion
functions separately for each field to translate them to network byte order and
vice versa. As a reminder, TCP header is illustrated below (from **[RFC
9293](https://datatracker.ietf.org/doc/html/rfc9293)**):

![TCP header](/images/tcp-header.png "TCP header")

## Socket buffers and flow control

The below picture illustrates a sending and receiving system, and the involved
buffers. After socket is created and opened, the `write` call copies data to the
kernel-side socket buffer. After this the TCP protocol implementation starts
sending data one or more packets at a time, depending on, for example, the
current congestion window. TCP headers and IP headers will be added to the
beginning of the packet before it is sent. Currently most packets in the
Internet are 1500 bytes long, this means that each TCP segment can include
maximum of 1460 bytes of data, depending on options used in the header.

![Sockets and buffers](/images/buffers.png "Sockets and buffers")

After TCP segment is sent, it is not yet removed from the send buffer, because
it is possible that packet is lost in the network and TCP may need to retransmit
it. When the segment arrives at the receiver, it is placed in the socket receive
buffer, until application calls `read` to copy data from receive buffer to
application. At this point the receive buffer space can be released. When the
segment arrives, the TCP receiver sends an acknowledgment of received data. When
acknowledgment arrives at the sender, it can remove the data from the socket
send buffer. Note that reception of acknowledgment does not mean that receiving
application has yet read the data from the buffer. The acknowledgment contains
also a 16-bit window advertisement field, that tells how much space there is
still available in the socket receive buffer. If the available buffer goes to
zero, TCP sender cannot send any more data, until there is more room.

TCP promises to deliver data reliably in order. Therefore, if a packet is lost,
the following segments arriving at receive buffer cannot be delivered to the
application until the missing segment is successfully delivered. In some cases
this may cause significant delay in data delivery.
