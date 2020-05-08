import os
import glob

import numpy as np
import librosa

# Detect splitted audio files
audio_files = glob.glob("ttd-world-record_audio[0-9][0-9][0-9].mp3")
audio_files.sort()

# Audio material in seconds each audio file (except possibly last) contains
# Needed to correctly produce beat timestamps relative to whole audio
# This should be the same value as in `-segment_time` option to `ffmpeg`
# splitting call
# split_period = 1800
split_period = 3600

for i, file in enumerate(audio_files):
    print(f"Processing {file}")

    # Load audio with its sample rate
    print(f"  Loading audio file")
    audio, sample_rate = librosa.load(file)

    # # One can plot the whole audio, but it is very big to handle, so demonstrate
    # # only first ten seconds
    # audio_length = len(audio) / sample_rate
    # times = np.linspace(0.0, audio_length, len(audio)) + i*split_period
    # first_10_sec = slice(0, sample_rate * 10)
    # plt.plot(times[first_10_sec], audio[first_10_sec])

    # # Rough, but fast estimate of bounce time can be done by detecting onset
    # # ("beginning of a musical note or other sound")
    # audio_onset = librosa.onset.onset_detect(audio, sample_rate, units="time")
    # print(audio_onset)

    # More accurate bounce detection can be done with "beat detection", as ball
    # bounces have distinctive sounds and Dan hardly speaks during whole video.
    # Here `tempo` is average tempo of beats and `beats` is detected timestamps of
    # "beats" which here is ball bounces.
    print(f"  Detecting beats")
    tempo, beats = librosa.beat.beat_track(
        audio, sample_rate, start_bpm=160, units="time"
    )
    ## Shift beat timing by "global" timestamp of audio start
    beats = beats + split_period * i
    ## Round to milliseconds
    beats = np.round(beats, decimals=3)
    ## Save beats
    audio_name = os.path.splitext(file)[0]
    beats_file = f"{audio_name}_beats.csv"
    np.savetxt(beats_file, beats, fmt="%.3f", delimiter=",")

# Produce a single beats file
beats_files = glob.glob("*audio[0-9][0-9][0-9]_beats.csv")
beats = np.concatenate([np.loadtxt(f, delimiter=",") for f in beats_files])
beats = np.sort(beats)

# Filter only those beats that were detected during actual ball bouncing, which
# starts at 74th second (00:01:14) of 'ttd-world-record_audio.mp3' file and
# ends at 19215th (05:20:15)
beats = beats[(beats >= 74) & (beats <= 19215)]

# Save beats
np.savetxt("ttd-world-record_beats.csv", beats, fmt="%.3f", delimiter=",")
