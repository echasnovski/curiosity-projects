local find_data = function(startup_log_lines)
  local appname = vim.env.NVIM_APPNAME or 'nvim'
  local init_time_pattern = '^[%d%.]+%s+([%d%.]+).*' .. vim.pesc(appname) .. '[\\/]init%.lua$'
  local plugin_time_pattern = '^[%d%.]+%s+([%d%.]+).*pack[\\/]core[\\/]opt[\\/][^\\/]+[\\/]plugin[\\/]'
  local total_time_pattern = '^([%d%.]+).+NVIM STARTED'

  local init_time, plugin_time, total_time = 0, 0, 0
  for _, l in ipairs(startup_log_lines) do
    -- Detect only a single 'init.lua'
    local cur_init = l:match(init_time_pattern)
    if cur_init ~= nil then init_time = tonumber(cur_init) or 0 end

    -- Accumulate 'init.lua'
    local cur_plugin = l:match(plugin_time_pattern)
    if cur_plugin ~= nil then plugin_time = plugin_time + (tonumber(cur_plugin) or 0) end

    -- Detect only a single (last) 'NVIM STARTED' time
    local cur_total = l:match(total_time_pattern)
    if cur_total ~= nil then total_time = tonumber(cur_total) or 0 end
  end

  return init_time, plugin_time, total_time
end

-- Traverse all startup files, compute summary lines, and write summary file
local summary_lines = { 'config_type,n_plugins,n_iteration,init_time,plugin_time,total_time' }
for name, _ in vim.fs.dir('startups') do
  local startup_log_lines = vim.fn.readfile(vim.fs.joinpath('startups', name))
  local init_time, plugin_time, total_time = find_data(startup_log_lines)
  local cur_summary = name:gsub('_', ',') .. ',' .. init_time .. ',' .. plugin_time .. ',' .. total_time
  table.insert(summary_lines, cur_summary)
end

vim.fn.writefile(summary_lines, 'startup-bench-summary.csv')
