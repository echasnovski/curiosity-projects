#! /bin/bash

# Perform benchmarking of number of installed plugins affects startup and
# runtime performance. Requires Neovim>=0.12. In particular:
# - Set up:
#   - Generate plugin source in './host' subdirectory.
#   - Generate clean dedicated Neovim 'nvim-bench-plugnumber' config.
#   - Run once to install plugins.
# - Benchmark:
#   - Run `NVIM_APPNAME=nvim-bench-plugnumber nvim --startuptime 'xxx'` many
#     times to generate many startup logs.
#   - Run a script to compute how long it takes to set a filetype, as this is
#     a common operation involving 'runtimepath' (as it has to go through all
#     'runtimepath' entries to find and source all 'ftplugin' scripts).
# - Summarize startup times by extracting times that are related to plugins:
#   - Duration of sourcing 'init.lua'.
#   - Duration of sourcing 'plugin/' files from installed plugins.
#
# Artifacts:
# - 'nvim_version' - data about Neovim version used for benchmarking.
# - 'startup-bench-summary.csv' - data about startup benchmarking.
# - 'filetype-bench-summary.csv' - data about setting filetype benchmarking.

# WARNING: EXECUTION OF THIS SCRIPT LEADS TO FLICKERING OF SCREEN WHICH WHICH
# MAY CAUSE HARM TO YOUR HEALTH. This is because there are many actual openings
# of Neovim with later automatic closing.

# Perform all operations in a separate config
export NVIM_APPNAME=nvim-bench-plugnumber

# Number of rounds to perform startup benchmark
export N_STARTUP_ROUNDS=10

# Number of rounds to perform filetype benchmark (odd number)
export N_FILETYPE_ROUNDS=1001

# Array of "plugin number" values to try
N_PLUGINS_ARRAY=(0 5 10 15 20 25 30 35 40 45 50)

# Main function for benchmarking one config_type+n_plugins pair
function benchmark {
  export CONFIG_TYPE=$1
  export N_PLUGINS=$2

  echo "==="
  echo "Config type:       $CONFIG_TYPE"
  echo "Number of plugins: $N_PLUGINS"
  echo ""

  # Set up clean config:
  # - Create plugin sources from which they will be installed. They will be
  #   created inside "./host/" of current working directory.
  # - Remove standard config directories.
  # - Create config file(s) that `vim.pack.add` plugin(s)
  echo "Set up plugins and config"
  nvim --clean -l 01_setup.lua

  # Install plugins
  echo "First run to install plugins"
  nvim --cmd "lua vim.defer_fn(function() vim.cmd('quit') end, $N_PLUGINS * 200)"
  # Sleep a lot to "cool down" from creating and installing plugins
  sleep $((N_PLUGINS / 10))

  # Benchmark startup
  mkdir -p ./startups
  echo "Benchmark startup $N_STARTUP_ROUNDS rounds"
  for i in $(seq 1 $N_STARTUP_ROUNDS); do
    echo "Round $i"
    nvim --startuptime "./startups/${CONFIG_TYPE}_${N_PLUGINS}_$i" --cmd 'lua vim.defer_fn(function() vim.cmd("quit") end, 500)'
    sleep 0.5
  done

  # Benchmark setting filetype
  echo "Benchmark setting filetype"
  # NOTE: Important to run as `-S` and not `-l` since it actually starts a UI
  # and is closer to actual runtime performance
  nvim -S '02_bench-filetype.lua'
  # Sleep a lot to "cool down" from extensive benchmark
  sleep $((N_FILETYPE_ROUNDS / 1000))

  echo "---"
  echo ""
  unset CONFIG_TYPE
  unset N_PLUGINS
}

# Print information
nvim --version > nvim_version
echo ""

# Do clean benchmark
rm -rf ./startups
rm -f ./filetype-bench-summary.csv
rm -f ./startup-bench-summary.csv

for n_plugins in "${N_PLUGINS_ARRAY[@]}"; do
  benchmark single $n_plugins
  benchmark many-gr $n_plugins
  benchmark many-sep $n_plugins
done

# Produce output summary
nvim --clean -l 03_make-startup-summary.lua

# Clean
rm -rf ./host
