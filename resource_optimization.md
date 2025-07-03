# Resource Optimization Summary

This document summarizes the CPU resource request adjustments made to the Kubernetes deployments and statefulsets to address scheduling issues due to insufficient CPU on the OKE cluster (2 nodes, 1 OCPU/6GB RAM per node).

**Total Available CPU:** 2000m (2 nodes * 1000m/node)
**Original Total CPU Requests:** 3050m
**New Total CPU Requests:** 1675m

## Changes Made:

The following table details the original and new CPU requests (`resources.requests.cpu`) for each modified service. Memory requests were kept the same as the primary issue was CPU. Limits were also largely unchanged but should be monitored.

| Service YAML File                          | Original CPU Request | New CPU Request | Change (Saved) |
|--------------------------------------------|----------------------|-----------------|----------------|
| `deployments/adminer-deployment.yaml`          | `50m`                | `25m`           | `25m`          |
| `deployments/api-gateway-deployment.yaml`    | `250m`               | `150m`          | `100m`         |
| `deployments/config-server-deployment.yaml`  | `250m`               | `150m`          | `100m`         |
| `deployments/department-service-deployment.yaml` | `250m`               | `150m`          | `100m`         |
| `deployments/employee-service-deployment.yaml` | `250m`               | `150m`          | `100m`         |
| `deployments/frontend-deployment.yaml`         | `100m`               | `75m`           | `25m`          |
| `deployments/grafana-deployment.yaml`        | `100m`               | `50m`           | `50m`          |
| `deployments/kibana-deployment.yaml`         | `100m`               | `50m`           | `50m`          |
| `deployments/logstash-deployment.yaml`       | `200m`               | `100m`          | `100m`         |
| `deployments/prometheus-deployment.yaml`     | `200m`               | `100m`          | `100m`         |
| `deployments/service-registry-deployment.yaml`| `100m`               | `75m`           | `25m`          |
| `deployments/zipkin-deployment.yaml`         | `100m`               | `50m`           | `50m`          |
| `statefulsets/elasticsearch-statefulset.yaml`| `500m`               | `250m`          | `250m`         |
| `statefulsets/mysql-department-statefulset.yaml`| `200m`              | `100m`          | `100m`         |
| `statefulsets/mysql-employee-statefulset.yaml`| `200m`              | `100m`          | `100m`         |
| `statefulsets/rabbitmq-statefulset.yaml`     | `200m`               | `100m`          | `100m`         |
| **Total Saved**                            |                      |                 | **`1375m`**    |

## Future Considerations:

*   **Performance Monitoring:** Closely monitor application performance. If critical services are too slow, you may need to:
    *   Further reduce CPU requests for less critical/background services.
    *   Temporarily scale down non-essential services to 0 replicas.
    *   Allocate slightly more CPU to the struggling critical services while still staying under the 2000m total.
*   **Memory Usage:** While this intervention focused on CPU, keep an eye on memory usage as well. If pods experience OOMKilled events, memory requests/limits may also need adjustment.
*   **Horizontal Pod Autoscaling (HPA):** If not already in use, consider implementing HPA for stateless services. This can help manage resources more dynamically but requires careful tuning of metrics and request/limit settings.
*   **Node Resource Upgrade:** If performance remains an issue across multiple services and further optimization of requests isn't viable, the long-term solution would be to increase OCPU capacity in your OKE node pool.
*   **Resource Quotas and LimitRanges:** Consider defining ResourceQuotas per namespace and LimitRanges to enforce sensible defaults for requests and limits, preventing future overallocation issues.

This optimization aims to allow all workloads to be scheduled. Further fine-tuning will likely be necessary based on observed performance and specific application needs.
