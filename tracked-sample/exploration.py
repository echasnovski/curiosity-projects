import random
import numpy as np

from tracked_sample import TrackedSample


def count_period_repeats(x, periods=[1]):
    x = np.asarray(x)
    return {st: np.sum(x[:-st] == x[st:]) for st in periods}


np.random.seed(101)

x = list(range(10))
n_sample = 10000
n_recent = 3

# `n_recent` most recently drawn elements won't be drawn
not_n_recent_weights = [0] * n_recent + [1] * (len(x) - n_recent)
not_n_recent = TrackedSample(x, not_n_recent_weights)

rand_draw_not_n_recent = np.array(not_n_recent.draw(n_sample))
print(np.bincount(rand_draw_not_n_recent))
## First `n_recent` periods should have 0 repeats
print(count_period_repeats(rand_draw_not_n_recent, periods=range(1, 11)))

# `n_recent` most recently drawn elements won't be drawn AND the recent -
# following "human logic" (the least recently drawn element will have bigger
# probability to be chosen)
not_n_recent_human_weights = [0] * n_recent + list(range(1, len(x) - n_recent + 1))
not_n_recent_human = TrackedSample(x, not_n_recent_human_weights)

rand_draw_not_n_recent_human = np.array(not_n_recent_human.draw(n_sample))
print(np.bincount(rand_draw_not_n_recent_human))
## First `n_recent` periods should have 0 repeats and it should grow linearly
## for some time
print(count_period_repeats(rand_draw_not_n_recent_human, periods=range(1, 11)))
