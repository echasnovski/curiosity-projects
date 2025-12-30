-- Palette creation ===========================================================
-- General principles:
-- - Should be recognized as "Neovim branded". Green and azure should prevail.
-- - Should have enough colors to be able to convey important information, but
--   not too many. Start with 4.
-- - Should be accessible both for users with color vision deficiency and sight
--   problems. Try use different chromas and (probably) bold text.
-- - Should use only built-in named colors from `vim.api.nvim_get_color_map()`.
--   Not a strict requirement, as those might be updated (in theory).

-- Requires 'echasnovski/mini.colors' for palette generation
local colors = require('mini.colors')

-- Base lightness values for dark color scheme
local base_lightness_dark = {
  background = 15,
  foreground = 85,
}

-- Base lightness values for light color scheme
local base_lightness_light = {
  background = 85,
  foreground = 15,
}

-- Base chroma levels for dark color scheme
local base_chroma_dark = {
  background = 5,
  pale = 5,
  base = 10,
  accent = 15,
}

-- Base chroma levels for light color scheme.
-- Needs lower background value to reduce sensory overload.
-- Needs higher foreground value for colors to be distinguishable at low
-- lightness. Usage of `gamut_clip = 'cusp'` will add to that
-- (see `:h MiniColors-gamut-clip`).
local base_chroma_light = {
  background = 2,
  pale = 10,
  base = 15,
  accent = 20,
}

-- Basic hues
local base_hue = {
  -- Equi-distant 4 hues aligned with hues from Neovim logo:
  -- - Green at 141 (#64b359)
  -- - Azure (blue) at 242 (#077dbb)
  orange = 60,
  green = 150,
  azure = 240,
  purple = 330,
}

-- Palette generator
local make_palette = function(lightness, chroma, hue)
  -- Use blue for background
  local bg_lch = { l = lightness.background, c = chroma.background, h = hue.azure }

  -- Use gray for foreground
  local fg_lch = { l = lightness.foreground, c = 0 }

  -- Reference lightness levels
  local bg_l, fg_l = bg_lch.l, fg_lch.l
  local is_dark = bg_l <= 50
  local l_bg_edge = is_dark and 0 or 100
  local l_fg_edge = is_dark and 100 or 0
  local l_mid = 0.5 * (bg_l + fg_l)

  -- Compute result
  local convert = function(lch) return colors.convert(lch, 'hex', { gamut_clip = 'cusp' }) end

  --stylua: ignore
  local res = {
    -- `_out`/`_mid` are third of the way towards reference (edge/center)
    -- `_out2`/`_mid2` are two thirds
    bg_out2 = convert({ l = 0.33 * bg_l + 0.67 * l_bg_edge, c = bg_lch.c, h = bg_lch.h }),
    bg_out  = convert({ l = 0.67 * bg_l + 0.33 * l_bg_edge, c = bg_lch.c, h = bg_lch.h }),
    bg      = convert(bg_lch),
    bg_mid  = convert({ l = 0.67 * bg_l + 0.33 * l_mid,     c = bg_lch.c, h = bg_lch.h }),
    bg_mid2 = convert({ l = 0.33 * bg_l + 0.67 * l_mid,     c = bg_lch.c, h = bg_lch.h }),

    fg_out2 = convert({ l = 0.33 * fg_l + 0.67 * l_fg_edge, c = fg_lch.c, h = fg_lch.h }),
    fg_out  = convert({ l = 0.67 * fg_l + 0.33 * l_fg_edge, c = fg_lch.c, h = fg_lch.h }),
    fg      = convert(fg_lch),
    fg_mid  = convert({ l = 0.67 * fg_l + 0.33 * l_mid,     c = fg_lch.c, h = fg_lch.h }),
    fg_mid2 = convert({ l = 0.33 * fg_l + 0.67 * l_mid,     c = fg_lch.c, h = fg_lch.h }),

    orange_bg     = convert({ l = bg_l, c = chroma.background, h = hue.orange }),
    orange_pale   = convert({ l = fg_l, c = chroma.pale,       h = hue.orange }),
    orange        = convert({ l = fg_l, c = chroma.base,       h = hue.orange }),
    orange_accent = convert({ l = fg_l, c = chroma.accent,     h = hue.orange }),

    green_bg     = convert({ l = bg_l, c = chroma.background, h = hue.green }),
    green_pale   = convert({ l = fg_l, c = chroma.pale,       h = hue.green }),
    green        = convert({ l = fg_l, c = chroma.base,       h = hue.green }),
    green_accent = convert({ l = fg_l, c = chroma.accent,     h = hue.green }),

    azure_bg     = convert({ l = bg_l, c = chroma.background, h = hue.azure }),
    azure_pale   = convert({ l = fg_l, c = chroma.pale,       h = hue.azure }),
    azure        = convert({ l = fg_l, c = chroma.base,       h = hue.azure }),
    azure_accent = convert({ l = fg_l, c = chroma.accent,     h = hue.azure }),

    purple_bg     = convert({ l = bg_l, c = chroma.background, h = hue.purple }),
    purple_pale   = convert({ l = fg_l, c = chroma.pale,       h = hue.purple }),
    purple        = convert({ l = fg_l, c = chroma.base,       h = hue.purple }),
    purple_accent = convert({ l = fg_l, c = chroma.accent,     h = hue.purple }),
  }

  return res
end

-- Actual palette depending on background
_G.palette_dark = make_palette(base_lightness_dark, base_chroma_dark, base_hue)
_G.palette_light = make_palette(base_lightness_light, base_chroma_light, base_hue)

local p = vim.o.background == 'dark' and palette_dark or palette_light

-- Highlight groups ===========================================================
vim.cmd('hi clear')
vim.g.colors_name = 'new-default'

--stylua: ignore start
local hi = function(name, data) vim.api.nvim_set_hl(0, name, data) end

-- General UI
hi('ColorColumn',    { fg=nil,             bg=p.bg_mid2 })
hi('Conceal',        { fg=p.azure,         bg=nil })
hi('CurSearch',      { fg=p.bg,            bg=p.green })
hi('Cursor',         { fg=p.bg,            bg=p.fg })
hi('CursorColumn',   { fg=nil,             bg=p.bg_mid })
hi('CursorIM',       { fg=p.bg,            bg=p.fg })
hi('CursorLine',     { fg=nil,             bg=p.bg_mid })
hi('CursorLineFold', { fg=p.bg_mid2,       bg=nil })
hi('CursorLineNr',   { fg=nil,             bg=nil,       bold=true })
hi('CursorLineSign', { fg=p.bg_mid2,       bg=nil })
hi('DiffAdd',        { fg=nil,             bg=p.green_bg })
hi('DiffChange',     { fg=nil,             bg=p.purple_bg })
hi('DiffDelete',     { fg=nil,             bg=p.orange_bg })
hi('DiffText',       { fg=nil,             bg=p.bg_mid2 })
hi('Directory',      { fg=p.azure,         bg=nil })
hi('EndOfBuffer',    { fg=p.bg_mid2,       bg=nil })
hi('ErrorMsg',       { fg=p.orange_accent, bg=nil })
hi('FloatBorder',    { fg=nil,             bg=p.bg_out })
hi('FoldColumn',     { fg=p.bg_mid2,       bg=nil })
hi('Folded',         { fg=p.fg_mid2,       bg=p.bg_mid })
hi('IncSearch',      { fg=p.bg,            bg=p.green })
hi('lCursor',        { fg=p.bg,            bg=p.fg })
hi('LineNr',         { fg=p.bg_mid2,       bg=nil })
hi('LineNrAbove',    { fg=p.bg_mid2,       bg=nil })
hi('LineNrBelow',    { fg=p.bg_mid2,       bg=nil })
hi('MatchParen',     { fg=nil,             bg=p.bg_mid2, bold=true })
hi('ModeMsg',        { fg=p.green,         bg=nil })
hi('MoreMsg',        { fg=p.azure,         bg=nil })
hi('MsgArea',        { link='Normal' })
hi('MsgSeparator',   { fg=p.fg_mid2,       bg=p.bg_mid2 })
hi('NonText',        { fg=p.bg_mid2,       bg=nil })
hi('Normal',         { fg=p.fg,            bg=p.bg })
hi('NormalFloat',    { fg=p.fg,            bg=p.bg_out })
hi('NormalNC',       { link='Normal' })
hi('PMenu',          { fg=p.fg,            bg=p.bg_mid })
hi('PMenuSbar',      { link='PMenu' })
hi('PMenuSel',       { fg=p.bg,            bg=p.fg,      blend=0 })
hi('PMenuThumb',     { fg=nil,             bg=p.bg_mid2 })
hi('Question',       { fg=p.azure,         bg=nil })
hi('QuickFixLine',   { fg=nil,             bg=p.bg_mid })
hi('Search',         { fg=p.bg,            bg=p.azure })
hi('SignColumn',     { fg=p.bg_mid2,       bg=nil })
hi('SpecialKey',     { fg=p.bg_mid2,       bg=nil })
hi('SpellBad',       { fg=nil,             bg=nil,       sp=p.orange, undercurl=true })
hi('SpellCap',       { fg=nil,             bg=nil,       sp=p.purple, undercurl=true })
hi('SpellLocal',     { fg=nil,             bg=nil,       sp=p.green,  undercurl=true })
hi('SpellRare',      { fg=nil,             bg=nil,       sp=p.azure,  undercurl=true })
hi('StatusLine',     { fg=p.fg_mid,        bg=p.bg_out })
hi('StatusLineNC',   { fg=p.fg_mid2,       bg=p.bg_out })
hi('Substitute',     { fg=p.bg,            bg=p.azure })
hi('TabLine',        { fg=p.fg_mid,        bg=p.bg_out })
hi('TabLineFill',    { link='Tabline' })
hi('TabLineSel',     { fg=p.fg_mid,        bg=p.bg_out,  bold = true })
hi('TermCursor',     { fg=nil,             bg=nil,       reverse=true })
hi('TermCursorNC',   { fg=nil,             bg=nil,       reverse=true })
hi('Title',          { fg=p.green,         bg=nil })
hi('VertSplit',      { link='Normal' })
hi('Visual',         { fg=nil,             bg=p.bg_mid2 })
hi('VisualNOS',      { fg=nil,             bg=p.bg_mid })
hi('WarningMsg',     { fg=p.purple,        bg=nil })
hi('Whitespace',     { fg=p.bg_mid2,       bg=nil })
hi('WildMenu',       { link='PMenuSel' })
hi('WinBar',         { link='StatusLine' })
hi('WinBarNC',       { link='StatusLineNC' })
hi('WinSeparator',   { link='Normal' })

-- Syntax (`:h group-name`)
hi('Comment', { fg=p.fg_mid2, bg=nil })

hi('Constant',  { fg=p.purple,       bg=nil })
hi('String',    { fg=p.green_accent, bg=nil })
hi('Character', { link='Constant' })
hi('Number',    { link='Constant' })
hi('Boolean',   { link='Constant' })
hi('Float',     { link='Constant' })

hi('Identifier', { fg=p.green_pale, bg=nil }) -- or {link='Normal'}
hi('Function',   { fg=p.azure,      bg=nil })

hi('Statement',   { fg=nil,  bg=nil, bold=true }) -- **bold** choice (get it?) for accessibility
hi('Conditional', { link='Statement' })
hi('Repeat',      { link='Statement' })
hi('Label',       { link='Statement' })
hi('Operator',    { fg=p.fg, bg=nil })
hi('Keyword',     { link='Statement' })
hi('Exception',   { link='Statement' })

hi('PreProc',   { fg=p.blue, bg=nil })
hi('Include',   { link='PreProc' })
hi('Define',    { link='PreProc' })
hi('Macro',     { link='PreProc' })
hi('PreCondit', { link='PreProc' })

hi('Type',         { fg=p.fg, bg=nil })
hi('StorageClass', { link='Type' })
hi('Structure',    { link='Type' })
hi('Typedef',      { link='Type' })

hi('Special',        { fg=p.azure_pale, bg=nil })
hi('SpecialChar',    { link='Special' })
hi('Tag',            { link='Special' })
hi('Delimiter',      { fg=p.orange_pale,     bg=nil }) -- makes more visible separators
hi('SpecialComment', { link='Special' })
hi('Debug',          { link='Special' })

hi('Underlined', { fg=nil,  bg=nil,           underline=true })
hi('Ignore',     { link='Normal' })
hi('Error',      { fg=p.bg, bg=p.orange_pale })
hi('Todo',       { fg=p.bg, bg=p.orange_pale, bold=true })

-- Built-in diagnostic
hi('DiagnosticError', { fg=p.orange_accent, bg=nil })
hi('DiagnosticHint',  { fg=p.green_accent,  bg=nil })
hi('DiagnosticInfo',  { fg=p.azure_accent,  bg=nil })
hi('DiagnosticWarn',  { fg=p.purple_accent, bg=nil })

hi('DiagnosticFloatingError', { fg=p.orange_accent, bg=p.bg_mid })
hi('DiagnosticFloatingHint',  { fg=p.green_accent,  bg=p.bg_mid })
hi('DiagnosticFloatingInfo',  { fg=p.azure_accent,  bg=p.bg_mid })
hi('DiagnosticFloatingWarn',  { fg=p.purple_accent, bg=p.bg_mid })

hi('DiagnosticSignError', { link='DiagnosticError' })
hi('DiagnosticSignHint',  { link='DiagnosticHint' })
hi('DiagnosticSignInfo',  { link='DiagnosticInfo' })
hi('DiagnosticSignWarn',  { link='DiagnosticWarn' })

hi('DiagnosticUnderlineError', { fg=nil, bg=nil, sp=p.orange_accent, underline=true })
hi('DiagnosticUnderlineHint',  { fg=nil, bg=nil, sp=p.green_accent,  underline=true })
hi('DiagnosticUnderlineInfo',  { fg=nil, bg=nil, sp=p.azure_accent,  underline=true })
hi('DiagnosticUnderlineWarn',  { fg=nil, bg=nil, sp=p.purple_accent, underline=true })

-- Tree-sitter
-- - Text
hi('@text.literal',   { link='Comment' })
hi('@text.reference', { link='Identifier' })
hi('@text.title',     { link='Title' })
hi('@text.uri',       { link='Underlined' })
hi('@text.underline', { link='Underlined' })
hi('@text.todo',      { link='Todo' })

-- - Miscs
hi('@comment',     { link='Comment' })
hi('@punctuation', { link='Delimiter' })

-- - Constants
hi('@constant',          { link='Constant' })
hi('@constant.builtin',  { link='Special' })
hi('@constant.macro',    { link='Define' })
hi('@define',            { link='Define' })
hi('@macro',             { link='Macro' })
hi('@string',            { link='String' })
hi('@string.escape',     { link='SpecialChar' })
hi('@string.special',    { link='SpecialChar' })
hi('@character',         { link='Character' })
hi('@character.special', { link='SpecialChar' })
hi('@number',            { link='Number' })
hi('@boolean',           { link='Boolean' })
hi('@float',             { link='Float' })

-- - Functions
hi('@function',         { link='Function' })
hi('@function.builtin', { link='Special' })
hi('@function.macro',   { link='Macro' })
hi('@parameter',        { link='Identifier' })
hi('@method',           { link='Function' })
hi('@field',            { link='Identifier' })
hi('@property',         { link='Identifier' })
hi('@constructor',      { link='Special' })

-- - Keywords
hi('@conditional', { link='Conditional' })
hi('@repeat',      { link='Repeat' })
hi('@label',       { link='Label' })
hi('@operator',    { link='Operator' })
hi('@keyword',     { link='Keyword' })
hi('@exception',   { link='Exception' })

hi('@variable',        { fg=p.fg, bg=nil }) -- makes variables stand out
hi('@type',            { link='Type' })
hi('@type.definition', { link='Typedef' })
hi('@storageclass',    { link='StorageClass' })
hi('@namespace',       { link='Identifier' })
hi('@include',         { link='Include' })
hi('@preproc',         { link='PreProc' })
hi('@debug',           { link='Debug' })
hi('@tag',             { link='Tag' })

-- - LSP semantic tokens
hi('@lsp.type.class',         { link='Structure' })
hi('@lsp.type.comment',       { link='Comment' })
hi('@lsp.type.decorator',     { link='Function' })
hi('@lsp.type.enum',          { link='Structure' })
hi('@lsp.type.enumMember',    { link='Constant' })
hi('@lsp.type.function',      { link='Function' })
hi('@lsp.type.interface',     { link='Structure' })
hi('@lsp.type.macro',         { link='Macro' })
hi('@lsp.type.method',        { link='Function' })
hi('@lsp.type.namespace',     { link='Structure' })
hi('@lsp.type.parameter',     { link='Identifier' })
hi('@lsp.type.property',      { link='Identifier' })
hi('@lsp.type.struct',        { link='Structure' })
hi('@lsp.type.type',          { link='Type' })
hi('@lsp.type.typeParameter', { link='TypeDef' })
hi('@lsp.type.variable',      { link='@variable' })

-- Terminal colors (not ideal)
vim.g.terminal_color_0  = p.bg
vim.g.terminal_color_1  = p.orange_accent
vim.g.terminal_color_2  = p.green
vim.g.terminal_color_3  = p.orange
vim.g.terminal_color_4  = p.azure
vim.g.terminal_color_5  = p.purple
vim.g.terminal_color_6  = p.green_accent
vim.g.terminal_color_7  = p.fg
vim.g.terminal_color_8  = p.bg
vim.g.terminal_color_9  = p.orange_accent
vim.g.terminal_color_10 = p.green
vim.g.terminal_color_11 = p.orange
vim.g.terminal_color_12 = p.azure
vim.g.terminal_color_13 = p.purple
vim.g.terminal_color_14 = p.green_accent
vim.g.terminal_color_15 = p.fg
