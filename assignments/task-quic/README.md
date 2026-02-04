---
---

# Assignment: Experimenting with QUIC

In this assignment, we will try out one QUIC implementation and test it a little.
We will use **[Quiche](https://github.com/cloudflare/quiche)**, an open-source
implementation by Cloudflare for this. We will again do this in an emulated
Mininet network.

First, we will need to clone _Quiche_ from the repository and build it (not yet
in Mininet):

    git clone -b 0.24.5 --recurse-submodules https://github.com/cloudflare/quiche.git
    cd quiche
    cargo build

**Note:** _Quiche_ requires BoringSSL for QUIC’s TLS handshake.
It is built automatically, but **cmake** must be _[installed](https://command-not-found.com/cmake)_.

For the sake of this experiment, let's create three 100 KB files and fill them
with arbitrary data, for example, as follows:

    yes A | head -c 100K > file-A.txt
    yes B | head -c 100K > file-B.txt
    yes C | head -c 100K > file-C.txt

For this exercise, it is probably easier to have these files just in the quiche
directory root, even though it would not typically be an ideal place to store them
(you can also pick another location, but you need to change the root path parameter
in the server setup accordingly).

The Quiche repository contains example applications for an HTTP/3 server and HTTP/3
client. We will start a Mininet setup with high latency and some random errors:

    sudo aalto/simple_topo.py --bw=1 --delay=200ms --loss=5

In the Mininet prompt, we will enable qlog logging using the environment variable,
start Wireshark and `quiche-server`. In this case, we do not start separate xterm
windows for different emulated hosts, but start everything directly on the
mininet prompt. You can also use separate xterm windows if that feels more
comfortable.

    lh1 export QLOGDIR=.
    rh1 export QLOGDIR=.
    rh1 wireshark &
    rh1 cd ../quiche ; target/debug/quiche-server --cert apps/src/bin/cert.crt --key apps/src/bin/cert.key --listen 0.0.0.0:4433 --root . &

In the last command, we assume that the Mininet directory and Quiche have been
installed in adjacent directories. If this is not the case, you may need to
change the path after the `cd` command. We will use the dummy certificate provided for
the Quiche example, and listen to connections on UDP port 4433. The Quiche
directory is also the root for the files the server is serving. The server does not
output anything, so it can be started to run in the background.

Finally, start the Wireshark capture, and `quiche-client` that requests the three
files created above:

    lh1 cd ../quiche ; target/debug/quiche-client --no-verify "https://10.0.0.3:4433/file-A.txt" "https://10.0.0.3:4433/file-B.txt" "https://10.0.0.3/file-C.txt"

The `--no-verify` option tells the client not to verify the TLS certificate sent by the server.
The certificate would not be considered valid, as we are running separate IP
address spaces in the Mininet environment.

When the transfer is concluded, there should be two files with the `.sqlog` suffix in
your Quiche directory, for client- and server-side qlogs. You can use the
**[Qvis tool](https://qvis.quictools.info/)** to visualize and analyze the logs.
In the "_Manage files_" tab, use Option 2 to upload your qlogs. Then, the
"_Sequence_" and "_Multiplexing_" tabs will be useful for the following
questions.

In MyCourses, answer the following questions:

- What information about the QUIC packets does Wireshark reveal as unencrypted?

- TCP is known to be hindered by _retransmission ambiguity_. Explain what
  that means. An old [paper by Karn and
  Partridge](https://dl.acm.org/doi/10.1145/55483.55484) discusses this issue.

- Does QUIC suffer from retransmission ambiguity similarly to TCP? Justify why.

- How do you recognize retransmitted data in the qlog and qvis analysis tools? Hint:
  See **[RFC 9000](https://datatracker.ietf.org/doc/html/rfc9000)** and sections
  12 (Packets and Frames) and 13 (Packetization and Reliability) for more
  information.

- Earlier, different strategies for handling concurrent I/O sources were discussed
  (e.g., I/O multiplexing with non-blocking sockets and multithreaded
  approaches). How does **quiche-server** handle concurrency?

- What stream IDs are used to transfer the data files? If there were a fourth
  file, what would likely be the stream ID? Why are these stream IDs used? Hint: See
  **[RFC 9000](https://datatracker.ietf.org/doc/html/rfc9000)** and section 2
  about streams for more information.

- What congestion control and recovery-related metrics does qlog show?

Let's now assume that `file-C.txt` contains more urgent data than the others,
and all files contain such _incremental_ information that even a portion of the
file is useful for the client as soon as possible. Adjust the stream priorities
so that `file-C.txt` gets a higher priority than the others, but ensure that the
transmission of all streams starts as soon as possible.

In MyCourses, report the start and completion times of each stream transfer for
all three files, both before and after the priority adjustment. Additionally,
provide the command-line used to start the client and include the resulting qlog
file from the client.
More information about stream priorities can be found in
**[RFC 9218](https://datatracker.ietf.org/doc/html/rfc9218)**.
You will need the `--send-priority-update` option in the `quiche-client` command
line and must add some query parameters to the HTTP URLs. You can use the `--help`
option to get more information about different command-line options and their
usage. Do not change the order in which the files are requested, but use stream
priorities.
