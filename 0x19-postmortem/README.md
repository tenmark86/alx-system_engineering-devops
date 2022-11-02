Elastic Cloud Incident Report: February 4, 2019
On Monday, February 4, 2019, at roughly 02:50 UTC, Elastic Cloud customers with deployments in the AWS us-east-1 region experienced degraded access to their clusters.
After any incident, we perform a detailed post mortem to understand what went wrong, find the root causes, and discover what we can do to ensure that it doesn’t happen again.
We’d like to share the root cause analysis we performed, the actions we’ve taken, and those we intend to take in the future to prevent incidents like this from happening again.
If you have additional concerns or questions, don’t hesitate to reach out to us through support@elastic.co.
Sincerely,
The Elastic Cloud team
Background
At a high level, the Elastic Cloud backend in each supported region consists of three main layers:
Allocator layer: Hosts for Elasticsearch and Kibana instances.
Coordination layer: This layer holds the system state, connected allocators, and maintains the actual location of each cluster's nodes and Kibana instances. This is implemented by a three-node Apache ZooKeeper ensemble.
Proxy layer with two parts:
Proxy/routing layer: Routes traffic to cluster nodes and Kibana instances based on that cluster’s virtual host name, fronted by a load-balancing layer which load balances between multiple proxy instances.
Proxy ZooKeeper Observer layer: This is a replica of the coordination layer and is used by the proxy services to reduce load on the coordination layer during normal operation.
To enable inter-host traffic using TLS, an ancillary container is used for services like Kibana to communicate internally to its Elasticsearch cluster securely. Each allocator host is running that container to allow secure, auditable connections to other hosts within Elastic Cloud.
What Happened
On 2019-02-04 Elastic Cloud customers experienced cluster connectivity instability issues and later a major service disruption in the AWS us-east-1 region. Deployments of Elasticsearch Service on Elastic Cloud in the AWS us-east-1 region would have been partially or completely unavailable between 02:50 and 09:28 UTC.
The majority of customers in us-east-1 also experienced Kibana access disruptions from 02:50 to 09:28 UTC, and a smaller number of customers had degraded access to their Kibana instances until 18:44 UTC.
The Elastic Cloud User Console was in a degraded state from 02:50 to 07:17 UTC and all customers using the Elastic Cloud Console would have seen increased timeouts as they were trying to view their active deployments.
The incident began following a routine patching procedure for the coordination layer in our AWS us-east-1 region. Despite following the same process as the other 12 regions, patching of our coordination service, ZooKeeper, in this region did not go as expected, resulting in an outage of the coordination services.
All times below are in UTC.
2019-02-04 02:25-02:45: First and second ensemble members were replaced with patched hosts.
2019-02-04 02:45: The ZooKeeper ensemble came under high load (CPU, IO, memory), with large numbers of client connection failures and re-connects across the ensemble. This continued for several minutes. The ensemble then appeared to stabilize, machine load decreased, outstanding request counts decreased, and connection failures decreased.
2019-02-04 02:50: The ZooKeeper ensemble undertook a leader election. Logging indicated that the ensemble leader was overwhelmed by incoming connections and shut down. The ensemble wasn’t able to quickly re-establish and maintain a quorum due to the incoming request load.
2019-02-04 02:50: An increase in HTTP 5xx errors was identified on the load balancer.
2019-02-04 02:55: Latency within the ZooKeeper ensemble increased due to ensemble instability, which in turn led to further client reconnections and instability in the ZooKeeper observer layer.
2019-02-04 03:22: Sweeping restart of internal services to reduce client connection problems.
2019-02-04 03:31: Quorum stabilized and engineering monitored the situation for ~20 minutes and, separately, a discussion was had about next steps. A call was made to roll forward with the operation.
2019-02-04 04:07: Roll-forward began for the remaining ensemble member.
2019-02-04 04:15: System-level unresponsiveness was observed on the final ensemble member; troubleshooting began, but multiple issues cropped up.
2019-02-04 04:39: Isolated ensemble by cutting off client connections to stabilize the system.
2019-02-04 04:46: Roll-back of the remaining ensemble member began after host instability was observed.
2019-02-04 05:25: Roll-back of the second ensemble member began due to host instability.
2019-02-04 05:48: First-seen runc bugs led to CPU softlocks and rendered the system unresponsive for two members of the ZooKeeper ensemble. The hosts had to be rebooted to mitigate this bug.
2019-02-04 06:00: Sweeping restart of internal services to reduce client connection problems; started working to identify what exactly was causing the host instability within ensemble members.
2019-02-04 06:45: Identified the root issue causing ensemble member instability: when entering the network namespace of a TLS proxying service container, runc would trigger a kernel OOPS and CPU softocks spanning minutes.
2019-02-04 07:10: A stable quorum was established by reducing client load and reducing operator debugging actions on the impacted ZooKeeper hosts.
2019-02-04 07:17: Incoming traffic was reintroduced and the customer control plane was brought back online.
2019-02-04 07:30: Once the client connections were re-established, the proxy layer began to exhibit high load due to a large influx of external re-connections. This caused instability in the proxy ZooKeeper observer layer, which led to continued unavailability in the proxy layer itself (i.e., customers still encountered issues connecting to their clusters).
2019-02-04 09:19: Once the ZooKeeper ensemble and observers were stable, the proxy fleet was scaled up and out to handle the increased traffic to ES clusters. A three-fold increase of requests to our proxy layer was noted.
2019-02-04 09:28: Availability to Elasticsearch deployments was restored. All proxies were now serving traffic and the error rate dropped to pre-incident levels.
While availability to Elasticsearch deployments was fully restored at 2019-02-04 09:28, Kibana deployments suffered an extended period of unavailability:
2019-02-04 09:35: CPU usage on Kibana host instances was observed to be much higher than usual. It was identified that our internal TLS proxying service was the main contributor.
2019-02-04 09:53: Kibana instances were not able to connect to their target Elasticsearch clusters due the internal TLS proxying service being unable to forward requests to the proxy layer. As Kibana was not closing sockets after a failed attempt, the number of open sockets grew out of bounds, filling the nf_conn_track table and causing a high strain on the internal proxying containers.
2019-02-04 12:30: A remediation runbook was developed and applied to mitigate the issue with Kibana instances exhibiting the connection issue. The runbook restarted the internal proxying container and Kibana instances, and also applied sysctl limits to prevent these issues from recurring in the future.
2019-02-04 18:44: Kibana access was fully restored.












Root Cause
At a high level, the problems included a combination of the below:
Failure in coordination layer
Failure in proxy/routing layer
While performing routine maintenance of the Elasticsearch Service coordination layer in the AWS us-east-1 region, an engineer carrying out the operation encountered an unfamiliar error. The engineer was following the documented procedure of replacing the underlying hosts, which had previously been successful when performed in other regions. Service metrics had reported the hosts as healthy, thus signaling that it was safe to proceed with the maintenance; however, the metrics proved to be insufficient in conveying the state of individual hosts and of the coordination layer as a whole. This led to unanticipated instability on and between hosts, which ultimately led to an overall failure of the coordination layer.
Due to dependencies of other platform components with the coordination layer, instability and loss of quorum in the coordination layer caused a major service disruption. A set of unrelated issues were encountered while investigating the primary source of the outage, which contributed to a further delay of the final resolution. Individually successful mitigation actions by our response team proved to be temporarily inefficient due to the scale of the failures being addressed, making a full resolution both more complicated and more difficult to achieve.
Resolution
Quorum within the ZooKeeper ensemble was re-established by removing client load where possible, giving the ensemble time to stabilize before gradually re-introducing client load.
The ZooKeeper observer layer utilized by the proxies was stabilized by increasing the initLimit setting. This setting controls the amount of time followers are allowed to connect and sync to a leader. Increasing this limit stabilized the observer layer, which flowed down to the proxy layer.
The extended availability issues with Kibana instances were resolved by restarting the internal proxying container and affected Kibana instances en masse. As part of the RCA investigation, it was identified that a set of previously unknown bugs in Kibana was resulting in connection leaks and HTTP request amplification back to the load balancing layer, driving extra traffic to the proxy layer and Elasticsearch deployments.
Impact
Coordination layer
100% of customers in us-east-1
Inability to create, modify, or delete clusters through the customer control panel
ZooKeeper was unavailable between 02:50 UTC and 07:17 UTC
Proxy layer
Proxy layer was impacted between 02:50 UTC and 09:15 UTC and 100% of customers within us-east-1 were affected in some way; our data indicates that every Elasticsearch cluster saw some failures during this time period
Inability to access Elasticsearch/Kibana/APM services within running clusters
Proxy remediation work began when ZooKeeper was made available again at 07:30 UTC
Kibana
This was a result of a set of cascading failures. Access to Kibana was impacted by the aforementioned proxy layer outage.
Kibana instances were impacted between 02:50 UTC and 18:44 UTC
Access was initially impacted by proxy layer availability as well as service discovery issues
A number of hosts affected by a bug in our internal TLS proxying service triggered by extended unavailability were identified and fixed
A socket leak in Kibana was identified and mitigated by restarting Kibana containers
Other issues with Kibana that were determined to lead to request amplification are also being investigated
Action Items
A number of action items have come from this extended incident and are actively being worked on by the Elastic Cloud team. These include the following:
Engineering and Architecture
Reduced the dataset size carried by our ZooKeeper ensembles by over 60%. By doing so, network and disk I/O requirements for ZooKeeper are greatly reduced during normal operation, as well as providing faster recovery times for ensemble members joining the quorum. (Completed)
Reduced the number of health-checks and intervals required to allow a proxy node, marked as healthy, to join our load balancing layer as eligible targets to route traffic. This action item aims to reduce the mean time to recovery. (Completed)
Further revamp the logic around our proxy health-checks to not account for ZooKeeper connectivity as part of the checklist. With this change, once a proxy is successfully initialized, and has received its configuration and cluster routes, it will no longer drift to an unhealthy state due to the state of the supporting ZooKeeper ensemble. This change aims to sacrifice a potential small consistency skew over general availability. (In progress)
Canarying the ground up rewrite of our proxy layer in production regions, as one of the final steps to switch to our proxy v2 architecture. The v2 architecture decouples the proxy service from the ZooKeeper state. (In progress)
Improve visibility around ZooKeeper by further investing in our internal logging strategy and introducing better metrics around the ZooKeeper processes, the JVM, and container/host systems. (In progress)
Improve resiliency in Kibana routes discovery methods. (In progress)
Identifying and solving issues with Kibana that lead to internal HTTP request amplifications during availability events. (In progress)
Identifying and solving issues with Kibana that lead to connection leaking. (In progress)
Identified and mitigated issues with internal monitoring agents not employing proper backoff strategies with Jitter. (Completed)
Process and Communications
Formalized our maintenance matrix to reduce exposure of critical services within a region. We will be operating within specific timeframes for each region to limit the exposure of a failure to non-critical times. (Completed)
