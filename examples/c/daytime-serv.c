// Daytime server example, taken and modified from W.R. Stevens'
// Unix Network Programming book

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <time.h>
#include <unistd.h>

#define MAXLINE 1024


int main(int argc, char **argv){

	int listenfd;
	int connfd;
	socklen_t len;
	struct sockaddr_in servaddr, cliaddr;
	char buff[MAXLINE];
	time_t ticks;

    // Requires port number as a command line argument
    if (argc != 2) {
        fprintf(stderr, "usage: daytime-serv <port>\n");
        return 1;
    }

    int port;
    if (sscanf(argv[1], "%d", &port) < 1) {
        fprintf(stderr, "invalid port number\n");
        return 1;
    }

	if ((listenfd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
		perror("listen");
		return 1;
	}
	
	bzero(&servaddr,sizeof(servaddr));
	servaddr.sin_family = AF_INET;
	servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
	servaddr.sin_port = htons(port);

	if (bind(listenfd, (struct sockaddr *) &servaddr, sizeof(servaddr)) < 0) {
		perror("bind");
		return 1;
	}

	listen(listenfd, 10);  // listen Queue for 10 pending connections

	// Loop forever, accept incoming connections one-by one.
	while(1) {

		len = sizeof(cliaddr);
		// active socket is created at connfd
		// Client address and port is written in cliaddr structure
		// inet_ntop converts binary address structure to string
		connfd = accept(listenfd, (struct sockaddr *) &cliaddr, &len);
		printf("connection from %s, port %d\n",
		    inet_ntop(AF_INET, &cliaddr.sin_addr, buff, sizeof(buff)),
		    ntohs(cliaddr.sin_port));

		ticks = time(NULL);
		snprintf(buff, sizeof(buff), "%.24s\r\n", ctime(&ticks));
		
		// In principle write could write only part of the buff, but it is
		// very unlikely for a newly accepted socket with this little data.
		// Note that we are intentionally not writing the trailing \0 from C string.
		if (write(connfd, buff, strlen(buff)) < 0) {
			perror("write");
			return 1;
		}

		close(connfd); // closes the active socket, not listening socket
	}
}