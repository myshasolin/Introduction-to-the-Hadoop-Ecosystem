#!/usr/local/bin/python3.7

import sys

for _ in sys.stdin:
    print(''.join(i for i in _ if not i.isalpha()).strip()) 
