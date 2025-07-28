# Helicone Infrastructure Helm Chart

This Helm chart deploys infrastructure components for Helicone, including monitoring, observability, and AWS Load Balancer Controller for managing Application Load Balancers (ALBs).

## Components

### AWS Load Balancer Controller

The AWS Load Balancer Controller manages AWS Elastic Load Balancers for a Kubernetes cluster. It provisions ALBs when you create Kubernetes Ingress resources with the appropriate annotations.

#### Prerequisites

- EKS cluster with IAM roles configured (handled by Terraform)
- Service account `aws-load-balancer-controller` created with proper IAM permissions

#### How it works

1. The controller watches for Ingress resources with `ingressClassName: alb`
2. When found, it creates and configures an ALB based on the annotations
3. The ALB routes traffic to the appropriate Kubernetes services

### Nginx Ingress Controller

Provides a Network Load Balancer (NLB) for general ingress needs.

### Monitoring Stack

- Prometheus for metrics collection
- Tempo for distributed tracing
- OpenTelemetry Collector for telemetry data
- Loki for log aggregation
- Beyla for eBPF-based observability

### Cluster Autoscaler

Automatically adjusts the number of nodes in your cluster based on pod resource requests.

## Installation

### 1. Ensure Terraform has been applied

```bash
cd terraform/eks
terraform apply
```

This creates the necessary IAM roles and policies for the AWS Load Balancer Controller.

### 2. Update Helm dependencies

```bash
cd charts/helicone-infrastructure
helm dependency update
```

### 3. Install the chart

```bash
helm install helicone-infrastructure . -f values.yaml -n helicone-infrastructure --create-namespace
```

## Configuration

### AWS Load Balancer Controller

Key configuration in `values.yaml`:

```yaml
awsLoadBalancerController:
  enabled: true
  clusterName: "helicone" # Must match your EKS cluster name
  serviceAccount:
    create: false # Using Terraform-created service account
    name: "aws-load-balancer-controller"
```

### Using ALB with Services

To use an ALB for your service, create an Ingress with:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-service
  annotations:
    alb.ingress.kubernetes.io/load-balancer-name: "my-alb"
    alb.ingress.kubernetes.io/scheme: "internet-facing"
    alb.ingress.kubernetes.io/target-type: "instance"
spec:
  ingressClassName: alb
  rules:
    - host: example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-service
                port:
                  number: 80
```

## Verifying Installation

### Check AWS Load Balancer Controller

```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

### Check ALB creation

```bash
# After creating an Ingress with ALB annotations
kubectl get ingress -A
# Check AWS Console or CLI for ALB
aws elbv2 describe-load-balancers
```

## Troubleshooting

### ALB not created

1. Check controller logs: `kubectl logs -n kube-system deployment/aws-load-balancer-controller`
2. Verify IAM permissions are correct
3. Ensure ingress has `ingressClassName: alb`
4. Check that service type is `NodePort` or `ClusterIP`

### Health check failures

1. Verify the health check path exists and returns 200
2. Check security groups allow traffic from ALB to nodes
3. Ensure target nodes are healthy
