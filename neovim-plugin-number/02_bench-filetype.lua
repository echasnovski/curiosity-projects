-- Benchmark in a dedicated regular listed buffer by setting a filetype
-- to a value that does not have 'ftplugin'. This is done to not add
-- performance cost of those scripts to benchmarks; only itself the fact of
-- searching should be benchmarked.
local set_option_value = vim.api.nvim_set_option_value
local opts = { buf = 0 }
local set_ft = function() set_option_value('filetype', 'does-not-exist', opts) end

local n = tonumber(vim.env.N_FILETYPE_ROUNDS)
local times = {}
for i = 1, n do
  local buf_id = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf_id)

  local start_time = vim.uv.hrtime()
  set_ft()
  times[i] = 0.000001 * (vim.uv.hrtime() - start_time)

  vim.api.nvim_buf_delete(buf_id, { force = true })
end

table.sort(times)
local median_time = n % 2 == 1 and times[0.5 * (n - 1) + 1] or 0.5 * (times[0.5 * n] + times[0.5 * n + 1])
local summary_line = string.format('%s,%s,%s', vim.env.CONFIG_TYPE, vim.env.N_PLUGINS, median_time)

local summary_path = vim.fs.abspath('filetype-bench-summary.csv')
if vim.uv.fs_stat(summary_path) == nil then vim.fn.writefile({ 'config_type,n_plugins,median_time' }, summary_path) end
local fd = io.open(summary_path, 'a')
fd:write(summary_line .. '\n')
fd:close()

-- Quit explicitly since this script needs to run interactively
vim.cmd('quit')
