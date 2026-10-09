#!/usr/bin/env bash
# Build & package the OwnTone HA add-on.
#
# Usage:
#   ./build.sh                 # docker build only
#   ./build.sh --all           # docker build + tar.gz
#   ./build.sh --all --push    # docker build + tar.gz + docker push (needs DOCKER_REGISTRY)
#
# Environment:
#   ADDON_VERSION=1.0.0       # version tag
#   DOCKER_REGISTRY=ghcr.io/user
#   ADDON_SLUG=owntone

set -euo pipefail

SLUG="${ADDON_SLUG:-owntone}"
VERSION="${ADDON_VERSION:-$(python3 - <<'PY'
import re
with open('config.yaml') as f:
    print(re.search(r'^version:\s*"?([^"\s]+)"?', f.read(), re.M).group(1))
PY
)}"
REGISTRY="${DOCKER_REGISTRY:-}"

echo "[build] slug=${SLUG} version=${VERSION}"

docker build \
  --build-arg ADDON_VERSION="${VERSION}" \
  --build-arg ADDON_SLUG="${SLUG}" \
  -t "${SLUG}:local" \
  -t "${SLUG}:${VERSION}" \
  .

if [[ "${1:-}" == "--all" || "${1:-}" == "--push" ]]; then
  echo "[build] packaging tar.gz"
  OUT="build/${SLUG}-${VERSION}.tar.gz"
  mkdir -p build
  docker save "${SLUG}:${VERSION}" | tar czf "${OUT}" -f -
  echo "[build] packaged ${OUT} ($(du -h "${OUT}" | awk '{print $1}'))"

  if [[ -n "${REGISTRY}" ]]; then
    docker tag "${SLUG}:${VERSION}" "${REGISTRY}/${SLUG}:${VERSION}"
    docker push "${REGISTRY}/${SLUG}:${VERSION}"
  fi
fi
