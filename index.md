---
title: Home
layout: home
---

# Advanced Networking course

These pages contain the material and assignments for the hands-on programming
and measurement tasks of the **Advanced Networking course (ELEC-E7321)** at
Aalto University. The assignment descriptions refer to MyCourse learning
platform available for students enrolled on the course. If you are not enrolled
on the course, but are just interested on the topic, feel free to try out the
tasks nevertheless.

The code examples and assignment templates in
this material are provided in the **[Rust](https://www.rust-lang.org/)** language.
However, you can use also other languages for your implementations and
experimentation, such as C or C++, or even Python. JavaScript is not a viable
option on this course.

Note that the material is still somewhat under development and there will be
changes and additions coming during the course. The GitHub repository for the
material is **[available](https://github.com/PasiSa/AdvancedNetworking)**. If you
find something to correct or add, feel free to drop an [GitHub
issue](https://github.com/PasiSa/AdvancedNetworking/issues/new)
in the repository, or just send [E-mail](mailto:pasi.sarolahti@aalto.fi) to the
author.

Links to currently available content:

- **[Setting up the exercise environment](environment.md)**. It is recommended
  that you read this with thought already before start of the course. The course
  assignments need to be run in a Linux system with various networking software
  installed. Therefore you should be able to run a virtual machine in your
  computer, hosting the Linux guest with needed software.

- **[Wireshark and Mininet](wireshark.md)**

- **[Socket programming basics](socket-basics.md)**

- **[Server sockets and concurrent connections](server-sockets.md)**

- **[UDP and datagram sockets](udp.md)**

- **[Linux networking](linux-tcpip.md)**

- **[Small code examples in C and Rust](examples.md)**

## Assignments

The assignment descriptions and other possible files needed for assignments are
under the
[assignments](https://github.com/PasiSa/AdvancedNetworking/tree/main/assignments)
folder in this git repository. The assignments also contain program templates
implemented in Rust that can be used to help you to get started with the
assignment. You may use the templates or implement your own solution from scratch.

One option is to clone or fork this repository to your local system, after which
you can start modifying the provided assignment templates, and maintain your
work in a forked personal git repository. This makes it easier to synchronize
your modifications between different systems, for example if you want to develop
you assignment code in your native system and development tools, but run the
code in the virtual Linux guest, that is technically a different machine in your
system.

The assignments are as follows:

- [Task 1: Simple client](assignments/task-001.md)
- [Task 2: TCP server](assignments/task-002.md)
- [Task 3: Data transfer using UDP](assignments/task-003.md)
- [Task: Experimenting with QUIC](assignments/task-quic.md)
- [Task: IP Tunnel](assignments/task-tun.md)
- _some more may be coming here..._
