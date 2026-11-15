# just manual: https://github.com/casey/just/#readme

_default:
    @just --list

versions:
    @./scripts/image-metadata.sh

check:
    @python3 -B -m unittest discover -s tests -v

build:
    #!/usr/bin/env bash
    set -euo pipefail
    image_tag="$(./scripts/image-metadata.sh --tag)"
    podman build --rm \
        -t "lab-caddy:${image_tag}" \
        -f Containerfile \
        .

test-build:
    #!/usr/bin/env bash
    set -euo pipefail
    ./scripts/image-metadata.sh >/dev/null
    podman build --rm \
        -t "lab-caddy:test" \
        -f Containerfile \
        .
    podman rmi "lab-caddy:test"

run-workflow:
    gh workflow run build.yaml

run-cleanup:
    gh workflow run cleanup-images.yaml

run-cleanup-force:
    gh workflow run cleanup-images.yaml -f dry_run=false

workflow-status:
    gh run list --workflow=build.yaml --limit=5

all-workflows:
    #!/usr/bin/env bash
    echo "Build Workflow:"
    gh run list --workflow=build.yaml --limit=3
    echo ""
    echo "Cleanup Workflow:"
    gh run list --workflow=cleanup-images.yaml --limit=3
