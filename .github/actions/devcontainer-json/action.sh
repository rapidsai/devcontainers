#! /usr/bin/env bash

# cd to the repo root
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../../";

os="${1:-"ubuntu:22.04"}";
features="${2:-"[]"}";
container_env="${3:-"null"}";
syft_ver="${4:-"latest"}";

VERSION="$(git describe --abbrev=0 --tags | sed 's/[a-zA-Z]//g' | cut -d '.' -f -2)";
tag="$(node -p "$(cat <<EOF
['cpp', ...${features}.filter((x) => !x.hide).map(({ name = '', version = '', suffix = '' }) => {
    if (name.includes(':')) {
        name = name.split('/').pop().split(':')[0];
    }
    return name + (version || '') + (suffix || '');
})].join('-')
EOF
)")";
tag="${VERSION:-latest}-${tag}-$(echo "${os}" | tr -d :)";

echo "tag=${tag}" >&3;

node -e "$(cat <<EOF

const {cpSync, readFileSync} = require('fs');
const json = JSON.parse(readFileSync('image/.devcontainer/devcontainer.json'));

json.build.args.BASE = '${os}';
json.build.args.RAPIDS_VERSION = '${VERSION}';
json.build.args.SYFT_VER = '${syft_ver}';
json.containerEnv = Object.assign(json.containerEnv || {}, ${container_env} || {});

const dups = {};

${features}.forEach(({name, ...feature}) => {
  const i = json.overrideFeatureInstallOrder.length - 1;
  if (name.includes(':')) {
    json.features[name] = feature;
    json.overrideFeatureInstallOrder.splice(i, 0, name.split(':')[0]);
  } else {
    name = './features/src/' + name;
    if (name in dups) {
        cpSync(
            name,
            name = name + "." + (++dups[name]),
            {recursive: true}
        );
    } else {
        dups[name] = 0;
    }
    json.features[name] = feature;
    json.overrideFeatureInstallOrder.splice(i, 0, name);
  }
});

console.log(JSON.stringify(json));
EOF
)" >&4;
