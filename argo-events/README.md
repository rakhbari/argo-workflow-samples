# Argo Events

## Install
We'll use the community maintained Helm to do the Argo Workflows install:
https://github.com/argoproj/argo-helm/tree/main/charts/argo-events

Add the chart repo & update it:
```
$ helm repo add argo https://argoproj.github.io/argo-helm`
$ helm repo update
```

Install the base system:
```
$ kubectl create ns argo-events
$ helm install argo-events argo/argo-events -n argo-events -f install/events-values.yaml
```

Install the `EventBus`:
```
kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/examples/eventbus/native.yaml
```

After a few seconds you should be able to check the status of the installed CR objects:
```
$ kubectl get all -n argo-events
NAME                                                  READY   STATUS    RESTARTS   AGE
pod/argo-events-controller-manager-64f46b7bf8-2jm7d   1/1     Running   0          18m
pod/events-webhook-f9886d6b4-wh4jz                    1/1     Running   0          21s

NAME                                             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
service/argo-events-controller-manager-metrics   ClusterIP   10.43.216.160   <none>        8082/TCP                     18m
service/eventbus-default-stan-svc                ClusterIP   None            <none>        4222/TCP,6222/TCP,8222/TCP   10m
service/events-webhook                           ClusterIP   10.43.183.223   <none>        443/TCP                      21s

NAME                                             READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/argo-events-controller-manager   1/1     1            1           18m
deployment.apps/events-webhook                   1/1     1            1           21s

NAME                                                        DESIRED   CURRENT   READY   AGE
replicaset.apps/argo-events-controller-manager-64f46b7bf8   1         1         1       18m
replicaset.apps/events-webhook-f9886d6b4                    1         1         1       21s
```

## Github `EventSource`
This `EventSource` type, once properly configured, will do the following:
1. Attempt to create a Github webhook for every repo you've listed in your `EventSource` spec
2. Create a `ClusterIP` type service to serve the webhook requests from Github

#### The `Secret` for Github Access
Create a PAT (Personal Access Token) on Github:
```
Top-right user icon -> Settings -> Developer settings -> Personal Access Tokens -> tokens (classic)
```

Create a GUID to be used as the webhook secret:
```
cat /proc/sys/kernel/random/uuid | sed 's/\-//g'
```

__Save both the Github PAT and your webhook secret GUID in a safe place!__

`base64` both values to be used with the `Secret` spec below:
```
echo "<your-github-api-token>" | base64
echo "<your-webhook-secret-guid>" | base64
```

Create a Github access `Secret` in a file `secret-github-access-myorg.yaml':
```
kind: Secret
metadata:
  name: github-access-<github-org>
type: Opaque
data:
  token: <your-github-api-token-base64>
  secret: <webhook-secret-key-base64>
```

Create a `~/github-vault-pass` file (A GUID would be best) and use `ansible-vault` to encrypt the secret:
```
ansible-vault encrypt --vault-pass-file ~/github-vault-pass argo-events/secret-github-access-myorg.yaml
```

Decrypt the file and `apply` it to your cluster in the `argo-events` namespace:
```
ansible-vault view --vault-pass-file ~/github-vault-pass argo-events/secret-github-access-myorg.yaml | k -n argo-events apply -f -
```

#### The `EventSource` object
We'll create an `EventSource` to receive `push` (and other events) from repos in our Github org. The following script will take the provided `<your-github-org>` and `<your-events-base-url>` and create an `EventSource` CR object with the name `<your-github-org>-github`.

Run the script:
```
$ ./scripts/eventsource-install.sh <your-github-org> <your-events-base-url>
```

__NOTE__: `<your-events-base-url>` must be a publicly accessible FQDN (Fully Qualified Domain Name) that you've hopefully already configured at your DNS provider (like CloudFlare), plus any `:port-num` needed to reach your server at home, otherwise Github won't be able to resolve and/or access it.

__Example__: Let's say your events FQDN is `events.mydomain.com` and the TLS `port` you've configured to reach your home server is `20443`. This will make `<your-events-base-url>` = `events.mydomain.com:20443`. `https://` is already assumed and hard-coded in the `EventSource` spec.

__NOTE:__: You'll have to hand-edit the list of repos in the `EventSource` spec prior to running that script. `EventSource` will attempt to create webhooks for every repo listed under `github.<your-github-org>.repositories.names` in the spec.

Creation of this `EventSource` (if all went well) will also generate a `ClusterIP` type `Service` named: `<eventsource-name>-eventsource-svc` service where `eventsource-name` is equal to `<your-github-org>-github`.

#### `IngressRoute` for the new `EventSource` service
Next we'll create an `IngressRoute` to expose the service for your newly created `EventSource` (above).

Run the script:
```
$ ./scripts/ingress-eventsource-install.sh <your-eventsource-name> <your-events-fqdn> <your-tls-cert-name>
```

__NOTES__:
* `<your-eventsource-name>` = `<your-github-org>-github`
* <your-events-fqdn> = The same publicly accessible FQDN you entered in the previous step

This will create an `IngressRoute` with the exact same name as the event-source service name above, with a hostname rule set to the publicly reachable `<your-events-fqdn>` and with the TLS cert set to `<your-tls-cert-name>`.

#### Validating Github `EventSource`
The `EventSource` you deployed to your cluster has all the info it needs to create webhook(s) for the repos you specified. Once your `IngressRoute` is live, you should be able to see the activity both by the event source service and Github.

Github will attempt to send a test `ping` payload to your configured webhook payload URL. If all worked well, your `IngressRoute` should pass the payload to your `EventSource` service and finally to the `<your-eventsource-name>-eventsource` pod for processing. If you tail the logs of that pod you should be able to see some log lines when that `ping` event arrives.

Get the name of the pod and tail (`-f`=follow) its logs:
```
$ export EVENTSOURCE_POD=$(kubectl -n argo-events get pods --no-headers -o custom-columns=":metadata.name" | grep eventsource)
$ kubectl logs -n argo-events -f ${EVENTSOURCE_POD}
```

Go to one of the Github repos you defined in your `EventSource` spec (above), Settings -> Webhooks, click on the webhook URL whose endpoint is `/github`, then `Recent Deliveries` tab. You should see a sent request labeled `ping` that may or may not have succeeded. Click to open it and then click `Redeliver`. Once you do, watch your `EventSource` pod log output. You should see a few log lines appear ending with one that looks something like this:
```
{"level":"info","ts":1671379584.5103176,"logger":"argo-events.eventsource","caller":"eventsources/eventing.go:542","msg":"Succeeded to publish an event","eventSourceName":"github-<your-github-org>","eventName":"<your-github-org>","eventSourceType":"github","eventID":"36663139616337322d623562642d343039372d626561372d633530616538666662353362"}
```

If you see these log lines, your Github `EventSource` is properly configured and ready to publish incoming Github events to your `Sensor`s.

## `Sensor`s
Now that we're getting Github events published on our `EventBus`, it's time to set up a `Sensor` (or two) to take action(s) when those events arrive.

