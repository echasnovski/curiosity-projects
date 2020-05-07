# TTD World Record

On May 7th, 2020, Dan Ives (founder of TableTennisDaily) did a live Youtube broadcast with him breaking world record for the "longest duration to control a table tennis ball with a bat". Previous record was [5 hours, 2 minutes, 37 seconds](https://www.guinnessworldrecords.com/world-records/table-tennis-bat-and-ball-control-duration?fb_comment_id=784092958310554_1433556316697545), while Dan's was (preliminary) **5 hours, 21 minutes, 7 seconds**. There is a [Youtube video](https://www.youtube.com/watch?v=nkgzLeNocb0) of him actually doing it.

However, even if total time is known, I would like to know the characteristics of bounces he did: total number, total and instantaneous bounce tempo (in "bounces per minute"), and so on. And thus the quest began.

## Solution

The idea of solution is straightforward: somehow extract audio from the world record video, detect bounces (as they have distinctive sound and 

You'll need the following tools (in order of their usage; probably best installed in separate environment for all Python packages):

- Python.
- [you-get](https://github.com/soimort/you-get) to download video with the lowest video quality.
- [ffmpeg](https://www.ffmpeg.org/) to extract audio from downloaded video.
- [librosa](https://github.com/librosa/librosa) to detect beats.
