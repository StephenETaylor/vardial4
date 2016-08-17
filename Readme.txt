Intend to work on the varDial shared task in this directory.
described at: http://ttg.uni-saarland.de/vardial2016/dsl2016.html


My plan is to write an lstm rnn which will classify Arabic transcripts.
I think it will be a variant of the Karpathy Torch char-rnn,
http://karpathy.github.io/2015/05/21/rnn-effectiveness/

   1)The loss function is closely related to the cross entropy between the
   training text and the test text so one could use the code unmodified,

   2)but I plan to rewrite the output of the model as a classifier,
   perhaps with 5 soft-max outputs or conceivably as 5 separate nn's,
   each classifying yes/no. (two soft-max outputs).

8/Aug/2016.  I wrote and sent off a de-Buckwalter-er today.  I think I
should split off some test data, some validation data.

wrote some python scripts, all in varDialTrainingData:
xliterate.py -- mentioned above, turns training file into 5 dialect files
split-task.py -- splits training file into training, validation, testing files
testform.py -- transforms a test file to drop out the correct answers.


makefile sort of documents usage of scripts.

To train with this code:
th train.lua -seq_length 520 -data_dir varDialTrainingData -gpuid -1

where  
  th invokes the Torch package (see http://torch.ch/)
  train.lua is the top-level code, but it also calls code in model, util, model-util, misc directories
  -seq_length 520 is an effort to include at least the first 520 characters of each training item.  much smaller sequence lengths are possible, but this 
length discards little of the training data.  The median sequence length in
the training data is about 300 -- I think 520 is beyond the 90th percentile.
  The varDialTrainingData directory includes the "training" file, which 
is used for training data.
  -gpuid -1 indicates that my laptop does not have an nVidia graphics card,
and I am using the CPU for training.

The code defaults to producing a checkpoint after every 1000 batches.
It's supposed to run for 50 epochs, but there may not be time enough
before August 31.  The validation loss function does seem to be decreasing
slowly.

Wrote test.lua which can specify a model; it accepts test lines from
standard input and writes standard output.  
