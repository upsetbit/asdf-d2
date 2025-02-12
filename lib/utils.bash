#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/terrastruct/d2"
TOOL_NAME="d2"
TOOL_TEST="d2 --version"

fail() {
  echo -e "asdf-$TOOL_NAME: $*"
  exit 1
}

curl_opts=(-fsSL)

# NOTE: You might want to remove this if d2 is not hosted on GitHub releases.
if [ -n "${GITHUB_API_TOKEN:-}" ]; then
  curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
    LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
  git ls-remote --tags --refs "$GH_REPO" |
    grep -o 'refs/tags/.*' | cut -d/ -f3- |
    sed 's/^v//' # NOTE: You might want to adapt this sed to remove non-version strings from tags
}

list_all_versions() {
  list_github_tags
}

download_release() {
  local version filename url
  version="$1"
  filename="$2"

  url="$GH_REPO/releases/download/v${version}/${TOOL_NAME}-v${version}-$(get_platform)-$(get_arch).tar.gz"

  echo "* Downloading $TOOL_NAME release $version..."
  curl "${curl_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}

install_version() {
  local install_type="$1"
  local version="$2"
  local install_path="$3"
  local tool_cmd
  tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"

  if [ "$install_type" != "version" ]; then
    fail "asdf-${TOOL_NAME} supports release installs only"
  fi

  # Check if a directory matching ${tool_cmd}-${version}-* exists in the extracted archive in $ASDF_DOWNLOAD_PATH.
  for dir in "${ASDF_DOWNLOAD_PATH}/${tool_cmd}-v${version}"; do
    if [ -d "$dir" ]; then
      ASDF_DOWNLOAD_PATH="$dir"
      break
    fi
  done

  (
    mkdir -p "${install_path}/bin"
    cp "${ASDF_DOWNLOAD_PATH}/bin/${tool_cmd}" "${install_path}/bin"

    test -x "${install_path}/bin/${tool_cmd}" || fail "Expected ${install_path}/bin/${tool_cmd} to be executable."

    echo "${TOOL_NAME} ${version} installation was successful!"
  ) || (
    rm -rf "$install_path"
    fail "An error ocurred while installing ${TOOL_NAME} ${version}."
  )
}

get_platform() {
  local platform
  platform=$(uname -s | tr '[:upper:]' '[:lower:]')
  case $platform in
  "darwin")
    echo "macos"
    ;;
  *)
    echo "$platform"
    ;;
  esac
}

get_arch() {
  local arch
  arch=$(uname -m)
  case $arch in
  "x86_64")
    echo "amd64"
    ;;
  "arm")
    echo "armv7" # Super best effort - TODO: find useful way to split armv6/armv7 maybe
    ;;
  "aarch64" | "arm64")
    echo "arm64"
    ;;
  "i686")
    echo "i386"
    ;;
  *)
    echo "$arch"
    ;;
  esac
}
