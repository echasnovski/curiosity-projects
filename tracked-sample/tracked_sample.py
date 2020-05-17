import random


class TrackedSample:
    """Tracked random sampling

    This implements sampling in which elements that can be sampled are
    "tracked" in terms of ordering "from most to least recently used". Elements
    ordered in that way is called "sampling pool" or just "pool".

    Drawing elements from a pool is an iterative (per single draw) procedure.
    One draw is done in the following way:
    - Sample with supplied `weights` single index inside a pool.
    - Extract element from pool at that index, which will be returned as
      desired draw.
    - Put this element **at the beginning** of the pool.

    Properties:
    - `pool` : Current state of sampling pool.
    - `weights` : Weights of pool indices.

    Public methods:
    - `draw()` : Draw `size` elements from current pool. Note that this affects
      the state of the pool.
    """

    def __init__(self, x, weights=None, preshuffle=True):
        """Initialize tracked random sampling object

        Parameters
        ----------
        x : Collection as a valid input to `list()`.
            Represents elements, from which samples should be drawn.
        weights : As `weights` argument in `random.choices()`, optional
            Weights of pool indices. `None` is treated as equal weights of
            necessary length.
        preshuffle : bool, optional
            Whether to shuffle a pool once during creation. Useful if input is
            in no particular order and there is a need to start random sampling
            right away (the most common situation).
        """
        self._pool = list(x)
        if preshuffle:
            random.shuffle(self._pool)

        self._inds = list(range(len(x)))

        # For future, it can be useful for `weights` to be a function that is
        # applied to current pool before each draw. For example, this enables
        # usage "Don't sample recent `k` items and sample rest with probability
        # proportional to items' lengths". This will introduce significant
        # overhead, though.
        self._weights = weights

    @property
    def pool(self):
        return self._pool

    @property
    def weights(self):
        return self._weights

    def _pop(self, index):
        """Return item at index and place it at the beginning"""
        res = self._pool.pop(index)
        self._pool.insert(0, res)
        return res

    def draw(self, size=1):
        """Draw sample

        Draw sample based on the following algorithm:
        - Randomly sample with supplied `weights` an index of the current pool,
          at which element will be drawn.
        - "Pop" this element from the pool: extract it, put at the beginning of
          the pool, and return it.
        - Repeat.

        Parameters
        ----------
        size : int, optional
            Size of sample to draw, by default 1

        Returns
        -------
        draw : list
            List of drawn elements
        """
        inds = random.choices(self._inds, weights=self._weights, k=size)
        return [self._pop(i) for i in inds]

    def __str__(self):
        return (
            "Tracked sampling object with current pool "
            "(from most to least recently drawn):\n"
            f"{self._pool}"
        )
