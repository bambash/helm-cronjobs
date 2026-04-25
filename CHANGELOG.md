# Changelog

All notable changes to this chart are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/);
versioning follows [Semantic Versioning 2.0](https://semver.org/).

---

## [v2.1.0] – Unreleased

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
