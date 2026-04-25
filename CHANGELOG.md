# Changelog

All notable changes to this chart are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/);
versioning follows [Semantic Versioning 2.0](https://semver.org/).

---

## [v2.2.0] – Unreleased

### Security
- Hardened pod and container security contexts conforming to the Kubernetes
  **restricted** Pod Security Standard (runAsNonRoot, seccompProfile RuntimeDefault,
  readOnlyRootFilesystem, no privilege escalation, drop ALL capabilities).
- `automountServiceAccountToken: false` on all generated ServiceAccounts and pod specs.
- Global `defaultPodSecurityContext` / `defaultContainerSecurityContext` values with
  per-job override support; backward-compatible with old `securityContext` key.

### Added
- `templates/networkpolicy.yaml` – deny-all ingress + DNS egress; gated by `networkPolicy.enabled`.
- `templates/pdb.yaml` – per-job PodDisruptionBudget (policy/v1); gated by `pdb.enabled`.
- `templates/vpa.yaml` – per-job VerticalPodAutoscaler (autoscaling.k8s.io/v1) in Off mode; gated by `vpa.enabled`.
- `values.schema.json` – full JSON Schema (draft-07) for all `values.yaml` keys.
- `values.yaml`: `defaultResources`, `mountTmpDir`, `terminationGracePeriodSeconds`,
  `preStopSleep`, `topologySpread`, `podAntiAffinity` global settings.
- Auto-mount `/tmp` as `emptyDir` when `readOnlyRootFilesystem: true`.
- Optional per-job `startupProbe` and `livenessProbe` support.
- Optional per-job `lifecycle`, `podAnnotations`, and `terminationGracePeriodSeconds` overrides.
- `serviceAccount.create` flag per job (default true) to skip SA creation when using existing SA.

### Changed
- `Chart.yaml`: added `type: application`, `appVersion`, `kubeVersion: >=1.29.0-0`,
  `icon`, `artifacthub.io/*` annotations.
- `templates/_helpers.tpl`: added `cronjobs.name` and `cronjobs.selectorLabels` helpers;
  all resources now carry full `app.kubernetes.io/*` label set.
- `templates/cronjob.yaml`: schedule moved to top of spec, consistent `nindent` formatting,
  standard labels on pod template, resources always rendered.
- `templates/serviceaccount.yaml`: fixed `hasKey` bug (string literal `"serviceAccount.name"`
  was never matching); added `automountServiceAccountToken: false`.
- `NOTES.txt`: Pod Security Standard namespace label instructions added.
- Version bumped to 2.2.0.

## [v2.1.0] – 2025-04-25

### Added
- `templates/tests/` – Helm test suite (connectivity, configuration, smoke).
- `templates/NOTES.txt` – post-install instructions including `helm test` usage.
- `ci/test-values.yaml` – CI-specific value overrides for the kind integration test.
- `.github/workflows/chart-ci.yaml` – lint, kubeconform validation, and kind integration tests on every PR/push.
- `.github/workflows/chart-release.yaml` – automated chart packaging and GitHub Pages Helm repo publication on semver tag push.

---

## [v2.0.0] – Initial release

### Added
- Multi-CronJob chart supporting arbitrary job definitions via `values.yaml`.
- Support for image pull secrets, env vars, envFrom, resource limits, security contexts, node selectors, tolerations, and affinity.
- ServiceAccount per job with optional custom name and annotations.
