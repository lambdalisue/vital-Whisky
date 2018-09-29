#!/usr/bin/env python
import os
import sys
import time
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--delay',
                    type=int,
                    default=0)
parser.add_argument('--newline',
                    choices=['\n', '\r', '\r\n'],
                    default='\n')
parser.add_argument('--out',
                    choices=['stdout', 'stderr'],
                    default='stdout')
args = parser.parse_args()

fo = sys.stderr if args.out == 'stderr' else sys.stdout

# Disable universal newline to prevent '\n' -> '\r\n' in Windows
if sys.platform.startswith('win'):
    if sys.version_info < (3,):
        import msvcrt
        msvcrt.setmode(fo.fileno(), os.O_BINARY)
    else:
        fo = open(
            fo.fileno(),
            mode=fo.mode,
            buffering=1,
            encoding=fo.encoding,
            errors=fo.errors,
            newline='\n',
            closefd=False,
        )

if args.delay:
    time.sleep(args.delay / 1000.0)

fo.write(os.getcwd())
fo.write(args.newline)
fo.flush()
