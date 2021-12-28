# Docker image with Packer, PowerShell, PowerCLI and self-hosted Azure DevOps agent
Dockerfile that creates Docker image with Ubuntu, Packer, PowerShell, PowerCLI and self-hosted Azure DevOps agent
Usage:
```sh 
docker build -t packercontainer:local .
```
If you want to pass specific Packer, PowerShell or Packer_Windows_Update version you can modify those directly in the Dockefile.

Alternatively you can pass specific product versions directly into build command:
```sh
docker build -t packercontainer:local --build-arg PS_VERSION="7.1.4" --build-arg PACKER_VERSION="1.7.7" .
```

By default  `start.sh` includes `--once` flag which means that container will exit after each triggered task in Azure DevOps. If you want to have persistent Azure DevOps agent that runs on Docker, remove `--once` flag from `start.sh` file. 