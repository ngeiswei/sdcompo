#!/usr/bin/env python2.7

import argparse
import csv
import os

# You need ngeiswei's fork at https://github.com/ngeiswei/ia-wrapper
from internetarchive import get_item

def change_file_extension(filename, new_extension):
    (root, _) = os.path.splitext(filename)
    return root + "." + new_extension

def padded_place(place_str):
    if place_str == 'AV':
        return place_str
    else:
        return "{0:02d}".format(int(place_str[:-2]))

def main():
    parser = argparse.ArgumentParser(description='Correct the title of the entries of a given set of rounds.')
    parser.add_argument('rounds', metavar='ROUND', nargs='+',
                        help='Round to correct')
    parser.add_argument('--metadata-file', default='metadata_rnd_1_to_85.csv',
                        help='Path of the metadata file')

    args = parser.parse_args()

    # Load metadata
    reader = csv.DictReader(open(args.metadata_file))

    # Iterate over entries of those rounds
    for d in reader:
        if d['round'] in args.rounds:
            place = d['place']
            author = d['author']
            padded_round = "{0:03d}".format(int(d['round']))
            title = d['title']
            root_target_file = 'SDC' + padded_round + '-' + padded_place(place) \
                + '_' + author + '_-_' + title.replace(' ', '_')
            target_file = 'files/' + root_target_file + ".flac"
            new_title = place + ' - ' + root_target_file
            md = {'title': new_title}
            item = get_item('SDCompo_Round_' + padded_round)
            print "Round {} {}: '{}' -> '{}'".format(d['round'], author, title, new_title)
            item.modify_metadata(md, target=target_file)

if __name__ == "__main__":
    main()
