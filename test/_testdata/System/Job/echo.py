#!/usr/bin/env python
from __future__ import print_function
import sys
import time

# Determine stdout/stderr from 1st argument
if len(sys.argv) <= 1:
    fo = sys.stdout
else:
    fo = getattr(sys, sys.argv[1])

print('Hello World', file=fo)
time.sleep(0.1)

print('Hello World', file=fo)
time.sleep(0.1)

fo.write('This is not line')
fo.flush()
