## Install
```bash
# install scripts
$ cat create-aks-setup-scripts-cm.sh
#!/bin/sh
NS=default   # change namespace
...
$ bash create-aks-setup-scripts-cm.sh
```
```bash
# install daemon-set (dry-run mode)
# and check pod logs
$ kubectl apply -f aks-setup-node-ds.yaml

# install daemon-set (prod mode)
$ vi aks-setup-node-ds.yaml  # remove env 'DRY'
$ kubectl apply -f aks-setup-node-ds.yaml
```

## Test
### Python Script
```bash
$ python scripts/setup.py test/kubelet
$ python scripts/setup.py test/kubelet.true
$ python scripts/setup.py test/kubelet.false

# debug
$ DEBUG=True python scripts/setup.py test/kubelet

# dry-run 
$ DRY=True   python scripts/setup.py test/kubelet
```

### Deployment
```bash
# install scripts
$ bash create-aks-setup-scripts-cm.s

# change env variables (DEBUG, DRY)
$ vi test/aks-setup-node-dp.yaml
$ kubectl apply -f test/aks-setup-node-dp.yaml
```

## References
### Python
- https://docs.python.org/ko/3/library/datetime.html
- https://docs.python.org/2/library/datetime.html#datetime.datetime.isoformat