"""
Conversion functions between color spaces: HEX <-> sRGB ([0;1]) <-> Oklab <-> Oklch

Notes:
- Coversions HEX <-> Oklab and HEX <-> Oklch produce coordinates in range [0; 100]
  and can conditionally correct lightness (`True` by default).
- Coversions sRGB <-> Oklab and sRGB <-> Oklch produce coordinates in range [0; 1].
"""
import numpy as np
from numpy.typing import ArrayLike, NDArray


# HEX <-> Oklch
def hex2oklch(hex: ArrayLike, correct_l: bool = True) -> NDArray:
    res = rgb2oklch(hex2rgb(hex))
    res[0:2, :] = 100 * res[0:2, :]
    if correct_l:
        res[0, :] = correct_lightness(res[0, :])
    return res


def oklch2hex(oklch: NDArray, correct_l: bool = True) -> NDArray:
    if correct_l:
        oklch[0, :] = correct_lightness_inv(oklch[0, :])
    oklch[0:2, :] = 0.01 * oklch[0:2, :]
    return rgb2hex(oklch2rgb(oklch))


# HEX <-> Oklab
def hex2oklab(hex: ArrayLike, correct_l: bool = True) -> NDArray:
    res = 100 * rgb2oklab(hex2rgb(hex))
    if correct_l:
        res[0, :] = correct_lightness(res[0, :])
    return res


def oklab2hex(oklab: NDArray, correct_l: bool = True) -> NDArray:
    if correct_l:
        oklab[0, :] = correct_lightness_inv(oklab[0, :])
    return rgb2hex(oklab2rgb(0.01 * oklab))


# HEX <-> RGB in [0;1]
def hex2rgb(hex: ArrayLike) -> NDArray:
    hex = np.atleast_1d(np.array(hex))
    hex = np.char.replace(hex, "#", "")

    dec = np.array([int(h, base=16) for h in hex])
    b = dec % 256
    g = ((dec - b) / 256) % 256
    r = np.floor(dec / 65536)
    # Each color stored as column for more natural matrix multiplication
    return np.array([r / 255, g / 255, b / 255])


def rgb2hex(rgb: NDArray) -> NDArray:
    rgb = np.array(rgb)
    # Use clamp gamut clipping here. Modify `rgb` prior for a better outcome.
    c = np.clip(np.round(255 * rgb), 0, 255).astype("int")

    return np.apply_along_axis(lambda x: f"#{x[0]:02x}{x[1]:02x}{x[2]:02x}", 0, c)


# Conversion matrices
conversion_matricies: dict = {}

conversion_matricies["linrgb2lms"] = np.array(
    [
        [0.4122214708, 0.5363325363, 0.0514459929],
        [0.2119034982, 0.6806995451, 0.1073969566],
        [0.0883024619, 0.2817188376, 0.6299787005],
    ]
)

conversion_matricies["cbrtlms2oklab"] = np.array(
    [
        [+0.2104542553, +0.7936177850, -0.0040720468],
        [+1.9779984951, -2.4285922050, +0.4505937099],
        [+0.0259040371, +0.7827717662, -0.8086757660],
    ]
)

conversion_matricies["oklab2cbrtlms"] = np.array(
    [
        [+1.0, +0.3963377774, +0.2158037573],
        [+1.0, -0.1055613458, -0.0638541728],
        [+1.0, -0.0894841775, -1.2914855480],
    ]
)

conversion_matricies["lms2linrgb"] = np.array(
    [
        [+4.0767416621, -3.3077115913, +0.2309699292],
        [-1.2684380046, +2.6097574011, -0.3413193965],
        [-0.0041960863, -0.7034186147, +1.7076147010],
    ]
)


# RGB in [0;1] <-> Oklab
def rgb2oklab(rgb: NDArray) -> NDArray:
    linrgb = rgb2linrgb(rgb)
    lms = np.matmul(conversion_matricies["linrgb2lms"], linrgb)
    cbrtlms = np.cbrt(lms)
    res = np.matmul(conversion_matricies["cbrtlms2oklab"], cbrtlms)

    # Explicitly convert gray colors
    is_gray = (np.abs(res[1:3, :]) < 1e-5).all(axis=0)
    res[1:3, np.nonzero(is_gray)] = 0

    return res


def oklab2rgb(oklab: NDArray) -> NDArray:
    cbrtlms = np.matmul(conversion_matricies["oklab2cbrtlms"], oklab)
    lms = cbrtlms**3
    linrgb = np.matmul(conversion_matricies["lms2linrgb"], lms)
    return linrgb2rgb(linrgb)


def rgb2linrgb(rgb: NDArray) -> NDArray:
    rgb = np.clip(rgb, 0, 1)
    return np.where(0.04045 < rgb, np.power((rgb + 0.055) / 1.055, 2.4), rgb / 12.92)


def linrgb2rgb(linrgb: NDArray) -> NDArray:
    linrgb = np.clip(linrgb, 0, 1)
    return np.where(
        0.0031308 >= linrgb,
        12.92 * linrgb,
        1.055 * np.power(linrgb, 0.416666667) - 0.055,
    )


# RGB in [0;1] <-> Oklch
def rgb2oklch(rgb: NDArray) -> NDArray:
    oklab = rgb2oklab(rgb=rgb)
    l, a, b = oklab[0, :], oklab[1, :], oklab[2, :]
    c = np.sqrt(a**2 + b**2)
    h = np.arctan2(b, a)
    return np.array([l, c, np.rad2deg(h) % 360])


def oklch2rgb(oklch: NDArray) -> NDArray:
    l, c, h = oklch[0, :], oklch[1, :], np.deg2rad(oklch[2, :] % 360)
    a = c * np.cos(h)
    b = c * np.sin(h)
    return oklab2rgb(np.array([l, a, b]))


# Source:
# https://bottosson.github.io/posts/colorpicker/#intermission---a-new-lightness-estimate-for-oklab
# Assume both input and output in range [0; 100] instead of [0; 1]
def correct_lightness(x: NDArray) -> NDArray:
    x = 0.01 * x
    k_1, k_2 = 0.206, 0.03
    k_3 = (1 + k_1) / (1 + k_2)

    res = 0.5 * (k_3 * x - k_1 + np.sqrt((k_3 * x - k_1) ** 2 + 4 * k_2 * k_3 * x))
    return 100 * res


def correct_lightness_inv(x: NDArray) -> NDArray:
    x = 0.01 * x
    k_1, k_2 = 0.206, 0.03
    k_3 = (1 + k_1) / (1 + k_2)
    res = x * (x + k_1) / (k_3 * (x + k_2))
    return 100 * res
