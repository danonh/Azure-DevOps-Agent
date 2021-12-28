# Docker image with Packer, PowerShell, PowerCLI and self-hosted Azure DevOps agent
Dockerfile that creates Docker image with Ubuntu, Packer, PowerShell, PowerCLI and self-hosted Azure DevOps agent
Usage:
```sh 
docker build -t packer:local .
```

By default  `start.sh` includes `--once` flag which means that container will exit after each triggered task in Azure DevOps. If you want to have persistent Azure DevOps agent that runs on Docker, remove `--once` flag from `start.sh` file. 