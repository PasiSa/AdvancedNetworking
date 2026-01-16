/*  You may start from this template when implementing Task 3,
    or use entirely own code.
 */

use std::{
    error::Error,
    io::{Read, Write},
    net::{TcpStream UdpSocket},
    time::Instant,
};

fn main() {
    println!("Task-UDP starting");

    // Start clock to measure the time it takes do finish transmission
    let start = Instant::now();

    /* TODO:
        - Open TCP connection to adnet-agent server
        - Write command message to socket: "TASK-UDP keyword"
        - Read server response that contains number of bytes and a character
     */

    // You can use the following to parse the response string into
    // vector of strings (as separated by whitespace).
    // Feel free to implement better error handling.
    let resp: Vec<&str> = std::str::from_utf8(&buf)?
        .split_whitespace()
        .collect();
    let size: usize = resp.get(0).unwrap().parse().unwrap();
    let character = resp.get(1).unwrap();
    println!("Starting to transmit {} bytes of {}.", size, character);

    // It might be good idea to implement the main UDP transmission logic
    // in a separate function. Here we return the check number from last
    // acknowledgment as return value.
    let checknum = transmit_loop(&address, size, character)?;

    let duration = start.elapsed();
    
    println!("Size: {} -- Checknum: {} -- Duration: {:?}", size, checknum, duration);
}


fn transmit_loop(address: &String, size: usize, character: &str) -> Result<u8, Box<dyn Error>> {
    let mut transmitted = 0;
    let mut checknum: u8 = 0;  // checkbyte from last received acknowledgment

    // TODO: create UDP socket

    while transmitted < size {
        /* TODO:
            - Start transmitting data according to instructions, in max. 1200 byte units
            - Process acknowledgments
            - You should retransmit datagrams for which you do not receive acknowledgment
              after waiting for a while
            - You will need to prepare for a situation that no acknowledgments arrive,
              i.e. you need some sort of timeout handling.
        */
    }
    Ok(checknum)
}
