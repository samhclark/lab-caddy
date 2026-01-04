# lab-caddy

Prebuilt Caddy container image with the Cloudflare DNS-01 module baked in. This exists so other projects (notably `../custom-coreos`) can pull a known-good image instead of building `xcaddy` at boot.

## Image

- Registry: `ghcr.io/samhclark/lab-caddy`
- Tag format: `<caddy-version>-cf-<cloudflare-version>`
- Example: `ghcr.io/samhclark/lab-caddy:2.11-cf-0.2.2`

## Versions

Pinned versions and digests live in `Containerfile`:

- `ARG CADDY_VERSION`
- `ARG CLOUDFLARE_VERSION`
- `FROM ...@sha256:` digests

When bumping versions, update the ARGs and the digests together.

## Local build

```bash
just build
```

Quick build test (builds then removes the image):

```bash
just test-build
```

## CI/CD

GitHub Actions builds, pushes, attests, and signs the image on a weekly schedule and on manual dispatch.

Cleanup workflow prunes old GHCR image versions on a weekly schedule (manual trigger defaults to dry-run).
