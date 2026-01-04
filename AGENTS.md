# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## Overview

This repo builds a precompiled Caddy container image with the Cloudflare DNS-01 module baked in. The image is used by `../custom-coreos` so boot-time builds are avoided.

## Key Files

- `Containerfile` - two-stage xcaddy build with pinned digests
- `Justfile` - local build and workflow helpers
- `.github/workflows/build.yaml` - build/push/attest/sign on schedule or manual
- `.github/workflows/cleanup-images.yaml` - GHCR retention cleanup
- `install-cosign.sh` - pinned cosign build/install helper for CI

## Commands

- `just versions` - show pinned versions and tag
- `just build` - build the image locally
- `just test-build` - build then remove the test image
- `just run-workflow` - trigger the build workflow
- `just run-cleanup` - trigger cleanup (dry run)
- `just run-cleanup-force` - trigger cleanup (deletion)

## Notes

- Update `Containerfile` ARGs and digests together when bumping versions.
- Tag format is `<caddy-version>-cf-<cloudflare-version>`.
