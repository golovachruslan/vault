#!/usr/bin/env bash
# Lazy dependency installation for future phases
# Context injection will be added in Phase 3

diff -q "${CLAUDE_PLUGIN_ROOT}/package.json" "${CLAUDE_PLUGIN_DATA}/package.json" >/dev/null 2>&1 || \
  (cd "${CLAUDE_PLUGIN_DATA}" && cp "${CLAUDE_PLUGIN_ROOT}/package.json" . && npm install --silent) || \
  rm -f "${CLAUDE_PLUGIN_DATA}/package.json"
