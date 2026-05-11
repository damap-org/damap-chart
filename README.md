[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/damap)](https://artifacthub.io/packages/search?repo=damap)

# DAMAP Helm Chart

This repository contains the Helm chart used to deploy DAMAP on Kubernetes and OpenShift environments.

The chart sources live under `chart/`.

## Repository structure

```text
.
├── .github/workflows/      # Release workflows
├── chart/                  # Helm chart sources
│   ├── templates/
|   ├── .helmignore
│   ├── Chart.yaml
│   ├── README.md           # Chart documentation (used also by Artifact Hub)
│   └── values.yaml
└── scripts/                # Local development and test cluster helpers
```

## Chart documentation

Chart installation, configuration, and deployment notes are available in `chart/README.md`.

## Releases

Development and release publishing are handled through GitHub Actions.

Published OCI chart packages are available at:

`oci://ghcr.io/damap-org/damap-chart`
