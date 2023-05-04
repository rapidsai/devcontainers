#! /usr/bin/env bash

# cd to the repo root
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../../";

os="${1:-}";
features="${2:-}";

VERSION="$(git describe --abbrev=0 --tags | sed 's/[a-zA-Z]//g' | cut -d '.' -f -2)";
tag="$(node -p "$(cat <<EOF
['cpp', ...${features}.filter((x) => !x.hide).map(({ name = '', version = '' }) => {
    if (name.includes(':')) {
        name = name.split('/').pop().split(':')[0];
    }
    return name + (version || '');
})].join('-')
EOF
)")";
tag="${VERSION:-latest}-${tag}-$(echo "${os}" | tr -d :)";

echo "tag=${tag}" >&3;

node -e "$(cat <<EOF

const json = JSON.parse(require('fs').readFileSync('image/.devcontainer/devcontainer.json'));

json.build.args.BASE = '${os}';

${features}.forEach(({name, ...feature}) => {
  const i = json.overrideFeatureInstallOrder.length - 1;
  if (name.includes(':')) {
    json.features[name] = feature;
    json.overrideFeatureInstallOrder.splice(i, 0, name.split(':')[0]);
  } else {
    name = './features/' + name;
    json.features[name] = feature;
    json.overrideFeatureInstallOrder.splice(i, 0, name);
  }
});

console.log(JSON.stringify(json));
EOF
)" >&4;
