#!/usr/bin/env python
import sys
import time

# Determine stdout/stderr from 1st argument
if len(sys.argv) <= 1:
    fo = sys.stdout
else:
    fo = getattr(sys, sys.argv[1])

# Get newline character from 2nd argument
if len(sys.argv) <= 2:
    newline = '\n'
else:
    newline = sys.argv[2]

# Disable universal newline to prevent '\n' -> '\r\n' in Windows
if sys.platform.startswith('win'):
    if sys.version_info < (3,):
        import os
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

fo.write('Hello')
fo.flush()
time.sleep(0.1)

fo.write(' World')
fo.flush()
time.sleep(0.1)

fo.write(newline)
fo.flush()
time.sleep(0.1)

fo.write('Hello')
fo.flush()
time.sleep(0.1)

fo.write(' World')
fo.flush()
time.sleep(0.1)

fo.write(newline)
fo.flush()
time.sleep(0.1)

fo.write('This is not line')
fo.flush()
