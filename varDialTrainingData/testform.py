#!/usr/bin/python3

# read throught the 'testing' file and write 'test.txt' file,
# which omits the correct answers and the category

import sys

with  open('test.txt','w') as outf:
   with open('testing') as inf:
      for line in inf:
         t1 = line.find('\t')
         t2 = line.find('\t',t1+1)
         text = line[:t1]
         outf.write(text)
         outf.write('\n')


