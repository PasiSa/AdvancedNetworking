// Example from server section on shared state and synchronization

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
