#!/bin/bash

NS=openshift-console
SECRET=console-serving-cert

kubectl get secret $SECRET -n $NS -o yaml > openshift-apps-com-cert.yaml
