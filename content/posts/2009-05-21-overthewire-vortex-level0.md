+++
title = "OverTheWire: Vortex Level0"
date = "2009-05-21"
tags = ["coding", "wargames", "vortex", "c"]
category = "blog"
+++

So what's this whole thing about? "The wargames offered by the OverTheWire community can help you to learn and practice security concepts in the form of funfilled games." by [OverTheWire.org][1]. So I started with [Vortex][2] and coded an example how to read 4 integers from server, sum them up, send result to server and get the login information back from server again. Sounds quite simple. I admit I had to refresh my knowledge about linux socket programming and go through some coding examples. And here is my solution for[ level0][3]:

~~~.c
 * ========================================================
 *
 *       Filename:  vortex_level0.c  
 *
 *    Description:  Read 4 integers from vortex.labs.pulltheplug.org:5842, sum
 *                  them up, send result to server and get login data
 *
 *        Version:  1.0
 *        Created:  05/20/2009 08:53:53 PM
 *       Compiler:  gcc
 *
 *         Author:  Victor Dorneanu 
 *
 * ========================================================
 */
#include 
#include 
#include 
#include 
#include 
#include 
#include 
#include 
#include 
#include 

#define HOSTNAME "vortex.labs.pulltheplug.org"
#define PORT "5842"

void die(char *mess) { perror(mess); exit(1); }

int main(int argc, char *argv[]) {
   int sock, rv;
   struct addrinfo hints, *servinfo, *p;
   unsigned int buffer[4];
   char login_data[200];
   unsigned int received = 0;
   int i, bytes;

   /*  Construct the server addrinfo structure */
   memset(&hints, 0, sizeof hints);         /*  Clear struct */
   hints.ai_family = AF_UNSPEC;             /*  IPv4 or IPv6 */
   hints.ai_socktype = SOCK_STREAM;

   if ((rv = getaddrinfo(HOSTNAME, PORT, &hints, &servinfo)) != 0) {
		fprintf(stderr, "getaddrinfo: %s
", gai_strerror(rv));
		return 1;
	}

	// loop through all the results and make a socket
	for(p = servinfo; p != NULL; p = p-&gt;ai_next) {
		if ((sock = socket(p-&gt;ai_family, p-&gt;ai_socktype, p-&gt;ai_protocol)) == -1) {
			die("Couldn't create socket");
			continue;
		}
		break;
	}

   /*  Establish  connection */
   if (connect(sock, servinfo-&gt;ai_addr, servinfo-&gt;ai_addrlen) &lt; 0) {
      die("Failed to connect to server");
   }

   /* Read 4 integers from server */
   for (i = 0; i &lt; 4; i ++) 
      read(sock, &buffer[i], 4);

   /* Sum up integers */
   received = 0;
   for(i=0; i &lt; 4; i++)  
      received += buffer[i];

   /*  Send sum to the server */
   if (send(sock, &received, sizeof(received), 0) != sizeof received) {
      die("Mismatch in number of sent bytes");
   }

   /* Read login data */
   if (recv(sock, &login_data, 200, 0) &lt; 1) {
      die("Mismatch in number of received bytes");
   }

   fprintf(stdout,"login: %s
", login_data);

   /*  Free addrinfo structure */
   freeaddrinfo(servinfo);

   /* Close connection */
   close(sock);
   exit(0);
}

~~~

 [1]: http://www.overthewire.org/wargames/
 [2]: http://www.overthewire.org/wargames/vortex/
 [3]: http://www.overthewire.org/wargames/vortex/level0.shtml
