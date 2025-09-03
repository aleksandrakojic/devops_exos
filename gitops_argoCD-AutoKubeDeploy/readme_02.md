#### Commands to Run

```
kustomize build appconfigs/guestbook/overlays/dev
```

```
kustomize build appconfigs/guestbook/overlays/staging
```

```
kustomize build appconfigs/guestbook/overlays/prod
```

```
git add .
```

```
git commit -m 'Initial GitOps repository setup'
```



---




# Development overlay

# appconfigs/guestbook/overlays/dev/kustomization.yaml

apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: guestbook-dev
resources:

- ../../base
  patchesStrategicMerge:
- deployment-patch.yaml
  commonLabels:
  environment: dev
  images:
- name: gcr.io/heptio-images/ks-guestbook-demo
  newTag: "0.2"

# appconfigs/guestbook/overlays/dev/deployment-patch.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: guestbook
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: guestbook
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"

# Staging overlay

# appconfigs/guestbook/overlays/staging/kustomization.yaml

apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: guestbook-staging
resources:

- ../../base
  patchesStrategicMerge:
- deployment-patch.yaml
- service-patch.yaml
  commonLabels:
  environment: staging
  images:
- name: gcr.io/heptio-images/ks-guestbook-demo
  newTag: "0.2"

# appconfigs/guestbook/overlays/staging/service-patch.yaml

apiVersion: v1
kind: Service
metadata:
  name: guestbook
spec:
  type: NodePort

# Production overlay

# appconfigs/guestbook/overlays/prod/kustomization.yaml

apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: guestbook-prod
resources:

- ../../base
  patchesStrategicMerge:
- deployment-patch.yaml
- ingress.yaml
  commonLabels:
  environment: production
  images:
- name: gcr.io/heptio-images/ks-guestbook-demo
  newTag: "0.1"

# appconfigs/guestbook/overlays/prod/deployment-patch.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: guestbook
spec:
  replicas: 5
  template:
    spec:
      containers:
      - name: guestbook
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
