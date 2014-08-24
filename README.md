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
$ python sudo setup.py install
```

Preparation
-----------

1. Clone this project

```
$ git clone https://github.com/ngeiswei/sdcompo.git
$ cd sdcompo
```

1. Download the entries from the ftp
```
$ mkdir entries
$ ftp ftp.sdcompo.com # you're supposed to know the name and password
$ wget --no-host-directories -r ftp://USER:PASS@sdcompo.com/round{LOW_RND..UP_RND}
```
where LOW_RND and UP_RND is the closed interval of rounds to
download. Don't forget to replace USER and PASS by what there are
supposed to be.

2. Generate the metadata

A metadata file is provided here (metadata_rnd_1_to_85.csv), but in
case you need to re-generate it, do the following

```
$ ./build-metadata.sh LOW_RND UP_RND > metadata_rnd_LOW_RND_to_UP_RND.csv
```

where LOW_RND and UP_RND correspond to the closed interval of rounds
to cover. This script will browse sdcompo.com and build a CSV file
with information like round, author, title, etc, for each entry. That
file is then used by the remaining scripts.

Render Rounds
-------------

TODO

Upload Rounds
-------------

TODO
