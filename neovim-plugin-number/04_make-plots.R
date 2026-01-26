library(readr)
library(dplyr)
library(forcats)
library(tidyr)
library(ggplot2)
library(ggrepel)
library(showtext)

# Load and prepare data
convert_config_type <- . %>%
  mutate(
    config_type = fct_recode(
      config_type,
      "Grouped add()" = "many-gr",
      "Separate add()" = "many-sep",
      "Single plugin" = "single"
    )
  )

startup_summary <- read_csv(
  "startup-bench-summary.csv",
  col_types = "ciiddd"
) |>
  pivot_longer(
    ends_with("_time"),
    names_to = "type",
    names_pattern = "(.*)_time",
    values_to = "time"
  ) |>
  convert_config_type()

startup_summary_median <- startup_summary |>
  group_by(config_type, n_plugins, type) |>
  summarise(time = median(time), .groups = "drop")

filetype_summary <- read_csv("filetype-bench-summary.csv", col_types = "cid") |>
  convert_config_type()

# Define plotting functions
bg <- "#15242F"
bg_light <- "#50606d"
fg <- "#E3E5CE"
config_type_colors <- c("#AFE4B9", "#A5DBFF", "#F4C2EE")

font_add_google("Ubuntu", family = "ubuntu")
showtext_auto()

plot_theme <- function() {
  font <- "ubuntu"
  theme_minimal() +
    theme(
      plot.background = element_rect(fill = bg, color = NA),
      panel.background = element_rect(fill = bg, color = NA),
      panel.grid.major.y = element_line(color = bg_light),
      panel.grid.major.x = element_blank(),
      panel.grid.minor = element_blank(),

      legend.position = "top",
      legend.background = element_rect(fill = bg, color = NA),
      legend.key = element_rect(fill = bg, color = NA),

      text = element_text(color = fg, family = font),
      axis.text = element_text(color = fg, size = 20, family = font),
      axis.title = element_text(size = 22, face = "bold"),
      plot.title = element_text(size = 24, face = "bold"),
      plot.subtitle = element_text(size = 20),
      plot.caption = element_text(size = 18),
      legend.text = element_text(size = 20),
      legend.title = element_text(size = 20, face = "bold")
    )
}

plot_startup_summary <- function(time_type) {
  df <- startup_summary |> filter(type == time_type)
  df_median <- startup_summary_median |> filter(type == time_type)

  ggplot(df, aes(x = n_plugins, y = time, color = config_type)) +
    geom_point(size = 5, alpha = 0.1) +
    geom_line(data = df_median, linewidth = 0.8, show.legend = FALSE) +

    geom_text_repel(
      data = df_median |> filter(n_plugins > 0 & n_plugins %% 10 == 0),
      aes(y = time, label = round(time, 1)),
      vjust = -1,
      size = 7,
      fontface = "bold",
      show.legend = FALSE
    ) +

    expand_limits(y = 0) +

    # Show solid square in legend
    scale_color_manual(values = config_type_colors) +
    guides(
      color = guide_legend(override.aes = list(shape = 15, size = 8, alpha = 1))
    ) +

    plot_theme() +
    labs(
      title = "",
      x = "Number of plugins",
      y = "Time (ms)",
      color = "Config type",
      caption = "@echasnovski"
    )
}

plot_filetype_summary <- function() {
  ggplot(
    filetype_summary,
    aes(x = n_plugins, y = median_time, color = config_type)
  ) +
    geom_point(size = 5) +
    geom_line(linewidth = 0.8, show.legend = FALSE) +

    geom_text_repel(
      data = filetype_summary |> filter(n_plugins > 0 & n_plugins %% 10 == 0),
      aes(y = median_time, label = round(median_time, 2)),
      vjust = -1,
      size = 7,
      fontface = "bold",
      show.legend = FALSE
    ) +

    expand_limits(y = 0) +

    # Show solid square in legend
    scale_color_manual(values = config_type_colors) +
    guides(
      color = guide_legend(override.aes = list(shape = 15, size = 8, alpha = 1))
    ) +

    plot_theme() +
    labs(
      title = "",
      x = "Number of plugins",
      y = "Time (ms)",
      color = "Config type",
      caption = "@echasnovski"
    )
}

save_plot <- function(plot, output) {
  showtext_opts(dpi = 96)
  ggsave(
    filename = output,
    plot = plot,
    width = 1600,
    height = 900,
    units = "px",
    dpi = 96,
    bg = bg
  )
}

# Make plots
init_plot <- plot_startup_summary("init") +
  labs(
    title = "Startup time of init.lua",
    subtitle = paste0(
      "Using many plugins results in a close to linear startup time increase",
      " with a significant slope\n",
      "Using one vim.pack.add() is faster than separate,",
      " but still much slower than a single \"bundle plugin\" "
    )
  )
save_plot(init_plot, "startup-summary_init.png")

plugin_plot <- plot_startup_summary("plugin") +
  labs(
    title = "Startup time of all plugin/ files",
    subtitle = "Increases close to linearly regardless of config type"
  )
save_plot(plugin_plot, "startup-summary_plugin.png")

total_plot <- plot_startup_summary("total") +
  labs(
    title = "Total startup time",
    subtitle = "Behaves similarly to times of init.lua"
  )
save_plot(total_plot, "startup-summary_total.png")

filetype_plot <- plot_filetype_summary() +
  labs(
    title = "Runtime overhead of setting a filetype",
    subtitle = paste0(
      "Using many plugins results in a linear increase",
      " with a significant slope\n",
      "No difference between one or separate vim.pack.add()\n",
      "Using one \"bundle plugin\" results in a constant overhead (much better)"
    )
  )
save_plot(filetype_plot, "filetype-summary.png")
