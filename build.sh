#!/usr/bin/env bash

set -u

curl "https://api.github.com/repos/risdenk/risdenk.github.io/pages/builds" \
  -X POST \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github.mister-fantastic-preview"

sleep 10

curl "https://api.github.com/repos/risdenk/risdenk.github.io/pages/builds/latest" \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github.mister-fantastic-preview"

