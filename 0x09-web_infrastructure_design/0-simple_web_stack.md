# 0. Simple web stack

https://i.imgur.com/oEfGB3O.jpg

# About infrastructure:
When the user types a web address that they want to access, in this case www.foobar.com, this HTTP request travels the internet and queries DNS for its IP address, as we have www before the domain name the DNS look at CNAME record where www.foobar.com points to, in our case it points to IP 8.8.8.8. In this ip address is where our server is, that is located in a data center. The server can be physical or virtual. This server runs an OS (operating system). We use Linux as an OS. Once on the server, it accesses to the port 80 (8.8.8.8:80) which is where our web server is, it is in charge of talking to the client, waiting for an “HTTP request” from a client to reply with an “HTTP respond” sending static files (HTML and CSS). This web server is inside an application server, this application is in charge of all the logic of the server as well as the database, it is in charge of generating the static files to send them through the web server. Our Database contains customer data and data necessary for the operation of the application.

# The issues are with this infrastructure:
Single Point of Failure (SPOF): In our case it is the same server since it communicates directly with the client, although it could fail in other places such as: the single database, the dns, the application server, a bottleneck in the communication. Downtime: In this design, we do not have a backup server in case we want to update the application, this leads to a service interruption every time we want to update the application. Cannot scale: It is designed for a small application with few clients, to scale the service the design would have to be changed, this leads to changing the infrastructure (server, etc.).
