#!/bin/bash

NS=${NS:-openshift-console}
SECRET=${SECRET:-console-serving-cert}

kubectl get secret $SECRET -n $NS -o yaml > openshift-apps-com-cert.yaml
