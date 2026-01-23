#! /bin/bash

# Perform benchmarking of how 'runtimepath' length affects performance.
# In particular:
# - Set up:
#   - Generate plugin source in './host' subdirectory.
#   - Generate clean dedicated Neovim 'nvim-bench-runtimepath' config.
#   - Run once to install plugins.
# - Benchmark:
#   - Run `NVIM_APPNAME=nvim-bench-runtimepath nvim --startuptime 'xxx'` many
#     times to generate many startup logs.
#   - Run a script to compute how long it takes to set a filetype, as this is
#     a common operation involving 'runtimepath' (as it has to go through all
#     'runtimepath' entries to find and source all 'ftplugin' scripts).
# - Summarize.

# WARNING: EXECUTION OF THIS SCRIPT LEADS TO FLICKERING OF SCREEN WHICH WHICH
# MAY CAUSE HARM TO YOUR HEALTH. This is because there are many actual openings
# of Neovim with later automatic closing.

# Number of rounds to perform benchmark
N_ROUNDS=1

# Perform all operations in a separate config
export NVIM_APPNAME=nvim-bench-runtimepath

function benchmark {
  local config_type=$1
  local n_plugins=$2

  echo "Config type:       $config_type"
  echo "Number of plugins: $n_plugins"
  echo ""

  # Set up clean config:
  # - Create plugin sources from which they will be installed. They will be
  #   created inside "./host/" of current working directory.
  # - Remove standard config directories.
  # - Create config file(s) that `vim.pack.add` plugin(s)
  echo "Set up plugins and config"
  export CONFIG_TYPE=$config_type
  export N_PLUGINS=$n_plugins
  nvim_new --clean -l 01_setup.lua
  unset CONFIG_TYPE
  unset N_PLUGINS

  # Install plugins
  echo "First run to install plugins"
  nvim_new --cmd "lua vim.defer_fn(function() vim.cmd('quit') end, $n_plugins * 150)"
  sleep 1

  # Benchmark startup
  # TODO: Try without `--startuptime` since `require()` seems to use different
  # code specifically in that case. Which might inference the result.
  mkdir -p ./startups
  echo "Benchmark startup $N_ROUNDS rounds"
  for i in $(seq 1 $N_ROUNDS); do
    echo "Round $i"
    nvim_new --startuptime "./startups/$config_type-$n_plugins-$i" --cmd 'lua vim.defer_fn(function() vim.cmd("quit") end, 500)'
    sleep 0.5
  done

  # # Benchmark setting filetype
  # echo "Benchmark setting filetype"
  # nvim_new -S '02_bench-filetype.lua'

  echo "---"
  echo ""
}

nvim --version
echo ""

rm -rf ./startups
benchmark single 10
benchmark many-gr 10
benchmark many-sep 10

rm -rf ./host

# Produce output summary
# nvim_new --clean -u 03_make_summary.lua
