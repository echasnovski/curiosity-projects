-- Dependencies:
-- - https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-colors.md
--   (for color scheme manipulations)
--
-- - Target color scheme plugins. Process of how they were chosen:
--     - Go through https://github.com/rockerBOO/awesome-neovim.
--     - Pick top 10 with most stars, considerable Neovim orientation (either
--       written in Lua or many Neovim related highlight groups), which are not
--       repeating.
--
--   Here is the final list (as of 2023-04-19):
--     - folke/tokyonight.nvim (3468 stars)
--     - catppuccin/nvim (2637 stars)
--     - rebelot/kanagawa.nvim (2212 stars)
--     - EdenEast/nightfox.nvim (2055 stars)
--     - sainnhe/everforest (1815 stars)
--     - projekt0n/github-nvim-theme (1376 stars)
--     - sainnhe/gruvbox-material (1316 stars)
--     - sainnhe/sonokai (1199 stars)
--     - navarasu/onedark.nvim (941 stars)
--     - rose-pine/neovim (931 stars)
--
--   Notes:
--     - dracula/vim (1228 stars) is not on the list as it has only a handful
--       `Diagnostic*` highlight groups.
--     - ellisonleao/gruvbox.nvim (982 stars) is not on the list as there is
--       more popular sainnhe/gruvbox-material which are essentially variations
--       on the same color scheme.

local colors = require('mini.colors')

-- Get colorscheme objects ====================================================
local cs_names = {
  -- Use the default variants of supplied color schemes.
  'tokyonight',
  'catppuccin',
  'kanagawa',
  'nightfox',
  'everforest',
  'github_dark',
  'gruvbox-material',
  'sonokai',
  'onedark',
  'rose-pine',
}

-- local cs_names = {
--   -- Use all supplied variants
--   "carbonfox",
--   "catppuccin-frappe",
--   "catppuccin-macchiato",
--   "catppuccin-mocha",
--   "duskfox",
--   "everforest",
--   "github_dark",
--   "github_dark_colorblind",
--   "github_dark_default",
--   "github_dimmed",
--   "gruvbox-material",
--   "kanagawa-dragon",
--   "kanagawa-wave",
--   "nightfox",
--   "nordfox",
--   "onedark",
--   "rose-pine-main",
--   "sonokai",
--   "terafox",
--   "tokyonight-moon",
--   "tokyonight-night",
--   "tokyonight-storm",
-- }

-- -- A light variant:
-- TODO

_G.cs_array = vim.tbl_map(function(name) return colors.get_colorscheme(name):compress():resolve_links() end, cs_names)

-- local n_threshold = 0
-- local n_threshold = math.floor(0.5 * #cs_names + 0.5)
-- local n_threshold = math.floor(0.61 * #cs_names + 0.5)
local n_threshold = #cs_names
local avg_color_space = 'oklab'

-- Compute average color scheme ===============================================
_G.extract = function(arr, field)
  local res = {}
  -- NOTE: use `pairs` instead of `ipairs` because there might be
  -- non-consecutive fields
  for _, v in pairs(arr) do
    if type(v) == 'table' and v[field] ~= nil then table.insert(res, v[field]) end
  end
  return res
end

local should_ignore = function(arr)
  -- Average only if operands are present with at least threshold number amount
  local n = vim.tbl_count(arr)
  return n == 0 or n < n_threshold
end

local median_numeric = function(arr)
  local t = vim.deepcopy(arr)
  table.sort(t)
  local id = math.floor(0.5 * #t + 0.5)
  return t[id]
end

local dist_circle = function(x, y)
  local d = math.abs((x % 360) - (y % 360))
  return math.min(d, 360 - d)
end

local median_hue = function(t)
  local hues = vim.deepcopy(t)

  -- Median hue is a number minimizing sum distances to points
  local dist_total = function(x)
    local res = 0
    for _, v in pairs(hues) do
      res = res + dist_circle(x, v)
    end
    return res
  end

  local best_hue, best_dist = nil, math.huge
  for i = 0, 359 do
    local cur_dist = dist_total(i)
    if cur_dist <= best_dist then
      best_hue, best_dist = i, cur_dist
    end
  end

  return best_hue
end

local median_hex_oklch = function(hex_tbl)
  if should_ignore(hex_tbl) then return nil end

  local lch_tbl = vim.tbl_map(function(x) return colors.convert(x, 'oklch') end, hex_tbl)

  -- Separate grays and non-grays
  local grays, nongrays = {}, {}
  for _, lch in pairs(lch_tbl) do
    if lch.h == nil then
      table.insert(grays, lch)
    else
      table.insert(nongrays, lch)
    end
  end

  -- If there are more grays, return gray. Otherwise, average non-grays.
  -- This way chroma of grays won't desaturate rest of the colors.
  local lch_res
  if #nongrays <= #grays then
    lch_res = { l = median_numeric(extract(grays, 'l')), c = 0 }
  else
    lch_res = {
      l = median_numeric(extract(nongrays, 'l')),
      c = median_numeric(extract(nongrays, 'c')),
      h = median_hue(extract(nongrays, 'h')),
    }
  end

  return colors.convert(lch_res, 'hex')
end

local median_hex_oklab = function(hex_tbl)
  if should_ignore(hex_tbl) then return nil end

  local lab_tbl = vim.tbl_map(function(x) return colors.convert(x, 'oklab') end, hex_tbl)

  local lab_res = {
    l = median_numeric(extract(lab_tbl, 'l')),
    a = median_numeric(extract(lab_tbl, 'a')),
    b = median_numeric(extract(lab_tbl, 'b')),
  }

  return colors.convert(lab_res, 'hex')
end

local median_hex = avg_color_space == 'oklch' and median_hex_oklch or median_hex_oklab

local median_boolean = function(bool_tbl)
  if should_ignore(bool_tbl) then return nil end

  local n_true = 0
  for _, v in pairs(bool_tbl) do
    if v == true then n_true = n_true + 1 end
  end

  -- Attribute is true if present in at least threshold number of color schemes
  -- If false, return `nil` to not explicitly include boolean attribute
  if n_true < n_threshold then return nil end
  return true
end

--stylua: ignore
local avg_hl_group = function(gr_tbl)
  if should_ignore(gr_tbl) then return nil end

  local res = {
    fg = median_hex(extract(gr_tbl, 'fg')),
    bg = median_hex(extract(gr_tbl, 'bg')),
    sp = median_hex(extract(gr_tbl, 'sp')),

    bold          = median_boolean(extract(gr_tbl, 'bold')),
    italic        = median_boolean(extract(gr_tbl, 'italic')),
    nocombine     = median_boolean(extract(gr_tbl, 'nocombine')),
    reverse       = median_boolean(extract(gr_tbl, 'reverse')),
    standout      = median_boolean(extract(gr_tbl, 'standout')),
    strikethrough = median_boolean(extract(gr_tbl, 'strikethrough')),
    undercurl     = median_boolean(extract(gr_tbl, 'undercurl')),
    underdashed   = median_boolean(extract(gr_tbl, 'underdashed')),
    underdotted   = median_boolean(extract(gr_tbl, 'underdotted')),
    underdouble   = median_boolean(extract(gr_tbl, 'underdouble')),
    underline     = median_boolean(extract(gr_tbl, 'underline')),
  }

  -- Don't clear highlight group
  if vim.tbl_count(res) == 0 then return nil end
  return res
end

local union = function(arr_arr)
  local value_is_present = {}
  for _, arr in pairs(arr_arr) do
    for _, x in pairs(arr) do
      value_is_present[x] = true
    end
  end
  return vim.tbl_keys(value_is_present)
end

_G.avg_colorschemes = function(cs_arr)
  local groups = extract(cs_arr, 'groups')

  local all_group_names = union(vim.tbl_map(vim.tbl_keys, groups))
  local res_groups = {}
  for _, hl_name in pairs(all_group_names) do
    res_groups[hl_name] = avg_hl_group(extract(groups, hl_name))
  end

  return colors
    .as_colorscheme({ name = 'average_cs', groups = res_groups })
    :add_cterm_attributes()
    :add_terminal_colors()
end
