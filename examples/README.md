---
---

# List of examples

## TCP in C

- **[daytime-cli.c](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/c/daytime-cli.c)**:
  Shows basic operation of opening a socket and reading some data from it.
  Modified from W.R. Stevens' Unix Network Programming book.

- **[daytime-serv.c](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/c/daytime-serv.c)**:
  Demonstrates a simple server socket, a counterpart of
  [daytime-cli.c](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/c/daytime-cli.c),
  that accepts a TCP connection and writes the current date and time to the
  accepted socket. Modified from W.R. Stevens' Unix Network Programming book.

- **[simple-client.c](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/c/simple-client.c)**:
  Demonstrates socket connection and name resolution, then writes and reads
  something from the socket. Modified from W.R. Stevens' Unix Network
  Programming book.

## TCP in Rust

- **[simple-client](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/rust/simple-client/src/main.rs)**:
  Opens connection, then writes and reads a bit of data. Should be equivalent
  behavior to
  [simple-client.c](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/c/simple-client.c)
  above.

- **[tcpheader](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/rust/tcpheader/src/main.rs)**:
  Example of converting a struct consisting TCP header fields into byte stream
  that can be written to a socket, and conversely, filling the struct from data
  read from byte stream. Demonstrates structure packing and byte order
  conversions.

- **[send-much](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/rust/send-much/src/main.rs)**:
  Contains both simple server and client implementation: server accepts
  connections, then waits for user input and reads all data someone sends to the
  socket, until the socket is closed. Client just sends the requested number of
  bytes. Used to demonstrate the effect of socket buffering on socket API
  behavior.

- **[simple-server](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/rust/simple-server/src/main.rs)**:
  Accepts a connection, then reads data from socket and writes some data back,
  then closes the connection. Handles only one connection at a time in a loop.
  Can be tested together with
  [simple-client](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/rust/simple-client/src/main.rs).

- **[iterative-server](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/rust/iterative-server/src/main.rs)**:
  Accepts incoming connections, then waits for incoming data and echoes it back
  in all active connections. Keeps connections open until other end closes them.
  Can handle multiple connections in parallel. Demonstrates non-blocking sockets
  in an iterative single-threaded server using Rust's **[mio
  crate](https://crates.io/crates/mio)**.

- **[threaded-server](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/rust/threaded-server/src/main.rs)**:
  Similar to
  [iterative-server](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/rust/iterative-server/src/main.rs),
  but spawns a new thread for each active client.

- **[async-server](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/rust/async-server/src/main.rs)**:
  Similar to
  [threaded-server](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/rust/threaded-server/src/main.rs)
  but applies collaborative multitasking using Rust's **[tokio
  crate](https://crates.io/crates/tokio)**.

## UDP

- **[simple-udp](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/rust/simple-udp/src/main.rs)**:
  Simple UDP example where client reads input from user and sends it to UDP
  server, then reads a response back. Server echoes the datagram it receives
  back to client. Both client and server implementations are in the same code.
