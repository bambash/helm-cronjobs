# helm-cronjobs

[![Release Charts](https://github.com/bambash/helm-cronjobs/actions/workflows/release.yml/badge.svg)](https://github.com/bambash/helm-cronjobs/actions/workflows/release.yml)

A Helm chart for deploying any number of Kubernetes `CronJob` resources from a single, unified `values.yaml`. Define all your batch jobs in one place — Helm handles the rest.

---

## Table of Contents

- [Installing the Chart](#installing-the-chart)
- [Quick Start](#quick-start)
- [Configuration Reference](#configuration-reference)
  - [Required Fields](#required-fields)
  - [CronJob Controls](#cronjob-controls)
  - [Job Controls](#job-controls)
  - [Container](#container)
  - [Security](#security)
  - [Service Account](#service-account)
  - [Private Registries](#private-registries)
  - [Scheduling](#scheduling)
  - [Volumes](#volumes)
  - [Pod Metadata](#pod-metadata)
- [Examples](#examples)
  - [Minimal Job](#minimal-job)
  - [Job with Environment Variables](#job-with-environment-variables)
  - [Job with Resource Limits and Security Context](#job-with-resource-limits-and-security-context)
  - [Job with Private Registry](#job-with-private-registry)
  - [Job with IRSA (AWS IAM Role)](#job-with-irsa-aws-iam-role)
  - [Job with Init Container and Volume](#job-with-init-container-and-volume)
  - [Job with Timezone (Kubernetes ≥ 1.27)](#job-with-timezone-kubernetes--127)
- [Upgrading](#upgrading)

---

## Installing the Chart

### From the Helm repository (recommended)

```bash
helm repo add helm-cronjobs https://bambash.github.io/helm-cronjobs
helm repo update
helm install my-cronjobs helm-cronjobs/helm-cronjobs -f values.yaml
```

### From source

```bash
git clone https://github.com/bambash/helm-cronjobs.git
helm install my-cronjobs ./helm-cronjobs -f values.yaml
```

---

## Quick Start

Create a `values.yaml`:

```yaml
jobs:
  say-hello:
    image:
      repository: busybox
      tag: "1.36"
      imagePullPolicy: IfNotPresent
    schedule: "*/5 * * * *"
    command: ["/bin/sh"]
    args: ["-c", "echo hello from $(date)"]
    restartPolicy: OnFailure
```

Install:

```bash
helm install my-cronjobs helm-cronjobs/helm-cronjobs -f values.yaml
```

List CronJobs:

```bash
kubectl get cronjobs -l app.kubernetes.io/instance=my-cronjobs
# NAME                    SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
# my-cronjobs-say-hello   */5 * * * *   False     0        2m              5m
```

---

## Configuration Reference

All configuration lives under the `jobs` key. Each sub-key becomes the job name, which is combined with the Helm release name to produce the CronJob name: `<release>-<jobname>`.

```yaml
jobs:
  <jobname>:
    # ... fields below
```

You can optionally override the release name prefix:

```yaml
nameOverride: my-prefix
```

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `image.repository` | string | Container image repository |
| `image.tag` | string | Container image tag |
| `schedule` | string | Cron expression (e.g. `"0 * * * *"`) |

### CronJob Controls

| Field | Default | Description |
|-------|---------|-------------|
| `image.imagePullPolicy` | `IfNotPresent` | `Always`, `Never`, or `IfNotPresent` |
| `concurrencyPolicy` | `Allow` | `Allow`, `Forbid`, or `Replace` |
| `failedJobsHistoryLimit` | `1` | Number of failed job runs to retain |
| `successfulJobsHistoryLimit` | `3` | Number of successful job runs to retain |
| `startingDeadlineSeconds` | — | Deadline (seconds) to start a missed job |
| `suspend` | — | Set to `true` to pause the schedule |
| `timeZone` | — | IANA timezone for the schedule (requires Kubernetes ≥ 1.27) |

### Job Controls

| Field | Default | Description |
|-------|---------|-------------|
| `restartPolicy` | `OnFailure` | `OnFailure` or `Never` |
| `backoffLimit` | — | Number of retries before marking the Job failed |
| `activeDeadlineSeconds` | — | Maximum seconds a Job may run |
| `ttlSecondsAfterFinished` | — | Auto-delete finished Jobs after N seconds |

### Container

| Field | Description |
|-------|-------------|
| `command` | Override the container entrypoint |
| `args` | Arguments passed to the command |
| `env` | List of `name`/`value` env vars (supports `valueFrom`) |
| `envFrom` | List of `secretRef` or `configMapRef` sources |
| `resources` | `requests` and `limits` for CPU and memory |
| `volumeMounts` | Volume mount definitions |
| `lifecycle` | `preStop` / `postStart` lifecycle hooks |

### Security

| Field | Description |
|-------|-------------|
| `securityContext` | Pod-level security context (full Kubernetes spec) |
| `containerSecurityContext` | Container-level security context (full Kubernetes spec) |

### Service Account

A `ServiceAccount` is automatically created for each job unless you provide an existing one.

| Field | Description |
|-------|-------------|
| `serviceAccount.name` | Use an existing ServiceAccount instead of creating one |
| `serviceAccount.annotations` | Annotations to add to the auto-created ServiceAccount (e.g. IRSA) |

### Private Registries

One `kubernetes.io/dockerconfigjson` Secret is created per Helm release and shared by all jobs that declare `imagePullSecrets`.

```yaml
imagePullSecrets:
  - username: myuser
    password: mypassword
    registry: registry.example.com
```

### Scheduling

| Field | Description |
|-------|-------------|
| `nodeSelector` | Node label selectors |
| `tolerations` | Pod tolerations |
| `affinity` | Pod affinity/anti-affinity rules |
| `topologySpreadConstraints` | Topology spread constraints |

### Volumes

| Field | Description |
|-------|-------------|
| `volumes` | Pod volume definitions |
| `volumeMounts` | Container volume mount definitions |
| `initContainers` | Init container definitions |

### Pod Metadata

| Field | Description |
|-------|-------------|
| `podAnnotations` | Annotations added to each Job pod |
| `podLabels` | Extra labels added to each Job pod |

---

## Examples

### Minimal Job

```yaml
jobs:
  cleanup:
    image:
      repository: alpine
      tag: "3.19"
    schedule: "0 3 * * *"
    command: ["/bin/sh", "-c", "echo cleaning up..."]
    restartPolicy: OnFailure
```

### Job with Environment Variables

```yaml
jobs:
  report-sender:
    image:
      repository: my-org/reporter
      tag: "2.1.0"
      imagePullPolicy: Always
    schedule: "0 8 * * 1"   # every Monday at 08:00
    env:
      - name: SMTP_HOST
        value: "smtp.example.com"
      - name: SMTP_PASSWORD
        valueFrom:
          secretKeyRef:
            name: smtp-secret
            key: password
    envFrom:
      - configMapRef:
          name: app-config
    restartPolicy: OnFailure
```

### Job with Resource Limits and Security Context

```yaml
jobs:
  data-processor:
    image:
      repository: my-org/processor
      tag: "1.4.2"
    schedule: "*/30 * * * *"
    resources:
      requests:
        cpu: 100m
        memory: 256Mi
      limits:
        cpu: 1000m
        memory: 1Gi
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
      fsGroup: 2000
      seccompProfile:
        type: RuntimeDefault
    containerSecurityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
    restartPolicy: OnFailure
    ttlSecondsAfterFinished: 3600
```

### Job with Private Registry

```yaml
jobs:
  private-job:
    image:
      repository: registry.example.com/my-org/my-image
      tag: "1.0.0"
      imagePullPolicy: Always
    schedule: "0 4 * * *"
    imagePullSecrets:
      - username: myuser
        password: mypassword
        registry: registry.example.com
    restartPolicy: OnFailure
```

### Job with IRSA (AWS IAM Role)

```yaml
jobs:
  s3-sync:
    image:
      repository: amazon/aws-cli
      tag: "2.15.0"
    schedule: "0 1 * * *"
    command: ["aws", "s3", "sync", "/data", "s3://my-bucket/backups/"]
    serviceAccount:
      name: s3-sync-sa
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/S3SyncRole
    restartPolicy: OnFailure
```

### Job with Init Container and Volume

```yaml
jobs:
  db-migrate:
    image:
      repository: my-org/app
      tag: "3.2.0"
    schedule: "0 0 * * 0"   # weekly, Sundays at midnight
    command: ["python", "manage.py", "migrate"]
    initContainers:
      - name: wait-for-db
        image: busybox:1.36
        command: ["sh", "-c", "until nc -z postgres 5432; do sleep 2; done"]
    volumes:
      - name: config
        configMap:
          name: app-config
    volumeMounts:
      - name: config
        mountPath: /app/config
        readOnly: true
    restartPolicy: OnFailure
    backoffLimit: 2
```

### Job with Timezone (Kubernetes ≥ 1.27)

```yaml
jobs:
  nightly-report:
    image:
      repository: my-org/reporter
      tag: "1.0.0"
    schedule: "0 22 * * *"
    timeZone: "America/New_York"   # runs at 22:00 Eastern time
    suspend: false
    restartPolicy: OnFailure
```

---

## Upgrading

### From v2.x to v3.x

- **`values.yaml` default changed**: `jobs` now defaults to `{}` (empty). Copy your existing job definitions into your own `values.yaml` file.
- **`resources` indentation fixed**: The rendered YAML is now correctly indented; no functional change.
- **`securityContext`** now passes through the full Kubernetes object instead of only `runAsUser`, `runAsGroup`, and `fsGroup`. Existing values continue to work.
- **New optional fields** are all opt-in and backward compatible: `timeZone`, `ttlSecondsAfterFinished`, `backoffLimit`, `activeDeadlineSeconds`, `startingDeadlineSeconds`, `suspend`, `podAnnotations`, `podLabels`, `initContainers`, `containerSecurityContext`, `topologySpreadConstraints`, `lifecycle`.
- **`serviceaccount.yaml`**: Fixed a bug where `serviceAccount.annotations` were silently ignored. If you relied on this field before, verify your ServiceAccount annotations are now applied correctly.

