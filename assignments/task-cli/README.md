---
---

# Assignment: Simple client

In this assignment you will implement a TCP client that opens a TCP connection
to the `adnet-agent` server assuming the `simple_topo` topology in our Mininet
setup. After you send initial control message `TASK-CLI keyword` to the server,
it will respond by sending a large message consisting of alphanumeric characters
to the same socket. Replace "keyword" with the word that is randomly given to
you in MyCourses task description. You should read all data the server sends.
After server
has finished sending data, it closes the TCP connection. Your task is to repeat
this assignment applying different properties on the bottleneck link, and report
the results following the instructions given below.

Note that the course git repository contains [Rust
templates](https://github.com/PasiSa/AdvancedNetworking/tree/main/assignments/task-cli)
for this task that you may use if you want.

You should repeat the assignment applying the following four scenarios:

1. **Long delay**. The bottleneck link has one-way delay of 200 ms, no limits on
   the transmission speed:
   `sudo aalto/simple_topo.py --delay=200ms`

2. **Slow transmitter** The bottleneck link has one-way delay of 50 ms, but
   transmission speed is limited to 100 kbps:
   `sudo aalto/simple_topo.py --delay=50ms --bw=0.1`

3. **Lossy link** The bottleneck link has one-way delay of 200 ms. Packet loss
   rate is 10%:
   `sudo aalto/simple_topo.py --delay=200ms --loss=10`

4. **Survival**: In this case you can find the parameters yourself. What is the
   most challenging network scenario you can think of that can still complete
   the TCP connection, delivering the same amount of bytes as the previous
   scenarios? In addition to delay, bandwidth and loss rate, you can also limit
   the packet queue size at the bottleneck link (argument `queue`).

Write a report that describes the following details. The report, and
answers to the following questions need to be submitted
in MyCourses for grading. For all the four afore-mentioned scenarios, the
answers to the following three questions should be the same:

- What was the keyword you used? (As randomly given in MyCourses task assignment)
- How many bytes did the server transmit before closing connection?
- What were the last 8 characters you received from server before connection was
  closed?

In addition, for each of the above four scenarios, report the following:

- How long does it take to complete the transfer? Give exact (millisecond
  granularity) answer, as measured by your program
- How many round-trips did the transfer take? If you think there were TCP
  retransmission timeouts, tell also that.
- How many retransmissions did TCP do during the transmission?

Tell also what parameters you used in the "Survival" scenario.

For this task, you will need to use
[Wireshark](https://pasisa.github.io/AdvancedNetworking/wireshark/) to
analyze the TCP traffic, to determine the number of round-trip times and
retransmissions.

Here are the likely useful steps on the Mininet command line, after starting
the `simple_topo` script in each of the four scenarios:

- `lh1 xterm &`: start a separate xterm window representing host "lh1" (IP:
  10.0.0.1)
- `rh1 xterm &`: start another xterm window representing host "rh1" (IP:
  10.0.0.3)
- On window representing "rh1": start `adnet-agent` server. It will be listening
  to TCP connections at IP address 10.0.0.3, port 12345
- On window representing "rh1", start Wireshark: `wireshark &`. Start capturing
  traffic on "rh1-eth0" interface. Because in this case server is doing the
  transmission of most data, analyzing e.g. round-trip times and retransmissions
  is easier when observing the server side of the connection.
- Start your client implementation on window representing "lh1"
