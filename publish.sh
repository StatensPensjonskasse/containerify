#!/bin/bash
set -e

npm install

if [[ `git status --porcelain` ]]; then
  echo "ERROR: Changes found in git"
  exit 1
fi

npm run lint
npm run build
npm run integrationTest
npm run registryTest

VERSION=$(cat package.json  | jq -r .version)
COMMIT_ID=$(git rev-parse HEAD)
echo "Point $VERSION to $COMMIT_ID and publish (Y/N)?"

if [ $(git tag -l $VERSION) ]; then
    echo "";
    echo "ERROR: A tag already exists for $VERSION"
    echo "Aborting...";
    exit 1;
fi


read -r -p "Are you sure? [y/N] " response
if [[ "$response" =~ ^([yY])$ ]]
then
    echo "Tagging..."
    git tag $VERSION $COMMIT_ID -m "Release of version $VERSION"
    git push --tags
    echo "Done!"
    TMP_CL_FILE=changelog-tmp.md
    awk '/^## / {p=1; ++count} count == 2 {exit} p' CHANGELOG.md > $TMP_CL_FILE
    gh release create "$VERSION" -F $TMP_CL_FILE
    rm $TMP_CL_FILE
else
    echo "Aborting"
fi
