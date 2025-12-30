library(tidyverse)
library(stringr)

format_percent <- scales::percent_format(accuracy = 0.1)

# A "year-log" file is the result of the following steps:
# - `git log --format="%h%x09%aN%x09%as%x09%s" --no-merges --since=2025-01-01 --shortstat > year-log`
# - Inside Neovim execute `:%s/\n\n \ze\d\+ file/\t`
# - Add column names: hash	author	date	title	shortstat
df <- read_tsv("year-log") |>
  mutate(
    commit_type = tolower(str_match(title, "^[^ (:!]+")[, 1]),
    n_insert = as.integer(str_match(shortstat, "([0-9]+) insertion")[, 2]),
    n_delete = as.integer(str_match(shortstat, "([0-9]+) deletion")[, 2]),
    n_insert = coalesce(n_insert, 0),
    n_delete = coalesce(n_delete, 0),
  )

# Total number of commits
nrow(df)

# Summary of commit types
df |>
  count(commit_type) |>
  mutate(share = format_percent(n / sum(n))) |>
  arrange(desc(n)) |>
  slice_head(n = 10)

# Total commit authors
df |> count(author) |> nrow()

# Top authors (total and without Vim patches) with at least 10 commits
top_authors <- . %>%
  mutate(share = format_percent(n / sum(n))) |>
  filter(n >= 10) %>%
  arrange(desc(n)) %>%
  print(n = Inf)

df |> count(author) |> top_authors()
df |> count(author, commit_type) |> top_authors()

# Biggest code addition and removal
df |>
  filter(n_insert - n_delete >= 1000) |>
  arrange(desc(n_insert - n_delete)) |>
  select(hash, author, title, n_insert, n_delete)

df |>
  filter(n_delete - n_insert >= 1000) |>
  arrange(desc(n_delete - n_insert)) |>
  select(hash, author, title, n_insert, n_delete)

# Extreme diff stat per author
df |>
  group_by(author, commit_type) |>
  summarise(diff_balance = sum(n_insert - n_delete), n_commits = n()) |>
  filter(n_commits >= 10) |>
  arrange(desc(diff_balance)) |>
  print(n = Inf)

# Activity per month
df |> transmute(month = month(date, label = TRUE, abbr = FALSE)) |> count(month)

# Get the numbers of: changed files, lines added, lines deleted:
# - Get "from" and "to" commits from 'year-log' as earliest and latest commits.
# - Compute: `git diff --shortstat <from-sha>..<to-sha>`
