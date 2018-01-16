#!/usr/bin/env python
from __future__ import print_function
import sys

# Use 'raw_input' instead in Python 2
if sys.version_info < (3,):
    input = raw_input

name = input('Please input your name: ')
print('Hello %s' % name)
