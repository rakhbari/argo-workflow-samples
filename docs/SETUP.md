## Port-forwarding `argo-server` locally
```
kubectl -n argo port-forward deployment/argo-server 2746:2746
```

## Argo Server Authentication
Below is summaried from Argo Server's own docs: https://argoproj.github.io/argo-workflows/access-token/

```
kubectl create sa ramin
```

```
kubectl create role ramin --verb=get,list,update,watch,create,patch,delete --resource=workflows.argoproj.io
```

```
kubectl create rolebinding ramin --role=ramin --serviceaccount=default:ramin
```

```
SECRET=$(kubectl get sa ramin -o=jsonpath='{.secrets[0].name}')
ARGO_TOKEN="Bearer $(kubectl get secret $SECRET -o=jsonpath='{.data.token}' | base64 --decode)"
echo $ARGO_TOKEN
```

Copy the output of `$ARGO_TOKEN` and paste it in the login UI token input box.
