#!/bin/bash

# =================================================================
# EKS Cluster Testing Script
# =================================================================
# This script deploys test applications to validate your EKS cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing EKS Cluster Functionality...${NC}"

# =================================================================
# Test 1: Deploy nginx test application
# =================================================================
echo -e "${BLUE}📋 Test 1: Deploying nginx test application...${NC}"

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-test
  namespace: test-apps
  labels:
    app: nginx-test
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-test
  template:
    metadata:
      labels:
        app: nginx-test
    spec:
      containers:
      - name: nginx
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 20
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: test-apps
spec:
  selector:
    app: nginx-test
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  type: LoadBalancer
EOF

echo -e "${GREEN}✅ Nginx application deployed${NC}"

# =================================================================
# Test 2: Deploy busybox for testing
# =================================================================
echo -e "${BLUE}📋 Test 2: Deploying busybox test pod...${NC}"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: busybox-test
  namespace: test-apps
spec:
  containers:
  - name: busybox
    image: busybox:1.35
    command: ['sh', '-c', 'sleep 3600']
    resources:
      requests:
        memory: "32Mi"
        cpu: "100m"
      limits:
        memory: "64Mi"
        cpu: "200m"
EOF

echo -e "${GREEN}✅ Busybox test pod deployed${NC}"

# =================================================================
# Test 3: Test persistent volume
# =================================================================
echo -e "${BLUE}📋 Test 3: Testing persistent volumes (EBS CSI)...${NC}"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
  namespace: test-apps
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp2
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pvc-test
  namespace: test-apps
spec:
  replicas: 1
  selector:
    matchLabels:
      app: pvc-test
  template:
    metadata:
      labels:
        app: pvc-test
    spec:
      containers:
      - name: test-container
        image: nginx:1.21-alpine
        volumeMounts:
        - name: test-volume
          mountPath: /data
        command: ['sh', '-c', 'echo "Hello EKS!" > /data/test.txt && tail -f /dev/null']
      volumes:
      - name: test-volume
        persistentVolumeClaim:
          claimName: test-pvc
EOF

echo -e "${GREEN}✅ Persistent volume test deployed${NC}"

# =================================================================
# Wait for deployments
# =================================================================
echo -e "${YELLOW}⏳ Waiting for applications to be ready...${NC}"

kubectl wait --for=condition=available --timeout=300s deployment/nginx-test -n test-apps
kubectl wait --for=condition=ready --timeout=300s pod/busybox-test -n test-apps
kubectl wait --for=condition=available --timeout=300s deployment/pvc-test -n test-apps

# =================================================================
# Check deployment status
# =================================================================
echo -e "${BLUE}📋 Checking deployment status...${NC}"
kubectl get all -n test-apps

# =================================================================
# Test DNS resolution
# =================================================================
echo -e "${BLUE}📋 Test 4: Testing DNS resolution...${NC}"
kubectl exec -n test-apps busybox-test -- nslookup kubernetes.default.svc.cluster.local

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ DNS resolution working${NC}"
else
    echo -e "${RED}❌ DNS resolution failed${NC}"
fi

# =================================================================
# Test service connectivity
# =================================================================
echo -e "${BLUE}📋 Test 5: Testing service connectivity...${NC}"
kubectl exec -n test-apps busybox-test -- wget -qO- nginx-service.test-apps.svc.cluster.local

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Service connectivity working${NC}"
else
    echo -e "${RED}❌ Service connectivity failed${NC}"
fi

# =================================================================
# Check persistent volume
# =================================================================
echo -e "${BLUE}📋 Test 6: Testing persistent volume...${NC}"
kubectl get pvc -n test-apps

PVC_STATUS=$(kubectl get pvc test-pvc -n test-apps -o jsonpath='{.status.phase}')
if [ "$PVC_STATUS" = "Bound" ]; then
    echo -e "${GREEN}✅ Persistent volume bound successfully${NC}"
else
    echo -e "${YELLOW}⚠️  PVC Status: $PVC_STATUS${NC}"
fi

# =================================================================
# Get LoadBalancer URL
# =================================================================
echo -e "${BLUE}📋 Getting LoadBalancer URL...${NC}"
echo -e "${YELLOW}⏳ Waiting for LoadBalancer to be ready (this may take a few minutes)...${NC}"

# Wait for LoadBalancer
for i in {1..30}; do
    EXTERNAL_IP=$(kubectl get svc nginx-service -n test-apps -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    if [ ! -z "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "null" ]; then
        echo -e "${GREEN}✅ LoadBalancer ready!${NC}"
        echo -e "${GREEN}🌐 Access your application at: http://$EXTERNAL_IP${NC}"
        break
    fi
    echo "Waiting for LoadBalancer... ($i/30)"
    sleep 10
done

if [ -z "$EXTERNAL_IP" ] || [ "$EXTERNAL_IP" = "null" ]; then
    echo -e "${YELLOW}⚠️  LoadBalancer still provisioning. Check later with:${NC}"
    echo "kubectl get svc nginx-service -n test-apps"
fi

# =================================================================
# Summary
# =================================================================
echo -e "${GREEN}"
echo "🎉 EKS Cluster Testing Complete!"
echo "================================="
echo -e "${NC}"

echo -e "${BLUE}Test Results Summary:${NC}"
echo "✅ Nginx deployment: $(kubectl get deployment nginx-test -n test-apps -o jsonpath='{.status.readyReplicas}')/3 replicas ready"
echo "✅ Busybox pod: $(kubectl get pod busybox-test -n test-apps -o jsonpath='{.status.phase}')"
echo "✅ PVC status: $(kubectl get pvc test-pvc -n test-apps -o jsonpath='{.status.phase}')"

echo -e "${YELLOW}Useful commands:${NC}"
echo "• Check pods: kubectl get pods -n test-apps"
echo "• Check services: kubectl get svc -n test-apps"  
echo "• Check logs: kubectl logs -l app=nginx-test -n test-apps"
echo "• Clean up: kubectl delete namespace test-apps"

echo -e "${BLUE}Access your applications:${NC}"
echo "• LoadBalancer URL: kubectl get svc nginx-service -n test-apps"
echo "• Port forward: kubectl port-forward svc/nginx-service 8080:80 -n test-apps"