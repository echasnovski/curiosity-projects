-- Define how plugin sources are created
local host_dir = vim.fs.normalize(vim.fs.abspath('./host'))
local CreateSources = {}

local make_plugin_file = function(repo_path, plug_number)
  local name = string.format('plugin%02d', plug_number)
  local cmd = string.format('Plugin%02d', plug_number)
  local lines = {
    -- Define one user command
    string.format('vim.api.nvim_create_user_command("%s", function() require("%s").run() end, {})', cmd, name),
    -- Define one `<Plug>` keymap
    string.format('vim.keymap.set("n", "<Plug>(%s)", function() require("%s").run() end)', cmd, name),
  }

  vim.fn.mkdir(vim.fs.joinpath(repo_path, 'plugin'), 'p')
  local file_path = vim.fs.joinpath(repo_path, 'plugin', name .. '.lua')
  vim.fn.writefile(lines, file_path)
end

local make_lua_module = function(repo_path, plug_number)
  local name = string.format('plugin%02d', plug_number)
  local cmd = string.format('Plugin%02d', plug_number)
  local lines = {
    string.format('local run = function() _G.value = "%s" end', cmd),
    string.format('local config = function() _G.%s = { "%s" } end', name, cmd),
    'return { config = config, run = run }',
  }

  vim.fn.mkdir(vim.fs.joinpath(repo_path, 'lua'), 'p')
  local file_path = vim.fs.joinpath(repo_path, 'lua', name .. '.lua')
  vim.fn.writefile(lines, file_path)
end

local init_git_repo = function(repo_path)
  vim.system({ 'git', 'init' }, { cwd = repo_path }):wait()
  vim.system({ 'git', 'add', '.' }, { cwd = repo_path }):wait()
  vim.system({ 'git', 'commit', '-m', 'Initial commit' }, { cwd = repo_path }):wait()
end

-- Separate plugins
CreateSources.many = function(n_plugins)
  for plug_number = 1, n_plugins do
    local repo_path = vim.fs.joinpath(host_dir, string.format('plugin%02d', plug_number))
    make_plugin_file(repo_path, plug_number)
    make_lua_module(repo_path, plug_number)
    init_git_repo(repo_path)
  end
end

-- Single plugin combining all plugin files and Lua modules
CreateSources.single = function(n_plugins)
  local repo_path = vim.fs.joinpath(host_dir, string.format('single%02d', n_plugins))
  for plug_number = 1, n_plugins do
    make_plugin_file(repo_path, plug_number)
    make_lua_module(repo_path, plug_number)
  end
  init_git_repo(repo_path)
end

-- Define how plugin sources are created
local CreateInitLines = {}

-- Add all plugins at once and then configure all at once
CreateInitLines['many-gr'] = function(n_plugins)
  local res = {}

  table.insert(res, 'vim.pack.add({')
  for plug_number = 1, n_plugins do
    local repo_path = vim.fs.joinpath(host_dir, string.format('plugin%02d', plug_number))
    table.insert(res, string.format('  "file://%s",', repo_path))
  end
  table.insert(res, '}, { confirm = false })')

  table.insert(res, '')
  for plug_number = 1, n_plugins do
    local mod_name = string.format('plugin%02d', plug_number)
    table.insert(res, string.format('require("%s").config()', mod_name))
  end

  return res
end

-- Add all plugins while immediately configuring them
CreateInitLines['many-sep'] = function(n_plugins)
  local res = {}

  for plug_number = 1, n_plugins do
    local repo_path = vim.fs.joinpath(host_dir, string.format('plugin%02d', plug_number))
    table.insert(res, string.format('vim.pack.add({ "file://%s" }, { confirm = false })', repo_path))

    local mod_name = string.format('plugin%02d', plug_number)
    table.insert(res, string.format('require("%s").config()', mod_name))

    table.insert(res, '')
  end

  return res
end

-- Add single plugin and configure all "sub-plugins"
CreateInitLines.single = function(n_plugins)
  local repo_path = vim.fs.joinpath(host_dir, string.format('single%02d', n_plugins))
  local res = { string.format('vim.pack.add({ "file://%s" }, { confirm = false })', repo_path) }

  -- - Run configuration on all its modules
  table.insert(res, '')
  for plug_number = 1, n_plugins do
    local mod_name = string.format('plugin%02d', plug_number)
    table.insert(res, string.format('require("%s").config()', mod_name))
  end

  return res
end

-- Set up
local config_type = vim.env.CONFIG_TYPE
local src_type = config_type:match('^%a+')
local n_plugins = tonumber(vim.env.N_PLUGINS)

-- - Create plugins in target directory
vim.fn.delete(host_dir, 'rf')
vim.fn.mkdir(host_dir, 'p')
if n_plugins > 0 then CreateSources[src_type](n_plugins) end

-- - Create clean config
for _, path_name in ipairs({ 'cache', 'config', 'data', 'state', 'log' }) do
  vim.fn.delete(vim.fn.stdpath(path_name), 'rf')
end

vim.fn.mkdir(vim.fn.stdpath('config'), 'p')
local init_lua = vim.fs.joinpath(vim.fn.stdpath('config'), 'init.lua')
local init_lines = n_plugins == 0 and { '' } or CreateInitLines[config_type](n_plugins)
vim.fn.writefile(init_lines, init_lua)
