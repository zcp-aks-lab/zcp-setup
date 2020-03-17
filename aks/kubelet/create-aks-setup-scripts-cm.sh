#!/bin/sh
NS=zcp-system
NAME=aks-setup-scripts

kubectl delete configmap $NAME -n $NS
kubectl create configmap $NAME -n $NS --from-file=scripts/entrypoint.sh --from-file=scripts/setup.py
