---
---

# Assignment: Data transfer using UDP

In this task you need to send largish amount of data using UDP protocol. Like
previous assignments, your client starts by opening a connection to
_adnet-agent_, and sending a control message: `TASK-UDP keyword`. The server
replies with string <number> <character>, that indicates how many bytes must be
sent using UDP, and the character that should be repeated in datagram payload
content. Note that you will need to send several datagrams according to
the following instructions, until the requested amount of data has been delivered.

Each UDP datagram should be structured from a **6-byte header** and payload as
follows:

- **Four bytes** that indicate **sequence number** of the datagram, in **network byte
  order**. The sequence number calculation starts from 1, and should be increased
  by one for each new datagram sent. If you decide to retransmit a datagram that
  has been transmitted earlier, it should re-use the same sequence number as
  originally.

- **Two bytes** that indicate the **number of bytes in payload**, in network byte order.
  The maximum length of the payload is 1200 bytes.

- After this you should include the payload, repeating the character indicated
  by _adnet-agent_.

The _adnet-agent_ server listens to UDP datagrams in **UDP port 20000**. For each
received datagram the server replies by 5-byte UDP acknowledgment with following
content:

- four bytes that indicate the highest consecutive sequence number received so
  far, i.e., if there is a datagram missing in the sequence number space, or
  they otherwise arrive at incorrect order, the server may repeat the same
  sequence number as previously. In other words, we are using cumulative
  acknowledgments similar to TCP.

- one byte that contain seemingly random number (but is not). Note the content
  of the last acknowledgment finishing the transmission. This number will
  be asked in the MyCourses task assignment for grading.

If you use Rust to implement your program, the [assignment
template](https://github.com/PasiSa/AdvancedNetworking/tree/main/assignments/task-udp)
may turn out to be useful.
You should run your implementation in three different mininet configurations, as
described below. Be prepared to the possibility that some of the datagrams may
be lost in the network and in such case need to be retransmitted. The queue
length in bottleneck link is limited, therefore it is not a good idea to try to
send all datagrams back-to-back, but slow down the transmission of datagrams
according to some strategy. You may study how TCP takes care of this, but it is
not required to implement a full-fledged modern congestion control algorithm.
Something simple suffices.

You should repeat the assignment applying the following three scenarios:

1. **Long delay**. The bottleneck link has one-way delay of 200 ms, no limits on
   the transmission speed:
   `sudo aalto/simple_topo.py --delay=200ms`

2. **Slow bottleneck** The bottleneck link has one-way delay of 50 ms, but
   transmission speed is limited to 100 kbps:
   `sudo aalto/simple_topo.py --delay=50ms --bw=0.1`

3. **Lossy link** The bottleneck link has one-way delay of 200 ms. Packet loss
   rate is 10%:
   `sudo aalto/simple_topo.py --delay=200ms --loss=10`

In your response, you should report the one-byte number code in last
acknowledgment. In addition, describe your approach for retransmissions and rate
control, to avoid congestion.

The assignment is successful if you can get acknowledgments for all datagrams in
all three scenarios. Measure also the time from the start of the transfer until
last acknowledgment is received, and tell that in your response. How efficient
can you make your UDP-based simple transport protocol?
