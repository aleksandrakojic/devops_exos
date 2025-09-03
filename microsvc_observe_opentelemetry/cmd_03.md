#### Commands to Run

```
kubectl create namespace microservices
```

```
kubectl apply -f microservices-manifests.yaml
```

```
kubectl get pods -n microservices
```

```
kubectl wait --for=condition=available deployment --all -n microservices --timeout=300s
```

```
./load-test.sh
```

```
kubectl logs -n microservices deployment/api-gateway | head -10
```
