#!/bin/bash

declare -A map=(
    ["liblingmo"]="lib_lingmo"
)

get_latest_release_info() {
    local repo_name=$1
    # Note: Set GITHUB_TOKEN before running the script or you will get pkgver=null
    local latest_info=$(curl -sL -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/repos/LingmoOS/$repo_name/releases/latest")

    local version=$(echo "$latest_info" | jq -r '.tag_name')
    local tarball_url=$(echo "$latest_info" | jq -r '.tarball_url')

    local tempfile=$(mktemp)
    wget -q -O "$tempfile" "$tarball_url"
    local sha256sum=$(sha256sum "$tempfile" | awk '{ print $1 }')
    rm "$tempfile"

    echo "$version $sha256sum"
}

for pkgbuild in */PKGBUILD; do
    pkgname=$(basename "$(dirname "$pkgbuild")")
    repo=${map[$pkgname]:-$pkgname}
    read -r version sha256sum < <(get_latest_release_info "$repo")
    local_version=$(grep -oP '^pkgver=\K.*' "$pkgbuild")
    if [[ "$local_version" == "$version" ]]; then
        echo "SKIP $pkgname"
        continue
    fi
    sed -i "s/^pkgver=.*/pkgver=$version/" "$pkgbuild"
    sed -i "s/^sha256sums=(.*)/sha256sums=('$sha256sum')/" "$pkgbuild"
    sed -i "s/^pkgrel=.*/pkgrel=1/" "$pkgbuild"
    cd "$pkgname"
    makepkg --printsrcinfo > .SRCINFO
    cd ..
    echo "$pkgname"
done
