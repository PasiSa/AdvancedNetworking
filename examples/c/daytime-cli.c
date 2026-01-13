// Simple daytime client -- modified from Stevens' example at
// intro/daytimetcpcli.c

#include <sys/socket.h>  // defines socket, connect, ...
#include <netinet/in.h>  // defines sockaddr_in
#include <strings.h>     // defines memset
#include <stdio.h>       // defines printf, perror, ...
#include <arpa/inet.h>   // inet_pton, ...
#include <unistd.h>      // read, ...
#include <string.h>      // memset

#define MAXLINE 80

int main(int argc, char **argv)
{
    int sockfd, n;
    char recvline[MAXLINE + 1];
    struct sockaddr_in servaddr;

    // Requires IPv4 address and server port number as a command line argument
    if (argc != 3) {
        fprintf(stderr, "usage: daytime-cli <IPaddress> <port>\n");
        return 1;
    }

    int port;
    if (sscanf(argv[2], "%d", &port) < 1) {
        fprintf(stderr, "invalid port number\n");
        return 1;
    }

    // Open a stream (TCP) IPv4 socket, and check if successful
    if ( (sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        perror("socket error");
        return 1;
    }

    memset(&servaddr, 0, sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    servaddr.sin_port   = htons(port);  // convert to network byte order
    
    // Convert string from command line into binary IPv4 address structure
    if (inet_pton(AF_INET, argv[1], &servaddr.sin_addr) <= 0) {
        fprintf(stderr, "inet_pton error for %s\n", argv[1]);
        return 1;
    }

    // Connect to IP address and port indicated by servaddr
    // Check if it was successful
    if (connect(sockfd,
                (struct sockaddr *) &servaddr,
                sizeof(servaddr)) < 0) {
        perror("connect error");
        return 1;
    }

    printf("Connect has completed. Press something\n");
    getchar();

    // Read data from socket, at most 80 (=MAXLINE) bytes
    // The result will appear in recvline
    // n contains number of bytes read, or 0 on endfile,
    // or < 0 on error
    // There is a loop, because the full line may not complete in single read
    while ( (n = read(sockfd, recvline, MAXLINE)) > 0) {
        recvline[n] = 0; // null terminate for printing purposes

        //  output to stdout (e.g., terminal display)
        if (fputs(recvline, stdout) == EOF) {
            fprintf(stderr, "fputs error\n");
            return 1;
        }
    }

    // If read return value was 0, loop terminates, without error
    if (n < 0) {
        perror("read error");
        return 1;
    }
    printf("Connection was closed.\n");
    return 0;
}
