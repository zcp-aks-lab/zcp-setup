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
Don't working
- `kubectl patch sa ...`

### 1.2. ClusterRole Labeling
Don't working
- Single Quote in Cmder

Logs
```bash
kubectl patch clusterrole view -p="{\"metadata\": {\"name\": \"member\"}}" --dry-run -o yaml | kubectl create -f -
kubectl label clusterrole cluster-admin cloudzcp.io/zcp-system-cluster-role=true
kubectl label clusterrole member cloudzcp.io/zcp-system-cluster-role=true
```
```bash
kubectl patch clusterrole edit -p="{\"metadata\": {\"name\": \"cicd-manager\"}}" --dry-run -o yaml | kubectl create -f -
kubectl patch clusterrole view -p="{\"metadata\": {\"name\": \"developer\"}}" --dry-run -o yaml | kubectl create -f -
```

### 1.3. Create ServiceAccount zcp-system-admin
```
curl https://raw.githubusercontent.com/cloudz-cp/zcp-installation/master/zcp-common/zcp-system-admin-sa-crb.yaml | kubectl create -f -
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  1791  100  1791    0     0   1791      0  0:00:01 --:--:--  0:00:01  3098
serviceaccount/zcp-system-admin created
clusterrolebinding.rbac.authorization.k8s.io/zcp-system-admin created
serviceaccount/zcp-system-sa-cloudzcp-admin created
clusterrolebinding.rbac.authorization.k8s.io/zcp-system-crb-cloudzcp-admin created
rolebinding.rbac.authorization.k8s.io/zcp-system-rb-cloudzcp-admin created
```

## 2. Setup ZCP
OpenShift Domain
- {host}.apps.zcplocal.ose4.com
- ~~support oss nginx annotations~~

Common Actions
- Change StorageClass of PVC
- Disable affinity and tolerations

### 2.1 Keycloak
- ~~Skip to create tls~~ 
- Create TLS Cert for *.cloudzcp.io (`java.security.cert.CertificateException: No subject alternative DNS name matching ... found.`)
- Copy TLS Cert from secret/harbor-cert for *.apps.zcplocal.ose4.com
- Create new scripts and yaml files for OpenShift

Copy Cert
```bash
kubectl get secret harbor-cert -n harbor -o yaml > apps-zcplocal-ose4-com-cert.yaml
```

Logs
```bash
git clone git clone https://github.com/zcp-aks-lab/zcp-keycloak.git

cd manifests/postgresql
bash kube_pvc_create_oc.sh  # zcp-oidc-postgresql-pvc-oc.yaml (Change storage-class)
bash helm_install_oc.sh     # values-oc.yaml (Disable affinity and tolerations)

cd manifests/keycloak
bash helm_install_oc.sh     # values-oc.yaml (Disable affinity and tolerations)
```

### 2.2 ZCP IAM
- Change KEYCLOAK_SERVER_URL

Logs
```bash
git clone https://github.com/zcp-aks-lab/zcp-iam

# mongodb
kubectl create -f zcp-iam-mongodb-pvc-oc.yaml  # Change storage-class
bash install.sh values-mongodb-oc.yaml         # Disable affinity and tolerations

# zcp-iam
bash template.sh
kubectl apply -f .tmp

kubectl patch deploy zcp-iam --type=json -p="[{\"op\": \"remove\", \"path\": \"/spec/template/spec/affinity\"}]"
kubectl patch deploy zcp-iam --type=json -p="[{\"op\": \"remove\", \"path\": \"/spec/template/spec/tolerations\"}]"
kubectl patch configmap zcp-iam-config -p="{\"data\":{\"KEYCLOAK_SERVER_URL\":\"https://iam.apps.zcplocal.ose4.com/auth\"}}"

kubectl rollout restart deploy/zcp-iam
```

### 2.3 ZCP Portal UI
Don't working
- Change Prefix of Menu. `sed: can't read s|##config_label##|openshift|g: No such file or directory`

```bash
git clone https://github.com/zcp-aks-lab/zcp-portal-ui

bash template.sh
kubectl apply -f .tmp

kubectl patch deploy zcp-portal-ui --type=json -p="[{\"op\": \"remove\", \"path\": \"/spec/template/spec/affinity\"}]"
kubectl patch deploy zcp-portal-ui --type=json -p="[{\"op\": \"remove\", \"path\": \"/spec/template/spec/tolerations\"}]"
# change zcp-portal-service-meta-config
kubectl rollout restart deploy/zcp-iam

kubectl patch ingress zcp-portal-ui-ingress --type=json -p="[{\"op\": \"replace\", \"path\": \"/spec/tls/0/secretName\", \"value\": \"apps-zcplocal-ose4-com-cert\"}]"
```

## Troubles
### 1. Self-signed certificate
```bash
# create secret with CA Cert

# zcp-keycloak
$ diff zcp-oidc-keycloak.yaml zcp-oidc-keycloak-2.yaml
11c11
<   name: zcp-oidc-keycloak
---
>   name: zcp-oidc-keycloak-2
15c15
<   - host: iam.apps.zcplocal.ose4.com
---
>   - host: openshift-zcp-iam.cloudzcp.io
24,25c24,25
<     - iam.apps.zcplocal.ose4.com
<     secretName: apps-zcplocal-ose4-com-cert
---
>     - openshift-zcp-iam.cloudzcp.io
>     secretName: cloudzcp-io-cert

# zcp-iam
kubectl patch configmap zcp-iam-config -p="{\"data\":{\"KEYCLOAK_SERVER_URL\":\"https://openshift-zcp-iam.cloudzcp.io/auth\"}}"
# kind: Deployment
# meatada:
#   name: zcp-iam
# spec:
#   template:
#     spec:
#       hostAliases:
#       - ip: 49.50.39.153
#         hostnames:
#         - iam.apps.zcplocal.ose4.com
#         - openshift-zcp-iam.cloudzcp.io

# zcp-portal-ui
kubectl patch configmap zcp-iam-config -p="{\"data\":{\"ACCESS_TOKEN_URI\":\"https://openshift-zcp-iam.cloudzcp.io/...\"}}"
kubectl patch configmap zcp-iam-config -p="{\"data\":{\"USER_AUTHORIZATION_URI\":\"https://openshift-zcp-iam.cloudzcp.io/...\"}}"
# kubectl patch deploy zcp-portal-ui --type=json -p="[{\"op\": \"add\", \"path\": \"/spec/template/spec\", \"value\": {\"hostAliases\": [{\"ip\":\"49.50.39.153\", \"hostnames\":[\"iam.apps.zcplocal.ose4.com\"]}]}}]"
# kind: Deployment
# meatada:
#   name: zcp-portal-ui
# spec:
#   template:
#     spec:
#       hostAliases:
#       - ip: 49.50.39.153
#         hostnames:
#         - iam.apps.zcplocal.ose4.com
#         - openshift-zcp-iam.cloudzcp.io
```