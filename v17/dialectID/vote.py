#/usr/bin/env python3

"""
  This program endeavors to combine a series of guessing programs based on
  their records on the development data.
  The inputs are:
   hypothesis -- which holds the output from run.sh for ivec input
   hypothesisw -- which holds the output from runw.sh for words.input
   testc -- the charsA output
   teste -- the wentropy output

for each of these we have a discount vector, showing how the program
fared on the development data for each output.
"""
import random

dvec = [[211/428, 117/212, 175/403, 234/315, 136/166], #hypothesis predictions
        [205/446, 68/142,  131/237, 237/543,  97/156], #hypothesisw predictions
        [161/361, 73/338,  122/310, 203/410, 104/205], # testc predictions
        [184/364, 87/220,  148/253, 246/511, 87/176]]  # teste predictions


# set up a correspondance between test text and metadata, by reading through
# the 5 .word files in the data/dev.vardial17 directory

md2answer = {} # dict takes md as key, provides dialect
md2question = {} #dict takes md as key, provides test text
q2md = {} # dict takes test text as key, provides meta-data

fn = ['EGY', 'GLF', 'LAV', 'MSA', 'NOR']

for d in fn:
    fil = 'data/dev.vardial2017/'+d+'.words'
    fi = open(fil)
    for line in fi:
        line = line.strip()
        sp = line.find(' ')
        md = line[:sp]
        qu = line[sp+1:]
        md2answer[md] = d
        md2question[md] = qu
        q2md[qu] = md
    fi.close()

# read in guesses for hypothesis file
def fill(hs2guess,hypothesis):
    with  open(hypothesis) as fi:
        for line in fi:
            line = line.strip()
            sp = line.find(' ')
            md = line[:sp]
            ans = line[sp+1:sp+2]
            d = fn[int(ans)-1]
            hs2guess[md] = d

hs2guess = {}
fill(hs2guess,'hypothesis')
hw2guess = {}
fill(hw2guess,'hypothesisw')

# read in guesses for teste file
def fillt(th,tf):
    with open(tf) as fi:
        for line in fi:
            line = line.strip()
            tb = line.find('\t')
            d = line[tb+1:]
            qu = line[:tb]
            md = q2md[qu]
            th[md] = d

te2guess = {}
fillt(te2guess,'teste.txt')

dtrans = {} # to convert to dialect to offset in tables
for i,d in enumerate(fn):
    dtrans[d] = i

# finally read through the last file
with  open('testc.txt') as fi:
    for line in fi:
        line = line.strip()
        tb = line.find('\t')
        d = line[tb+1:]
        qu = line[:tb]
        md = q2md[qu]
        votes = [0]*(1+len(fn))
        votes[dtrans[d]] = dvec[2][dtrans[d]] # give fractional vote according
                                              # to reliability of this file on 
                                              # this dialect
        for i,dic in enumerate([ hs2guess, hw2guess, te2guess]):
            guess = dtrans[dic[md]]
            # votes[guess] += dvec[i][guess] # can't add probabilities
            votes[guess] = 1 - (1-votes[guess])*(1-dvec[i][guess])


        guess = random.randint(0,4)
        for i,g in enumerate(votes):
            if g > votes[guess]: guess = i
        print(qu+'\t'+fn[guess])


