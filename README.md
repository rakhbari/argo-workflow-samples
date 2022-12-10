# argo-workflow-samples
A proper quickstart for Argo Workflows which gives you all you need to run a sample Workflow the correct way, in an app's namespace and using a service account that's been created specifically for running the app's `Workflow` specs.

## Argo Workflows installation
We'll to with the default `Cluster` install of Argo Workflows as described in their own docs:
https://argoproj.github.io/argo-workflows/installation/

## Argo Server Authentication & Authorization (Authn/Authz)
Authentication is handled by creating a `ServiceAccount` (SA) to run `Workflow` specs, and later retrieving its `Bearer` token for you to use to login to the Argo Server UI.

Authorization part of K8s RBAC has been broken up into 2 sets of specs:

* `clusterrole-workflow-run.yaml` & `rolebinding-workflow-run.yaml`: `ClusterRole`s and `RoleBinding`s needed for running/executing `Workflow` specs (ie: Using `argo submit ...` from the shell)
* `clusterrole-workflow-ui.yaml` & `rolebinding-workflow-ui.yaml`: `ClusterRole`s and `RoleBinding`s required for viewing the `Workflow` runs in the Argo Server UI

Below is a script put together from Argo Server's own docs: https://argoproj.github.io/argo-workflows/access-token/, which handles both the Authn and Authz explained above:

The script `create-workflow-sa.sh` in the `scripts/` dir does the following things:
1. Creates the given namespace, if one doesn't exist
1. Creates the given service acct and a token secret for it, if one doesn't exist
1. Creates the required `ClusterRole`s, if they don't exist
1. Applies the needed `RoleBinding`s in the given namespace for the service acct
1. Calls `get-sa-token` script to retrieve the `Bearer` token for the newly create service acct and echos it to the console

__NOTE__: The script requires use of `envsubst` command. If you have an older Linux distro please do a search on how to get it installed on your machine before proceeding: https://www.google.com/search?q=bash+envsubst+command+not+found

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

## Port-forwarding `argo-server` locally
Argo Server UI should be running at ClusterIP port `2746`. Run following command to `port-forward` to it:
```
kubectl -n argo port-forward deployment/argo-server 2746:2746
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
