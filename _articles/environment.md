---
title: The exercise environment
---

## Setting up Mininet

Many of the exercises on this course use the **[Mininet
emulator](https://mininet.org/)** to build virtual network environments with given
topologies and characteristics. Mininet requires Linux to run. If you do not
have a Linux system available, you will need a virtual machine hosting the Linux
system.

There are different options for virtual machine, including:

- [VirtualBox](https://www.oracle.com/virtualization/technologies/vm/downloads/virtualbox-downloads.html)
  is available for all common operating systems.

- [VMware](https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion)
  is another option that should be available for major operating systems.

- [Parallels](https://www.parallels.com/products/desktop/) is a good option for
  Mac users who have money (it is not freely available).

- [UTM](https://mac.getutm.app/) is a free alternative for Mac users. After
  installing UTM, you should find the [Ubuntu 22.04
  image](https://mac.getutm.app/gallery/ubuntu-20-04) provided in UTM gallery,
  that you can install.

After installing the virtual machine, you should install the actual operating
system from an ISO image. We have used [Ubuntu
24.04](https://ubuntu.com/download) desktop. Note that the Ubuntu 24.04 desktop
version is not available for ARM-based Mac, so Mac users should rather find the
ARM-based version of Ubuntu 24.04 server, and then after booting the server
installation, separately install Ubuntu desktop tools with `apt`, and then
reboot again the virtual machine:

```bash
sudo apt install ubuntu-desktop
sudo reboot
```

Note, that the above is not needed, if you use UTM that provides a separate
image in its gallery.

As the next step, you install and use the needed networking tools, according to
the instructions in this chapter.

If you are using Windows, you should note that Windows Subsystem for Linux does
not work (at least very easily) with mininet and other networking tools used on
this course, but you'll need an actual virtual machine installation.

The course assignments and software are tested on a recent Ubuntu Linux
distribution, but other distributions may work as well. Mininet is mostly
implemented using Python, and we have used Python version 3.12 for testing. The
rest of the instructions assume Ubuntu distribution.

We assume that you are at least elementary familiar with the basic operation of
the command line interface. In your Ubuntu system, locate "Terminal" to open a
command line terminal window, where you start working on the following
instructions.

After getting your virtual machine up and running, you should update the Ubuntu
packages and install a few other packages needed by the tools in this course:

```bash
sudo apt-get update
sudo apt-get upgrade
sudo apt install git python-is-python3 help2man pip python3-pip net-tools
sudo apt install telnet cgroup-tools cgroupfs-mount iputils-ping curl
```

Clone Mininet from git repository. On this course we use our own fork that has a
few additional scripts and modifications compared to the original parent
repository:

```bash
git clone https://github.com/PasiSa/mininet
```

After this, install mininet, along with some additional network tools it needs:

```bash
mininet/util/install.sh -fw
sudo apt-get install openvswitch-switch
sudo service openvswitch-switch start
cd mininet
sudo make install
```

Now Mininet should work. You can try it using one of our simple network
scripts:

```bash
sudo aalto/simple_topo.py --delay=200ms
```

The script implements a simple topology with four nodes (titled "lh1", "lh2",
"rh1" and "rh2"), two routers, connected with a bottleneck link that has one-way
propagation latency of 200 ms. Mininet command line interface opens, where you
can run different programs in one of the emulated mininet nodes.

![Simple topology](/images/simple-topo.png "Simple topology")

For example, typing `lh1 ping rh1` starts a ping tool at "lh1" (at IP address
10.0.0.1) that sends ICMP echo requests to "rh1" (at IP address 10.0.0.3), that
replies them. You should see the output on terminal, in most cases reporting a
bit over 400 ms delay in getting responses, because the packets travel through
the bottleneck link that has 200 ms propagation time.

Sometimes it happens that mininet crashes in the middle of simulation, or when
it is starting up. In this case some of the network state may end up in
unfinished state that prevents mininet from being started again. In such
situation you can clean up the network state by typing `sudo mn -c`, and try to
start mininet after that.

## Working over ssh from the host machine (UTM)

**Optional:** When working with a virtual machine, it may be more convenient to
use the tools and terminal available in the host machine, and access the virtual
machine using a ssh connection between the host and virtual machine. First, the
virtual machine needs ssh server installed and started (sometimes this might
have been done already with the initial installation of the Linux distribution):

```bash
sudo apt install openssh-server
sudo systemctl start ssh
sudo systemctl enable ssh
```

After this you should find the IP addressed the virtual guest system uses
internally. Type

```bash
ip addr show
```

and locate the IP address associated with a network interface. It should be an
address in the private address space, for example starting with 10.x.x.x or
192.168.x.x. This is the address you can use when connecting to the virtual
guest OS using ssh after this:

```bash
ssh username@ip.address
```

Particularly, the popular development environment _VScode_ can connect to a
remote host using ssh, in which case one can do development using the locally
installed VScode in the host machine that actually operates on the files in the
remote machine over a ssh connection.

## Working over ssh from the host machine (Virtualbox)

**Optional:** When working with a virtual machine, it may be more convenient to
use the tools and terminal available in the host machine, and access the virtual
machine using a ssh connection between the host and virtual machine. First, the
virtual machine needs ssh server installed and started (sometimes this might
have been done already with the initial installation of the Linux distribution):

```bash
sudo apt install openssh-server
sudo systemctl start ssh
sudo systemctl enable ssh
```

Next, check if the virtual machine's firewall is enabled. 

```bash
sudo ufw status
```

If the firewall is not active (i.e. the command responds with `Status: inactive`), you do not need to run the next command. If the command responds with `Status: active`, you need to enable ssh access with the command:

```bash
sudo ufw allow ssh
```

Next, you need to set up port forwarding from your host machine to the virtual machine. In the Virtualbox window, select your virtual machine. Go to Settings -> Network -> Adapter 1 -> Advanced (arrow down) -> Port Forwarding. This should open a list of Port Forwarding Rules. Create a new rule with the plus icon and set the fields as following:

| Field        | Value            |
|--------------|------------------|
| **Name**     | ssh              |
| **Protocol** | TCP              |
| **Host Port**| 2222             |
| **Guest Port**| 22              |
| **Host IP**  | (Leave blank)    |
| **Guest IP** | (Leave blank)    |

Your port forwarding rules should now look like this:

![Port forwarding rules](/images/virtualbox-port-forwarding.png "Port forwarding rules")


Finally, you should be able to access your virtual machine from your host machine using ssh. To test it out, on your host machine, run the command:

```bash
ssh -p 2222 username@localhost
```

Particularly, the popular development environment VScode can connect to a remote host using ssh, in which case one can do development using the locally installed VScode in the host machine that actually operates on the files in the remote machine over a ssh connection.

## Setting up the course exercise software

Many of the exercises on this course communicate with a tool called
"adnet-agent", that performs different tasks depending on the exercise, and
communicates using a protocol that will be eventually described along with the
assignments. Adnet-agent is implemented in [Rust
language](https://www.rust-lang.org/). Therefore, next you should install the
Rust build tools on your virtual machine by running:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Then follow instructions appearing on terminal.

Clone `adnet-agent` from git repository, for example in your home directory root

```bash
cd $HOME
git clone https://github.com/PasiSa/adnet-agent.git
```

Go to the `adnet-agent` directory and build the executable from source:

```bash
cd adnet-agent
cargo build
```

We will tell more about `adnet-agent` later with the assignments. You can find
the adnet-agent source code in the [git
repository](https://github.com/PasiSa/adnet-agent).

**Optional:** If you want to use git for managing your own code development, you
should also set up ssh keys on your virtual machine, that are needed for git
access. New keys can be generated using `ssh-keygen` command on command line
terminal. You can use default options to questions `ssh-keygen` presents. Copy
the public key (`$HOME/.ssh/id_rsa.pub`) to your GitHub settings: "Settings /
SSH and GPG keys" from the top right corner in GitHub web interface, then press
"New SSH key", and copy the public key to the correct text field. You can output
the key on Linux terminal by typing `cat $HOME/.ssh/id_rsa.pub`.

Some of the course assignments involve programming network software. To help you
get started with the assignments, the course material contains code examples
written in the **Rust** language. Recently, Rust has gained popularity among
people working with network software to replace older languages such as C or
C++, for example, due to its properties related to safer memory management.
However, the exercises are designed so that they do not require any particular
programming language. Therefore you can use also C or C++ in the to implement
the exercise assignments. Also Python should work, although it may be a bit more
difficult to operate on binary data with Python, which many of the exercises on
this course require. JavaScript is not a viable choice on this course.

If you are new to Rust, don't be afraid to try it. The Rust development team has
provided comprehensive [online resources](https://www.rust-lang.org/learn) for
learning Rust. You can start, for example, from the [Rust
book](https://doc.rust-lang.org/book/). There are plenty of Rust examples in the
Internet that can be found with some googling. Also ChatGPT knows Rust pretty
well.

Note that the cargo build and package management system used by Rust does not
work inside the Mininet virtual network, because it tries to contact resources
elsewhere in the Internet. Therefore, if you use Rust to develop your
implementations, instead of using `cargo run` in the Mininet environment you
should start the program directly from the binary executable you have compiled
using `cargo build` (typically under `target/debug` folder in your project
root), for example:

    target/debug/adnet-agent
