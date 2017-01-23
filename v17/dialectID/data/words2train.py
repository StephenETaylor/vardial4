#/usr/bin/env python3

# a program to read a .words file and write a file in vardial3 training format,
# which is 
#   text\tQ\tDIA

import sys
inf = open(sys.argv[1])
for line in inf:
    line = line.strip()
    sp = line.find(' ')
    print(line[sp+1:]+'\tQ\t'+line[:3])
