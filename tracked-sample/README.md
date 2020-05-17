# Tracked random sampling

This directory contains implementation and exploration of "Tracked random sampling", in which result of the next random draw can depend on how long ago in the past element was drawn. In other words, elements that can be sampled are "tracked" in terms of ordering "from most to least recently used" (from the "was just drawn" one to "was drawn a long time ago" one).

Elements ordered "from most to least recently used" is called "sampling pool" or just "pool". What makes `TrackedSample` useful is that sampling is done iteratively (per every draw) using supplied pool indices weights:

- Sample with supplied `weights` single index of a current pool.
- Extract element from pool at that index, which will be returned as next draw.
- Put this element **at the beginning** of the pool (as it is now "the most recently drawn").
- Repeat necessary number of times.

## Usage

Use 'tracked_sample.py' file as a module for `TrackedSample` class.

## Examples

```python
import random
from tracked_sample import TrackedSample

random.seed(101)

x = list(range(1, 11))

# Sampling based on "human intuition": "least recently drawn elements are more
# likely to be drawn":
human_intuition = TrackedSample(x, weights=list(range(1, 11)))
## Draws are perceived as "less likely to repeat"
human_intuition.draw(25)
#> [10, 1, 6, 3, 2, 10, 6, 8, 5, 2, 9, 6, 7, 10, 6, 8, 9, 3, 5, 10, 4, 9, 2, 5, 9]

# Sampling with equal probability but do not repeat the previous draw
sample_not_recent = TrackedSample(x, weights=[0] + [1] * (len(x) - 1))
## No element is drawn twice in a row
sample_not_recent.draw(size=25)
#> [8, 4, 5, 8, 5, 4, 5, 8, 2, 9, 4, 6, 5, 8, 1, 6, 3, 2, 9, 2, 9, 2, 1, 7, 4]

# Get current state of sampling pool
sample_not_recent.pool
#> [4, 7, 1, 2, 9, 3, 6, 8, 5, 10]
```
