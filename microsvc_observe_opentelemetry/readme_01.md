# Create observability namespace

kubectl create namespace observability

# Deploy Jaeger using Operator

kubectl create -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.39.0/jaeger-operator.yaml -n observability

# Wait for operator to be ready

kubectl wait --for=condition=available deployment jaeger-operator -n observability --timeout=300s

# Create Jaeger instance

cat > jaeger-instance.yaml <<EOF
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: jaeger
  namespace: observability
spec:
  strategy: allInOne
  allInOne:
    image: jaegertracing/all-in-one:latest
    options:
      log-level: info
      memory:
        max-traces: 50000
  storage:
    type: memory
  ingress:
    enabled: false
  ui:
    options:
      dependencies:
        menuEnabled: true
      tracking:
        gaID: UA-000000-2
EOF

kubectl apply -f jaeger-instance.yaml

# Deploy OpenTelemetry Collector

cat > otel-collector.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-collector-config
  namespace: observability
data:
  collector.yaml: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
      prometheus:
        config:
          scrape_configs:
            - job_name: 'otel-collector'
              scrape_interval: 10s
              static_configs:
                - targets: ['0.0.0.0:8888']

    processors:
      batch:
        timeout: 1s
        send_batch_size: 1024
      memory_limiter:
        limit_mib: 512

    exporters:
      jaeger:
        endpoint: jaeger-collector:14250
        tls:
          insecure: true
      prometheus:
        endpoint: "0.0.0.0:8889"
      logging:
        loglevel: debug

service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [jaeger, logging]
        metrics:
          receivers: [otlp, prometheus]
          processors: [memory_limiter, batch]
          exporters: [prometheus, logging]
------------------------------------------

apiVersion: apps/v1
kind: Deployment
metadata:
  name: otel-collector
  namespace: observability
spec:
  replicas: 1
  selector:
    matchLabels:
      app: otel-collector
  template:
    metadata:
      labels:
        app: otel-collector
    spec:
      containers:
      - name: otel-collector
        image: otel/opentelemetry-collector-contrib:latest
        command:
          - "/otelcol-contrib"
          - "--config=/conf/collector.yaml"
        volumeMounts:
        - name: otel-collector-config-vol
          mountPath: /conf
        ports:
        - containerPort: 4317   # OTLP gRPC receiver
        - containerPort: 4318   # OTLP HTTP receiver
        - containerPort: 8889   # Prometheus metrics
        env:
        - name: GOGC
          value: "80"
      volumes:
      - name: otel-collector-config-vol
        configMap:
          name: otel-collector-config
          items:
            - key: collector.yaml
              path: collector.yaml
----------------------------------

apiVersion: v1
kind: Service
metadata:
  name: otel-collector
  namespace: observability
spec:
  ports:

- name: otlp-grpc
  port: 4317
  targetPort: 4317
- name: otlp-http
  port: 4318
  targetPort: 4318
- name: metrics
  port: 8889
  targetPort: 8889
  selector:
  app: otel-collector
  EOF

kubectl apply -f otel-collector.yaml
