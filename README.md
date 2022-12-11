# argo-workflow-samples
A proper quickstart for Argo Workflows which gives you all you need to run a sample Workflow the correct way, in an app's namespace and using a service account that's been created specifically for running the app's `Workflow` specs.

## Argo Workflows installation
We'll use the community maintained Helm to do the Argo Workflows install:
https://github.com/argoproj/argo-helm/tree/main/charts/argo-workflows

Add the chart repo & update it:
```
$ helm repo add argo https://argoproj.github.io/argo-helm`
$ helm repo update
```

Install AWF in the `argo` namespace using our own `values.yaml` file:
```
helm install argo-workflows argo/argo-workflows -n argo -f install/values.yaml
```

__NOTE__: The `values.yaml` file configures the Argo Server install with `--auth-mode=client`, which means the Argo Server UI wil require a `Bearer` token for login. You can read all about it in [Argo Server Auth Mode](https://argoproj.github.io/argo-workflows/argo-server-auth-mode/) doc. See the `AuthN/AuthZ` section below.

You can then check on the status of the installation with: `kubectl get all -n argo`
You should end up with a list of all `Pod`s, `Service`s, and `Deployment`s that should look something like this:
```
NAME                                                      READY   STATUS    RESTARTS   AGE
pod/argo-workflows-workflow-controller-857dc9749b-8gt2c   1/1     Running   0          34h
pod/argo-workflows-server-78f895c777-lcgbl                1/1     Running   0          34h

NAME                                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/argo-workflows-server                ClusterIP   10.43.238.25    <none>        2746/TCP   34h
service/argo-workflows-workflow-controller   ClusterIP   10.43.115.214   <none>        8081/TCP   34h

NAME                                                 READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/argo-workflows-workflow-controller   1/1     1            1           34h
deployment.apps/argo-workflows-server                1/1     1            1           34h

NAME                                                            DESIRED   CURRENT   READY   AGE
replicaset.apps/argo-workflows-workflow-controller-857dc9749b   1         1         1       34h
replicaset.apps/argo-workflows-server-78f895c777                1         1         1       34h
```

## Argo Server Authentication & Authorization (Authn/Authz)
The `values.yaml` file used to install Argo Server specified `--auth-mode=client`, which means the Argo Server UI wil require a `Bearer` token for login. This is a much safer AuthN/AuthZ mechanism. Authentication is handled by creating a `ServiceAccount` (SA) to run `Workflow` specs, and later retrieving its `Bearer` token for you to use to login to the Argo Server UI.

Below is a script put together from Argo Server's own docs: https://argoproj.github.io/argo-workflows/access-token/, which handles both the Authn and Authz explained above:

The `create-workflow-sa.sh` script does the following things:
1. Creates the given namespace, if one doesn't exist
1. Creates the given service acct and a token secret for it, if one doesn't exist
1. Creates the required `ClusterRole`s, if they don't exist
1. Applies the needed `RoleBinding`s in the given namespace for the service acct
1. Calls `get-sa-token` script to retrieve the `Bearer` token for the newly create service acct and echos it to the console

__NOTE__: The script requires use of the `envsubst` command. If you have an older Linux distro please do a search on how to get it installed on your machine before proceeding: https://www.google.com/search?q=bash+envsubst+command+not+found

Run the script with these args:
```
./scripts/create-workflow-sa.sh <namespace> <service_acct>
```
Example:
```
./scripts/create-workflow-sa.sh app1 user1
```

The output should end with something similar to this:
```
===> ARGO_TOKEN for SA user1:
Bearer eyJhbG....XcnUCw
```

Copy the output of `$ARGO_TOKEN` and paste it in the login UI token input box.

## Argo Server UI
At this point the Argo Server UI should be running as a `type: ClusterIP` service on port `2746`. You have a couple of choices for accessing its UI.

#### Create `IngressRoute` for `mydomain.com`

If you have a properly configured/installed ingress controller in your K8s cluster, as outlined by my [k3d-config]() project, then you should run the `install-ingress.sh` script by supplying it with:
1. `ARGO_FQDN`: Fully qualified domain name for your Argo Server. eg: `argo.mydomain.com`
1. `TLS_CERT_SECRET_NAME`: The production certificate secret name for your domain. eg: `mydomain-production`

```
$ ./scripts/ingress-install.sh argo.mydomain.com mydomain-production
```

__NOTE__: The `IngressRoute` definition in `install/ingress-argo-server-ui.yaml` also defined an additional `argo.lan` hostname for your to be able to hit the Argo Server UI without using your domain name.

Once you've ran the script, you should be able to hit the Argo Server UI at: `https://argo.mydomain.com/workflows/app1`

#### Local `port-forward`
If on the other hand you haven't configured an ingress controller for your cluster and don't have a TLS cert for your domain, you can just run the following command to `port-forward` to the Argo Server UI from your local machine:
```
kubectl -n argo port-forward deployment/argo-workflows-server 2746:2746
```
Once done, you should be able to hit the Argo Server UI at: `https://localhost:2746/workflows/app1`

## Creating Workflows
Although you can `kubectl apply` `Workflow` specs directly, I've found it easier to use the Argo CLI `argo submit` to do the same.

You can try out all example `Workflow` specs found in [Argo Workflow's own repo examples folder](https://github.com/argoproj/argo-workflows/tree/master/examples). We'll be submitting one of those example workflows in the `namespace` and using the service acct we created earlier:

__NOTE__: The `--watch` arg displays a nice textual representation of the `Workflow`, in addition to what you see in the Argo Server UI

```
argo submit -n app1 --serviceaccount user1 --watch https://raw.githubusercontent.com/argoproj/argo-workflows/master/examples/loops-dag.yaml
```

Once you run this, you should see the Workflow run and complete successfully in the Argo Server UI (link above).
