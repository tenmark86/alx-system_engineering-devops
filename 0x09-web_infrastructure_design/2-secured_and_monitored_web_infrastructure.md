# 2-secured_and_monitored_web_infrastructure.md

![image](https://user-images.githubusercontent.com/83606182/185594619-2cbe51ff-afbf-4de9-879c-70078be3769f.png)


## Firewalls:
The firewall filters the content that enters and leaves our networks through certain rules known as access control list, these rules can be set by the network administrator according to their needs. Some of the elements that the firewall uses to determine if the information it receives can access or leave the network are: IP addresses, domain names, protocols, ports and keywords, among others. There are many types of firewalls and the choice of which to use depends on the needs of the network.

## SSL Certificate (Secure Socket Layer):
It is a global security standard that allows a connection to be kept secure, authenticates the identity of the servers and encrypts the information exchanged using a system of keys, one public and one private, without which it is almost impossible to decrypt the information in case of being intercepted

## Monitoring:
With this application we monitor servers taking data from it and send it to the application servers (Ex. NewRelic) and there reports on vulnerabilities and security violations are generated, then It will give you a detailed analysis about your server and application.

## What to do if you want to monitor your web server QPS?
You can install a Monitor client on your server to monitor your QPS

## Why having only one MySQL server capable of accepting writes is an issue?
If the primary MySQL database is down, the entire site will not be able to make changes (add or remove users).

## Why having servers with all the same components (database, web server and application server) might be a problem?
Because the instructions given by one server can collide with instructions from the other and cause problems
