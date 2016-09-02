#!/usr/bin/python3
"""
  This script combines a bunch of files, each of which is a list of 
five probabilities.

It combines them  by addition; in effect it votes.

Each of the input files is listed on the command line.
The lines are read in parallel and added.
Also, lines are read from the test file,
and the output consists of a test output file.
"""
import sys
import math

idialect = ['oth', 'EGY', 'GLF', 'LAV', 'MSA', 'NOR']


testfn = 'varDialTrainingData/test.txt'
test = open(testfn,'r')

handle = []
for f in sys.argv[1:]:
    handle.append(open(f,'r'))

for line in test:
    t = line.find('\t')
    p = [0]*6
    for h in handle:
        ps = h.readline().split()
        for i in range(1,6):
            p[i] += float(ps[i-1])

    # now find max without renormalizing
    dial = 1
    for i in range(2,6):
        if p[i] > p[dial]: dial = i

    print(line[:t]+'\t'+idialect[dial])



