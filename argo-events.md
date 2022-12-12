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