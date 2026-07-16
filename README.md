## Linux Packer Templates for Tart

Repository with Packer templates to build [Tart VMs](https://github.com/cirruslabs/tart) to use with self-hosted GitHub Actions runners and [Cirrus Runners](https://tart.run/integrations/github-actions/).

See a full list of VMs available [here](https://github.com/orgs/cirruslabs/packages?repo_name=linux-image-templates).

[The image workflow](.github/workflows/images.yml) rebuilds and publishes the images every Saturday. To rebuild and publish a single image, open **Actions → Linux Images → Run workflow** and select the image; select `all` to rebuild every image.
