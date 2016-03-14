SDCRender & InternetArchive Upload Tools
========================================

Overview
--------

This project contains a collection of scripts to help render the
entries of The Soundevotion Competition (sdcompo.com) and upload them
to The Internet Archive (archive.org).

Requirements
------------

- Bash (tested on 4.2)

- FLAC (1.3.0 has actually a bug and crashes at some point, I've been
  using the development version as of 6 Oct 2014)

  ```
  git clone https://git.xiph.org/flac.git
  ```

- Git

- Python 2.7

- Wine (tested on 1.6.1)

- Renoise Windows versions (all versions covering the rounds you need
  to render)

- Other possibly trackers like Psycle, Schism, depending on what round
  you want to render

- All plugins corresponding to the samplepacks of the rounds to render

- A custom version of ia-wrapper, install it as follow:

```
$ git clone https://github.com/ngeiswei/ia-wrapper.git
$ cd ia-wrapper
$ sudo python setup.py install
```

Preparation
-----------

1. Clone this project

    ```
    git clone https://github.com/ngeiswei/sdcompo.git
    cd sdcompo
    ```

2. Download the entries from the ftp

    ```
    mkdir entries
    cd entries
    wget --no-host-directories -r --user=USER --password=PASS ftp://sdcompo.com/round{LOW_RND..UP_RND}
    cd ..
    ```

    where LOW_RND and UP_RND is the closed interval of rounds to
    download. You're supposed to know what USER and PASS are. 

3. [Optional] Download the samplepacks from the ftp. This can be very
   convenient because the samplepacks also contain some legacy plugins

    ```
    wget --no-host-directories -r --user=USER --password=PASS ftp://sdcompo.com/samplepacks
    ```

4. Generate the metadata

    A metadata file is provided here (metadata_rnd_1_to_89.csv), but
    in case you need to re-generate it, do as follows

    ```
    ./build-metadata.sh LOW_RND UP_RND > metadata_rnd_LOW_RND_to_UP_RND.csv
    ```

    where LOW_RND and UP_RND correspond to the closed interval of
    rounds to cover. This script will browse sdcompo.com and build a
    CSV file with information like round, author, title, etc, for each
    entry. That file is then used by the remaining scripts.

Render Rounds
-------------

```
./render.sh ROUND [AUTHOR]
```

where ROUND is the number of the round you want to render. Optionally
you may provide the name of the author, if you don't want to render
the whole round. Note that if you partially render the round, the
script will be able to resume where you stopped by asking you if you
want to skip already rendered entires.

What that script will iteratively go through each entry of the round
and automatically launch the right tracker (at its right version) for
each one. The result will be a flac file for each entry under the
folder

Note that it is possible that some filenames have been corrupted
during ftp transfer, in particular names using spanish accents or
such, you may therefore need to correct those filenames by using the
ones in the meta-data CSV file as reference.

``` entries ```

Upload Rounds
-------------

First will need to have registered your IAS3 access and secret keys to
ia-wrapper, if you haven't done so, you may use ia configure tool

```
ia configure
```

and enter you IA S3 access and secret keys (that you maye get from
http://archive.org/account/s3.php).

To upload the round(s) now rendered just type

```
./upload-rounds.sh ROUND [ROUND ...]
```

Once the rounds are uploaded, you're gonna have to fix a few tags and
song titles. But first the internetarchive needs to have completely
converted the flac files into mp3s, which may take up to an hour. You
may want to check that everything has been converted just to be sure,
before running the next script. Once it's ready run the following
python script:

```
./correct-ia-titles.py ROUND
```

where ROUND is obviously the number of the ROUND you wish to correct.

TODO
----

-[ ] Make correct-ia-titles.py capable of correcting entries added later
