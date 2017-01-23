#/usr/env/python3

"""
This program combines the data directory reference file with
a .words file to create a vardial3 format gold file.
"""

import sys

# list of dialects borrowed from ../scripts/eval.py
langList=['EGY', 'GLF', 'LAV', 'MSA','NOR']

# first set up hash from metadata to dialect number
fr = open('../../reference','r')
rdict = dict()
for line in fr:
    sp = line.find(' ')
    meta = line[:sp]
    dialect = line[sp+1:sp+2]
    rdict[meta] = dialect

# now read through .words file
fin = open(sys.argv[1],'r') 
for line in fin:
    line = line.strip()
    sp = line.find(' ')
    meta = line[:sp]
    text = line[sp+1:]

    standard = rdict[meta]
    ts = langList[int(standard)-1]
    # write out line in gold format
    print(text+'\tQ\t'+ts)
