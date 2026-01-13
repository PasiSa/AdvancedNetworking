/* Open TCP socket, send some data and receive data back.
 * 
 * Usage: cargo run -- <name/address>:<port> <string>
 */

use std::{
    env,
    error::Error,
    io::{Read, Write},
    net::TcpStream,
};


fn main() -> Result<(), Box<dyn Error>> {
    // Collect command-line arguments into a vector
    let args: Vec<String> = env::args().collect();

    if args.len() != 3 {
        eprintln!("arguments: <host>:<port> <message>");
        return Err("Invalid command".into());
    }

    // Connect TCP socket. If connection fails, exit the main function with error.
    // The connect function does both name resolution and connection establishment.
    let mut socket = TcpStream::connect(&args[1])?;

    // as_bytes() converts the string from command line argument into a u8 byte slice.
    // If write produces an error, we exit the main function immediately.
    let n = socket.write(args[2].as_bytes())?;
    if n < args[2].len() {
        // We could not write everything.
        // In reality, we should call write() again with the rest of the data.
        println!("Not everything was written");
    }

    // Allocate u8 buffer of 160 bytes and read data to it from socket.
    // Print the output to screen.
    // Assume it is UTF-8 encoded string, otherwise interrupts with error.
    // If read causes error, exits the main function
    let mut buf: [u8; 160] = [0; 160];
    socket.read(&mut buf)?;
    println!("{}", std::str::from_utf8(&buf)?);

    Ok(())  // Everything successful!
}
