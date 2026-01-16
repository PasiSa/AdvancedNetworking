/*  You may start from this template when implementing the task,
    or use entirely own code.
    This template assumes that each client is handled in a separate thread.
 */

use std::{
    error::Error,
    io::{Read, Write},
    net::{SocketAddr, TcpStream, TcpListener},
    thread,
};


/// Separate struct for each client might be useful.
/// Feel free to modify as needed.
struct Client {
    socket: TcpStream,  // Active socket accepted from listening socket
    address: SocketAddr,  // Peer address of the client socket
    written: u32,  // How many bytes written so far
    total: u32,  // How many bytes we should write in total
    character: u8,  // What byte to write
}


fn main() {
    println!("Task-SRV starting");

    /* TODO:
        - Bind listening socket to a chosen port
        - Open TCP connection to adnet-agent server
        - Write command message to socket: "TASK-SRV keyword IP:port"
     */

    loop {
        /* TODO:
            - Accept next incoming connection
            - Create a Client instance for the new client connection
            - Spawn a thread to handle communication (in process_client function),
              move the client instance ownership to the thread
         */
    }
}


// This function is started in spawned thread
fn process_client(mut client: Client) {
    loop {
        /* TODO:
            - Read 32-bit value for transfer length, convert from network byte order.
              If connection is closed, return from function (will terminate thread)
            - Read the byte that should be used to fill the written content
            - Write the requested number of bytes. Single write call will not be enough.
            */
        println!("Wrote {} bytes of character {}", client.written, client.character);
    }
}