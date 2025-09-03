#### Commands to Run

```
kubectl get configmap argocd-notifications-cm -n argocd -o yaml
```

```
kubectl get pods -n argocd | grep notifications
```

```
kubectl logs -f deployment/argocd-notifications-controller -n argocd
```

```
argocd app sync guestbook-dev --dry-run
```

```
kubectl get applications -n argocd -o wide
```

---




# ArgoCD Notifications Configuration

# Create notification configuration

kubectl create configmap argocd-notifications-cm -n argocd --from-literal=config.yaml='
api:
  slack:
    token: $slack-token
subscriptions:

- recipients:
  - slack:devops-alerts
    triggers:
  - on-sync-failed
  - on-sync-succeeded
  - on-health-degraded
    templates:
    template.app-sync-succeeded: |
    email:
    subject: Application {{.app.metadata.name}} synced successfully
    message: |
    Application {{.app.metadata.name}} is now running new version.
    Repository: {{.app.spec.source.repoURL}}
    Revision: {{.app.status.sync.revision}}
    template.app-sync-failed: |
    email:
    subject: Failed to sync application {{.app.metadata.name}}
    message: |
    The sync operation of application {{.app.metadata.name}} has failed.
    Repository: {{.app.spec.source.repoURL}}
    Error: {{.app.status.operationState.message}}
    triggers:
    trigger.on-sync-succeeded: |
  - when: app.status.sync.status == "Synced"
    send: [app-sync-succeeded]
    trigger.on-sync-failed: |
  - when: app.status.sync.status == "Failed"
    send: [app-sync-failed]
    '

# Create secret for Slack token

kubectl create secret generic argocd-notifications-secret 
  --from-literal=slack-token=xoxb-your-slack-token -n argocd

# Enable notifications controller

kubectl patch configmap argocd-cmd-params-cm -n argocd 
  --patch '{"data":{"notifications.controller.enabled":"true"}}'

# Restart ArgoCD to pick up changes

kubectl rollout restart deployment argocd-server -n argocd
kubectl rollout restart deployment argocd-notifications-controller -n argocd

# Add annotations to applications for notifications

kubectl annotate application guestbook-dev 
  notifications.argoproj.io/subscribe.on-sync-succeeded.slack=devops-alerts -n argocd

kubectl annotate application guestbook-staging 
  notifications.argoproj.io/subscribe.on-sync-failed.slack=devops-alerts -n argocd

# Prometheus monitoring for ArgoCD

# Add ServiceMonitor for ArgoCD metrics

apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: argocd-metrics
  namespace: argocd
  labels:
    app: argocd-metrics
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: argocd-metrics
  endpoints:

- port: metrics
  interval: 30s
  path: /metrics

# Grafana Dashboard for ArgoCD

# Sample PromQL queries for ArgoCD monitoring:

# - argocd_app_health_status

# - argocd_app_sync_total

# - argocd_cluster_connection_status

# - argocd_app_reconcile_duration
