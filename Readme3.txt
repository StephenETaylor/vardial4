This directory and its subdirectory contain the programs and data developed
for the varDial 2016 Arabic dialect recognition shared task by
team AHAQST:
ahanani@birzeit.edu
aqaroush@birzeit.edu
staylor@fitchburgstate.edu

Our first run was prepared by an SVM developed by aqaroush@birzeit.edu
using character tri-grams extracted by ahanani@bitzeit.edu
Two of the runs submitted, run2 and run3 are prepared by software here.
Run2 used wordfreq.py
and run3 combined run2 and the output of two LSTM neural networks
written in torch, using a neural network combiner.m, written in Octave.

Partial file manifest:

combine.py	a python script for combining probability vectors by
		plurality vote.  Not successful, output of wordfreq.py
		was too polarized.

ctxt		the shared task test input
ctxt.c0		wordfreq.py output on the shared task (run2)
ctxt.c1		torch test.lua -init_from cv/lm_lstm_epoch0.16_1.3176.t7 output
ctxt.c2		th test.lua -init_from cw/lm_lstm_epoch0.32_1.4369.t7 output
ctxt.c3		octave ex4/combiner.m output (run3)
cv		directory holding checkpoints for 2-layer LSTM
cw		directory holding checkpoints for 3-layer LSTM
dsum.lua	lua program to summarize training data 
esum.lua	lua program to summarize training data 

ex4		directory holding combiner.m development. contents follows:
    c3data.mat			data for combiner.m	
    checkNNGradients.m		octave subroutine source file
    combiner.m			an octave script used to combine 3 model outputs
    combiner.mat		the saved NN parameters used by combiner.m
    computeNumericalGradient.m		octave subroutine source file
    C.txt
    debugInitializeWeights.m		octave subroutine source file
    displayData.m		octave subroutine source file
    ex4.m		training script, outputs combiner.mat
    fmincg.m		octave subroutine source file
    lib
    m1.txt		link to probability vector file for wordfreq outputs
    m2.txt		link to probability vector file for LSTM-2 outputs
    m3.txt		link to probability vector file for LSTM-3 outputs
    make_mat_file.py	used to prepare datafile for training
    make_output.py	python script to reformat combiner output
    nnCostFunction.m	octave subroutine source file
    octave-core
    predictions		combiner output
    predict.m			octave subroutine which runs neural network
    randInitializeWeights.m	octave subroutine source file
    sigmoidGradient.m		octave subroutine source file
    sigmoid.m			octave subroutine source file

makefile	goal %.c3 builds run3. goal c3train builds combiner NN
Manifest.txt	an older version of the file manifest
model		directory holds torch model descriptions
test.lua	Torch source file for LSTM model evaluations
train.lua	Torch source file for LSTM model training
util		directory holds torch subroutines
varDialTrainingData directory holds training data and scripts to transform it
wordfreq.py	python script to generate run2
