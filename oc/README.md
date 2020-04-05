## Kubeconfig
```bash
oc login -u admin --server=https://api.xxxx.ose4.com:6443
oc new-project zcp-system
oc adm policy add-scc-to-user anyuid system:serviceaccount:zcp-system:default -n zcp-system

kubectl config get-contexts
```

## Exclude Steps
* Label and Taint Nodes
* Label on to zcp-system and default
* Create ImagePullSecrets for kube-system
* Install Storage Plugin
* Install Tiller
* Create TLS Secret for Ingress

## 1. Setup Cluster

### 1.1 Create ImagePullSecerts for zcp-system

### 1.2. ClusterRole Labeling
```bash
kubectl patch clusterrole view -p="{\"metadata\": {\"name\": \"member\"}}" --dry-run -o yaml | kubectl create -f -
kubectl label clusterrole cluster-admin cloudzcp.io/zcp-system-cluster-role=true
kubectl label clusterrole member cloudzcp.io/zcp-system-cluster-role=true

kubectl patch clusterrole edit -p="{\"metadata\": {\"name\": \"cicd-manager\"}}" --dry-run -o yaml | kubectl create -f -
kubectl patch clusterrole view -p="{\"metadata\": {\"name\": \"developer\"}}" --dry-run -o yaml | kubectl create -f -
```

### 1.3. Create ServiceAccount zcp-system-admin
```
curl -s https://raw.githubusercontent.com/cloudz-cp/zcp-installation/master/zcp-common/zcp-system-admin-sa-crb.yaml | kubectl create -f -
serviceaccount/zcp-system-admin created
clusterrolebinding.rbac.authorization.k8s.io/zcp-system-admin created
serviceaccount/zcp-system-sa-cloudzcp-admin created
clusterrolebinding.rbac.authorization.k8s.io/zcp-system-crb-cloudzcp-admin created
rolebinding.rbac.authorization.k8s.io/zcp-system-rb-cloudzcp-admin created
```

## 2. Setup ZCP
- OpenShift Domain : {host}.apps.xxx.ose4.com

### 2.1 Keycloak
Create TLS Secret
```bash
# Copy from OpenShift Console (for apps.xxx.ose4.com)
bash create-openshift-cert.sh
kubectl apply -f openshift-apps-com-cert.yaml -n zcp-system

# Create Secret (for cloudzcp.io)
# !! Prepare cloudzp-io-cert.yaml !!
kubectl apply -f clouzcp-io-cert.yaml -n zcp-system
```

Install Keycloak
```bash
git clone https://github.com/zcp-aks-lab/zcp-keycloak.git & cd zcp-keycloak
git apply ../patch-keycloak.diff

# edit config files
vi manifests/env.properties    # after 'OpenShift'
vi manifests/postgresql/zcp-oidc-postgresql-pvc-oc.yaml
vi manifests/postgresql/values-oc.yaml
vi manifests/keycloak/values-oc.yaml

# postgresql
cd manifests/postgresql
bash kube_pvc_create_oc.sh
bash helm_install_oc.sh

# keycloak
cd ../keycloak
bash helm_install_oc.sh
```

### 2.2 ZCP IAM
```bash
git clone https://github.com/zcp-aks-lab/zcp-iam & cd zcp-iam
git apply ../patch-iam.diff

# edit config files
cd k8s/template
vi setenv.sh      # after 'OpenShift'
vi mongodb/zcp-iam-mongodb-pvc-oc.yaml
vi mongodb/values-mongodb-oc.yaml

# mongodb
cd mongodb & bash install_oc.sh

# zcp-iam
bash template.sh
kubectl apply -f .tmp

kubectl patch deploy zcp-iam --type=json -p='[{"op": "remove", "path": "/spec/template/spec/affinity"}]'
kubectl patch deploy zcp-iam --type=json -p='[{"op": "remove", "path": "/spec/template/spec/tolerations"}]'
kubectl rollout restart deploy/zcp-iam
```

## Troubles
### 1. Self-signed certificate
```bash
# ERR LOG
java.security.cert.CertificateException: No subject alternative DNS name matching ... found.
```