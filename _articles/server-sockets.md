---
title: Server programming and concurrent connections
---

## Active and passive sockets

When a connection-oriented client socket is opened for communication, it is said
to be an **active socket**. Active socket can be used for sending and receiving
data, and it is bound to a local and remote IP address and transport port. A
server application first opens a socket in passive mode. **Passive socket** does
not yet have a remote end point, and it only knows the local IP address and port
it is listening to for new connection requests. Therefore, passive socket cannot
be used for sending or receiving data.

When passive socket is created, it is typically bound to known IP address and
transport port, that needs to be known by the clients so that they can connect
the server. With the `bind` call the server implementation chooses the IP
address and port. In modern systems it is common that a host has multiple IP
addresses in use at the same time for different network interfaces. For example,
a laptop has the loopback address 127.0.0.1 for host-local communication, and it
can have WiFi and wired LAN interfaces, both with different IP address. Commonly
the IP address is bound to "**any**" address, i.e., 0.0.0.0 in the case of IPv4.
This means that incoming connections are taken from any network interface. On
the other hand, if an application wants to limit to a particular interface it
accepts connections from, the address needs to be bound accordingly.

When a new connection request comes in at the server, it needs to accept the
connection request using `accept` call. This spawns a new active socket for the
incoming client. This socket has both endpoint addresses defined, and it can be
used for sending and receiving data. After this the operation of the socket
becomes symmetric: both ends can send and receive data as they wish, but
typically based on some defined protocol. Over time, there may be multiple
active sockets open as new clients arrive, and the server needs to apply some
strategy how to manage the concurrent clients in timely way, remembering that by
default read and write calls may block program execution indefinitely, unless
concurrency and non-blocking operation is taken care of appropriately.

## Example: simple server

We will now take a look at
**[simple-server](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/rust/simple-server/src/main.rs)**
example in our GitHub repository, probably the simplest server implementation
possible. This program accepts incoming connections one at the time, reads any
data sent by the accepted client, and then echoes the data back. After this the
connection is closed and the server starts to wait for the next client. The
server takes the IP address and transport port to bind to as command line
argument. If you use "0.0.0.0" (assuming IPv4) as the IP address, connections
are accepted from all network interfaces. If you use 0 as transport port, system
will pick an available port for you. In practice this is inconvenient, because
then the client applications would not know which port to connect to.

First you need to start the server by something like:

    cargo run -- 0.0.0.0:2000

and then on another terminal window you can use netcat to test it, and typing
some message:

    nc 127.0.0.1 2000

Or, you can use the simple client on the other terminal window to send the
message (running this on the simple-client directory):

    cargo run -- 127.0.0.1:2000 Hello

The simple server starts by creating a passive server socket and binding it to
the address given as command line argument. `server` is the passive server
socket listening for connections.

    let server = TcpListener::bind(&args[1])?;

Then it starts a loop that starts by waiting for the next incoming client. The
`accept` call may block the execution for a long time.

    let (mut socket, address) = server.accept()?;
    println!("Accepting connection from {}", address.to_string());

When the call completes, we will get the active `socket` representing the
connected client, and the address of the client, that will be printed on the
terminal.

After this, the server will read some data from the active client socket,
assuming that client knows that it is expected to write something. If the client
did not write anything, but would rather wait some input from elsewhere, the
`read` call would block for a long time.

    let mut buf: [u8; 160] = [0; 160];
    let readn = socket.read(&mut buf)?;

Finally, the server echoes the data that was read back to the client, and closes
the socket, as the lifetime of the local `socket` variable ends at the end of
the loop.

## Handling concurrent connections

Typically the situation is that a server needs to manage multiple clients
concurrently, each with dedicated TCP connection. In such case it is important
that none of the connect blocks the execution of the server, for example having
the server implementation waiting forever for a `read` call to complete, and
therefore not being able to respond to other clients. There are different
strategies to design such server.

### I/O multiplexing with non-blocking sockets

Multiple sockets can be handled one at a time in an iterative loop in a
single thread. Sockets can be made **non-blocking** in which case they return a
specific **WouldBlock** error whenever the call (e.g. `read` or `write`) would
not be able to return immediately. The Posix C API has functions such as
`select` or `poll` that can be used to wait simultaneously multiple event from
any of the specified sockets. In addition there are system-specific, more
efficient variants such as `epoll` in Linux or `kqueue` in BSD-based systems and
MacOS.

In Rust, [mio](https://docs.rs/crate/mio) is a library (or "crate" in Rust
terminology) that encapsulates the non-blocking socket operation into fairly
easy set of functions. Our next example is
**[iterative-server](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/rust/iterative-server/src/main.rs)**
that demonstrates the use of _mio_ (you may want to open the code in a parallel
window while reading this section). The server just reads incoming data from
socket and echoes it back. Different from the earlier implementation, the server
does not close the socket after writing data, but after responding to client, it
continues waiting for more data, until the client closes the connection.
Therefore the server needs to prepare to handle multiple client sockets
simultaneously.

The first lines of the `main` function are similar to previous example, reading
the binding address from command line arguments. Then we set up Mio's poll
service and container for the Mio events. Each possible event source is assigned
an unique "Token" that identifies the event source, basically not much different
from integer. We implement a small "TokenManager" for easier allocation and
release of unique tokens in a separate file, `tokenmanager.rs`.

At first we add just the passive listening socket as event source. Note that
with Mio the `TcpStream` and `TcpListener` implementations are different than
the standard implementations of the same types (see the `use` statements in the
beginning of the program). These are compatible with Mio and implement
non-blocking operation.

The heart of the main event loop is Mio's `poll` function that stops until at
least one event is available. Note that after poll completes, there may be
multiple events available, so we need to handle all of them iteratively. If
there is an event on the listening socket, we know that we can call `accept`
safely without blocking the program. We have a small `Client` structure that
contains the socket and address of an client. All active clients are stored in a
`HashMap` container. If there was any more complicated application logic, the
`Client` structure could contain also other client-specific information that is
needed. When a new client is accepted, a new token is allocated for it and
registered to Mio as an interesting event source.

Mio has separate event types for situations when socket is readable, and for
situations when socket is writable without blocking the execution. If we wanted
a proper implementation, we should also handle the `write` calls through an
event processing loop, but in this case we skip it for simplicity (and perhaps
laziness). On the other hand, we write a maximum of 160 bytes, so it can be
assumed to take quite many write calls without client reading anything before
the send buffer gets full and blocks writes.

After client connections are opened, also the possible client socket events are
checked in separate if branch. Here one should note handling of the `read` call
return values. In Rust, an often used return type is `Result` that can yield two
return value variants. `Ok` response is returned when read is successful. In the
case of Ok, the return value will indicate the number of bytes read. If the
return value is 0, the client has closed the socket, and therefore we should
clean up: release the Mio event token, and remove the client from the HashMap.
This also causes the lifetime of the socket to end, so it will be cleaned up
also from our end. `Err` response means that error occurred in read. Also in
this case we clean up the client socket, but do not terminate the operation of
the main server loop. Earlier we have mostly used the `?` operator that
propagates the possible error up in the call stack, which would have caused
termination of the program.

The `write` call shows another way of checking for an error outcome, in case we
are not interested in the exact Ok return value. A better alternative, in
addition to handling the write call through the writable event, would be to
check how many bytes were actually written, and prepare for the case when only
part of the data was written. Again, lazy coding.

You can test the program by first starting the server in the same way as before:

    cargo run -- 0.0.0.0:2000

Then, open more than one terminal windows where you start a netcat session in
each, opening multiple connections to server:

    nc 127.0.0.1 2000

Try typing different things to different terminal windows, closing netcat in
some windows by Ctrl-D (Hang-up of connection) or Ctrl-C (Interrupt netcat), and
then restarting netcat.

### Multithreaded operation

Sometimes an easier option is to spawn a separate thread for each client. As we
see in the
**[threaded-server](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/rust/threaded-server/src/main.rs)**
example, for our simple echo server the code indeed is rather short and simple,
compared to the iterative server. However, there are a few things to consider
before applying multiple threads for server logic. First, spawning a separate
thread costs some execution time from the operating system, that
manages the threads in the system. In addition, if application logic requires
the different threads to access shared data, one should be careful that the
concurrent operations do not cause inconsistencies in data modifications,
and defects due to data inconsistency that may be difficult to track. For
example, access to critical shared data can be protected by `Mutex` type in
Rust. This is not the case in our example, though, where each session is
independent of each other.

As before our `main` function starts by parsing the address to bind to from
command line arguments and binds the socket. The main loop is very simple: it
just waits in the `accept` call until a new connection arrives, and then spawns
a new thread for processing the client in `process_client` function. The
ownership of the `socket` and `address` variables is moved to the new thread
with `move` keyword. After this the main thread starts waiting for the next
connection. The thread `spawn` function would return a handle to the thread that
the main thread could use for interacting with the spawned threads, for example,
to wait for the completion of an earlier spawned thread. In this case of a
simple echo server, we do not have use for it, though. The threads live their
own life independently. When the program is terminated, all spawned threads will
also die.

The `process_client` function is also slightly simpler, although quite similar
to the iterative server case, because now we do not need to handle Mio and its
events. The read and write calls may block, but they only block the current
thread and therefore do not harm the other clients or prevent listening socket
from accepting new connections.

### Collaborative multitasking

In collaborative multitasking, the program code voluntarily indicates locations
where it can yield execution to other tasks. This differs from multi-threaded
operation, where the operating system scheduler can reschedule another thread
preemptively at any time.

In Rust, collaborative multitasking is provided by the
**[Tokio](https://crates.io/crates/tokio)** crate. It adds a small runtime
component alongside the main function that takes care of the task scheduling,
and `async` keyword that is used to indicate an asynchronous function that can
be interrupted on locations with `await` keyword. Example
**[async-server](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/rust/async-server/src/main.rs)**
shows how this is done. The implementation looks similar to the threaded server,
but now applies Tokio and collaborative multitasking concepts.

There is more information about this topic in a Rust book about **[Asynchronous
Programming](https://rust-lang.github.io/async-book/)**.
