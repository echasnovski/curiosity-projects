## Benchmark how plugin number affects performance

Perform and analyze benchmarks of how number of installed plugins can affect overall Neovim performance. There are two main reasons for doing this:

- To get an actual data about whether lazy loading can be objectively justified.
- To see if there is a performance benefit of using 'mini.nvim' instead of its standalone repos.

Two performance aspects are benchmarked: startup and runtime.

### Startup

Effect on startup when installing/adding many plugins. Plugin manager of choice is [`vim.pack`](https://neovim.io/doc/user/helptag.html?tag=vim.pack) (available on Neovim>=0.12).

Source of plugins is procedurally generated inside a './host' subdirectory of current directory and named `pluginNN` (`NN` is a two digit number). They then are installed via `vim.pack.add({ 'file://xxx' })`.

Each plugin has very simple placeholder functionality and is written with "good practices" in mind. In particular, plugin number `NN` contains:

- 'lua/pluginNN.lua' is a Lua code provided by a plugin:

    ```lua
    local run = function() _G.value = "PluginNN" end
    local config = function() _G.pluginNN = { "PluginNN" } end
    return { config = config, run = run }
    ```

- 'plugin/pluginNN.lua' file (that is sourced during startup) that creates one user command and `<Plug>` mapping:

    ```lua
    vim.api.nvim_create_user_command("PluginNN", function() require("pluginNN").run() end, {})
    vim.keymap.set("n", "<Plug>(PluginNN)", function() require("pluginNN").run() end)
    ```

Three types of configs are benchmarked:

- `many-gr` - many independent plugins are installed and configured in "grouped" manner. This is the most robust and straightforward way to install many plugins.

    The 'init.lua' looks like this:

    ```lua
    vim.pack.add({
      'file:///path/to/working/directory/host/plugin01',
      -- ...
      'file:///path/to/working/directory/host/pluginXX',
    }, { confirm = false })

    require('plugin01').config()
    -- ...
    require('pluginXX').config()
    ```

- `many-seq` - many independent plugins are installed and configured in "sequential" manner. This installs and loads one plugin at a time while immediately configuring it. This is meant to check if having plugin entry in 'runtimepath' closer to its start adds meaningful startup improvement (as `require('pluginNN')` then needs to traverse fewer directories). SPOILER: its complicated.

    The 'init.lua' looks like this:

    ```lua
    vim.pack.add({ 'file:///path/to/working/directory/host/plugin01' }, { confirm = false })
    require('plugin01').config()

    -- ...

    vim.pack.add({ 'file:///path/to/working/directory/host/pluginXX' }, { confirm = false })
    require('pluginXX').config()
    ```

- `single` - single plugin that combines all Lua modules and plugin files of separate plugins into one. All 'lua/pluginNN.lua' and 'plugin/pluginNN.lua' files are combined under single directory. This provides the same functionality as many plugins, but "packaged" in a single plugin. This only adds a single entry to 'runtimepath' and is used as a reference to compare against.

    The 'init.lua' looks like this:

    ```lua
    vim.pack.add({ 'file:///path/to/working/directory/host/singleXX' }, { confirm = false })

    require('plugin01').config()
    -- ...
    require('pluginXX').config()
    ```

### Runtime

Effect on runtime performance when using data from so called "runtime files". For more details and examples see [`:h 'runtimepath'`](https://neovim.io/doc/user/helptag.html?tag='runtimepath') (available on Neovim>=0.12).

The reason it is important is because using runtime files involves searching through (usually) all entries in 'runtimepath'. Adding a plugins adds an entry to runtimepath, so this would affect any runtime related searching.

The most common operation involving runtime files is setting a [filetype](https://neovim.io/doc/user/helptag.html?tag='filetype') in a buffer. This results in searching and sourcing all filetype plugin scripts for that particular filetype. *Every time* filetype is set, which is *not negligible* (every file open, every plugin specific buffer that wants to be customized, etc.).

Benchmarking is fairly straightforward:
- Gather data by repeating many times:
    - Create a new dedicated regular buffer to test in.
    - Set 'filetype=does-not-exist' while timing only this operation. Use a filetype value which does not have filetype plugin scripts to not add performance cost of those scripts to benchmarks; only itself the fact of searching should be benchmarked.
- Compute median time and record it.

### Scripts

Run via `./benchmark.sh` to benchmark (don't forget to allow it to execute: `chmod u+x ./benchmark.sh`). Assumes `/bin/bash` and `nvim` executables. WARNING: EXECUTION OF THIS SCRIPT LEADS TO FLICKERING OF SCREEN WHICH WHICH MAY CAUSE HARM TO YOUR HEALTH. This is because there are many actual openings of Neovim with later automatic closing.

A `./benchmark.sh` script produces the following artifacts:

- 'nvim_version' - data about Neovim version used for benchmarking.
- 'startup-bench-summary.csv' - data about startup benchmarking.
- 'filetype-bench-summary.csv' - data about setting filetype benchmarking.

Run `Rscript 04_make-plots.R` to produce plots. Needs R/Rscript executable with necessary packages installed (see top of the script for the exact list).
