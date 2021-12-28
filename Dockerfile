# Indicates the base image.
FROM ubuntu:18.04

# Define Args for the needed to add the package
ARG PACKER_VERSION="1.7.8"
ARG PACKER_WINDOWSUPDATE_VERSION="0.14.0"
ARG PS_VERSION=7.1.3
ARG PS_PACKAGE=powershell_${PS_VERSION}-1.ubuntu.18.04_amd64.deb
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}
ARG TARGETARCH=amd64
ARG AGENT_VERSION="2.195.2"

# Define ENVs for Localization/Globalization
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    # set a fixed location for the Module analysis cache
    PSModuleAnalysisCachePath=/var/cache/microsoft/powershell/PSModuleAnalysisCache/ModuleAnalysisCache \
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-Ubuntu-18.04
ENV PACKER_VERSION=${PACKER_VERSION}
ENV PACKER_WINDOWSUPDATE_VERSION=${PACKER_WINDOWSUPDATE_VERSION}
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

# Install dependencies and clean up
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    # curl is required to grab the Linux package
        curl \
    # less is required for help in powershell
        less \
    # requied to setup the locale
        locales \
    # required for SSL
        ca-certificates \
        gss-ntlmssp \
    # PowerShell remoting over SSH dependencies
        openssh-client \
    # Install python
    python3 \
    python3-pip\
    python3-boto\
    # Install unzip
    unzip \
    # Install DevOps Agent packages
    jq \
    git \
    iputils-ping \
    libcurl4 \
    libicu60 \
    libunwind8 \
    netcat \
    libssl1.0 \
    # Download the Linux package and save it
    && echo ${PS_PACKAGE_URL} \
    && curl -sSL ${PS_PACKAGE_URL} -o /tmp/powershell.deb \
    && curl -LO https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip \
    && curl -LO https://github.com/rgl/packer-plugin-windows-update/releases/download/v${PACKER_WINDOWSUPDATE_VERSION}/packer-plugin-windows-update_v${PACKER_WINDOWSUPDATE_VERSION}_x5.0_linux_amd64.zip \
    && unzip '*.zip' -d /usr/bin \
    && chmod +x /usr/bin/packer-plugin-windows-update_v${PACKER_WINDOWSUPDATE_VERSION}_x5.0_linux_amd64 \
    && rm *.zip \
    && mv /usr/bin/packer-plugin-windows-update_v${PACKER_WINDOWSUPDATE_VERSION}_x5.0_linux_amd64 /usr/bin/packer-plugin-windows-update \
    && curl -LsS https://aka.ms/InstallAzureCLIDeb | bash \
    && apt-get install --no-install-recommends -y /tmp/powershell.deb \
    && apt-get dist-upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen $LANG && update-locale \
    # remove powershell package
    && rm /tmp/powershell.deb \
    # intialize powershell module cache
    # and disable telemetry
    && export POWERSHELL_TELEMETRY_OPTOUT=1 \
    && pwsh \
        -NoLogo \
        -NoProfile \
        -Command " \
          \$ErrorActionPreference = 'Stop' ; \
          \$ProgressPreference = 'SilentlyContinue' ; \
          while(!(Test-Path -Path \$env:PSModuleAnalysisCachePath)) {  \
            Write-Host "'Waiting for $env:PSModuleAnalysisCachePath'" ; \
            Start-Sleep -Seconds 6 ; \
          }"

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /azp
RUN if [ "$TARGETARCH" = "amd64" ]; then \
      AZP_AGENTPACKAGE_URL=https://vstsagentpackage.azureedge.net/agent/${AGENT_VERSION}/vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz; \
    else \
      AZP_AGENTPACKAGE_URL=https://vstsagentpackage.azureedge.net/agent/${AGENT_VERSION}/vsts-agent-linux-${TARGETARCH}-${AGENT_VERSION}.tar.gz; \
    fi; \
    curl -LsS "$AZP_AGENTPACKAGE_URL" | tar -xz

COPY ./start.sh .
RUN chmod +x start.sh


# Install the VMware.PowerCLI Module
SHELL [ "pwsh", "-command" ]
RUN Install-Module VMware.PowerCLI, PowerNSX -Force -Confirm:0;
RUN Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -confirm:$false

## Install DevOps Agnet
#CMD [ "pwsh" ]
#CMD    ["/bin/bash"]
ENTRYPOINT [ "./start.sh" ]
