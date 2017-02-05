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

trainingFile = 'varDialTrainingData/training'
#default to Arabic dialects
idialect = ["OTH" , "EGY", "GLF", "LAV", "MSA", "NOR"]
numDialects = 5

five = 1
ignore = True
iprobsFile = None
oprobsFile = None
testfn = 'varDialTrainingData/test.txt'
least_n_gram = 1
max_n_gram = 1
verbose = False
SHINGLE = True
HYPFORM = False

for i,arg in enumerate(sys.argv):
    if ignore: ignore = False
    elif arg == '-bag':
        SHINGLE = False
    elif arg == '-cutoff':
        five = int(sys.argv[i+1])
        ignore = True
    elif arg == '-combine':
        iprobsFile = sys.argv[i+1]
        ignore = True
    elif arg == '-hout':
        oprobsFile = sys.argv[i+1]
        ignore = True
        HYPFORM = True
    elif arg =='-least_n_gram':
        least_n_gram = int(sys.argv[i+1])
        ignore = True
    elif arg == '-max_n_gram':
        max_n_gram = int(sys.argv[i+1])
        ignore = True
    elif arg == '-nextDialect':
        if idialect[0] == 'OTH': # if this is the first -nextDialect switch
            idialect = ['oth']   # reset the list of dialects to empty
            numDialects = 0
        idialect.append( sys.argv[i+1])
        numDialects += 1
        ignore = True
    elif arg == '-pout':
        oprobsFile = sys.argv[i+1]
        ignore = True
    elif arg == '-test':
        testfn = sys.argv[i+1]
        ignore = True
    elif arg == '-train':
        trainingFile = sys.argv[i+1]
        ignore = True
    elif arg == '-verbose':
        verbose = True
    else:
        print('illegal flag',arg)
        print('usage:\npython3 wordfreq [-max_n_gram #][-test file][-cutoff num][-combine file][-pout file] > testout')
        sys.exit(1)

dialect = {}
for i,d in enumerate(idialect):
    dialect[d] = i;

totalLines = 0
totalWords = 0
dialCount = [0]*len(idialect)

freq1 = [dict(), dict(), dict(), dict(), dict(), dict()]
freq2 = [dict(), dict(), dict(), dict(), dict(), dict()]
freq3 = [dict(), dict(), dict(), dict(), dict(), dict()]

tr = open(trainingFile, 'r')

for line in tr:
    line = line.strip()
    totalLines += 1
    t = line.find('\t')
    text = line[:t]
    dial = dialect[line[t+3:]]
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

"""
# this code commented out, Dec 20, 2016
# the following code was used for submission 2 of the vardial3 workshop.
# it didn't work as well as one might have expected from the training data.
# so try using entropy instead.  The standard deviations are definitely 
# interesting data, though, and words with highest standard deviations
# are especially interesting.  But:  yEny is much less common in MSA than in
# any of the dialects. (over ten sigma) but is still quite common, compared to
# other words.
#
# estimate  most interesting deviations for each dialect from expected means
freq = [freq1, freq2, freq3]
dev = []
sig = [0, [], [], [], [], []] # we optionally report these, but don't retain 
                              # them very long. So we don't need 1 for each n
for n in range(max_n_gram):
    dev.append([0, {}, {}, {}, {}, {}])
    for d in range(1,numDialects+1): 
        for (w,k) in freq[n][d].items():
            if freq[n][0][w] < five: 
                dev[n][d][w] = 0 
                continue  # ignore infrequent words
            ep =  freq[n][0][w] / totalWords  # expected occurrences
            ee = dialCount[d] * ep           # expected occurrences
            evar = ep * (1 - ep)
            es = math.sqrt(evar*dialCount[d])  # expect std deviation of occurances
            sigmas = (k-ee)/es      # number of sigmas deviation
            sig[d].append((w,sigmas,ee,k,es))
            dev[n][d][w] = sigmas	# save these figures for later
        sig[d].sort(key = (lambda x: abs(x[1])), reverse = True)
        if verbose: print(d, sig[d][0], sig[d][1], sig[d][2], sig[d][3]) # report for debugging
"""

"""
  Dec 20, 2016.  Rewriting the methods of this file to see whether I 
  can get better performance:
  try to use entropy instead of standard deviation.  So compute log frequency
  for those words(/bigrams/trigrams) with frequencies abouve the cutoff.
  In ordr to re-use the code which follows, I keep the entropies in the hash
  dev[n][d][w] where n is the n-gram size, d is an integer in the rage 1-5
"""
freq = [freq1, freq2, freq3]
unlikely = [0]*(numDialects+1)
dev = []
for n in range(max_n_gram):
    dev.append([0, {}, {}, {}, {}, {}])
    for d in range(1,(numDialects+1)): 
        unlikely[d] = math.log(1/(dialCount[d] ), 2)
        for (w,k) in freq[n][d].items():
            if freq[n][0][w] < five: 
                dev[n][d][w] = 0 
                continue  # ignore infrequent words
            p = freq[n][d][w] / (dialCount[d] )
            dev[n][d][w] = math.log(p,2)

# now  compute most-likely dialects for bag of words sentences from test file
test = open(testfn,'r')

#iprobsFile is a text file holding probability estimates for each test file line
if iprobsFile:
    iprobsFile = open(iprobsFile,'r')

if oprobsFile:
    oprobsFile = open(oprobsFile,'w')

# in the following code, I attempt to choose the correct entropy by
# ignoring second-through nth words in an n-gram. 
# thus the ignored words add nothing to the entropy of the line,
# and the division at the end of the loop effectively divides the frequency of
# the n-gram  by n for each word.
# [this captures the intuition that the cross entropy of "abc" and "abc" is 0
# and the cross perplexity of "abc" wrt to "abcabc" is only at the "c's" where
# there are two choices, so that the per-character perplexity is 8/6.]
#This has the 
# problem that I may miss adjacent but overlapping n-grams of high order.
# I'll still catch a following n-gram as a smaller, perhaps n-1, but even 
# possibly unigram, so that (after division by len(ll)) I'll have a slightly
# too-high perplexity = too-low entropy. [although my log-probs are all 
# negative, so aren't precisely entropies.]
# a fix for this might be to maintain for each character a frequency-so-far
# based on the n-grams we have considered. If it is part of an m-gram 
# started in the last m characters, it has the log-probability of the m-gram,
# divided by m; if it is also part of a k-gram 
# it should have the lesser of the two probabilities.
for line in test:
    p = [0]*(numDialects+1)   # probability for each dialect
    
    ll = line.split()
    for d in range(1,(numDialects+1)):
        llp = [0]*(max_n_gram+len(ll))   #used by BAG mode
        igncnt = 0
        for i,w in enumerate(ll):

            if igncnt > 0:
                igncnt += -1
            else :
                # build w, w1, w2
                if i+1 < len(ll): w2 = w+' '+ll[i+1]
                else: 
                    w2 = w+' end0'
                    w3 = w+' end0 end1'
                if i+2 < len(ll): w3 = w2 + ' ' + ll[i+2]
                elif i+1 < len(ll): w3 = w2 +' end0'

                sigma = 0
                if SHINGLE:
                    for n in range(max_n_gram-1,least_n_gram-1-1,-1):
                        w0 = [w, w2, w3][n]
                        if sigma == 0:
                            sigma = dev[n][d].get(w0,0)
                            if sigma != 0:
                                igncnt = n
                                break
                    if sigma == 0:
                        sigma = unlikely[d]
                else: # BAG mode.  find greatest probability for every gram
                    for n in range(max_n_gram-1,least_n_gram-1-1,-1):
                        w0 = [w, w2, w3][n]
                        delta = dev[n][d].get(w0,0)/(n+1)
                        if delta !=0:
                            for j in range(i,i+n+1):
                                if llp[j] == 0 or llp[j] < delta:
                                    llp[j] = delta
                    if llp[i] != 0:
                        sigma = llp[i] # we've now considered all the ngrams
                                   # that char i could be in.   
                    else:
                        sigma = unlikely[d]

                p[d] += sigma

    for d in range(1,(numDialects+1)):
        p[d] = p[d] / len(ll)# / max_n_gram # normalize per word.  

    ## p array ranges from -infinity to 0.  Use math.exp to bring it to 
    ## positive range (without reordering) then normalize.
    ## normalize p array
    ##  first ensure no numeric overflow
    #s = max(p[1:(numDialects+1)])
    #for i in range(1,(numDialects+1)):
    #        p[i] += -s
    # convert to positive numbers
    ln2 = math.log(2)
    for i in range(1,(numDialects+1)):
        p[i] = math.exp(p[i]*ln2) # 2**p[i]

    # normalize to sum to 1
    s = sum(p[1:(numDialects+1)])
    for i in range(1,(numDialects+1)):
        p[i] = p[i] / s 

    # if -pout, write normalized probabilities to file
    if oprobsFile: 
        if HYPFORM:  # if we want the probsfile to be in "hypothesis" format
            # find largest likelihood (without renormalizing)
            dial = 1
            for i in range(2,(numDialects+1)):
                if p[i] > p[dial]: dial = i
            oprobsFile.write(str(dial)+' ') #output guess

        oprobsFile.write('{:.5f} {:.5f} {:.5f} {:.5f} {:.5f}\n'.format(p[1],p[2],p[3],p[4],p[5]))

    # if combining, add in another normalized probability from file
    if iprobsFile:
        pother = iprobsFile.readline().split()
        for i in range(1,(numDialects+1)):
            p[i] += float(pother[i-1])

    # find largest likelihood (without renormalizing)
    dial = 1
    for i in range(2,(numDialects+1)):
        if p[i] > p[dial]: dial = i
    print(line[:-1] + '\t' + idialect[dial])


test.close()


