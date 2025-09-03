#### Commands to Run

```
kubectl port-forward -n observability svc/jaeger-query 16686:16686 &
```

```
python3 analyze-traces.py
```

```
echo "Open Jaeger UI at http://localhost:16686"
```

```
echo "Look for traces from api-gateway, user-service, order-service, inventory-service"
```

```
curl -s http://localhost:8080/api/user/1/orders | jq .
```

```
echo "Check Jaeger for the distributed trace of this request"
```
