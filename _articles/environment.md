---
title: The exercise environment
---

This guide will help you set up a Linux environment with **[Mininet](https://mininet.org/)** for network simulation exercises. Mininet is a network emulator that creates virtual network topologies for testing and experimentation.

## Prerequisites

- A computer capable of running virtual machines
- At least 4GB RAM and 20GB free disk space
- Basic familiarity with command line interfaces

## 1. Linux Environment Setup

### Virtual Machine Options

Since Mininet requires Linux, you'll need to set up a virtual machine if you don't have Linux installed natively. There are different options for virtual machine, including:

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

    sudo apt install ubuntu-desktop
    sudo reboot

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

## 2. Quick Installation

To install Mininet and all required networking tools for the Advanced Networking course, download and run the [installation script](../assets/install.sh):

```bash
# Verify that curl is installed
sudo apt install curl

# Download the installation script
curl -O https://raw.githubusercontent.com/PasiSa/AdvancedNetworking/main/assets/install.sh

# Make executable and run
chmod +x install.sh
./install.sh
```

### Installation Options

The script supports several command-line options for customization:

```bash
# View all options
./install.sh --help

# Custom installation directory
./install.sh --dir ~/ELEC-E7321

# Non-interactive mode (for automation)
./install.sh --non-interactive

# Test existing installation
./install.sh --test-only

# Clean installation (removes existing files)
./install.sh --clean
```

### Getting Help

If you encounter issues during installation:

1. **Check the script output** - All steps are clearly logged with colored status messages
2. **Review system requirements** - Ensure your Linux distribution is supported
3. **Verify internet connectivity** - The script downloads packages and source code
4. **Check disk space** - Ensure you have sufficient storage available
5. **Run with verbose output** - The script provides detailed information about each step

The installation typically takes 10-15 minutes depending on your system and internet speed. Once complete, you'll have a fully functional SDN development environment ready for network experiments and coursework.

## 3. Testing Your Installation

### Basic Mininet Test

Now Mininet should work. You can try it using one of our simple network
scripts:

    sudo INSTALL_DIR/mininet/aalto/simple_topo.py --delay=200ms

The script implements a simple topology with four nodes (titled "lh1", "lh2",
"rh1" and "rh2"), two routers, connected with a bottleneck link that has one-way
propagation latency of 200 ms. Mininet command line interface opens, where you
can run different programs in one of the emulated mininet nodes.

![Simple topology](/images/simple-topo.png "Simple topology"){: width="90%" .center-img }

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

## 4. SSH Access Setup (Optional)

**Optional:** When working with a virtual machine, it may be more convenient to
use the tools and terminal available in the host machine, and access the virtual
machine using a ssh connection between the host and virtual machine. First, the
virtual machine needs ssh server installed and started (sometimes this might
have been done already with the initial installation of the Linux distribution):

    sudo apt install openssh-server
    sudo systemctl start ssh
    sudo systemctl enable ssh

Next, check if the virtual machine's firewall is enabled.

    sudo ufw status

If the firewall is not active (i.e. the command responds with `Status: inactive`),
you do not need to run the next command. If the command responds with `Status: active`,
you need to enable ssh access with the command:

    sudo ufw allow ssh

After this you should find the IP addressed the virtual guest system uses
internally. Type

    ip addr show

and locate the IP address associated with a network interface. It should be an
address in the private address space, for example starting with 10.x.x.x or
192.168.x.x. This is the address you can use when connecting to the virtual
guest OS using ssh after this:

    ssh username@ip.address

Next, you need to set up port forwarding from your host machine to the virtual machine.
In the Virtualbox window, select your virtual machine. Go to
Settings -> Network -> Adapter 1 -> Advanced (arrow down) -> Port Forwarding.
This should open a list of Port Forwarding Rules. Create a new rule with the plus
icon and set the fields as following:

| Field          | Value         |
| -------------- | ------------- |
| **Name**       | ssh           |
| **Protocol**   | TCP           |
| **Host Port**  | 2222          |
| **Guest Port** | 22            |
| **Host IP**    | (Leave blank) |
| **Guest IP**   | (Leave blank) |

Your port forwarding rules should now look like this:

![Port forwarding rules](/images/virtualbox-port-forwarding.png "Port forwarding rules")

Finally, you should be able to access your virtual machine from your host machine using ssh.
To test it out, on your host machine, run the command:

    ssh -p 2222 username@localhost

Particularly, the popular development environment VScode can connect to a remote host using ssh,
in which case one can do development using the locally installed VScode in the host machine that
actually operates on the files in the remote machine over a ssh connection.

## 5. Course Software Setup

Many of the exercises on this course communicate with a tool called
"adnet-agent", that performs different tasks depending on the exercise, and
communicates using a protocol that will be eventually described along with the
assignments. Adnet-agent is implemented in [Rust
language](https://www.rust-lang.org/). Therefore, next you should install the
Rust build tools on your virtual machine by running:

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

Then follow instructions appearing on terminal.

Clone `adnet-agent` from git repository, for example in your home directory root

    cd $HOME
    git clone https://github.com/PasiSa/adnet-agent.git

Go to the `adnet-agent` directory and build the executable from source:

    cd adnet-agent
    cargo build

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
Internet that can be found with some googling. Using AI tools to assist with
programming is allowed, but please try to understand what you are doing and why.
Sometimes AI makes silly proposals.

Note that the cargo build and package management system used by Rust does not
work inside the Mininet virtual network, because it tries to contact resources
elsewhere in the Internet. Therefore, if you use Rust to develop your
implementations, instead of using `cargo run` in the Mininet environment you
should start the program directly from the binary executable you have compiled
using `cargo build` (typically under `target/debug` folder in your project
root), for example:

    target/debug/adnet-agent
