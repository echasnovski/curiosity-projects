# TTD World Record

On May 7th, 2020, Dan Ives (founder of TableTennisDaily) did a live Youtube broadcast with him breaking world record for the "longest duration to control a table tennis ball with a bat". Previous record was [5 hours, 2 minutes, 37 seconds](https://www.guinnessworldrecords.com/world-records/table-tennis-bat-and-ball-control-duration?fb_comment_id=784092958310554_1433556316697545), while Dan's was (preliminary) **5 hours, 21 minutes, 4 seconds**. There is a [Youtube video](https://www.youtube.com/watch?v=nkgzLeNocb0) of him actually doing it.

However, even if total time is known, I would like to know the characteristics of bounces he did: total number, total and instantaneous bounce tempo (in "bounces per minute"), and so on. And thus the quest began.

## Solution

The idea of solution is straightforward: somehow extract audio from the world record video, detect bounces (as they have distinctive sound and 

You'll need the following tools (in order of their usage; probably best installed in separate environment for all Python packages):

- Python.
- [you-get](https://github.com/soimort/you-get) to download video with the lowest video quality.
- [ffmpeg](https://www.ffmpeg.org/) to extract audio from downloaded video.
- [librosa](https://github.com/librosa/librosa) to detect beats.

During execution of this solution **all downloaded data should be considered as for personal use only**.

Steps (each step takes considerable amount of time to complete):

- **Download video**. You'll only need audio, so the lowest video quality should be enough. I did it with 'you-get' in terminal (**Note** that it will download 407.4 MiB of video in file 'ttd-world-record.mpy'). Execution time depends on your internet connection speed and Youtube's speed capabilities:

    you-get --itag=160 https://www.youtube.com/watch?v=nkgzLeNocb0 --output-filename='ttd-world-record'

- **Extract audio**. I did it with 'ffmpeg' in terminal (**Note** that this will produce 294.3 MiB file 'ttd-world-record_audio.mp3'):

    ffmpeg -i ttd-world-record.mp4 -vn ttd-world-record_audio.mp3

- **Split audio by time**. Analyzing ~300 MiB audio file will require much RAM, so to handle this, split audio into consecutive chunks by 3600 seconds (60 minutes). This will produce files 'ttd-world-record_audio000.mp3', 'ttd-world-record_audio001.mp3', and so on up until 'ttd-world-record_audio010.mp3', where '00i' indicates the index in sequence. **Note** that this will introduce some missed bounces on the joints of audio files:

    ffmpeg -i ttd-world-record_audio.mp3 -f segment -segment_time 3600 -c copy ttd-world-record_audio%03d.mp3

- **Run 'create-beats.py'**. This file produces 'ttd-world-record_beats.csv' file with timestamps of beats in 'ttd-world-record_audio.mp3' file. **Note** that this is time consuming step (probably around 10 minutes using 1 core). Currently it produces warnings due to 'librosa' intended reading behavior (https://github.com/librosa/librosa/issues/1015), so `-W ignore` flag is added:

    python -W ignore create-beats.py

- **Manually delete intermediate files** (identified by all having common pattern "audio[0-9]"):

    rm *audio[0-9]*
