#!/usr/bin/env python
from __future__ import print_function
import sys

for line in sys.stdin:
    sys.stdout.write('stdin: %s' % line)
    sys.stdout.flush()
