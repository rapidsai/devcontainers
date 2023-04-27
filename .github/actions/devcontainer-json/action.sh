#! /usr/bin/env bash

# cd to the repo root
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../../";

os="${1:-}";
features="${2:-}";
repo_owner="${3:-}";

VERSION="$(git describe --abbrev=0 --tags | sed 's/[a-zA-Z]//g' | cut -d '.' -f -2)";
VER="$(echo "${VERSION}" | sed -E 's/0([0-9]+)/\1/g' | cut -d '.' --complement -f3)";
sdk="cpp-$(node -p "${features}.map((x) => x.name + x.version).join('-')")";
tag="${VERSION:-latest}-${sdk}-$(echo "${os}" | tr -d :)";

echo "tag=${tag}";

node -e "$(cat <<EOF

var json = JSON.parse(require("fs").readFileSync("image/.devcontainer/devcontainer.json"));

json.build.args.BASE = "${os}";

${features}.forEach(({name, ...feature}) => {
  var i = json.overrideFeatureInstallOrder.length - 1;
  var f = "./features/" + name;
  json.features[f] = feature;
  json.overrideFeatureInstallOrder.splice(i, 0, f);
});

require("fs").writeFileSync("image/.devcontainer/devcontainer.json", JSON.stringify(json));
EOF
)"

echo "image: ghcr.io/${repo_owner}/devcontainers:${tag}" >&2;
echo "image/.devcontainer/devcontainer.json:" >&2;
cat "image/.devcontainer/devcontainer.json" >&2;
