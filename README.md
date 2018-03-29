# helm-cronjobs
You can define an array of jobs in values.yaml helm will take care of creating all the CronJobs.
```
$ helm install .
NAME:   volted-grasshopper
LAST DEPLOYED: Thu Mar 29 09:45:02 2018
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1beta1/CronJob
NAME                         SCHEDULE     SUSPEND  ACTIVE  LAST SCHEDULE  AGE
volted-grasshopper-cronjob2  * * * * *    False    0       <none>
volted-grasshopper-cronjob1  */5 * * * *  False    0       <none>
```
list cronjobs:
```
$ kubectl get cronjob
NAME                          SCHEDULE      SUSPEND   ACTIVE    LAST SCHEDULE   AGE
volted-grasshopper-cronjob1   */5 * * * *   False     0         <none>          21s
volted-grasshopper-cronjob2   * * * * *     False     0         <none>          21s
```
list jobs:
```
$ kubectl get jobs
NAME                                     DESIRED   SUCCESSFUL   AGE
volted-grasshopper-cronjob2-1522334760   1         0            22s
```
