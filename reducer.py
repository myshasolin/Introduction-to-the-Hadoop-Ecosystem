#!/usr/local/bin/python3.7

import sys, random

count, batch_count = 0, 0
stop, batch = random.randint(1, 5), []

for i in sys.stdin:
    count += 1
    batch.append(i.strip())
    if len(batch) == stop:
        print(', '.join(batch))
        batch_count += len(batch)
        stop, batch = random.randint(1, 5), []
if batch:
    print(', '.join(batch))
    batch_count += len(batch)
        
print(f'\ncount = {count}\nbatch_count = {batch_count}\n')
