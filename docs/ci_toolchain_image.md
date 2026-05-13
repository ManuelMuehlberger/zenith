# CI Toolchain Image

## Purpose

The main quality gate runs on a self-hosted Gitea runner that starts a fresh
container for every job. Reinstalling Java, Flutter, and Android SDK components
on every run is slow and adds avoidable network variance.

This repo now includes a dedicated CI toolchain image pipeline that:

1. Builds a reusable container image with Java 17, Flutter, and Android build
   tooling preinstalled.
2. Automatically refreshes that image when Flutter stable advances.
3. Promotes a floating image tag that the runner can use directly, while keeping
   immutable build tags for auditability and rollback.

## Files

- `.ci/toolchain-image/Dockerfile`: builds the reusable CI image.
- `scripts/resolve_flutter_stable.py`: resolves Flutter stable metadata from the
  official Linux release manifest.
- `scripts/ci_image_smoke_test.sh`: validates a candidate image against this repo.
- `.gitea/workflows/refresh-ci-image.yml`: builds, validates, and promotes the
  CI image.
- `.gitea/workflows/quality-gate.yml`: detects whether the runner already has a
  prebuilt toolchain and only falls back to setup actions when it does not.

## What Changes In Main CI

The main quality gate still runs on `ubuntu-latest` in
`.gitea/workflows/quality-gate.yml`.

Behavior:

1. If the runner image already contains Java 17 and the current Flutter stable
   release, the workflow skips `actions/setup-java` and `subosito/flutter-action`.
2. If the runner image does not provide them, the workflow falls back to those
   setup actions.

That keeps rollout safe. The repo can land the image automation before the
runner label is changed, and the runner can switch later without breaking CI.

## Tag Model

The refresh workflow publishes three tag shapes:

1. Immutable build tag: `flutter-<version>-<source-hash>`
2. Version alias: `flutter-<version>`
3. Promoted stable alias: `flutter-stable`

Example:

- `registry.example.com/manu/zenith-ci:flutter-3.41.9-a1b2c3d4e5f6`
- `registry.example.com/manu/zenith-ci:flutter-3.41.9`
- `registry.example.com/manu/zenith-ci:flutter-stable`

The immutable tag changes whenever either of these changes:

1. Flutter stable version
2. CI image source definition, such as the Dockerfile, smoke test, or refresh workflow logic

That avoids the common problem where a Dockerfile changes but an old version-only
tag still looks current.

## Automatic Refresh Flow

`.gitea/workflows/refresh-ci-image.yml` runs in three cases:

1. On a schedule
2. Manually through `workflow_dispatch`
3. On `main` when the CI image definition files change

Its flow is:

1. Resolve the current Flutter stable release, or an explicit version when one
   is provided manually.
2. Compute a source hash from the image definition files.
3. Build the immutable image if that exact build does not already exist.
4. Smoke-validate the image against the checked-out repo.
5. Promote `flutter-<version>` and `flutter-stable` only after validation passes.

That means new Flutter releases are not adopted blindly. They are only promoted
after the repo still passes basic validation inside the new image.

## Smoke Validation

The image refresh workflow validates the candidate image by running:

1. `flutter --version`
2. `dart --version`
3. `java -version`
4. `flutter doctor -v`
5. `flutter pub get`
6. `dart format --output=none --set-exit-if-changed lib test`
7. `flutter analyze`
8. A focused Flutter test slice
9. `flutter build apk --debug`

This is intentionally lighter than the full quality gate, but still strong
enough to prevent obviously broken toolchain promotions.

## Registry Configuration

Create these repo variables:

1. `CI_IMAGE_REGISTRY`: registry host, for example `mygit.7cc.xyz`
2. `CI_IMAGE_REPOSITORY`: repository path, for example `manu/zenith-ci`

Create these repo secrets:

1. `CI_IMAGE_REGISTRY_USERNAME`
2. `CI_IMAGE_REGISTRY_PASSWORD`

The credentials must be able to push container images to the configured
repository.

## Runner Configuration

Two runner labels are involved.

### Main CI Runner

The quality gate continues to run on `ubuntu-latest`, but the label should point
at the promoted image instead of the generic act image.

Recommended label mapping:

```text
ubuntu-latest:docker://mygit.7cc.xyz/manu/zenith-ci:flutter-stable
```

If you also use `ubuntu-22.04`, point it at the same image unless you have a
reason to keep a separate mapping.

### Image Builder Runner

The image refresh workflow runs on `ci-image-builder` and expects Docker build
and push capability. The cleanest option is a dedicated host-style runner label:

```text
ci-image-builder:host
```

That runner must have:

1. Docker CLI available
2. Permission to talk to the Docker daemon
3. Network access to your container registry

## Required Runner Behavior

For the promoted floating tag to be picked up automatically, keep runner image
pull behavior enabled. In `act_runner` config that means:

```yaml
container:
  force_pull: true
```

Without `force_pull: true`, the runner may keep using an older cached image even
after `flutter-stable` has been promoted.

For your Docker-based Gitea setup, keep the runner on the internal Gitea network
as well:

```yaml
container:
  network: gitea_gitea
```

## Manual Operations

You can trigger `.gitea/workflows/refresh-ci-image.yml` manually to:

1. Rebuild the current stable image
2. Force a rebuild of an existing immutable tag
3. Test a specific stable Flutter version before the scheduled refresh picks it up

The workflow accepts:

1. `flutter_version`: optional exact stable version
2. `force_rebuild`: optional boolean

## Rollback

Rollback is a promotion operation, not a rebuild.

To roll back, retag a previously known-good immutable image as `flutter-stable`
and push it again.

Example:

```sh
docker pull registry.example.com/manu/zenith-ci:flutter-3.41.9-a1b2c3d4e5f6
docker tag \
  registry.example.com/manu/zenith-ci:flutter-3.41.9-a1b2c3d4e5f6 \
  registry.example.com/manu/zenith-ci:flutter-stable
docker push registry.example.com/manu/zenith-ci:flutter-stable
```

The next job will then pull the rolled-back promoted tag.

## Updating Android SDK Packages

The Docker image currently preinstalls:

1. Android platform API 36
2. Build tools 36.0.0
3. Android platform API 35
4. Build tools 35.0.0
5. NDK 28.2.13676358

If a future Flutter stable release or Android Gradle Plugin bump needs a newer
Android SDK platform or build tools version, update the args in
`.ci/toolchain-image/Dockerfile`. The refresh workflow will fail smoke
validation instead of silently promoting a broken image.
