#!python3

"""
This program is intended to split segments in the training data which are longer
than 500 characters into non-overlapping segments, split on word boundaries.
The input is "training", the output file is "training.s".  I envision 
two different training file versions, the other being "training.t" which
will omit every segment longer than 520 characters; such segments are likely
to contain code-switching in any case.  Certainly we observe for training on 
segments longer than 520 characters a wide variation in the loss function,
which is partially due to the small batch sizes -- ten percent of the sizes 
are in the range 520 - 18000 (the largest training segment is 3868) there are 6858 training segments, so we'd expect at most 700 segments over the last sizes:
there are in fact 1467-978 = 489 batches, most believed to be singletons.

It's not clear which of the two approaches will give better performance;
the first goal is to stop oscillation of the loss function.  Both omission and
splitting should increase batch size and help with oscillation.
splitting will give more data, but it will be anomalous and if there is code-switching may be mislabeled.

"""

rawtrain = open("training",'r')
splittrain = open("training.s",'w')
droptrain = open("training.t",'w')

#rawtrain data contains three tab separated fields
# training segment\tQ\tDIA
# where Q is always "Q" and DIA is one of EGY, GLF, LAV, MSA, NOR

for line in rawtrain:
    t = line.find('\t')
    tseg = line[:t]
    dialect = line[t+3:]
    if len(tseg) < 520 :
        splittrain.write(line)
        droptrain.write(line)
    else:
        t = tseg.find(' ',490)
        while t>-1:
            splittrain.write(tseg[:t])
            splittrain.write('\tQ\t'+dialect)
            tseg = tseg[t+1:]
            t = tseg.find(' ',490)
        splittrain.write(tseg)
        splittrain.write('\tQ\t'+dialect)
splittrain.close()
droptrain.close()
