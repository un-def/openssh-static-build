# OpenSSH Static Build Recipe

## Prerequisites

* [Docker](https://docs.docker.com/engine/install/)
* [just](https://github.com/casey/just)

## Recipes

* build: `just build`
* run sshd as a non-root user: `just run-sshd [PORT]`
* pack a minimal sshd installation: `just pack-sshd`
