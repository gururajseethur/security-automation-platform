#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
if [ ! -d .git ]; then
  git init
  git branch -M main
  git remote add origin https://github.com/gururajseethur/security-automation-platform.git
  git fetch origin main
  git reset --soft origin/main
fi
git add -A
git -c user.name="Gururaj Seethuru" -c user.email="gururajseethureducation@gmail.com" \
    commit -m "Add platform source: API, workflows, deployment and CI"
git push origin main
echo "Done: https://github.com/gururajseethur/security-automation-platform"
