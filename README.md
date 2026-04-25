# helm-cronjobs
You can define an array of jobs in values.yaml helm will take care of creating all the CronJobs.

## How to use as a starter chart

1. Find your Helm data directory, `HELM_DATA_HOME`

    ```
    helm env
    ```

1.  `cd` to this directory, then

    ```
    mkdir starters
    cd starters
    ```

1.  Clone this repo

1.  In your cronjob project, set up your new chart with

    ```
    helm create -p helm-cronjobs your_chart_name
    ```

## Configuration

Via `values.yaml`

### Overview

```yaml
jobs:
  jobname-1:
    # job definition
  jobname-2:
    # job definition
  jobname-n:
    # job definition
```

### Details

```yaml
jobs:
  ### REQUIRED ###
  <job_name>:
    image:
      repository: <image_repo>
      tag: <image_tag>
      imagePullPolicy: <pull_policy>
    schedule: "<cron_schedule>"
    failedJobsHistoryLimit: <failed_history_limit>
    successfulJobsHistoryLimit: <successful_history_limit>
    concurrencyPolicy: <concurrency_policy>
    restartPolicy: <restart_policy>
  ### OPTIONAL ###
    imagePullSecrets:
    - username: <user>
      password: <password>
      email: <email>
      registry: <registry>
    env:
    - name: ENV_VAR
      value: ENV_VALUE
    envFrom:
    - secretRef:
      name: <secret_name>
    - configMapRef:
      name: <configmap_name>
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
    serviceAccount:
      name: <account_name>
      annotations:  # Optional
        my-annotation-1: <value>
        my-annotation-2: <value>
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
$ helm install test-cron-job .
NAME:   cold-fly
LAST DEPLOYED: Fri Feb  1 15:29:21 2019
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1/CronJob
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

---

## Running Tests

After installing the chart, run the Helm test suite:

```bash
helm test <release-name> --logs
```

The suite contains three test pods:

| Pod | What it checks |
|-----|----------------|
| `*-test-connectivity` | All CronJob resources exist and are reachable via the Kubernetes API |
| `*-test-configuration` | Schedule, image, and env-var values in the live CronJob spec match `values.yaml` |
| `*-test-smoke` | Triggers a one-off Job from the chosen CronJob (`tests.smoke.jobName`) and asserts exit 0 |

Test behaviour is configurable via `values.yaml`:

```yaml
tests:
  enabled: true
  image:
    repository: bitnami/kubectl
    tag: "1.29"
  connectivity:
    enabled: true
    timeoutSeconds: 60
  configuration:
    enabled: true
    jobName: hello-env-var          # which job to inspect
    expectedEnvVars:
      - name: ECHO_VAR
        value: "busybox"
    timeoutSeconds: 60
  smoke:
    enabled: true
    jobName: hello-ubuntu           # which job to trigger
    timeoutSeconds: 120
```

---

## CI / CD

### GitHub Actions workflows

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `chart-ci.yaml` | PR / push to `main` or `master` | `helm lint` → `kubeconform` validation → kind cluster install → `helm test` |
| `chart-release.yaml` | Push of a semver tag (`v*.*.*`) | Validate tag vs `Chart.yaml`, package chart, publish GitHub Release + update Helm repo index on `gh-pages` |

### Branching and tagging convention

- `main` / `master` is always releasable.
- Releases are cut by pushing a semver tag **after** updating `version:` in `Chart.yaml`:

```bash
# 1. Bump version in Chart.yaml (e.g. 2.0.0 → 2.1.0)
# 2. Commit and push to main
git tag v2.1.0
git push origin v2.1.0
```

- Pre-release suffixes are supported (`v1.2.3-rc.1`, `v1.2.3-beta.2`, etc.).
- The release workflow validates that the tag matches `Chart.yaml`; it will fail fast if they diverge.

### Installing from the Helm repository

Once the first release has been published and `gh-pages` is enabled in the repository settings:

```bash
helm repo add helm-cronjobs https://<owner>.github.io/helm-cronjobs/
helm repo update
helm install my-release helm-cronjobs/helm-cronjobs
```

### Required secrets

| Secret | Where it comes from | Used by |
|--------|--------------------|---------| 
| `GITHUB_TOKEN` | Automatically provided by GitHub Actions | Both workflows |

No additional secrets are required.
