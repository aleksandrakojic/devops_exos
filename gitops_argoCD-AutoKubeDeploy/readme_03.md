#### Commands to Run

```
git status
```

```
git log --oneline
```

```
argocd app sync guestbook-dev
```

```
kubectl get pods -n guestbook-dev -w
```

```
argocd app diff guestbook-dev
```

```
argocd app history guestbook-dev
```

---




# Test GitOps workflow

# 1. Make a change to the application

# Update appconfigs/guestbook/base/deployment.yaml

# Change image tag or add environment variable

# 2. Create a new feature branch

git checkout -b feature/update-app

# Edit deployment to add environment variable

cat << EOF >> appconfigs/guestbook/base/deployment.yaml
        env:
        - name: PORT
          value: "3000"
        - name: ENVIRONMENT
          value: "gitops-demo"
EOF

# 3. Commit and push changes

git add .
git commit -m "Add environment variable to guestbook"
git push origin feature/update-app

# 4. Merge to main (simulating PR merge)

git checkout main
git merge feature/update-app
git push origin main

# 5. Watch ArgoCD sync the changes

argocd app sync guestbook-dev
argocd app wait guestbook-dev --timeout 300

# 6. Verify deployment

kubectl get pods -n guestbook-dev
kubectl describe deployment guestbook -n guestbook-dev

# 7. Manually sync staging and production

argocd app sync guestbook-staging
argocd app sync guestbook-prod

# 8. Rollback test

# Create a breaking change

echo "invalid yaml" >> appconfigs/guestbook/base/deployment.yaml
git add . && git commit -m "Breaking change for rollback test"
git push origin main

# 9. Observe ArgoCD detect the issue and rollback

argocd app history guestbook-dev
argocd app rollback guestbook-dev `<previous-revision>`
