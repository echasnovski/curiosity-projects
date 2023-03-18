"""
Computation of hue leaf cusp for sRGB in Oklch color space. That is, a point which:
    - Has integer hue equal to `ceil(h)`.
    - Has maximum chroma (c) among gamut (sRGB representable colors) slice with
      same integer hue.
"""

import numpy as np
import pandas as pd

from oklab import conversion


def compute_cusps():
    # Create grid of all sRGB colors (scaled to [0;1])
    channel_colors = np.linspace(0, 1, 256)
    grid = np.array(np.meshgrid(channel_colors, channel_colors, channel_colors))
    grid = grid.reshape(3, -1)

    # Convert all colors to Oklch with correctled lightness
    oklch = conversion.rgb2oklch(grid)
    oklch[0, :] = 100 * conversion.correct_lightness(0.01 * oklch[0, :])

    # Create data frame of all colors
    colors_df = pd.DataFrame(
        np.concatenate([grid, oklch]).T, columns=["r", "g", "b", "L", "c", "h"]
    )

    # Compute cusps for all integer hues
    colors_df["hue_floor"] = colors_df.h.apply(np.floor).astype("int")
    cusps = (
        colors_df.sort_values("c", ascending=False)
        .drop_duplicates("hue_floor")
        .sort_values("hue_floor")
        .reset_index(drop=True)
    )

    # Prepare data frame and write to csv
    cusps_rgb = cusps.loc[:, ["r", "g", "b"]].to_numpy().T
    cusps["hex"] = conversion.rgb2hex(cusps_rgb)

    # # Make column names as in https://bottosson.github.io/misc/colorpicker/
    cusps["L_r"] = cusps["L"]
    cusps["L"] = conversion.correct_lightness_inv(cusps["L_r"].to_numpy())

    cusps.loc[:, ["L", "L_r", "c", "h"]] = cusps.loc[:, ["L", "L_r", "c", "h"]].round(
        decimals=2
    )
    return cusps.loc[:, ["hue_floor", "hex", "L", "L_r", "c", "h"]]


def main():
    print("Computing cusps")
    cusps = compute_cusps()

    print("Saving cusps")
    cusps.to_csv("cusps.csv", index=False)


if __name__ == "__main__":
    main()
