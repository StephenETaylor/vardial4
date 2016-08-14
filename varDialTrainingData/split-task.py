#!/usr/bin/python3
# this file splits standard input into three files:
#   a training file
#   a validation file
#   a test file
#
# by reading through the file and putting 18 lines into the training file
#                                   next  1 line into validation file
#                                   next  1 lines into testing file

import sys

split_pattern = [18,1,1]
outf = []
for i in ["training", "validation", "testing"]:
   outf.append(open(i,"w"))

count = 0
i = 0
s = 0
for line in sys.stdin:
   if s >= split_pattern[i]:
      i = (i+1) % 3
      s = 0
   outf[i].write(line)

   count += 1
   s += 1

for i in outf:
   i.close()

print('wrote', count, 'lines')


