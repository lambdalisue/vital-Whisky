#!/usr/bin/env python
from __future__ import print_function
import sys

data = [line for line in sys.stdin]

for line in data:
    print('IN: %s' % line, end='')
