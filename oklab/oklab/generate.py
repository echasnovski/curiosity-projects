"""
Generate data related to Oklab/Oklch color space:

- Hue leaf cusps for sRGB in Oklch color space. That is, points which:
    - Have integer hue equal to `ceil(h)`.
    - Have maximum chroma (c) among gamut (sRGB representable colors) slice with
      same integer hue.
- Colors which are outside of a simplified model for gamut: triangle with
  vertices at (0; 0), (0; 100), and cusp **inside hue leaf in (c, L) = (x, y)
  coordinates** and **for uncorrected lightness**:
    - Equation for lower segment (between (0; 0) and cusp): y * c_cusp = x * L_cusp
    - Equation for upper segment (between (0; 100) and cusp):
      (100 - y) * c_cusp = x * (100 - L_cusp)
"""

import numpy as np
import pandas as pd

from oklab import conversion


def generate_all_colors():
    # Create grid of all sRGB colors (scaled to [0;1])
    channel_colors = np.linspace(0, 1, 256)
    grid = np.array(np.meshgrid(channel_colors, channel_colors, channel_colors))
    grid = grid.reshape(3, -1)

    # Convert all colors to Oklch with correctled lightness
    oklch = conversion.rgb2oklch(grid)
    oklch[0:2, :] = 100 * oklch[0:2, :]

    colors = pd.DataFrame(
        np.concatenate([grid, oklch]).T, columns=["r", "g", "b", "L", "c", "h"]
    )
    colors["hue_floor"] = colors.h.apply(np.floor).astype("int")

    return colors


def compute_cusp_data(colors):
    # Compute cusps for all integer hues
    cusps = (
        colors.sort_values("c", ascending=False)
        .drop_duplicates("hue_floor")
        .sort_values("hue_floor")
        .reset_index(drop=True)
    )

    # Prepare data for output and return
    cusps_rgb = cusps.loc[:, ["r", "g", "b"]].to_numpy().T
    cusps["hex"] = conversion.rgb2hex(cusps_rgb)
    cusps["L_r"] = conversion.correct_lightness(cusps["L"].to_numpy())
    cusps.loc[:, ["L", "L_r", "c", "h"]] = cusps.loc[:, ["L", "L_r", "c", "h"]].round(
        decimals=2
    )
    return cusps.loc[:, ["hue_floor", "hex", "L", "L_r", "c", "h"]]


def compute_colors_outside_triangle(colors, cusps):
    cusps_right = cusps.loc[:, ["hue_floor", "L", "c"]].rename(
        columns={"L": "L_cusp", "c": "c_cusp"}
    )
    c = colors.merge(cusps_right, how="left")

    # Range of allowed `L` is computed based on its current `c`:
    # - Lower is from segment between (0, 0) and cusp.
    # - Upper is from segment between (0, 100) and cusp.
    saturation = c["c"] / c["c_cusp"]
    c["L_lower"] = saturation * c["L_cusp"]
    c["L_upper"] = saturation * (c["L_cusp"] - 100) + 100

    # Maximum allowed `c` is computed based on its currnet `L` and depends on
    # whether `L` is below or above `L_cusp`:
    # - If below, then it is from lower triangle segment.
    # - If above - from upper segment.
    c["c_upper"] = np.where(
        c["L"] <= c["L_cusp"],
        c["c_cusp"] * c["L"] / c["L_cusp"],
        c["c_cusp"] * (100 - c["L"]) / (100 - c["L_cusp"]),
    )

    # Compute if outside of triangle. Round prior to computing condition to
    # avoid very small light differences.
    c.loc[:, ["L", "L_lower", "L_upper", "c", "c_upper"]] = c.loc[
        :, ["L", "L_lower", "L_upper", "c", "c_upper"]
    ].round(decimals=2)
    is_outside = ((c["L"]) < c["L_lower"]) | (c["L_upper"] < (c["L"]))
    outside_triang = c.loc[is_outside, :].copy()

    is_below = outside_triang["L"] < outside_triang["L_lower"]
    l_outside = np.where(
        is_below,
        outside_triang["L_lower"] - outside_triang["L"],
        outside_triang["L"] - outside_triang["L_upper"],
    )
    outside_triang["L_outside"] = np.round(l_outside, decimals=2)

    # Compute the closest hex color from modeled range
    # NOTE: this is not entirely accurate as data is rounded to 2 decimal places
    l_modeled = np.where(is_below, outside_triang["L_lower"], outside_triang["L_upper"])
    lch = np.concatenate(
        [np.atleast_2d(l_modeled), outside_triang.loc[:, ["c", "h"]].to_numpy().T]
    )
    outside_triang["hex_modeled"] = conversion.oklch2hex(lch, correct_l=False)

    # Prepare output data and return
    rgb = outside_triang.loc[:, ["r", "g", "b"]].to_numpy().T
    outside_triang["hex"] = conversion.rgb2hex(rgb)
    return outside_triang.loc[
        :, ["hue_floor", "hex", "hex_modeled", "L", "L_lower", "L_upper", "c", "c_upper", "L_outside"]
    ].sort_values("L_outside", ascending=False)


def main():
    print("Generating all colors")
    colors = generate_all_colors()

    # Cusps
    print("Computing cusps")
    cusps = compute_cusp_data(colors)

    print("Saving cusps")
    cusps.to_csv("cusps.csv", index=False)

    # Colors outside of triangle
    print("Computing colors outside of triangle")
    colors_outside_triangle = compute_colors_outside_triangle(colors, cusps)

    print("Saving colors outside of triangle")
    colors_outside_triangle.to_csv("colors_outside_triangle.csv", index=False)


if __name__ == "__main__":
    main()
