# helm-cronjobs

Deploy and manage multiple Kubernetes CronJobs from a single Helm chart.
Define any number of jobs in `values.yaml`; the chart creates CronJobs,
ServiceAccounts, and optional NetworkPolicy / PDB / VPA resources for each.

Kubernetes ≥ 1.29 required. Conforms to the **restricted** Pod Security Standard.

---

## Quick start

```bash
helm repo add helm-cronjobs https://<owner>.github.io/helm-cronjobs/
helm repo update
helm install my-release helm-cronjobs/helm-cronjobs
```
---

## How to use as a starter chart

1. Find your Helm data directory: `helm env` → look for `HELM_DATA_HOME`.
2. `cd $HELM_DATA_HOME && mkdir -p starters && cd starters`
3. Clone this repo.
4. Scaffold a new chart: `helm create -p helm-cronjobs your_chart_name`

---

## Configuration

### Job definition overview

```yaml
jobs:
  job-a:            # creates CronJob <release>-job-a
    image:
      repository: my-image
      tag: "1.0.0"
      imagePullPolicy: IfNotPresent
    schedule: "*/5 * * * *"
    failedJobsHistoryLimit: 1
    successfulJobsHistoryLimit: 3
    concurrencyPolicy: Forbid   # Allow | Forbid | Replace
    restartPolicy: OnFailure    # OnFailure | Never
    command: ["/app/run"]
    args: ["--flag"]
    env:
      - name: MY_VAR
        value: "hello"
    resources:
      limits:   { cpu: 200m, memory: 256Mi }
      requests: { cpu: 100m, memory: 128Mi }
```

---

## Values reference

### Global settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `nameOverride` | string | `""` | Override release name in all resource names (≤63 chars) |
| `terminationGracePeriodSeconds` | int | `30` | Seconds between SIGTERM and SIGKILL (per-job override available) |
| `mountTmpDir` | bool | `true` | Auto-mount `/tmp` emptyDir when `readOnlyRootFilesystem: true` |

### Security contexts (chart-level defaults)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `defaultPodSecurityContext.runAsNonRoot` | bool | `true` | Reject pods running as root |
| `defaultPodSecurityContext.runAsUser` | int | `65534` | UID for all containers (override per job) |
| `defaultPodSecurityContext.runAsGroup` | int | `65534` | GID for all containers |
| `defaultPodSecurityContext.fsGroup` | int | `65534` | Supplemental GID for volume ownership |
| `defaultPodSecurityContext.seccompProfile.type` | string | `RuntimeDefault` | Seccomp profile |
| `defaultContainerSecurityContext.allowPrivilegeEscalation` | bool | `false` | Block privilege escalation |
| `defaultContainerSecurityContext.readOnlyRootFilesystem` | bool | `true` | Read-only root FS |
| `defaultContainerSecurityContext.capabilities.drop` | list | `["ALL"]` | Dropped Linux capabilities |

### Resource defaults

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `defaultResources.limits.cpu` | string | `100m` | Default CPU limit |
| `defaultResources.limits.memory` | string | `128Mi` | Default memory limit |
| `defaultResources.requests.cpu` | string | `50m` | Default CPU request |
| `defaultResources.requests.memory` | string | `64Mi` | Default memory request |

### Workload reliability

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `preStopSleep.enabled` | bool | `false` | Inject a pre-stop sleep hook on all jobs |
| `preStopSleep.seconds` | int | `5` | Sleep duration in seconds |
| `topologySpread.enabled` | bool | `false` | Spread pods across topology zones |
| `topologySpread.constraints[].maxSkew` | int | `1` | Max pod imbalance between zones |
| `topologySpread.constraints[].topologyKey` | string | `topology.kubernetes.io/zone` | Topology key |
| `topologySpread.constraints[].whenUnsatisfiable` | string | `DoNotSchedule` | Scheduling behaviour when constraint cannot be met |
| `podAntiAffinity.enabled` | bool | `false` | Preferred anti-affinity across nodes |
| `podAntiAffinity.weight` | int | `100` | Anti-affinity preference weight (1–100) |

### PodDisruptionBudget

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `pdb.enabled` | bool | `false` | Create a PDB per job (policy/v1) |
| `pdb.minAvailable` | int/string | `1` | Minimum available pods during voluntary disruption |

> **Warning:** `minAvailable: 1` will block node drains while a job pod is running.
> Only enable for long-running jobs where partial eviction is unacceptable.

### NetworkPolicy

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `networkPolicy.enabled` | bool | `false` | Create a NetworkPolicy for all job pods |
| `networkPolicy.egress.allowAll` | bool | `true` | Allow all outbound traffic (DNS is always allowed) |
| `networkPolicy.egress.additionalRules` | list | `[]` | Extra egress rules when `allowAll: false` |

### VerticalPodAutoscaler

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `vpa.enabled` | bool | `false` | Create a VPA per job (requires VPA controller) |
| `vpa.updateMode` | string | `"Off"` | `Off` or `Initial` only — `Auto`/`Recreate` will evict running pods |

### Per-job settings

Each entry under `jobs` supports these keys:

| Key | Required | Description |
|-----|----------|-------------|
| `image.repository` | ✅ | Container image repository |
| `image.tag` | ✅ | Image tag |
| `image.imagePullPolicy` | — | `Always \| IfNotPresent \| Never` (default `IfNotPresent`) |
| `schedule` | ✅ | Cron expression (5-field) |
| `failedJobsHistoryLimit` | ✅ | Retain N failed Job records |
| `successfulJobsHistoryLimit` | ✅ | Retain N successful Job records |
| `concurrencyPolicy` | ✅ | `Allow \| Forbid \| Replace` |
| `restartPolicy` | ✅ | `OnFailure \| Never` |
| `command` | — | Override container ENTRYPOINT |
| `args` | — | Override container CMD |
| `env` | — | Environment variable list |
| `envFrom` | — | ConfigMap / Secret env-from sources |
| `resources` | — | Overrides `defaultResources` for this job |
| `podSecurityContext` | — | Overrides `defaultPodSecurityContext` for this job |
| `containerSecurityContext` | — | Overrides `defaultContainerSecurityContext` for this job |
| `terminationGracePeriodSeconds` | — | Per-job SIGTERM window |
| `lifecycle` | — | Container lifecycle hooks (overrides `preStopSleep`) |
| `livenessProbe` | — | Detect hung containers |
| `startupProbe` | — | Allow extra init time before liveness kicks in |
| `serviceAccount.name` | — | Use a specific SA name (auto-generated if empty) |
| `serviceAccount.create` | — | `true` (default) — set `false` to use pre-existing SA |
| `serviceAccount.automountServiceAccountToken` | — | Default `false` |
| `serviceAccount.annotations` | — | Annotations on the generated ServiceAccount |
| `imagePullSecrets` | — | Registry credentials (prefer existing secrets in production) |
| `nodeSelector` | — | Node selector labels |
| `tolerations` | — | Pod tolerations |
| `affinity` | — | Full affinity spec (disables `podAntiAffinity` for this job) |
| `volumes` | — | Additional volumes |
| `volumeMounts` | — | Additional volume mounts |
| `podAnnotations` | — | Annotations on the pod template |

---

## Running Tests

```bash
helm test <release-name> --namespace <ns> --logs
```

| Test pod | What it validates |
|----------|-------------------|
| `*-test-connectivity` | All CronJob resources exist in the cluster |
| `*-test-configuration` | Live spec matches schedule, image, and env vars in values |
| `*-test-smoke` | One-off Job run exits 0 within `tests.smoke.timeoutSeconds` |

---

## CI / CD

### Workflows

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `chart-ci.yaml` | PR / push to `main` or `master` | `helm lint --strict` → `kubeconform` → kind cluster → `helm test` |
| `chart-release.yaml` | Push of `v*.*.*` tag | Validate semver, package, GitHub Release + `gh-pages` index |

### Release process

```bash
# 1. Bump version in Chart.yaml and CHANGELOG.md, commit to main
# 2. Tag and push
git tag v2.2.0
git push origin v2.2.0
```

Pre-release tags are supported: `v2.2.0-rc.1`, `v2.2.0-beta.2`, etc.

### Installing from the Helm repository

```bash
helm repo add helm-cronjobs https://<owner>.github.io/helm-cronjobs/
helm repo update
helm install my-release helm-cronjobs/helm-cronjobs
```

### Required secrets

| Secret | Source | Used by |
|--------|--------|---------|
| `GITHUB_TOKEN` | Automatically provided | Both workflows |

No additional secrets are required.

---

## Security

- Conforms to the Kubernetes **restricted** Pod Security Standard by default.
- All generated ServiceAccounts have `automountServiceAccountToken: false`.
- No secrets are stored in `values.yaml` by default; use `imagePullSecrets` only
  for non-production clusters and supply credentials via `--set` or sealed secrets
  in production.
- `helm install --validate` uses `values.schema.json` to catch invalid input early.
