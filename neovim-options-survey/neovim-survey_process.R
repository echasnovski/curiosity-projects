# Code for processing results of "Neovim built-in options survey":
# - Google form: https://forms.gle/ciFiJ6z1VaQe8iN56
# - Reddit announcement:
#   https://www.reddit.com/r/neovim/comments/z1tmjg/neovim_builtin_options_survey_needs_your/?utm_source=share&utm_medium=web2x&context=3
library(dplyr)
library(ggplot2)
library(purrr)
library(readr)
library(stringr)
library(tibble)
library(tidyr)

# Read survey answers =========================================================
process_string_answer <- function(string_answer) {
  dummy_result <- data.frame(option = character(), value = character())

  if (is.na(string_answer) || string_answer == "") {
    return(dummy_result)
  }

  # Clean string input
  string_result <- string_answer |>
    # Remove guard lines (although many did not supply them)
    str_remove_all("[:space:]*---Please copy all lines---[:space:]*") |>
    # Clean up messy submissions
    # Lines with trailing whitespace
    str_replace_all("[:space:]*\n[:space:]*", "\n") |>
    # Lines copied with Neovim's line numbers (absolute or relative)
    str_remove_all("^[:space:]*[0-9]+[:space:]*") |>
    str_replace_all("\n[:space:]*[0-9]+[:space:]*", "\n")

  if (!str_detect(string_result, "^neovim_version,")[[1]]) {
    return(dummy_result)
  }

  # Convert to data frame
  read_delim(
    string_result,
    delim = ",",
    col_names = c("option", "value"),
    col_types = "cc",
    escape_double = FALSE,
    na = c("NA"),
    progress = FALSE
  )
}

raw_results <- read_csv("neovim-options-survey_results.csv", na = c("NA"))
colnames(raw_results) <- c("timestamp", "string_answer")

results <- map_dfr(raw_results[["string_answer"]], process_string_answer)

n_answers <- sum(results$option == "neovim_version")

# Check duplicated answers (usually only empty strings)
is_answer_dupl <- duplicated(raw_results$string_answer)
raw_results$string_answer[is_answer_dupl]

# Create all possible version range counts ====================================
# Create information about options that are not present in all tested Neovim
# versions (0.7.2, 0.8.0, 0.9.0 (2022-12-05 nightly)). Done by taking output
# keys of `vim.api.nvim_get_all_options_info()` (executed in every Neovim
# version) and removing common ones (present in all three of them).
# Helper code looked something like this:
# ```r
#   option_files <- list.files(pattern = "^neovim-options_version")
#   options_per_version <- lapply(option_files, readLines)
#   names(options_per_version) <- option_files
#   common_options <- Reduce(intersect, options_per_version)
#
#   non_common_options <- lapply(options_per_version, setdiff, common_options)
# ```
special_option_version_ranges <- tribble(
  ~option, ~version_range,
  # Added in Neovim=0.8
  "mousemoveevent", ">=0.8",
  "mousescroll", ">=0.8",
  "winbar", ">=0.8",

  # Added in Neovim=0.9
  "endoffile", ">=0.9",
  "lispoptions", ">=0.9",
  "splitkeep", ">=0.9",

  # Removed in Neovim=0.9 (https://github.com/neovim/neovim/pull/20545)
  "cscopepathcomp", "<0.9",
  "cscopeprg", "<0.9",
  "cscopequickfix", "<0.9",
  "cscoperelative", "<0.9",
  "cscopetag", "<0.9",
  "cscopetagorder", "<0.9",
  "cscopeverbose", "<0.9"
)

# Compute data about possible number of answers which could have set the option
version_ranges_equal <- results |>
  filter(option == "neovim_version") |>
  mutate(
    # Convert to number for correct sort
    value = as.numeric(str_extract(value, "^\\d+\\.\\d+"))
  ) |>
  count(value, name = "n_possible") |>
  arrange(value) |>
  transmute(range = str_c("=", value), n_possible)

version_ranges_removed <- version_ranges_equal |>
  transmute(
    range = str_replace(range, "^=", "<"),
    # If option was removed in `0.x`, count all answers with Neovim version
    # strictly less than `0.x`
    n_possible = cumsum(lag(n_possible, default = 0))
  )

version_ranges_added <- version_ranges_removed |>
  transmute(
    range = str_replace(range, "^<", ">="),
    n_possible = n_answers - n_possible
  )

version_ranges <- bind_rows(
  tibble(range = "all", n_possible = n_answers),
  version_ranges_removed,
  version_ranges_added
)

add_n_possible <- function(df) {
  df |>
    # Add number of answers which could have set corresponding option
    left_join(special_option_version_ranges, by = c(option = "option")) |>
    mutate(version_range = coalesce(version_range, "all")) |>
    left_join(version_ranges, by = c(version_range = "range")) |>
    # Remove temporary column
    select(-version_range)
}

# Add number of answers with default option values ============================
default_counts <- results |>
  count(option) |>
  # Don't add default versions of Neovim version (no such thing) and Leader key
  # (treat `"nil"` as default later)
  filter(!(option %in% c("neovim_version", "leader"))) |>
  add_n_possible() |>
  transmute(option = option, value = "*default*", n = n_possible - n)

results_summary <- bind_rows(
  results |> count(option, value),
  default_counts
) |>
  mutate(
    # Tweak "leader" option
    # - Use `nil` value as `*default*` (as documented in `:h mapleader`)
    # - Use `"<Space>"` instead of literal `" "`
    value = ifelse(option == "leader" & value == "nil", "*default*", value),
    value = ifelse(value == " ", "<Space>", value)
  ) |>
  # Arrange per option
  arrange(option, desc(n))

# Enrich result counts ========================================================
round_preserve_sum <- function(x, digits = 0) {
  # https://stackoverflow.com/a/35930285
  up <- 10^digits
  x <- x * up
  y <- floor(x)
  indices <- tail(order(x - y), round(sum(x)) - sum(y))
  y[indices] <- y[indices] + 1
  y / up
}

share_to_percent <- function(x) {
  percent_number <- round_preserve_sum(100 * x / sum(x))
  str_c(percent_number, "%")
}

results_summary <- results_summary |>
  add_n_possible() |>
  # Compute share of answer along its count
  transmute(option, value, n, share = round(n / n_possible, digits = 3)) |>
  filter(
    # Don't count `bufhidden` because options were collected in scratch buffer
    # (which always has value `"hide"`)
    option != "bufhidden",
    # Don't count `viminfo` because during `:source neovim-options-survey.lua`
    # default value is shown as empty string while returned value is the one
    # actually used
    option != "viminfo"
  ) |>
  # Add percent string
  group_by(option) |>
  mutate(percent = share_to_percent(share)) |>
  ungroup()

# Analyze "list options" ======================================================
# A "list option" is one that can contain many sub values combined with either
# a comma ("commalist option") or empty string ("flaglist option"). Exact lists
# for both of them is taken via `commalist` and `flaglist` boolean flags in
# output of `vim.api.nvim_get_all_options_info()`.
#
# Convert each sub value into a separate one.
spread_list_options <- function(summary_df, option_names, sep) {
  summary_df |>
    filter(option %in% option_names) |>
    # Could use `separate_rows()`, but it doesn't work well with `sep = ""`
    # (adds extra `""` as result of separation)
    mutate(value = str_split(value, sep)) |>
    unnest_longer(value) |>
    # Ensure that output is always string
    mutate(value = as.character(value))
}

commalist_options <- c(
  "backspace",      "backupcopy",      "backupdir",      "backupskip",
  "belloff",        "breakindentopt",  "casemap",        "cdpath",
  "cinkeys",        "cinoptions",      "cinscopedecls",  "cinwords",
  "clipboard",      "colorcolumn",     "comments",       "complete",
  "completeopt",    "cscopequickfix",  "cursorlineopt",  "dictionary",
  "diffopt",        "directory",       "display",        "errorformat",
  "eventignore",    "fileencodings",   "fileformats",    "fillchars",
  "foldclose",      "foldmarker",      "foldopen",       "grepformat",
  "guicursor",      "guifont",         "guifontwide",    "helplang",
  "highlight",      "indentkeys",      "isfname",        "isident",
  "iskeyword",      "isprint",         "jumpoptions",    "keymodel",
  "langmap",        "lispwords",       "listchars",      "matchpairs",
  "mousescroll",    "mouseshape",      "nrformats",      "packpath",
  "path",           "printoptions",    "redrawdebug",    "runtimepath",
  "scrollopt",      "selectmode",      "sessionoptions", "shada",
  "shadafile",      "spellfile",       "spelllang",      "spelloptions",
  "spellsuggest",   "suffixes",        "suffixesadd",    "switchbuf",
  "tags",           "termpastefilter", "thesaurus",      "undodir",
  "varsofttabstop", "vartabstop",      "viewoptions",    "virtualedit",
  "wildignore",     "wildmode",        "wildoptions",    "winhighlight"
)

flaglist_options <- c(
  "breakat", "cpoptions", "formatoptions", "guioptions", "mouse", "shortmess",
  # NOTE: 'whichwrap' is included in "flaglist", but it can also have comma
  # separated values. Will be processed separately.
  "whichwrap"
)

results_listoptions <- bind_rows(
  results |> spread_list_options(commalist_options, sep = ","),
  results |>
    mutate(
      value = ifelse(option == "whichwrap", str_remove_all(value, ","), value)
    ) |>
    spread_list_options(flaglist_options, sep = "")
)

results_listoptions_summary <- results_listoptions |>
  count(option, value, sort = TRUE)

# Barplot of "interesting" options ============================================
interesting_options <- tribble(
  ~option,          ~default_value,
  "cursorline",     "false",
  "cursorcolumn",   "false",
  "expandtab",      "false",
  "ignorecase",     "false",
  "laststatus",     "2",
  "leader",         "\\",
  "mouse",          "nvi",
  "number",         "false",
  "relativenumber", "false",
  "shiftwidth",     "8",
  "showtabline",    "1",
  "showmode",       "true",
  "signcolumn",     "auto",
  "smartcase",      "false",
  "splitbelow",     "false",
  "splitright",     "false",
  "tabstop",        "8",
  "termguicolors",  "false",
  "undofile",       "false",
  "wrap",           "true"
)
interesting_summary <- results_summary |>
  inner_join(interesting_options, by = "option") |>
  mutate(
    # Replace "*default*" placeholder with actual default value
    value = ifelse(value == "*default*", default_value, value),

    # Squash rare non-default option values into `rare`
    value = ifelse(value != default_value & share < 0.1, "rare", value),
  ) |>
  group_by(option, value) |>
  summarise(n = sum(n), share = sum(share), .groups = "drop_last") |>
  mutate(percent = share_to_percent(share)) |>
  ungroup()

# Create plotting data
plot_data <- interesting_summary |>
  group_by(option) |>
  mutate(
    # Add with-in group id for a more pretty bar order for same option
    group_id = rank(share),
    # Enclose string option values in quotes
    value_label = ifelse(
      option %in% c("leader", "mouse", "signcolumn") & value != "rare",
      str_c('"', value, '"'),
      value
    ),
  ) |>
  ungroup() |>
  # Create bar color variable
  left_join(interesting_options, by = "option") |>
  mutate(
    color_var = case_when(
      value == "rare" ~ "rare non-default\n(less than 10%)",
      value == default_value ~ "default",
      TRUE ~ "non-default"
    )
  ) |>
  select(-default_value) |>
  arrange(option, desc(share))

plot_option_order <- plot_data |>
  filter(color_var == "default") |>
  arrange(desc(share)) |>
  pull(option)

colors <- c(
  bg            = "#0F191F",
  bg_gray       = "#42474B",
  fg            = "#D0D0D0",
  default       = "#8FFF6D",
  "non-default" = "#09BDF9",
  rare          = "#AAAAAA"
)

dodge2 <- position_dodge2(width = 0.9, padding = 0.1, preserve = "single")
font_family <- "Input"

gg <- ggplot(
  plot_data,
  aes(option, share, group = group_id, fill = color_var)
) +
  # Plot bars
  geom_col(position = dodge2) +
  # Plot text labels: option value and percent
  geom_text(
    aes(label = value_label, y = -0.005),
    position = dodge2,
    hjust = 1,
    color = colors[["fg"]], family = font_family, size = 3, fontface = "bold"
  ) +
  geom_text(
    aes(label = percent),
    position = dodge2,
    hjust = -0.05,
    color = colors[["fg"]], family = font_family, size = 3, fontface = "bold"
  ) +
  # Make horizontal bars
  coord_flip() +
  # Tweak scales
  scale_x_discrete(limits = plot_option_order) +
  scale_y_continuous(
    # Show no tick labels
    breaks = c(),
    # Make sure that labels are shown. Tightly connected to size of save plot.
    expand = c(0.25, 0)
  ) +
  scale_fill_manual(
    values = c(
      default = colors[["default"]],
      "non-default" = colors[["non-default"]],
      "rare non-default\n(less than 10%)" = colors[["rare"]]
    ),
    name = NULL
  ) +
  # Add main text
  labs(
    x = NULL,
    y = NULL,
    title = "Usage of basic Neovim built-in options",
    subtitle = paste0(
      "Based on a survey from 2022-11-22 to 2022-12-08\n",
      "Total number of answers: ", n_answers
    ),
    caption = "Made by @echasnovski"
  ) +
  # Modify theme
  theme(
    rect = element_rect(fill = colors[["bg"]]),
    text = element_text(family = font_family, size = 10, color = colors[["fg"]])
  ) +
  theme(
    legend.position = "top",
    legend.justification = "left",
    # Set panel theme
    panel.background = element_rect(fill = colors[["bg"]]),
    legend.background = element_rect(linewidth = 0),
    legend.key = element_rect(color = colors[["bg"]]),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.ticks.y = element_blank(),
    # Set text theme
    axis.text = element_text(face = "bold", size = 12, color = colors[["fg"]]),
    title = element_text(size = 12, face = "bold"),
    # Show only left axe
    axis.line.y.left = element_line(color = colors[["bg_gray"]]),
    axis.line.y.right = element_blank(),
    axis.line.x.bottom = element_blank(),
    axis.line.x.top = element_blank(),
    # Align title to left of the plot
    plot.title.position = "plot"
  )

# Save output artefacts =======================================================
# Plot with summary of basic options
ggsave(
  "neovim-survey-summary_basic-options-plot.png",
  plot = gg,
  width = 5,
  height = 12,
  units = "in",
)

# Summary of top non-default options
results_summary |>
  filter(
    # Don't Neovim version as option
    option != "neovim_version",
    # "Most common" meaning at least 25% set it
    share >= 0.25,
    # "Non-default"
    value != "*default*",
  ) |>
  arrange(desc(share)) |>
  select(-share) |>
  write_csv("neovim-survey-summary_top-nondefault.csv")

# Summary of all answers
results_summary |>
  select(-share) |>
  write_csv("neovim-survey-summary_all.csv")

# Summary of separated list options
write_csv(
  results_listoptions_summary |> arrange(option, desc(n)),
  "neovim-survey-summary_separated-listoptions.csv"
)
