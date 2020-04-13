## Kubeconfig
```bash
# mkdir keycloak && cd keycloak
# export KUBECONFIG=$(pwd)/config

# oc login -u admin --server=https://api.xxx.yyy.zzz:6443
# oc new-project zcp-system   # oc project zcp-system

oc adm policy add-scc-to-user anyuid system:serviceaccount:zcp-system:default -n zcp-system
oc policy add-role-to-user edit "system:serviceaccount:tiller:tiller"

kubectl config get-contexts

helm init --client-only
helm repo update
```

## Exclude Steps
* Label and Taint Nodes
* Label on to zcp-system and default
* Create ImagePullSecrets for kube-system
* Install Storage Plugin
* Install Tiller
* ~~Create TLS Secret for Ingress~~

## 1. Setup Cluster

### 1.1 Create ImagePullSecerts for zcp-system
```bash
TOKEN=...

kubectl create secret docker-registry bluemix-cloudzcp-secret   --docker-server=registry.au-syd.bluemix.net \
  --docker-username=token --docker-email=token -n zcp-system --docker-password=$TOKEN
kubectl create secret docker-registry au-icr-io-cloudzcp-secret --docker-server=au.icr.io \
  --docker-username=token --docker-email=token -n zcp-system --docker-password=$TOKEN

kubectl patch sa -n zcp-system default -p "{\"imagePullSecrets\":[{\"name\":\"bluemix-cloudzcp-secret\"},{\"name\":\"au-icr-io-cloudzcp-secret\"}]}"
```

### 1.2. ClusterRole Labeling
```bash
kubectl patch clusterrole view -p="{\"metadata\": {\"name\": \"member\"}}" --dry-run -o yaml | kubectl create -f -
kubectl label clusterrole cluster-admin cloudzcp.io/zcp-system-cluster-role=true
kubectl label clusterrole member cloudzcp.io/zcp-system-cluster-role=true

kubectl patch clusterrole edit -p="{\"metadata\": {\"name\": \"cicd-manager\"}}" --dry-run -o yaml | kubectl create -f -
kubectl patch clusterrole view -p="{\"metadata\": {\"name\": \"developer\"}}" --dry-run -o yaml | kubectl create -f -
kubectl label clusterrole admin cloudzcp.io/zcp-system-namespace-role=true
kubectl label clusterrole cicd-manager cloudzcp.io/zcp-system-namespace-role=true
kubectl label clusterrole developer cloudzcp.io/zcp-system-namespace-role=true
```

### 1.3. Create ServiceAccount zcp-system-admin
```
curl -s https://raw.githubusercontent.com/cloudz-cp/zcp-installation/master/zcp-common/zcp-system-admin-sa-crb.yaml | kubectl create -f -
```

## 2. Setup ZCP
- OpenShift API Server : https://api.xxx.yyy.zzz
- OpenShift Domain : {host}.apps.xxx.yyy.zzz

```bash
git clone https://github.com/zcp-aks-lab/zcp-setup && cd zcp-setup
git checkout openshift
```

### 2.1 Keycloak
Create TLS Secret
```bash
# [SKIP] Copy from OpenShift Console (for apps.xxx.yyy.zzz)
# bash create-openshift-cert.sh
# kubectl apply -f openshift-apps-com-cert.yaml -n zcp-system

# Create Secret (for cloudzcp.io)
# !! Prepare cloudzp-io-cert.yaml !!
kubectl apply -f cloudzcp-io-cert.yaml -n zcp-system
```

Install Keycloak
```bash
git clone https://github.com/zcp-aks-lab/zcp-keycloak.git && cd zcp-keycloak
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
bash kube_secret_create_realm.sh
bash helm_install_oc.sh
```

### 2.2 ZCP IAM
```bash
git clone https://github.com/zcp-aks-lab/zcp-iam && cd zcp-iam
git apply ../patch-iam.diff

# edit config files
cd k8s/template
vi setenv.sh      # after 'OpenShift'
vi mongodb/zcp-iam-mongodb-pvc-oc.yaml
vi mongodb/values-mongodb-oc.yaml

# mongodb
(cd mongodb && kubectl create -f zcp-iam-mongodb-pvc-oc.yaml)
(cd mongodb && bash install_oc.sh)    # (cd mongodb && bash install_oc_helm3.sh)

# zcp-iam
bash template.sh
kubectl apply -f .tmp

kubectl patch deploy zcp-iam --type=json -p='[{"op": "remove", "path": "/spec/template/spec/affinity"}]'
kubectl patch deploy zcp-iam --type=json -p='[{"op": "remove", "path": "/spec/template/spec/tolerations"}]'

kubectl rollout restart deploy/zcp-iam
```

### 2.3 ZCP Console
```bash
git clone https://github.com/zcp-aks-lab/zcp-portal-ui && cd zcp-portal-ui
git apply ../patch-console.diff

# edit config files
cd k8s/template
vi setenv.sh      # after 'OpenShift'

# zcp-portal-ui
bash template.sh
kubectl apply -f .tmp

kubectl patch deploy zcp-portal-ui --type=json -p="[{\"op\": \"remove\", \"path\": \"/spec/template/spec/affinity\"}]"
kubectl patch deploy zcp-portal-ui --type=json -p="[{\"op\": \"remove\", \"path\": \"/spec/template/spec/tolerations\"}]"

kubectl edit cm zcp-portal-service-meta-config -n zcp-system
kubectl rollout restart deploy/zcp-portal-ui
```

## Troubles
### 1. Self-signed certificate
```bash
# ERR LOG
java.security.cert.CertificateException: No subject alternative DNS name matching ... found.
```

### 2. ~~Helm Version~~
```bash
# ERR LOG
$ bash helm_install_oc.sh
Error: unknown flag: --name
$ helm version
version.BuildInfo{Version:"v3.1.2", GitCommit:"d878d4d45863e42fd5cff6743294a11d28a9abce", GitTreeState:"clean", GoVersion:"go1.13.8"}

# Solution: use 'xxx_helm3.sh'
$ bash helm_install_oc_helm3.sh
```

Install Helm v2.12.3
```bash
curl -sO https://get.helm.sh/helm-v2.12.3-linux-amd64.tar.gz
tar -zxvf helm-v2.12.3-linux-amd64.tar.gz

# mv linux-amd64/helm /usr/local/bin/helm
export PATH="$(pwd)/linux-amd64:$PATH"
export HELM_HOME="$(pwd)/.helm"
```