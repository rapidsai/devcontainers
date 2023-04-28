#! /usr/bin/env bash

# cd to the repo root
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../../";

os="${1:-}";
features="${2:-}";

VERSION="$(git describe --abbrev=0 --tags | sed 's/[a-zA-Z]//g' | cut -d '.' -f -2)";
tag="cpp-$(node -p "${features}.map((x) => x.name + (x.version || '')).join('-')")";
tag="${VERSION:-latest}-${tag}-$(echo "${os}" | tr -d :)";

echo "tag=${tag}" >&3;

node -e "$(cat <<EOF

var json = JSON.parse(require("fs").readFileSync("image/.devcontainer/devcontainer.json"));

json.build.args.BASE = "${os}";

${features}.forEach(({name, ...feature}) => {
  var i = json.overrideFeatureInstallOrder.length - 1;
  var f = "./features/" + name;
  json.features[f] = feature;
  json.overrideFeatureInstallOrder.splice(i, 0, f);
});

console.log(JSON.stringify(json));
EOF
)" >&4;
