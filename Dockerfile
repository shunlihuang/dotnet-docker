ARG REPO=mcr.microsoft.com/dotnet/aspnet
FROM $REPO:3.1-alpine3.13

ENV \
    # Unset ASPNETCORE_URLS from aspnet base image
    ASPNETCORE_URLS= \
    # Disable the invariant mode (set in base image)
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip \
    # PowerShell telemetry for docker image usage
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-DotnetCoreSDK-Alpine-3.13

# Add dependencies for disabling invariant mode (set in base image)
RUN apk add --no-cache icu-libs

# Install .NET Core SDK
RUN dotnet_sdk_version=3.1.411 \
    && wget -O dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Sdk/$dotnet_sdk_version/dotnet-sdk-$dotnet_sdk_version-linux-musl-x64.tar.gz \
    && dotnet_sha512='58bf68237e604cb4b5f64b71c140f5498ee4c2471689fc7630fdcf09c5694fe75d75961418fc4ac6cebac6544972aee98dc9c3cfab3876182c4a5eba694e90dc' \
    && echo "$dotnet_sha512  dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -C /usr/share/dotnet -oxzf dotnet.tar.gz ./packs ./sdk ./templates ./LICENSE.txt ./ThirdPartyNotices.txt \
    && rm dotnet.tar.gz \
    # Trigger first run experience by running arbitrary cmd
    && dotnet help

USER root
RUN echo '10.32.48.64 meqasebgbg.whq.wistron' >> /etc/hosts

# Install PowerShell global tool
RUN powershell_version=7.0.6 \
    && wget -O PowerShell.Linux.Alpine.$powershell_version.nupkg https://pwshtool.blob.core.windows.net/tool/$powershell_version/PowerShell.Linux.Alpine.$powershell_version.nupkg \
    && powershell_sha512='82e8aab9214ec98200b9abfd0c3efd1b693947f18636dd0c37e30db1476aad8a959e58268aafb26d980fef76c0fac9dc58488278d9c09b179e5b922d290f83a8' \
    && echo "$powershell_sha512  PowerShell.Linux.Alpine.$powershell_version.nupkg" | sha512sum -c - \
    && mkdir -p /usr/share/powershell \
    && dotnet tool install --add-source / --tool-path /usr/share/powershell --version $powershell_version PowerShell.Linux.Alpine \
    && dotnet nuget locals all --clear \
    && rm PowerShell.Linux.Alpine.$powershell_version.nupkg \
    && chmod 755 /usr/share/powershell/pwsh \
    && ln -s /usr/share/powershell/pwsh /usr/bin/pwsh \
    # To reduce image size, remove the copy nupkg that nuget keeps.
    && find /usr/share/powershell -print | grep -i '.*[.]nupkg$' | xargs rm \
    # Add ncurses-terminfo-base to resolve psreadline dependency
    && apk add --no-cache ncurses-terminfo-base
