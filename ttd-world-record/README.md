# TTD World Record

On May 7th, 2020, Dan Ives (founder of TableTennisDaily) did a live Youtube broadcast with him breaking world record for the "longest duration to control a table tennis ball with a bat". Previous record was [5 hours, 2 minutes, 37 seconds](https://www.guinnessworldrecords.com/world-records/table-tennis-bat-and-ball-control-duration?fb_comment_id=784092958310554_1433556316697545), while Dan's was (preliminary) **5 hours, 21 minutes, 4 seconds**. There is a [Youtube video](https://www.youtube.com/watch?v=nkgzLeNocb0) of him actually doing it.

However, even if total time is known, I would like to know the characteristics of bounces he did: total number, total and instantaneous bounce tempo (in "bounces per minute"), and so on. **And thus the quest begins**.

## Solution

The idea of solution is straightforward: somehow get audio from the world record video, detect bounces (as they have distinctive sound) and count them.

You'll need the following tools, which were applied on Ubuntu 18.04 (in order of their usage; Python packages probably best to be installed in a separate environment):

- Python.
- [you-get](https://github.com/soimort/you-get) to download video with the lowest video quality.
- [ffmpeg](https://www.ffmpeg.org/) to extract audio from downloaded video.
- [librosa](https://github.com/librosa/librosa) to detect beats.

During execution of this solution **all downloaded data should be considered as for personal use only**.

Almost each step takes considerable amount of time and RAM to complete.

### Get audio

- **Download video**. You'll only need audio, so the lowest video quality should be enough. I did it with 'you-get' in terminal (**Note** that it will download 407.4 MiB of video in file 'ttd-world-record.mpy'). Execution time depends on your internet connection speed and Youtube's speed capabilities:

```bash
    you-get --itag=160 https://www.youtube.com/watch?v=nkgzLeNocb0 --output-filename='ttd-world-record'
```

- **Extract audio**. I did it with 'ffmpeg' in terminal (**Note** that this will produce 294.3 MiB file 'ttd-world-record_audio.mp3'):

```bash
    ffmpeg -i ttd-world-record.mp4 -vn ttd-world-record_audio.mp3
```

### Detect bounces

- **Split audio by time**. Analyzing ~300 MiB audio file will require much RAM, so to handle this, split audio into consecutive chunks by 3600 seconds (60 minutes). This will produce files 'ttd-world-record_audio000.mp3', 'ttd-world-record_audio001.mp3', and so on up until 'ttd-world-record_audio010.mp3', where '00i' indicates the index in sequence. **Note** that this will introduce some missed bounces on the joints of audio files:

```bash
    ffmpeg -i ttd-world-record_audio.mp3 -f segment -segment_time 3600 -c copy ttd-world-record_audio%03d.mp3
```

- **Run 'create-beats.py'**. Bounces in this audio has nature very similar to regular song beats, so a beat detection algorithm was used. Runngin file 'create-beats.py' produces 'ttd-world-record_beats.csv' file with timestamps of bounces (i.e. beats in interval from 00:01:14 to 05:20:15) in 'ttd-world-record_audio.mp3' file. **Note** that this is time consuming step (probably around 10 minutes using 1 core). Currently it produces warnings due to 'librosa' intended reading behavior (see [this issue](https://github.com/librosa/librosa/issues/1015)), so `-W ignore` flag is added:

```bash
    python -W ignore create-beats.py
```

- **Manually delete intermediate files** (identified by all having common pattern "audio[0-9]"):

```bash
    rm *audio[0-9]*
```

### Count bounces

So the total number of **detected** bounces is 49923 with an average tempo of ~156.5 bounces per minute.

However, YouTube footage is not a "preshot and uploaded" one, but is a direct result of live stream. This resulted into some missing footage. Total time of record based on footage is
5h19m1s (from 00:01:14 to 05:20:15 video timestamps). However, tablet shows
total time of 5h21m4s (from 00:00:03 to 05:21:07 at corresponding video
timestamps). So there is missing 2m3s. They were results of video jumps due to, probably, internet connection issues (I encourage everyone to believe in Dan's honesty):

- [From 02:32:24 to 02:32:25](https://youtu.be/nkgzLeNocb0?t=9144) in footage time there is a jump in "tablet
  time" from 02:31:13 to 02:31:24. This is a gap of 10 seconds.
- [From 02:32:41 to 02:32:42](https://youtu.be/nkgzLeNocb0?t=9161) - tablet jumps from 02:31:41 to 02:32:12. Gap of 30 seconds.
- [From 02:49:17 to 02:49:18](https://youtu.be/nkgzLeNocb0?t=10157) - tablet jumps from 02:48:48 to 02:48:59. Gap of 10 seconds.
- [From 02:49:29 to 02:49:30](https://youtu.be/nkgzLeNocb0?t=10169) - tablet jumps from 02:49:10 to 02:49:41. Gap of 30 seconds.
- [From 02:55:29 to 02:55:30](https://youtu.be/nkgzLeNocb0?t=10529) - tablet jumps from 02:55:41 to 02:55:52. Gap of 10 seconds.
- [From 02:55:37 to 02:55:38](https://youtu.be/nkgzLeNocb0?t=10537) - tablet jumps from 02:55:59 to 02:56:30. Gap of 30 seconds.
- The rest 3 seconds seems to be the result of my roundings and possibly some very small jumps.

Close video timestamps and systematic length of jumps are another indicators of internet connection issues.

Knowing that there is 2m3s of footage missing and that average tempo was ~156.5 bounces per minute, we can add 321 bounces to detected ones.

Finally, the **total number of bounces in Dan Ives world record can be estimated as 50244 bounces** (error should be less than 100 bounces for sure). **And thus the quest ends**.
