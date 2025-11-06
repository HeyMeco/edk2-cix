# Build instructions
## Using Docker with Ubuntu 24.04 baseimage
```
docker run -it --rm -v $(pwd):/work -w /work ubuntu:24.04 bash
```

## Inside container:
```
apt update && apt-get build-dep .
make deb
```

# edk2-cix

[![Release](https://github.com/radxa-pkg/edk2-cix/actions/workflows/release.yaml/badge.svg)](https://github.com/radxa-pkg/edk2-cix/actions/workflows/release.yaml)

## Build

For the time being the build system must run on a x86_64 host due to use of CIX specific tools available in binary form, only.

1. `git clone --recurse-submodules https://github.com/radxa-pkg/edk2-cix.git`
2. Open in [`devcontainer`](https://code.visualstudio.com/docs/devcontainers/containers)
3. `make deb`
