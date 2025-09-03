#### Commands to Run

```
kubectl create namespace observability
```

```
kubectl apply -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.39.0/jaeger-operator.yaml -n observability
```

```
kubectl apply -f jaeger-instance.yaml
```

```
kubectl apply -f otel-collector.yaml
```

```
kubectl get pods -n observability
```

```
kubectl port-forward -n observability svc/jaeger-query 16686:16686 &
```
