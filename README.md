# helm-cronjobs

A Helm chart for deploying Kubernetes CronJobs. Define an array of jobs in `values.yaml` and Helm will create all the CronJobs for you.

## Installation

```bash
helm install my-release .
```

## Configuration

Jobs are configured under the `jobs` key in `values.yaml`:

```yaml
jobs:
  my-job:
    image:
      repository: my-image
      tag: latest
      imagePullPolicy: IfNotPresent
    schedule: "*/5 * * * *"
    failedJobsHistoryLimit: 1
    successfulJobsHistoryLimit: 3
    concurrencyPolicy: Forbid
    restartPolicy: OnFailure
```

See [`values.yaml`](values.yaml) for the full list of available options.

## License

[MIT](LICENSE)
