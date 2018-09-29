#!/usr/bin/env python
import time
import sys
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--delay',
                    type=int,
                    default=0)
parser.add_argument('--exitval',
                    type=int,
                    default=0)
args = parser.parse_args()

if args.delay:
    time.sleep(args.delay / 1000.0)
sys.exit(args.exitval)
