#!/usr/bin/env bash

set -ex

if [ ! -d /out ]; then
    echo "The /out directory has not been mapped"
    exit 1
fi

if [ "${1:---help}" == "--help" ]; then
    shift
    cat <<'EOF'
usage: offline-package.sh [TAG]

TAG is the upstream github tag you wish to build against (usually the latest release)
EOF
    exit
fi

git clone https://github.com/cloudfoundry-incubator/stratos.git stratos-ui || true

if ! which npm > /dev/null; then
    echo "npm and node missing - please install before running"
else
    npm_location=$(which npm)
    export NODE_HOME=${npm_location%%/bin/npm}
fi

mkdir -p cache
CWD="$(pwd)"
BUILD_DIR="$CWD/stratos-ui"

# prebuild ui
cd stratos-ui

if [ -n $1 ]; then
echo "Checking out stratos-ui at tag $1"
git checkout $1
fi

# Building the 4.0.0 version of Stratos produces the below error:
# An unhandled exception occurred: Cannot find module '/stratos-ui/./dist-devkit/build/index.transform.js'
# The 4 commands below produce the missing module required for running `npm run prebuild-ui` to completion.
npm install -g typescript
cd src/frontend/packages/devkit/
npm run build || true
cd $BUILD_DIR

npm install
npm run prebuild-ui
rm -Rf ./dist

# Actually build Stratos
bash -x deploy/cloud-foundry/build.sh "$BUILD_DIR" "$CWD/cache"
cd "$CWD"
# Remove the node_modules and bower_components folders - only needed for build
if [ -d "$BUILD_DIR/node_modules" ]; then
  rm -rf $BUILD_DIR/node_modules
fi

if [ -d "$BUILD_DIR/bower_components" ]; then
  rm -rf $BUILD_DIR/bower_components
fi

echo "web: ./deploy/cloud-foundry/start.sh" > $BUILD_DIR/Procfile

ls -lah "$BUILD_DIR"
cd $BUILD_DIR
zip -r "$CWD/stratos-ui-packaged.zip" ./*
cd "$CWD"

mv stratos-ui-packaged.zip /out/