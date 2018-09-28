#!/usr/bin/env python
from __future__ import print_function
import argparse
import sys
import time

parser = argparse.ArgumentParser()
parser.add_argument('--delay', type=float, default=0.0)
parser.add_argument('--interval', type=float, default=0.1)
parser.add_argument('--exitcode', type=int, default=0)

args = parser.parse_args()

time.sleep(args.delay)

sys.stdout.write('stdout\n')
sys.stdout.flush()
time.sleep(args.interval)
sys.stderr.write('stderr\n')
sys.stderr.flush()
time.sleep(args.interval)

sys.stdout.write('Hello')
sys.stdout.flush()
time.sleep(args.interval)
sys.stderr.write('Hello')
sys.stderr.flush()
time.sleep(args.interval)

sys.stdout.write('World\n')
sys.stdout.flush()
time.sleep(args.interval)
sys.stderr.write('World\n')
sys.stderr.flush()
time.sleep(args.interval)

sys.stdout.write('This is not line')
sys.stdout.flush()
sys.stderr.write('This is not line')
sys.stderr.flush()

sys.exit(args.exitcode)
