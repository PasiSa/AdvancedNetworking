---
layout: home
---

# Advanced Networking course

These pages contain the material and assignments for the **Advanced Networking
course (ELEC-E7321)** at Aalto University. The assignment descriptions refer to
_MyCourses_ learning platform available for students enrolled on the course. If you
are not enrolled on the course, but are just interested on the topic, feel free
to try out the tasks nevertheless.

The code examples and assignment templates in this material are provided in the
**[Rust](https://www.rust-lang.org/)** language, and some that are closer to the
kernel and device interface level also in C. However, you may use any language
of your preference for the assignments. Some of the assignments closer to the
kernel and network drivers may not be doable with higher-level interpreted
languages, though.

The GitHub repository for the
material is **[available](https://github.com/PasiSa/AdvancedNetworking)**. If you
find something to correct or add, feel free to drop an [GitHub
issue](https://github.com/PasiSa/AdvancedNetworking/issues/new)
in the repository, or just send [E-mail](mailto:pasi.sarolahti@aalto.fi) to the
author.

The course structure is the following:

1. Introduction
1. [Network programming basics](socket-basics/)
1. [Server programming and managing concurrency](server-sockets/)
1. Congestion control
1. Evolution of the Web and the QUIC protocol
1. Linux Networking Internals
1. Software Defined Networking and Programmable Networks
1. Datacenter networking
1. Internet of Things and challenged networks

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

The following assignments are available:

- [Simple client](assignments/task-cli.md)
- [TCP server](assignments/task-srv.md)
- [Data transfer using UDP](assignments/task-udp.md)
- _More will be coming later_
