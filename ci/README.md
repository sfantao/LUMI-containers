# LUMI containers CI infratructure.

This folder contains helpers to complement the CI workflow. Namely an Openstack container to control the build VM. This container is built during the workflow itself.

There is also a placeholder folder for developers to manage secrets that are not part of the repository.

## CI workings

The CI is prepared to run on a VM managed through OpenStack. It assumes a compatible VM image exists that implements the github-runners as well as proper management of the Docker cache. The CI is defined in `.github/workflows/containers-build.yml` (workflow definition file). Only one workflow can run at a given time. A single workflow relies on several runners:
* 2 `cpouta` runners: they build the Docker images locally on the cpouta instance - one of them is the `main` one and is tasked to prepare the VM and clean up dangling LUMI jobs. Two parallel builds are supported at the moment. The `main` runner also validates the tests results at the end.
* 1 `cpouta-transfer`: tasked to transfer the Docker image and tests files for each image to LUMI.
* 4 `cpouta-test`: tasked to issue the build of the singularity images and submit the testing jobs. Maximum 4 simulatenous singularity builds are supported. These builds use compute nodes as login nodes compute limitations perclude that.

### The VM image 
The VM image is based on Ubuntu and is named `production_containers_workflow`. The current ID of the image is in `OS_MY_IMAGE` in the workflow definition file. The flavor used is defined under `OS_MY_FLAVOUR` and is currently set to `hpc.5.64core`. The docker build requires significant  ammounts of memory.

It uses Docker CE instalation for the builds. It was installed as indicated in `https://docs.docker.com/engine/install/ubuntu/#install-from-a-package`. An unprivileged user, `work`, runs the github runners and is part of the `docker` group. There are `systemd` services for each runner configured to use the user `work`.

The image mounts a persistent storage volume. The main goal of this volume is to persist `/var/lib/docker`. When the VM is started, there is a `prepare-vm` command that `work` can run as `sudo` that makes sure the mounts exist and `/var/lib/docker` symlink to persistent storage is valid, restarting the Docker daemon after the mount is known to be valid.

The VM is configured to be accessed by SSH from selected IPs. This is mostly a admin option, useful to debug or recreate some processes manually on the VM. This is not a requirement for the CI to work.

### The CI workflow in a nutshell

These are the steps the CI executes with some explanation:

* Build OpenStack Docker image (run on Github own runners): this image is meant to be used in comming steps to interact with the VM, it is pushed to the project `gcr.io` so that it can be used at later stages of this workflow.
* Start and configure CPouta VM (run on Github own runners inside the Openstack container): creates the VM based on a preconfigured image, creates the mounts on the VM and restarts Docker to reload the cache. The runners in the VM are configured as a service so they should get active automatically when the VM is on. There are several security policies set on VM as well.
* Build Docker images (run on Cpouta VM): run up to 2 parallel builds of the images.
* Push images and tests to LUMI (run on Cpouta with remote commands to LUMI): this will make the docker images available on the LUMI registry and create the scripts to build the singularity images and issue the tests.
* Run singularity builds and tests (run on Cpouta with remote commands to LUMI): builds up to 4 simulatenous singularity images and launches the tests as separate jobs. If the job succeeds the image is copied to a designated folder for tested image, otherwise the image is transferred to a designated folder for failed images. When the tests are issued by comming workflows, these designated folder are checked and the build is skipped if an image already exists.
* Validate results (run on Cpouta with remote commands to LUMI): wait for tests to complete and assert that they completed successfully or not.
* Remove the VM (run on Github own runners inside the Openstack container): this removes the VM.

All secrets and access details are obtained from the Github Actions configurations meant to manage that.