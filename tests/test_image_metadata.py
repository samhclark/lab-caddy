"""Exercise the metadata boundary used by local builds and image publishing."""

import subprocess
import tempfile
import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / "scripts/image-metadata.sh"
BUILDER = "docker.io/library/caddy:2.11.9-builder@sha256:" + "a" * 64
RUNTIME = "docker.io/library/caddy:2.11.9@sha256:" + "b" * 64
MODULE = "--with github.com/caddy-dns/cloudflare@v0.2.4"
CONTAINERFILE = f"FROM {BUILDER} AS builder\nRUN xcaddy build {MODULE}\nFROM {RUNTIME}\n"


class ImageMetadataTests(unittest.TestCase):
    def invoke(self, content, *, tag_only=False):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "Containerfile"
            path.write_text(content)
            arguments = [str(SCRIPT)]
            if tag_only:
                arguments.append("--tag")
            return subprocess.run(
                [*arguments, str(path)],
                cwd=directory,
                capture_output=True,
                text=True,
                check=False,
            )

    def assert_rejected(self, content, message):
        result = self.invoke(content)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "", "failed validation must not emit publishing outputs")
        self.assertIn(message, result.stderr)

    def test_metadata_is_ready_for_github_outputs(self):
        result = self.invoke(CONTAINERFILE)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            result.stdout,
            "caddy_version=2.11.9\ncloudflare_version=0.2.4\nimage_tag=2.11.9-cf-0.2.4\n",
        )

    def test_tag_only_mode_returns_the_local_build_tag(self):
        result = self.invoke(CONTAINERFILE, tag_only=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "2.11.9-cf-0.2.4\n")

    def test_updating_only_containerfile_updates_all_metadata(self):
        updated = CONTAINERFILE.replace("2.11.9", "2.12.0").replace("v0.2.4", "v0.3.0")
        result = self.invoke(updated)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            result.stdout,
            "caddy_version=2.12.0\ncloudflare_version=0.3.0\nimage_tag=2.12.0-cf-0.3.0\n",
        )

    def test_repository_defaults_work_outside_the_repository_directory(self):
        with tempfile.TemporaryDirectory() as directory:
            result = subprocess.run(
                [str(SCRIPT)], cwd=directory, capture_output=True, text=True, check=False
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        metadata = dict(line.split("=", 1) for line in result.stdout.splitlines())
        self.assertEqual(set(metadata), {"caddy_version", "cloudflare_version", "image_tag"})
        self.assertEqual(
            metadata["image_tag"],
            f"{metadata['caddy_version']}-cf-{metadata['cloudflare_version']}",
        )

    def test_partial_caddy_updates_are_rejected(self):
        self.assert_rejected(
            CONTAINERFILE.replace("2.11.9-builder", "2.12.0-builder"),
            "builder and runtime versions must match",
        )

    def test_missing_or_duplicate_references_are_rejected(self):
        for reference, name in [(BUILDER, "builder"), (RUNTIME, "runtime")]:
            with self.subTest(name=name, case="missing"):
                self.assert_rejected(
                    "\n".join(line for line in CONTAINERFILE.splitlines() if reference not in line),
                    f"exactly one digest-pinned Caddy {name} reference",
                )
            with self.subTest(name=name, case="duplicate"):
                self.assert_rejected(
                    CONTAINERFILE + f"FROM {reference}\n",
                    f"exactly one digest-pinned Caddy {name} reference",
                )

    def test_missing_malformed_or_unpinned_digests_are_rejected(self):
        for reference in (BUILDER, RUNTIME):
            for bad_reference in (reference.split("@")[0], reference[:-1], reference[:-1] + "z"):
                with self.subTest(reference=bad_reference):
                    self.assert_rejected(
                        CONTAINERFILE.replace(reference, bad_reference),
                        "invalid digest-pinned Caddy reference",
                    )

    def test_preview_image_versions_are_rejected(self):
        self.assert_rejected(
            CONTAINERFILE.replace("2.11.9-builder", "2.12.0-rc1-builder"),
            "invalid digest-pinned Caddy reference",
        )

    def test_missing_or_duplicate_cloudflare_pins_are_rejected(self):
        for content in (
            CONTAINERFILE.replace(MODULE, ""),
            CONTAINERFILE.replace(MODULE, f"{MODULE} {MODULE}"),
            CONTAINERFILE + f"RUN xcaddy build {MODULE}\n",
        ):
            with self.subTest(content=content):
                self.assert_rejected(content, "exactly one Cloudflare module pin")

    def test_cloudflare_versions_must_be_stable_numeric_releases(self):
        for version in ("latest", "v0.3.0-rc1", "v0.3", "v0.3.0;echo-injected"):
            with self.subTest(version=version):
                self.assert_rejected(
                    CONTAINERFILE.replace("v0.2.4", version), "invalid stable Cloudflare version"
                )

    def test_comments_and_missing_final_newline_are_supported(self):
        content = f"# FROM {BUILDER}\n# {MODULE}\n" + CONTAINERFILE.replace(
            MODULE, f"{MODULE} # example: {MODULE}"
        ).rstrip("\n")
        result = self.invoke(content)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_commented_out_cloudflare_pin_is_not_a_build_input(self):
        self.assert_rejected(
            CONTAINERFILE.replace(MODULE, f"# {MODULE}"), "exactly one Cloudflare module pin"
        )

    def test_missing_containerfile_fails_without_outputs(self):
        result = subprocess.run(
            [str(SCRIPT), "/nonexistent/lab-caddy/Containerfile"],
            capture_output=True, text=True, check=False,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertIn("cannot read", result.stderr)


if __name__ == "__main__":
    unittest.main()
