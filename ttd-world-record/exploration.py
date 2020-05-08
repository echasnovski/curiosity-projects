import numpy as np
from scipy.ndimage.filters import uniform_filter1d
import matplotlib.pyplot as plt

beats = np.loadtxt("ttd-world-record_beats.csv", delimiter=",")

# How tempo changed over time
def compute_instant_tempo(beats, n=5):
    """Instantaneous tempo of beats

    Computation is done by inversing "local" period in seconds and converting
    into standard "beats per minute". "Local" period is computed by averaging
    two differences between three consecutive beat timestamps. For first and
    last beats first and last differences are taken.
    """
    beat_diff = np.diff(beats)
    local_period = uniform_filter1d(beat_diff, size=n)
    # local_period = 0.5 * (beat_diff[:-1] + beat_diff[1:])
    instant_tempo = 60 / local_period
    start_tempo = 60 / beat_diff[0]

    return np.concatenate([[start_tempo], instant_tempo])


def sec_to_time(x):
    hours = x // 3600
    mins = (x - 3600 * hours) // 60
    secs = x - 3600 * hours - 60 * mins

    return list(zip(hours, mins, secs))


print(f"Total number of detected beats: {len(beats)}")

duration_minutes = (beats[-1] - beats[0]) / 60
avg_bpm = len(beats) / duration_minutes
print(f"Average bounes per minute: {avg_bpm}")

plt.plot(beats, compute_instant_tempo(beats, n=61))
plt.show()

# There is some missing footage. Total time of record based on footage is
# 5h19m1s (from 00:01:14 to 05:20:15 video timestamps). However, tablet shows
# total time of 5h21m4s (from 00:00:03 to 05:21:07 at corresponding video
# timestamps). So there is missing 2m3s. Some noticable moments on the video:
# - From 02:32:24 to 02:32:25 in footage time there is a jump in "tablet
#   time" from 02:31:13 to 02:31:24. This is a gap of 10 seconds.
# - From 02:32:40 to 02:32:41 in footage time - jump from 02:31:41 to 02:32:12.
#   Gap of 30 seconds.
# - From 02:49:17 to 02:49:18 in footage time - jump from 02:48:48 to 02:48:59.
#   Gap of 10 seconds.
# - From 02:49:29 to 02:49:30 in footage time - jump from 02:49:10 to 02:49:41.
#   Gap of 30 seconds.
# - From 02:55:29 to 02:55:30 in footage time - jump from 02:55:41 to 02:55:52.
#   Gap of 10 seconds.
# - From 02:55:37 to 02:55:38 in footage time - jump from 02:55:59 to 02:56:30.
#   Gap of 30 seconds.
# - The rest 3 seconds seems to be the result of my roundings and possibly some
#   very small jumps.
