## Linux Packer Templates for Tart

Repository with Packer templates to build [Tart VMs](https://github.com/cirruslabs/tart) to use with self-hosted GitHub Actions runners and [Cirrus Runners](https://tart.run/integrations/github-actions/).

See a full list of VMs available [here](https://github.com/orgs/cirruslabs/packages?repo_name=linux-image-templates).

[The image workflow](.github/workflows/images.yml) rebuilds and publishes the images every Saturday. To rebuild and publish a single image, open **Actions → Linux Images → Run workflow** and select the image; select `all` to rebuild every image.

The dependency step reuses installed Homebrew tools and installs missing packages. Update the self-hosted runners' tools separately. Intel macOS runners need compatible preinstalled dependencies because [Homebrew no longer builds new bottles for Intel macOS](https://docs.brew.sh/Support-Tiers#future-macos-support).

Publishing uses the workflow's `GITHUB_TOKEN`. Each destination GHCR package must grant this repository **Write** access through **Package settings → Manage Actions access**, or inherit access from this repository. If publishing fails with `403 permission_denied: write_package`, check these [package access settings](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility#ensuring-workflow-access-to-your-package), even when the workflow already has `packages: write`.

### Omarchy

Build a native ARM64 Omarchy desktop template on an Apple Silicon Mac. The
[builder](omarchy/build.sh) imports the factory disk from the
[latest stable Try Omarchy release](https://github.com/omacom/try-omarchy/releases/latest)
after checking the SHA-256 digest of each disk asset. [Packer](omarchy/omarchy.pkr.hcl)
configures the VM with 4 CPUs, 8 GiB of memory, and a 1440 × 900 display.

```sh
brew install cirruslabs/cli/tart hashicorp/tap/packer jq zstd
./omarchy/build.sh omarchy
tart clone omarchy omarchy-desktop
tart run omarchy-desktop
```

Press Return at the Omarchy welcome screen and follow the prompts to set up
your account on the clone.

The Linux Images workflow publishes `ghcr.io/cirruslabs/omarchy:latest` and a tag
matching the Try Omarchy release used for the build. Select `omarchy:latest` to
rebuild Omarchy on its own.
