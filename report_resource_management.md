## Resource Management Best Practices for Kubernetes Report

This section discusses the importance of defining resource requests and limits for applications deployed in Kubernetes, a practice not currently observed in the project's Docker Compose files, and provides guidance for implementing it.

### Current State: Absence of Resource Definitions

A review of the `docker-compose.yml` and related files shows that no explicit CPU or memory resource allocations (like Docker Compose's `deploy.resources` block) are defined for the services. While some applications, like Elasticsearch (`ES_JAVA_OPTS`), might have internal memory settings (e.g., JVM heap size), these are not declarations that Docker or Kubernetes can use for resource management at the container level.

### Introduction to Kubernetes Resource Requests and Limits

In Kubernetes, you can specify resource **requests** and **limits** for each container within a Pod. These primarily apply to CPU and memory.

*   **Requests**:
    *   **CPU Request**: The amount of CPU that is guaranteed for the container. The Kubernetes scheduler uses this value to find a Node that has enough available CPU capacity for the Pod. CPU is typically measured in "cores" (e.g., `0.5` for half a core, `1` for one core) or "millicores" (e.g., `500m` for half a core).
    *   **Memory Request**: The amount of memory that is guaranteed for the container. When a Pod is scheduled, the scheduler ensures the selected Node has at least this much memory available. Memory is measured in bytes (e.g., `128Mi` for 128 Mebibytes, `1Gi` for 1 Gibibyte).
    *   If a container's resource usage exceeds its request, it might be throttled (for CPU) or continue to use more memory up to its limit.

*   **Limits**:
    *   **CPU Limit**: The maximum amount of CPU that the container can use. If a container tries to exceed its CPU limit, it will be throttled (its CPU usage will be capped).
    *   **Memory Limit**: The maximum amount of memory the container can use. If a container tries to allocate memory beyond its limit, it typically becomes a candidate for termination by the system (OOMKill - Out Of Memory Kill).
    *   It's common to set the memory limit higher than the request, but CPU limits can be more nuanced and sometimes are not set, allowing containers to burst to use available CPU if requests are met.

### Why Defining Requests and Limits is Crucial in Kubernetes

Specifying resource requests and limits is a fundamental best practice in Kubernetes for several reasons:

1.  **Cluster Stability and Resource Contention Prevention**:
    *   Requests ensure that Pods have the resources they need to run reliably.
    *   Limits prevent individual containers from consuming excessive resources and starving other containers on the same Node, which can lead to Node instability or application failures.

2.  **Effective Scheduling**:
    *   The Kubernetes scheduler uses resource requests to make intelligent decisions about where to place Pods. It will only place a Pod on a Node that has enough unallocated resources to satisfy the Pod's requests. Without requests, the scheduler operates with incomplete information.

3.  **Quality of Service (QoS) Classes**:
    *   Kubernetes assigns a Quality of Service (QoS) class to each Pod based on its resource requests and limits:
        *   **Guaranteed**: Pods where every container has both memory and CPU requests set, and these requests are equal to their respective limits. These Pods are given the highest priority and are least likely to be killed if a Node runs out of resources.
        *   **Burstable**: Pods where at least one container has a CPU or memory request set, but requests are not equal to limits for all containers (or some containers have requests but no limits). These Pods can use more resources than requested (up to their limits) if available. They are more likely to be killed than `Guaranteed` Pods if resources become scarce.
        *   **BestEffort**: Pods where no container has any CPU or memory requests or limits defined. These Pods have the lowest priority and are the first to be killed if the Node experiences resource pressure.
    *   Appropriate QoS classes help Kubernetes manage resource contention more predictably.

4.  **Cost Optimization (Cloud Environments)**:
    *   In cloud environments, Nodes (VMs) have associated costs. By accurately defining resource requests, you can pack Pods more efficiently onto Nodes, potentially reducing the number of Nodes required and thus lowering infrastructure costs. Over-provisioning (requesting much more than needed) can lead to wasted resources and higher costs.

### Determining Appropriate Values for Requests and Limits

Finding the right values is an iterative process:

1.  **Initial Estimation**: Start with educated guesses based on application type, expected load, and developer knowledge. For Java applications, consider JVM heap size settings (e.g., `-Xmx`) as a starting point for memory requests/limits.
2.  **Monitoring**: Deploy your application and use monitoring tools (like Prometheus, Grafana, or cloud provider monitoring services) to observe actual CPU and memory consumption under typical load.
3.  **Load Testing**: Perform load tests to understand how resource consumption changes under stress and peak conditions. This helps identify appropriate limits.
4.  **Iteration**: Adjust requests and limits based on monitoring and load testing data. It's common to start with slightly more generous requests/limits and then tune them down as you gain confidence in the application's resource profile.
5.  **Application Performance Metrics**: Correlate resource settings with application performance metrics (response times, error rates) to ensure that resource constraints are not negatively impacting users.

### Initial Step: Add Resource Definitions to Docker Compose

As a preliminary step to build discipline and start gathering baseline data, you can add resource definitions to your `docker-compose.yml`. Docker Compose (version 3+) supports a `deploy.resources` key that is similar in concept to Kubernetes requests (reservations) and limits.

**Example Docker Compose Snippet**:

```yaml
version: "3.8"
services:
  department-service:
    build:
      context: ../department-service
      dockerfile: Dockerfile
    # ... other configurations ...
    deploy:
      resources:
        reservations: # Analogous to Kubernetes requests
          cpus: '0.25' # 0.25 CPU cores
          memory: 256M
        limits:       # Analogous to Kubernetes limits
          cpus: '0.5'  # 0.5 CPU cores
          memory: 512M
    # ...
```
This won't directly translate to Kubernetes resource management but can help:
*   Developers start thinking about resource needs.
*   Provide initial values that can be used as a starting point for Kubernetes manifests.
*   Some local testing tools might respect these for simulating resource constraints.

### Consequences of Not Setting Requests and Limits in Kubernetes

If you deploy Pods to Kubernetes without setting resource requests and limits:
*   They will be assigned the `BestEffort` QoS class.
*   These Pods are the most likely to be killed during Node resource shortages.
*   The scheduler has no information to make optimal placement decisions, potentially leading to uneven resource distribution and "noisy neighbor" problems where one Pod negatively impacts others by consuming too many resources.
*   It becomes very difficult to manage cluster capacity and predict resource needs.

Defining resource requests and limits is a cornerstone of running applications reliably and efficiently in Kubernetes. It is strongly recommended to make this a standard practice for all services being migrated.
