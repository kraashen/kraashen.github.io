---
title: "Checking Updates and Updating AUR Packages by Scripting"
date: 2021-04-08
draft: false
tags:
    - linux
    - arch
---

[AUR packages](https://wiki.archlinux.org/index.php/Arch_User_Repository)
by default are managed as Git repositories that contain `PKGBUILD` package
descriptions. These description files allow users to compile packages
from sources with `makepkg`, and then installing them using `pacman`.

To help managing these packages as your collection inevitably grows,
various wrapper tools exist, such as an excellent Go-based tool named `yay`.

Arch wiki states, that it is recommended to use and understand the manual
flow first before diving into AUR tooling. So, what could be more fun than...
making own yet-another-aur-management-tool?

Process for installing and updating AUR packages is described in
[Arch Wiki](https://wiki.archlinux.org/index.php/Arch_User_Repository#Installing_and_upgrading_packages),
so with few lines of shell script (tm) we can automate both checking safely for updates
similarly as `checkupdates` tool from `pacman-contrib` package and updating
individual packages if they have updates available.

```
$ aur-checkupdates
spotify 1:1.1.55.498-2 -> 1:1.1.56.595-1
$ aur-update -ri spotify
```

This was a fun mini-project in the spirit of keeping things simple(ish)
by using the existing CLI tooling.

## Scripts

### .zshrc

```bash
# ...

# AUR management
export AUR_PACKAGES_PATH="$HOME/Packages"
```

### Checking for updates

```bash
#!/bin/bash
#
# Check if foreign packages installed have updates available in
# AUR.
#
# Return codes:
#   0 = Updates available
#   1 = Something went wrong
#   2 = No updates available
#
# Author: Tomi Juntunen <erani@iki.fi>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

if ! command -v jq > /dev/null;
then
    echo "jq is needed for this script to run" >&2
    exit 1
fi

AUR_API="https://aur.archlinux.org/rpc/?v=5&type=info"

Args=""
InstalledPackages=$(pacman --query --foreign)

# Go through installed foreign packages and construct
# HTTP query based on them
while read -r Package;
do
    PackageName=${Package%[[:space:]]*}
    Args="${Args}&arg[]=$PackageName"
done <<< "${InstalledPackages}"

Response=$(curl --silent "${AUR_API}""${Args}")
Results="$(jq --raw-output .results <<< "${Response}")"

Output=$""

while read -r Package;
do
    PackageName=${Package%[[:space:]]*}
    InstalledPackageVersion=${Package#*[[:space:]]}
    RemotePackage=""
    RemotePackageInfo=""

    while read -r Remote;
    do  
        RemotePackage=$(jq --raw-output .Name <<< "${Remote}")

        [[ "${RemotePackage}" != "${PackageName}" ]] && continue

        RemotePackageInfo="${Remote}"
        break
    done <<< "$(jq --compact-output '.[]' <<< "${Results}")"

    if [[ -z ${RemotePackageInfo} ]];
    then
        echo "No package info found for package ${PackageName}" >&2
        continue
    fi

    RemotePackageVersion=$(jq --raw-output .Version <<< "${RemotePackageInfo}")

    # Check if the remote package is of a newer version than installed one and store results
    # in the output string
    if [[ "${RemotePackageVersion}" != "${InstalledPackageVersion}" ]];
    then
        if [[ "${Output}" = "" ]];
        then
            Output=$"${Output}${PackageName} ${InstalledPackageVersion} -> ${RemotePackageVersion}"
            continue
        fi

        Output=$"${Output}\n${PackageName} ${InstalledPackageVersion} -> ${RemotePackageVersion}"
    fi
done <<< "${InstalledPackages}"

if [[ -z "${Output}" ]];
then
    exit 2
else
    echo -e "${Output}"
    exit 0
fi
```

### Installing Update

```bash
#!/bin/bash
#
# Update an AUR package to latest version (using Git and makepkg).
# Return codes:
#   0 = Updates available
#   1 = Something went wrong
#   2 = No updates available
#
# Author: Tomi Juntunen <erani@iki.fi>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

AUR_API="https://aur.archlinux.org/rpc/?v=5&type=info"

function print_usage {
    cat <<EOF
Update an AUR package

Usage:
    aur-update [options] [packagename]

Options:
  Options passed to Makepkg. See makepkg(8) for details.
    -r      Remove unneeded dependencies after install.
    -i      Install package.
    -c      Clean leftover files after install.
    -s      Install required dependencies.
EOF
}

function check_update {
    Response=$(curl --silent "${AUR_API}&arg[]=$1")
    RemoteVersion="$(jq --raw-output .results[0].Version <<< "${Response}")"

    echo "Installed version: $2, remote version: ${RemoteVersion}"

    if [[ "${RemoteVersion}" != $2 ]];
    then
        return 0
    fi
    return 2
}

if ! command -v jq > /dev/null;
then
    echo "jq is needed for this script to run" >&2
    exit 1
fi

if [[ -z "${AUR_PACKAGES_PATH}" ]];
then
    echo "AUR_PACKAGES_PATH not set" >&2
    exit 1
fi

if [[ ! -d "${AUR_PACKAGES_PATH}" ]];
then
    echo "AUR_PACKAGES_PATH does not exist" >&2
    exit 1
fi

MAKEPKG_OPTS=""

while getopts "risch" Opt; do
    case "${Opt}" in
        h)
            print_usage
            exit 0
            ;;
        r)
            MAKEPKG_OPTS="${MAKEPKG_OPTS}-r "
            ;;
        i)
            MAKEPKG_OPTS="${MAKEPKG_OPTS}-i "
            ;;
        s)
            MAKEPKG_OPTS="${MAKEPKG_OPTS}-s "
            ;;
        c)
            MAKEPKG_OPTS="${MAKEPKG_OPTS}-c "
            ;;
        *)
            print_usage
            exit 0
            ;;
    esac
done

shift "$((OPTIND-1))"

PackageName=$1
InstalledPackage=$(pacman --query --foreign | grep ${PackageName})
InstalledPackageVersion=$(cut -d ' ' -f 2 <<< ${InstalledPackage})

if [[ -z "${PackageName}" ]];
then
    echo "Missing package name"
    print_usage
    exit 1
elif [[ "${InstalledPackage}" = "" ]];
then
    echo "Package has not been installed"
    exit 1
fi

check_update ${PackageName} ${InstalledPackageVersion}

if [ "$?" = 2 ] ;
then
    echo "Package has no updates available"
    exit 2
fi

WorkDir="${AUR_PACKAGES_PATH}"/"${PackageName}"

_GIT_DEFAULT_BRANCH=$(cd "${WorkDir}"; git remote show origin | grep "HEAD branch" | cut -d: -f2 | tr -d ' ')

echo "Checking out to default branch in repository"

if ! (cd "${WorkDir}"; git checkout "${_GIT_DEFAULT_BRANCH}");
then
    echo "Checkout to default branch failed" >&2
    exit 1
fi

echo "Fetching remote changes"

if ! (cd "${WorkDir}"; git fetch);
then
    echo "Fetching remote changes" >&2
    exit 1
fi

echo "Reading remote diff"

if ! (cd "${WorkDir}"; git diff "${_GIT_DEFAULT_BRANCH}" origin/"${_GIT_DEFAULT_BRANCH}");
then
    echo "Diffing changes failed" >&2
    exit 1
fi

echo "Are these changes OK? [y|N]"
read -r Answer

Answer=${Answer:-n}

if [[ "${Answer}" = "n" ]];
then
    echo "Update cancelled" >&2
    exit 1
elif [[ "${Answer}" = "y" ]];
then
    echo "Pulling remote changes"
    (cd "${WorkDir}"; git pull)
    echo "Running makepkg and installing update"
    (cd "${WorkDir}"; makepkg "${MAKEPKG_OPTS}")
else
    echo "Update cancelled" >&2
    exit 1
fi

exit 0
```
