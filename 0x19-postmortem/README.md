
![Cod](https://media.tenor.com/4ehBI_jmjr8AAAAC/bravo-six-going-dark-captain-price.gif)

# Call Of Duty server requests failure report

Last week, it was reported that the call of Duty server was returning 500 Error on all requests made on the platform routes, all the services were down. 90% of the users were affected. The root cause was the failure of our master server on AWS Service host.

## Timeline
The error was realized on Saturday 26th February 1200 hours (East Africa Time) when our Site Reliability Engineer, Mr Price saw the master server lagging in speed. Our engineers on call disconnected the master server  for further system analysis and channelled all requests to a second server on Azure. They solved problem by Sunday 27th Febraury 2200 hours (East Africa Time).

## Root cause and resolution
The COD Server is served by 2 ubuntu cloud servers. The master server  was connected to serve all requests, and it stopped functioning due to memory outage as a results of so many requests because during a previous test, the client server  was disconnected temporarily for testing and was not connected to the load balancer afterwards.

The issue was fixed when the master server was temporarily disconnected for memory clean-up then connected back to the loadbalancer and round-robin algorithm was configured so that both the master and client servers can handle equal amount of requests.

## Measures against such problem in future
* Choose the best loadbalancing algorithm for your programs
* Always keep an eye on your servers to ensure they are running properly
* Have extra back-up servers to prevent your program fro completely going offline during an issue
