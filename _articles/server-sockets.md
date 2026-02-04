---
title: Server programming and concurrent connections
---

Implementing a server for a network application can be challenging compared to
the client, especially regarding the I/O operations, as typically servers need
to be responsive to large number of clients concurrently.

This section

- Goes through the basics of **passive sockets** that are used by server
  applications to accept incoming connections from clients.

- Discusses different **strategies for handling several concurrent clients**
  and their tradeoffs. There are small Rust examples of these variants.

- Covers how shared data can be protected among concurrent multithreaded
  sessions using **locks** and **mutexes**.

- Discusses a common use case of passing data from one source (e.g. file) to
  another (e.g. socket), and how it can be made more efficient by **avoiding
  copying** in the userspace application.

Related assignment: **[TCP server](../assignments/task-srv/)**

## Active and passive sockets

When a connection-oriented client socket is opened for communication, it is
called an **active socket**. An active socket can be used for both sending and
receiving data, and it is bound to both a local and remote IP address and
transport-layer port.

In contrast, a server application initially opens a socket in _passive_ mode. A
**passive socket** is not yet associated with a remote endpoint. It is bound
only to the local IP address and port on which the server listens for incoming
connection requests. This address needs to be known by the client so that it can
connect the server. A passive socket cannot be used to send or receive data.

The `bind` call is used by the server to choose the IP
address and port. In modern systems it is common that a host has multiple IP
addresses in use at the same time for different network interfaces. For example,
a laptop has the loopback address 127.0.0.1 for host-local communication, and it
can have WiFi and wired LAN interfaces, both with different IP address. Commonly
the IP address is bound to "**any**" address, i.e., 0.0.0.0 in the case of IPv4.
This means that incoming connections are taken from any network interface. On
the other hand, if an application wants to limit to a particular interface it
accepts connections from, the address needs to be bound accordingly.

When a new connection request comes in at the server, it needs to accept the
connection request using `accept` call. This creates a new active socket for
communication with the incoming client. This socket has both endpoint addresses
defined, and it can be used for sending and receiving data. After this the
operation of the socket becomes symmetric: both ends can send and receive data
as they wish, but typically based on some defined protocol. Over time, there may
be multiple active sockets open as new clients arrive, and the server needs to
apply some strategy how to manage the concurrent clients in timely way,
remembering that by default read and write calls may block program execution
indefinitely, unless concurrency and non-blocking operation is taken care of
appropriately.

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

```rust
let server = TcpListener::bind(&args[1])?;
```

Then it starts a loop that starts by waiting for the next incoming client. The
`accept` call may block the execution for a long time.

```rust
let (mut socket, address) = server.accept()?;
println!("Accepting connection from {}", address.to_string());
```

When the call completes, we will get the active `socket` representing the
connected client, and the address of the client, that will be printed on the
terminal.

After this, the server will read some data from the active client socket,
assuming that client knows that it is expected to write something. If the client
did not write anything, but would rather wait some input from elsewhere, the
`read` call would block for a long time.

```rust
let mut buf: [u8; 160] = [0; 160];
let readn = socket.read(&mut buf)?;
```

Finally, the server echoes the data that was read back to the client, and closes
the socket, as the lifetime of the local `socket` variable ends at the end of
the loop.

## Handling concurrent connections

A server typically needs to manage multiple, often thousands of clients
concurrently, each using a dedicated TCP connection, while responding to client
communication in a timely manner. Therefore, the server design must be carefully
considered to ensure acceptable performance and scalability. Most importantly,
the server must avoid situations where the execution becomes blocked while
waiting for interaction from one client, preventing it from serving the others.
Many I/O functions, such as `read` and `write` are blocking by default. For
example, if no data is available on the socket, a `read` call may wait until
data arrives, blocking the execution of the program thread.

Also the **error handling** is important: in addition to possible implementation
bugs in the server, it is possible that the client behaves incorrectly,
sometimes intentionally for a malicious purpose. The network communication may
always suffer from errors that cause periods of disconnections and
unpredictable, sometimes long, **delays**. Therefore some kind of timeout logic
at the application is often needed to clean up such connections that have been
inactive for a long time and may not be operational anymore.

There are different strategies to manage concurrent communication, which we
discuss below.

### I/O multiplexing with non-blocking sockets

Sockets can be **can be configured into a non-blocking mode**, in which case the
calls return immediately, but for example, if `read` did not have any data to
read, and it would have blocked in the blocking mode, the call returns a specific
**WouldBlock** error code (that is not actually an error). A naive
implementation would be to build a while loop in the server that reads all
sockets in this way. However, this would create a busy loop that would
unnecessarily load the CPU, even if no data is coming from any of the clients.

To avoid unnecessary CPU load, the Posix C API has functions
**[select](https://man7.org/linux/man-pages/man2/select.2.html)** and
**[poll](https://man7.org/linux/man-pages/man2/poll.2.html)** functions that can
be used to wait simultaneously I/O events from any of the defined sockets, or
other I/O sources. These functions block until any of the give sources can be
called so that the execution would not block. Their return value indicate the
sources with available events, that can then be iterated one by one. In addition
there are system-specific, more efficient variants for these functions, such as
`epoll` in Linux or `kqueue` in BSD-based systems and MacOS. In practice, use of
the `select` function is discouraged because of its inefficient and limited
interface, for example it only supports 1024 simultaneous sources, which in many
purposes is too small these days.

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

First we add just the passive listening socket as event source ([line
60](https://github.com/PasiSa/AdvancedNetworking/blob/087f8e89704b72a69864f269d9b4421b2777990e/examples/rust/iterative-server/src/main.rs#L60)).
Note that with Mio the `TcpStream` and `TcpListener` implementations are
different than the standard implementations of the same types (see the `use`
statements in the beginning of the program). These are compatible with Mio and
implement non-blocking operation.

The heart of the main event loop is Mio's `poll` function ([line
71](https://github.com/PasiSa/AdvancedNetworking/blob/087f8e89704b72a69864f269d9b4421b2777990e/examples/rust/iterative-server/src/main.rs#L71))
that stops until at least one event is available. After poll
completes, there may be multiple events available, so we need to handle all of
them iteratively. If there is an event on the listening socket, we know that we
can call `accept` safely without blocking the program. We have a small `Client`
structure that contains the socket and address of an client. All active clients
are stored in a `HashMap` container. If there was any more complicated
application logic, the `Client` structure could contain also other
client-specific information that is needed. When a new client is accepted, a new
token is allocated for it and registered to Mio as an interesting event source.

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

A benefit of a single-threaded, event-driven server design is that it can scale
efficiently and behave predictably (as long as the operations are not blocking),
as it avoids thread management overhead and synchronization. However, designing
such applications can be complex, particularly with respect to state management
and robust error handling.

### Multithreaded operation

One possible approach for server design is to spawn a separate thread for each
client. As we see in the
**[threaded-server](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/rust/threaded-server/src/main.rs)**
example, the code for a simple echo server is relatively short and
straightforward compared to an iterative server implementation. However, few
factors should be considered before adopting a multi-threaded server design.
First, creating and managing threads incurs overhead, because the operating
system is responsible for scheduling and maintaining them. In addition, if the
application logic requires multiple threads to access shared data, care must be
taken to prevent concurrent operations from causing data inconsistencies, which
can lead to subtle and difficult-to-debug errors. For example, access to shared
mutable state can be protected using synchronization primitives such as `Mutex`
in Rust. In the echo server example this is not an issue, as each client session
is independent.

The `main` function again starts by parsing the address to bind to from command
line arguments and binds the socket. The main loop is very simple: it just waits
in the `accept` call until a new connection arrives ([line
34](https://github.com/PasiSa/AdvancedNetworking/blob/087f8e89704b72a69864f269d9b4421b2777990e/examples/rust/threaded-server/src/main.rs#L34)),
and then spawns a new thread for processing the client in `process_client`
function. The ownership of the `socket` and `address` variables is moved to the
new thread with `move` keyword. After this the main thread starts waiting for
the next connection. The thread `spawn` function would return a handle to the
thread that the main thread could use for interacting with the spawned threads,
for example, to wait for the completion of an earlier spawned thread. In this
case of a simple echo server, we do not have use for it, though. For this simple
server example the multithreaded approach suits nicely, because the client
threads are independent of each other. When the program is terminated, all
spawned threads will also die.

The `process_client` function is also slightly simpler, although quite similar
to the iterative server case, because now we do not need to handle Mio and its
events. The read and write calls may block, but they only block the current
thread and therefore do not harm the other clients or prevent listening socket
from accepting new connections.

One advantage of a multi-threaded server model is that it can exploit multiple
CPU cores by executing threads in parallel. A single-threaded server executes on
only one core at a time. Often the network applications are not limited by CPU
capacity, but are rather I/O-bound.

### Collaborative multitasking

**Collaborative multitasking** is a concurrency model in which program execution
is organized into tasks. Typically, each client can be assigned to a dedicated
task. In this model program explicitly indicates points where it can yield
control to other tasks. Unlike multi-threaded execution, where the operating
system may preempt a running thread at any time, task switching in collaborative
multitasking occurs only at well-defined yield points chosen by the programmer
or the runtime.

In Rust, collaborative multitasking is commonly implemented using asynchronous
programming and an event-driven runtime such as
**[Tokio](https://crates.io/crates/tokio)**. The runtime provides a lightweight
task scheduler that runs alongside the main function and manages the execution
of asynchronous tasks. Functions declared with the `async` keyword may suspend
execution at `await` points, allowing other tasks to make progress while waiting
for I/O or other asynchronous events.

The **[async-server](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/rust/async-server/src/main.rs)**
example illustrates this approach. Its structure resembles the threaded server,
but instead of relying on operating system threads, it uses asynchronous tasks
scheduled cooperatively by the runtime. This enables the server to handle many
concurrent connections efficiently without the overhead of creating a separate
thread for each client.

Also the collaborative multitasking operation can be run using multiple parallel
threads. The Tokio runtime supports both single-threaded and multi-threaded
execution. In both cases, asynchronous tasks are scheduled cooperatively, but in
the multi-threaded runtime, tasks may execute in parallel on multiple operating
system threads, allowing the application to utilize multiple CPU cores. However,
even with multi-threaded operation, tasks are not preempted arbitrarily, but
they yield execution only at `await` points.

There is more information about this topic in a Rust book about **[Asynchronous
Programming](https://rust-lang.github.io/async-book/)**.

## Separate process per client

When an application needs to keep the different client sessions separated
without interaction between clients, in some cases a good approach is to fork a
dedicated process to handle each client. For example, the **ssh** server applies
this approach, as the different shell sessions should by definition be securely
isolated from each other. Because the operating system guarantees the isolation
between processes, application programmer can quite easily develop the
application logic without worrying if anything in the I/O would block other
clients, or that there would be data race or other synchronization issues.

Typically a process-based server starts with a master process that has the
passive socket listening for connections. The master server waits for incoming
connections in a loop and after accepting the connection, forks a child process
to continue the operation from this point on. It is also possible to change the
executable code at this point, for example to execute a bash shell or other
application. The child process inherits all the open I/O descriptors from the
master, particularly the socket that was accepted. In the case of terminal
servers, typically the standard input and standard output streams are directed
to socket, in which case all input and output from child application is
transmitted over a TCP connection to the client.

Historically, another case of using multiple processes was applied by the Apache
web server, that pre-forked a set of processes that each are waiting for
incoming connections and then serve the HTTP request. Each process were waiting
in accept call for an incoming client, and operating system than assigned the
connection to one of the processes that was available. The modern servers do not
apply this design, however.

## Shared state and synchronization

In concurrent server applications, multiple execution contexts (threads or
asynchronous tasks) may access shared state. Shared state can include data
structures holding connection metadata, session information, caches, counters,
or global configuration. When such state is accessed concurrently, careful
synchronization is required to ensure correctness.

If multiple execution contexts read and modify shared data without proper
coordination, **data races** may occur. Data races can lead to inconsistent or
corrupted state and to bugs that are often difficult to reproduce and
diagnose. Preventing data races requires ensuring that shared mutable data is
accessed in a controlled and well-defined manner.

### Synchronization mechanisms

Common synchronization mechanisms include:

- **Mutexes**, which provide mutual exclusion for critical sections of code
- **Read-write locks**, which allow concurrent reads but exclusive writes
- **Atomic operations**, which enable lock-free access to simple shared variables

In multi-threaded server designs, synchronization is typically required whenever
multiple threads access shared mutable state. Locks and mutexes can be used to
avoid this, but one should avoid holding locks during blocking operations such
as network I/O, as this can significantly degrade performance and lead to
contention or deadlocks.

Asynchronous servers often reduce the need for synchronization by structuring
execution around cooperative multitasking. However, shared state is still
possible, particularly when using multi-threaded runtimes or shared resources
across tasks. In Rust, shared state between asynchronous tasks is commonly
managed using thread-safe reference counting (`Arc`) combined with synchronization
primitives such as `Mutex`.

### Example

Below is a simple example that demonstrates the use of the `Arc` and `Mutex`
mechanisms in Rust. It starts four threads in parallel that use a shared integer
counter, each increasing it by one. The counter is wrapped inside a Mutex type
that needs to be locked using the `lock` function before modifying the counter.
The lock is automatically released when the locked variable runs out of scope
(e.g., its program block).

```rust
use std::sync::{Arc, Mutex};
use std::thread;

fn main() {
    // Shared state: a counter protected by a mutex.
    let counter = Arc::new(Mutex::new(0));

    // Vector for thread handles.
    let mut handles = Vec::new();

    for _ in 0..4 {
        // Clone the Arc to share ownership between threads.
        // The Arc type maintains reference count of the number of copies of the data.
        let clonedcounter = Arc::clone(&counter);

        let handle = thread::spawn(move || {
            // Lock the mutex before accessing the shared data.
            let mut value = clonedcounter.lock().unwrap();
            *value += 1;
            // Mutex is automatically unlocked when `value` goes out of scope
        });

        handles.push(handle);
    }

    // Wait for all threads to finish
    for handle in handles {
        handle.join().unwrap();
    }

    println!("Final counter value: {}", *counter.lock().unwrap());
}
```

The same example can be found in our **[git repo](https://github.com/PasiSa/AdvancedNetworking/tree/main/examples/rust/thread-mutex.rs)**.
For testing this kind of simple programs with Rust, you can compile a single
source file using the **rustc** command, e.g. `rustc thread-mutex.rs`. This would
produce executable called `thread-mutex` that can be executed on command line to
test if it works.

## Efficient file transfer

Read and write operations to socket, or any other type of descriptor (file,
pipe, standard input/output, etc.) involve copying data from application buffer
to kernel socket buffer, and vice versa. In the normal case, copying requires CPU
work to move bytes from one memory location to another, between kernel and the
user space so it is not the most efficient operation.

In the common networking use case of transmitting contents of a file over a TCP
connection, such as in file transfer protocols or HTTP, the application would
need to read the contents of a file into a application buffer using a `read`
operation, transferring data from kernel to user space. Then it needs to copy
the data from application buffer to socket using a `write` call, causing another
copy from user space to kernel. If the file is large (e.g. a Docker image), it
does not fit into application buffer at once, but this needs to be repeated
iteratively until the whole file is copied. This will cause burden to CPU.

Linux (and many other systems) have implemented a
**[sendfile](https://man7.org/linux/man-pages/man2/sendfile.2.html)** function
to make this common use case more efficient. The function tells the kernel to
copy data from one file descriptor to another, for example, from a file to a TCP
socket. This way the application does not need to repeatedly need to copy the
data back and forth to and from its buffer, but the operating system kernel does
the copying inside kernel space. This way it will be significantly more
efficient operation.

Another variant of this kind of "zero-copy" operation is Linux-specific
**[splice](https://man7.org/linux/man-pages/man2/splice.2.html)** function that
copies data between a pipe (such as socket) and another descriptor. It is better
suited for non-file data such as streaming a live content, or proxying data from
one socket to another.

Below is a simple example of using `sendfile` for copying contents of a file
into a TCP socket.

```rust
use std::fs::File;
use std::os::fd::AsFd;
use std::net::TcpStream;
use nix::sys::sendfile::sendfile;

fn main() -> std::io::Result<()> {
    // Connect to the server
    let stream = TcpStream::connect("127.0.0.1:9000")?;

    // Open the file to send
    let file = File::open("example.txt")?;

    // Use sendfile to transfer the file
    let _ = sendfile(stream.as_fd(), file.as_fd(), None, usize::MAX).unwrap();

    println!("File sent successfully!");
    Ok(())
}
```

Because this program requires the **nix** crate for the `sendfile`
implementation, it cannot be directly compiled with the `rustc` command, but it
is best to make it a simple cargo package that includes **nix**. Place the file
under `src/main.rs` in the cargo packet directory and add `Cargo.toml` in the
root, for example something like following:

```yaml
[package]
name = "sendfile_test"
version = "0.1.0"
edition = "2021"

[dependencies]
nix = { version = "0.29", features = ["zerocopy"] }
```
