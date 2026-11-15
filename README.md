# lab-caddy

Prebuilt Caddy container image with the Cloudflare DNS-01 module baked in. This exists so other projects (notably `../custom-coreos`) can pull a known-good image instead of building `xcaddy` at boot.

## Image

- Registry: `ghcr.io/samhclark/lab-caddy`
- Tag format: `<caddy-version>-cf-<cloudflare-version>`

## Versions

`Containerfile` is the source of truth for versions:

- The two `FROM` references pin the Caddy builder and runtime images by version
  and digest. Their Caddy versions must match.
- The `xcaddy --with` argument pins the Cloudflare module version.

`scripts/image-metadata.sh` reads and validates these pins, then emits
`caddy_version`, `cloudflare_version`, and `image_tag` as `key=value` lines.
The publishing workflow consumes these as GitHub step outputs. Local builds use
the same script's `--tag` output. Missing, duplicate, malformed, or mismatched
pins fail before a build or publication can proceed.

When bumping Caddy, update both `FROM` versions and their digests together.
No Justfile or workflow version edits are needed. Changing only the Cloudflare
pin also updates the derived tag automatically.

Dependabot handles the Caddy base images as a group and maintains GitHub Actions.
`renovate.json` tracks only the Cloudflare Go module embedded in the `xcaddy`
command; enable the Renovate GitHub App for this repository to activate it.
Neither updater is configured to merge automatically.

## Local build

Show the derived metadata and run the parser's behavioral tests:

```bash
just versions
just check
```

```bash
just build
```

Quick build test (builds then removes the image):

```bash
just test-build
```

## CI/CD

GitHub Actions builds, pushes, attests, and signs the image on a weekly schedule and on manual dispatch.

Pull requests and pushes to `main` run metadata tests and validate the current
build inputs without publishing an image.

Cleanup workflow prunes old GHCR image versions on a weekly schedule (manual trigger defaults to dry-run).
