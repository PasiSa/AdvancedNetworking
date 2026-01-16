/*  You may start from this template when implementing Task 1,
    or use entirely own code.
 */

use std::{
    io::{Read, Write},
    net::TcpStream,
    time::Instant,
};

fn main() {
    println!("Task-CLI starting");

    // Start clock to measure the time it takes do finish transmission
    let start = Instant::now();

    /* TODO:
        - Open TCP connection to adnet-agent server
        - Write command message to socket: "TASK-CLI keyword"
        - Read all data incoming to the socket until the other end closes TCP connection
        - Pay attention to total bytes read, and the last 8 characters read
     */

    let duration = start.elapsed();
    
    //println!("Total size: {} -- Last bytes: {} -- Duration: {:?}", total_size, last, duration);
}