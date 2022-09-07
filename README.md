# argo-workflow-samples
See `docs/SETUP.md` for Argo Server setup

## Argo Server Authentication
Below is a script put together from Argo Server's own docs: https://argoproj.github.io/argo-workflows/access-token/

The script `create-workflow-sa.sh` in the `scripts/` dir does the following things:
1. Creates the given namespace, if one doesn't exist
1. Creates the given service acct, if one doesn't exist
1. Applies `role-workflow.yaml` in the given namespace
1. Applies `rolebinding-workflow.yaml` in the given namespace substituting the namespace/service acct combo in the file.
1. Creates a bearer token from the service acct's k8s secret and echos it to the console.

```
./scripts/create-workflow-sa.sh <namespace> <service_acct>
```
Example:
```
./scripts/create-workflow-sa.sh app1 user1
```

The output should end with something similar to this:
```
===> ARGO_TOKEN for SA user2:
Bearer eyJhbG....XcnUCw
```

Copy the output of `$ARGO_TOKEN` and paste it in the login UI token input box.

## Port-forwarding `argo-server` locally
Argo Server UI should be running at ClusterIP port `2746`. Run following command to `port-forward` to it:
```
kubectl -n argo port-forward deployment/argo-server 2746:2746
```
Once done, you should be able to hit the Argo Server UI at: `https://localhost:2746/workflows/app1`

## Creating Workflows
Although you can `kubectl apply` `Workflow` specs directly, I've found it easier to use the Argo CLI `argo submit` to do the same.

I've included a copy of `http-hello-world` workflow for you try. We'll be submitting this workflow in the `namespace` we created earlier and telling the Argo CLI to use the service acct we created to do the work:

```
argo submit workflow-http-hello-world-template.yaml -n app1 --serviceaccount user1
```

Once you run this, you should see the Workflow run and complete successfully in the Argo Server UI (link above).
