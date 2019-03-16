# helm-cronjobs
You can define an array of jobs in values.yaml helm will take care of creating all the CronJobs.

## Configuration
template:
```yaml
jobs:
  ### REQUIRED ###
  - name: <job_name>
    image:
      repository: <image_repo>
      tag: <image_tag>
      pullPolicy: <pull_policy>
    schedule: "<cron_schedule>"
    failedJobsHistoryLimit: <failed_history_limit>
    successfulJobsHistoryLimit: <successful_history_limit>
    concurrencyPolicy: <concurrency_policy>
    restartPolicy: <restart_policy>
  ### OPTIONAL ###
    env:
    - name: ENV_VAR
      value: ENV_VALUE
    command: ["<command>"]
    args:
    - "<arg_1>"
    - "<arg_2>"
    resources:
      limits:
        cpu: <cpu_count>
        memory: <memory_count>
      requests:
        cpu: <cpu_count>
        memory: <memory_count>
    nodeSelector:
      key: <value>
    tolerations:
    - effect: NoSchedule
      operator: Exists
    volumes:
      - name: config-mount
        configMap:
          name: configmap-name
          items:
            - key: configuration.yml
              path: configuration.yml
    volumeMounts:
      - name: config-mount
        mountPath: /etc/config
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: kubernetes.io/e2e-az-name
              operator: In
              values:
              - e2e-az1
              - e2e-az2
```

## Examples
```
$ helm install .
NAME:   cold-fly
LAST DEPLOYED: Fri Feb  1 15:29:21 2019
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1beta1/CronJob
NAME                    AGE
cold-fly-hello-world    1s
cold-fly-hello-ubuntu   1s
cold-fly-hello-env-var  1s
```
list cronjobs:
```
$ kubectl get cronjob
NAME                     SCHEDULE      SUSPEND   ACTIVE    LAST SCHEDULE   AGE
cold-fly-hello-env-var   * * * * *     False     0         23s             1m
cold-fly-hello-ubuntu    */5 * * * *   False     0         23s             1m
cold-fly-hello-world     * * * * *     False     0         23s             1m
```
list jobs:
```
$ kubectl get jobs
NAME                                DESIRED   SUCCESSFUL   AGE
cold-fly-hello-env-var-1549056600   1         1            45s
cold-fly-hello-ubuntu-1549056600    1         1            45s
cold-fly-hello-world-1549056600     1         1            45s
```
