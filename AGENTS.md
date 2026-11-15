# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## Overview

This repo builds a precompiled Caddy container image with the Cloudflare DNS-01 module baked in. The image is used by `../custom-coreos` so boot-time builds are avoided.

## Key Files

- `Containerfile` - two-stage xcaddy build with pinned digests
- `scripts/image-metadata.sh` - shared validation and derived image metadata
- `Justfile` - local checks, build, and workflow helpers
- `tests/test_image_metadata.py` - behavioral coverage for the metadata boundary
- `.github/workflows/check.yaml` - read-only metadata checks on PRs and main
- `.github/workflows/build.yaml` - build/push/attest/sign on schedule or manual
- `.github/workflows/cleanup-images.yaml` - GHCR retention cleanup
- `.github/dependabot.yaml` - grouped Caddy base-image and GitHub Actions updates
- `renovate.json` - Cloudflare module updates only

## Commands

- `just versions` - show pinned versions and tag
- `just check` - run metadata behavioral tests
- `just build` - build the image locally
- `just test-build` - build then remove the test image
- `just run-workflow` - trigger the build workflow
- `just run-cleanup` - trigger cleanup (dry run)
- `just run-cleanup-force` - trigger cleanup (deletion)

## Notes

- `Containerfile` is authoritative: update both Caddy `FROM` versions and
  digests together, or the Cloudflare `--with` pin. Never duplicate versions
  in the Justfile or workflows; use the shared metadata script.
- Run `just check` after metadata changes and `just test-build` after build changes.
- Tag format is `<caddy-version>-cf-<cloudflare-version>`.
