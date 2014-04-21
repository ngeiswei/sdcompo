#!/usr/bin/env python2.7

import argparse
import csv

# You need ngeiswei's fork at https://github.com/ngeiswei/ia-wrapper
from internetarchive import get_item

def main():
    parser = argparse.ArgumentParser(description='Correct the title of the entries of a given set of rounds.')
    parser.add_argument('rounds', metavar='ROUND', nargs='+',
                        help='Round to correct')
    parser.add_argument('--metadata-file', default='metadata_rnd_1_to_75.csv',
                        help='Path of the metadata file')

    args = parser.parse_args()

    # Load metadata
    reader = csv.DictReader(args.metadata_file)

    # Iterate over entries of those rounds
    for d in reader:
        if d['round'] in args.rounds:
            # TODO
            target = 'files/hello-world.txt'
            md = {'new-file-tag': 'test value'}
            item = get_item('iacli-test-item')
            item.modify_metadata(md, target=target)

if __name__ == "__main__":
    main()
