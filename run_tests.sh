#!/bin/bash
set -e

mkdir -p ".testenv/config/nvim"
mkdir -p ".testenv/data/nvim"
mkdir -p ".testenv/state/nvim"
mkdir -p ".testenv/run/nvim"
mkdir -p ".testenv/cache/nvim"
PLUGINS=".testenv/data/nvim/site/pack/plugins/start"

if [ ! -e "$PLUGINS/plenary.nvim" ]; then
  git clone --depth=1 https://github.com/nvim-lua/plenary.nvim.git "$PLUGINS/plenary.nvim"
fi

XDG_CONFIG_HOME=".testenv/config" \
  XDG_DATA_HOME=".testenv/data" \
  XDG_STATE_HOME=".testenv/state" \
  XDG_RUNTIME_DIR=".testenv/run" \
  XDG_CACHE_HOME=".testenv/cache" \
  nvim --headless -u test/minimal_init.lua \
  -c "PlenaryBustedDirectory ${1-test} { minimal_init = './test/minimal_init.lua' }"
echo "Success"
