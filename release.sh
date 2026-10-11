#!/usr/bin/env bash
# Builds signed source packages and uploads them to the PPA (Launchpad builds the .deb).
#   ./release.sh            upload the version in debian/changelog
#   ./release.sh --dry-run  build and sign, but don't upload
# Needs: sudo apt install devscripts debhelper dput, and your GPG key registered in Launchpad.
# To release a new version first run:  dch -v 1.1.0 -D resolute "What changed"
# and update VERSION in the buscador script.
set -euo pipefail
PPA="ppa:acostadev08/hopla"
SERIES=(resolute noble)          # Ubuntu 26.04 and 24.04 (older ones have GTK < 4.12)
DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="$(mktemp -d)"
DRY=${1:-}

cd "$DIR"
for cmd in debuild dput gpg; do
    command -v $cmd >/dev/null || { echo "Missing $cmd: sudo apt install devscripts debhelper dput"; exit 1; }
done
version=$(dpkg-parsechangelog -S Version)
script_version=$(sed -n 's/^VERSION = "\(.*\)"/\1/p' buscador)
[ "$version" = "$script_version" ] || { echo "debian/changelog is $version but VERSION in buscador is $script_version"; exit 1; }

for series in "${SERIES[@]}"; do
    # One upload per Ubuntu series: same code, version suffix ~<series>1 and that series as target.
    work="$OUT/hopla-$version~$series"
    mkdir -p "$work"
    tar --exclude=.git --exclude=__pycache__ -cf - . | tar -xf - -C "$work"
    (cd "$work" &&
        sed -i "1s/^hopla ([^)]*) [a-z]*;/hopla ($version~${series}1) $series;/" debian/changelog &&
        debuild -S -sa -d)
    if [ "$DRY" = "--dry-run" ]; then
        echo "Built $OUT/hopla_${version}~${series}1_source.changes (not uploaded)"
    else
        dput "$PPA" "$OUT/hopla_${version}~${series}1_source.changes"
    fi
done
echo "Done. Follow the builds at https://launchpad.net/~acostadev08/+archive/ubuntu/hopla/+packages"
