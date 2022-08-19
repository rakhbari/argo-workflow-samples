## Port-forwarding `argo-server` locally
Argo Server UI should be running at ClusterIP port `2746`. Run following command to `port-forward` to it:
```
kubectl -n argo port-forward deployment/argo-server 2746:2746
```
Once done, you should be able to hit the Argo Server UI at: https://localhost:2746

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

## Configure `Role` and `RoleBinding` for proper K8s RBAC
```
kubectl apply -f role.yaml -f rolebinding.yaml -n argo-samples
```

## Install/apply the `hello-world` Workflow
```
argo submit -n argo-samples --watch https://raw.githubusercontent.com/argoproj/argo-workflows/master/examples/hello-world.yaml
```
