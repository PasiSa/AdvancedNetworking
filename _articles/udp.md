---
title: UDP and datagram sockets
---

Datagram sockets are typically used to send and receive UDP datagrams. They are
connectionless, and need only minimal state in the operating system. The
communication is not reliable and there is no congestion control or flow
control. UDP is typically used for different kinds of signaling or service
discovery protocols, where individual messages are small, or for DNS name
resolution. UDP is also used for data where delay variation is undesirable, such
as realtime audio/video calls or multiplayer games. Recently UDP has been used
for HTTP transfers with [QUIC protocol](https://en.wikipedia.org/wiki/QUIC),
where the reliability and congestion control is built on a separate layer on top
of UDP.

**[simple-udp](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/rust/simple-udp/src/main.rs)**
is a simple example demonstrating sending and receiving data between a UDP
client and a UDP server. In Rust, UDP socket can be created with the bind call,
that at the same time binds it to a local address an port. In Posix C API there
would be a separate `socket` call for creating the socket, and a separate `bind`
call for binding it.

UDP socket does not need to be connected, but once created, the application can
start sending or receiving data right away. Therefore, there are separate calls
for sending data from an unconnected socket (`send_to`) and for receiving data
using an unconnected socket (`recv_from`). Because the socket is not connected,
the same socket can be used for sending to multiple different destinations or
receiving from multiple different sources.
