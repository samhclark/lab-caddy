# just manual: https://github.com/casey/just/#readme

CADDY_VERSION := "2.11"
CLOUDFLARE_VERSION := "0.2.2"
IMAGE_TAG := "{{CADDY_VERSION}}-cf-{{CLOUDFLARE_VERSION}}"

_default:
    @just --list

versions:
    @echo "Caddy Version: {{CADDY_VERSION}}"
    @echo "Cloudflare Plugin Version: {{CLOUDFLARE_VERSION}}"
    @echo "Image Tag: {{IMAGE_TAG}}"

build:
    #!/usr/bin/env bash
    podman build --rm \
        --build-arg CADDY_VERSION="{{CADDY_VERSION}}" \
        --build-arg CLOUDFLARE_VERSION="{{CLOUDFLARE_VERSION}}" \
        -t "lab-caddy:{{IMAGE_TAG}}" \
        -f Containerfile \
        .

test-build:
    #!/usr/bin/env bash
    podman build --rm \
        --build-arg CADDY_VERSION="{{CADDY_VERSION}}" \
        --build-arg CLOUDFLARE_VERSION="{{CLOUDFLARE_VERSION}}" \
        -t "lab-caddy:test" \
        -f Containerfile \
        . && podman rmi "lab-caddy:test"

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
