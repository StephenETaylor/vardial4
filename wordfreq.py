#!python3
import math
import sys

"""
I thought I'd try a last-minute completely different approach:
use n-gram frequencies to derive a likelihood score that a bag-of-words is
drawn from dialect x, then choose the highest likelihood as the dialect for
a particular sequence.  This code computes the frequency vs dialect for
1,2 and 3 -grams.

I've chosen a cut-off of 5 occurences in the training data to consider
an n-gram worthwhile.
"""

five = 5
ignore = True
iprobsFile = None
oprobsFile = None
testfn = 'varDialTrainingData/test.txt'

for i,arg in enumerate(sys.argv):
    if ignore: ignore = False
    elif arg == '-cutoff':
        five = sys.argv[i+1]
        ignore = True
    elif arg == '-combine':
        iprobsFile = sys.argv[i+1]
        ignore = True
    elif arg == '-pout':
        oprobsFile = sys.argv[i+1]
        ignore = True
    elif arg == '-test':
        testfn = sys.argv[i+1]
        ignore = True
    else:
        print('usage:\npython3 wordfreq [-test file][-cutoff num][-combine file][-pout file] > testout')


idialect = ["OTH" , "EGY", "GLF", "LAV", "MSA", "NOR"]

dialect = {'OTH': 0, 'EGY' : 1, 'GLF' : 2, 'LAV':3, 'MSA':4, 'NOR':5}

totalWords = 0
totalLines = 0
dialCount = [0]*6

freq1 = [dict(), dict(), dict(), dict(), dict(), dict()]
freq2 = [dict(), dict(), dict(), dict(), dict(), dict()]
freq3 = [dict(), dict(), dict(), dict(), dict(), dict()]

tr = open('varDialTrainingData/training', 'r')

for line in tr:
    totalLines += 1
    t = line.find('\t')
    text = line[:t]
    dial = dialect[line[t+3:t+6]]
    words = ['start0','start1'] + text.split() + ['end0', 'end1']
    wm2 = wm1 = 'empty0'
    for w in words:
        totalWords += 1
        dialCount[dial] += 1
        freq1[0][w] = freq1[0].get(w,0) + 1
        freq1[dial][w] = freq1[dial].get(w,0) + 1
        if wm1 != 'empty0':
            w2 = wm1 + ' ' + w
            freq2[0][w2] =freq2[0].get(w2,0) + 1
            freq2[dial][w2] =freq2[dial].get(w2,0) + 1
            if wm2 != 'empty0':
                w3 = wm2 + ' ' + w2
                freq3[0][w3] =freq3[0].get(w3,0) + 1
                freq3[dial][w3] =freq3[dial].get(w3,0) + 1
        wm2 = wm1
        wm1 = w

tr.close() # done reading training file

unigrams = sorted(freq1[0].items(),key = (lambda a : a[1]), reverse=True)
#print(unigrams[0], unigrams[1], unigrams[2], unigrams[3], unigrams[4])

# estimate  most interesting deviations for each dialect from expected means
sig = [0, [], [], [], [], []]
dev = [0, {}, {}, {}, {}, {}]
for d in range(1,6):
    for (w,k) in freq1[d].items():
        if freq1[0][w] < five: 
            dev[d][w] = 0 
            continue  # ignore infrequent words
        ep =  freq1[0][w] / totalWords  # expected occurrences
        ee = dialCount[d] * ep           # expected occurrences
        evar = ep * (1 - ep)
        es = math.sqrt(evar*dialCount[d])  # expect std deviation of occurances
        sigmas = (k-ee)/es      # number of sigmas deviation
        sig[d].append((w,sigmas,ee,k,es))
        dev[d][w] = sigmas	# save these figures for later
    sig[d].sort(key = (lambda x: abs(x[1])), reverse = True)
#    print(d, sig[d][0], sig[d][1], sig[d][2], sig[d][3]) # report for debugging

# presumably we can similarly estimate deviations for bigrams and trigrams

# now  compute most-likely dialects for bag of words sentences from test file
test = open(testfn,'r')

#iprobsFile is a text file holding probability estimates for each test file line
if iprobsFile:
    iprobsFile = open(iprobsFile,'r')

if oprobsFile:
    oprobsFile = open(oprobsFile,'w')

for line in test:
    p = [0]*6   # probability for each dialect
    
    for w in line.split():
        for d in range(1,6):
            sigma = dev[d].get(w,0)
#            t += sigma **2 #compute log-normal probability from sigma
#            if sigma < 0:
#                p[d] += -t      # rare words make dialect choice less probable
#            else:
#                p[d] += t       # common ones more likely
            p[d] += sigma

    # P array ranges from -infinity to +infinity.  Use math.exp to bring it to 
    # positive range (without reordering) then normalize.
    # normalize p array
    #  first ensure no numeric overflow
    s = max(p[1:6])
    for i in range(1,6):
            p[i] += -s
    # convert to positive numbers
    for i in range(1,6):
        p[i] = math.exp(p[i])

    # normalize to sum to 1
    s = sum(p[1:6])
    for i in range(1,6):
        p[i] = p[i] / s 

    # if -pout, write normalized probabilities to file
    if oprobsFile: 
        oprobsFile.write('{:.5f} {:.5f} {:.5f} {:.5f} {:.5f}\n'.format(p[1],p[2],p[3],p[4],p[5]))

    # if combining, add in another normalized probability from file
    if iprobsFile:
        pother = iprobsFile.readline().split()
        for i in range(1,6):
            p[i] += float(pother[i-1])

    # find largest likelihood (without renormalizing)
    dial = 1
    for i in range(2,6):
        if p[i] > p[dial]: dial = i
    print(line[:-1] + '\t' + idialect[dial])


test.close()


