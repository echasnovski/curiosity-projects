import numpy as np
import matplotlib.pyplot as plt
import librosa


audio_file = "ttd-audio_sample.wav"

# Load audio with its sample rate
audio, sample_rate = librosa.load(audio_file)
audio_length = len(audio) / sample_rate
times = np.linspace(0.0, audio_length, len(audio))

# One can plot the whole audio, but it is very big to handle, so demonstrate
# only first ten seconds
first_10_sec = slice(0, sample_rate * 10)
plt.plot(times[first_10_sec], audio[first_10_sec])

# Rough, but fast estimate of bounce time can be done by detecting onset
# ("beginning of a musical note or other sound")
audio_onset = librosa.onset.onset_detect(audio, sample_rate, units="time")
print(audio_onset)

# More accurate bounce detection can be done with "beat detection", as ball
# bounces have distinctive sounds and Dan hardly speaks during whole video.
# Here `tempo` is average tempo of beats and `beats` is detected timestamps of
# "beats" which here is ball bounces.
tempo, beats = librosa.beat.beat_track(audio, sample_rate, start_bpm=180, units="time")
print(tempo, beats)


# How tempo changed over time
def compute_instant_tempo(beats):
    """Instantaneous tempo of beats

    Computation is done by inversing "local" period in seconds and converting
    into standard "beats per minute". "Local" period is computed by averaging
    two differences between three consecutive beat timestamps. For first and
    last beats first and last differences are taken.
    """
    beat_diff = np.diff(beats)
    local_period = 0.5 * (beat_diff[:-1] + beat_diff[1:])
    instant_tempo = 60 / local_period
    edge_tempo = 60 / beat_diff[[0, -1]]

    return np.concatenate([[edge_tempo[0]], instant_tempo, [edge_tempo[1]]])


instant_tempo = compute_instant_tempo(beats)
plt.plot(beats, instant_tempo)
