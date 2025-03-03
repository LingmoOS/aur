#!/bin/bash

tempdir=$(mktemp -d)

for pkgbuild in */PKGBUILD; do
    pkgname=$(basename "$(dirname "$pkgbuild")")
    version=$(grep -oP '^pkgver=\K.*' "$pkgbuild")
    git clone -c init.defaultBranch=master "ssh://aur@aur.archlinux.org/${pkgname}.git" "${tempdir}/${pkgname}"
    (cd "${tempdir}/${pkgname}" && git checkout master)
    (cd $pkgname && cp PKGBUILD .SRCINFO "${tempdir}/${pkgname}")
    (cd "${tempdir}/${pkgname}" && git commit -am "Update version to ${version}" && git push)
    echo $pkgname
done

rm -rf "${tempdir}"
