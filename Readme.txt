(This is a file which will probably have another name later...)
I'm starting to prepare for the next release of data, by writing some 
programs which I didn't get around to previously.

1) redo wordFreq.py to use entropy
2) attempt an SVM?
3) try using char-rnn entropy/loss function (of char-rnn trained onthe 5 subsets) to distinguish dialects.

4)experiment with widening hidden layers for nn.
4.5) and widening hidden layer for combiner.

Dec 22, 2016
rewrote wordfreq.py, foolishly giving it the same name as before.

From before, I have a program, statistics.lua, which reads standard input 
and prints some statistics.

make wordstats should invoke it.
When I run the vardial3 version of "make wordstats" I get 186/380 wrong,
for a fraction wrong of 0.48947368...
(which uses the std deviation scheme)
The modified version, using entropy, gets 166 errors for a fraction 
wrong of 0.43684210526316	
(both on the reserved training data, not the workshop test data)
Should test on the workshop data!

Should test on the workshop data (which might be ctext)
... did.
The makefile now contains wordstats{0,1,2,3}
The new version of wordfreq is a few percent better on both reserved training
and workshop data.  But not amazing!

Next do paul heikkinen inspired char string stuff...

December 23, 2016
I note that there isn't much documentation on use of the google cloud.
I did use it to train, but I didn't document it that I can see.
presumably I used gcloud compute, and presumably I started training instances
in the background.  There is a little documentation on the training process,
and perhaps, if I can find it, some history on the instance. If I find it,
I should document it here.

Maybe  before moving on to char string stuff, I should debug and try word
bigrams...  since code to collect them is already in place.

December 23, again, pulled down somehistory.txt from the cloud, and did a 
little bit of documentation.  

Dec 24, wentropy.py replaces wordform.py, and I'll plan to pull the old version
of wordform.py forward from varDial3.  Code for bigrams and trigrams
executes without error, but doesn't improve performance on the reserved training
data over unigrams.  make wenstat* produces various statistics.

If I recall correctly, Paul Heikinnen described his procedure as basically
finding the largest n-gram from each word, and largest n-grams from the 
remaining fragments, and adding in the appropriate entropies.  Obviously I
could check his paper.  But I thought I might try doing x-grams where 0<x<l,
where l is the largest training sentence.  To keep the memory usage in line,
I'll keep l tables of n-grams, one for each size, and make only one copy of
the training data, which I will leave in memory.  This will work fine for
the data we have.  Then if a test segment exactly matches an existing 
training segment the cross-entropy will be zero?

I plan to code this in C.

Dec 29
... code still in progress...
Downloaded the test data and baseline system.  So far the sample doesn't run,
1. Downloaded multi-class SVM code from 
	http://download.joachims.org/svm_multiclass/current/svm_multiclass.tar.gz
   The executables svm_multiclass_learn and svm_multiclass_classify were
   supposed to end up in the DialectID/scripts directory, but whether I just
   found them there, or moved them there after download, I don't remember. 
2. installed BeautifulSoup with command 
	sudo pip2 install bs4

At this point the sample script run.sh ran, with 57% accuracy.
Presumably one could run it with other parameters.

Dec 31, continuing with chars.c.  Currently not initializing training strings
correctly, although I think I was previously doing this;  get count of
4000 strings out of 7500+

Jan 1, 2017.  Problem wasn't initializing training strings, but looping through
them.  existing code makes assumptions about storage layout instead of using
the training strings table.  I think I should have (but won't code now)
a series of structs: str would replace strptr, which has a confusing name,
trstr would be a training string, with a str as its first element, dialect
following, hstr would be a str from training, which has a count array following,
and all would cast to a cstr, comparison string.

Need to code test...
Should add command line interface to vary the train and test files.
seems to be a bug; read only 4000 training strings, should be 7500+
Could increase storage utilization by varying the factor by which rehashed
tables are bigger than original.  Currently two; expected average utilization
in code is half-way between 0.7 and 0.7/2, or possibly 52.5.  Since those
tables are big, and I'd like to have more of them...

Jan 2, 2017.  read through test strings, I think, but still don't compute
entropy.  Added code to accumulate totals, and then rewrote it to use
a totals array which is manually double indexed.  However, I am now getting
a malloc error, usually caused by wild stores; likely it is the totals code...
looks like I was using the offset, and not the length, as subscript.
Output claims to examine 6858 training strings, same as number in training file;
but last test string seems to be an eof character?

So my plan for cross-entropies is roughly:
for dialects i in range 1-n:
  find the longest matching string for dialect i. this splits the string into
  three pieces: test-beginning, match, test-end
    recursively compute cross-entropy for test-beginning.
    stitch test-beginning and match with a bigram.
    recursivly compute for test-end, and stitch to other pieces with a bigram.
    divide sum of entropies by total number of characters.
I may need to redo the datastructures to pull it off.

So: "find the longest matching string for dialect i" -- starting with maxstring
length, look for matches at each offset in test string.  If we get a match, and
it has a zero count for dialect i, don't use it, keep looking.

Ran program, ps caught growth at 741160,1196160, 1266156, I think those are
1-K units, so program reached 1.3GB.

Jan 3,
Coded entropy as described above, except skipped stitching.  
assorted bugs discovered.

Jan 4, 2017
looks like the first character of the test string output is getting duplicated.
I'm reading one too many test strings; last string consists only of a junk
character. EOF? yes.

Almost all of the test strings are diagnosed as LAV, a handful as EGY.
Need to get rid of the diagnostic output so that I can run the test output
through the statistics.lua program.  I'll code a -verbose flag.

The program guessed LAV almost always; EGY 28 times, MSA and NOR once.
Results not much better than chance.  Presumably a systematic error...

Well, there was a systematic error, I was returning dialect with min log prob
instead of max.  But fixing that actually made matters worse!
for the first test string, for which the answer is NOR, I get a log-prob for
EGY of 2.39 -- whic is positive, which seems impossible.  Other entropies
make some sense.
Stepping through the computation, the first substring is 
"dp Al$Eb AlflsTyny ".  It's counts were: {4201709, 0, 13238272, 1, 0},
and the totals for 19 for dialect 0 were about 340000;  the totals seem 
sensible, but the counts do not.  The zeros would be okay.
hashtables[19] has a length of 2560000, that is, it was rehashed 8 times.
I could try checking the counts at each rehash, to see when it goes wrong...
I checked a few other strings of lenth 19.  Many have the same two counts
wrong.
A handful of strings of length 1 didn't reveal any of them, but on the
fourth of length 10, I hit one; all the examples seem to have the same 
wrong values: 40201709 for 0 and 13228272 for 2.  For strings of length 3,
I found some examples that had non-zero counts for other dialects and were
slightly incremented.  Similarly for strings of length 2.  That table has
been rehashed twice.

So, in the rehash code, I used "st" instead of "ns", thus copying the counts
from the paramter string, which doesn't necessarily have sensible counts,
instead of the string which was just rehashed.

However, that fix changed things without improving them.  Now mostly guess EGY
and LAV, but still have 79% wrong.  Changed entropy test again... increased
error rate to 81%.  Check entropy, etc. next time...

Jan 4, again, 8PM
Turns out there were some bugs in compute single entropy; it only did the
biggest string.  That fix jumped the error rate down to 0.43 -- on the 
withheld training data, which we've seen before.  It also gives a whole bunch
of "Mysteriously... character notin the training data"

January 5,
The problem with the "Mysteriously" turned out to be condition in the offset part of the for loop for compute_single_entropy.  was j<x.length-i; changed to
j<x.length-i+1; single character strings did not go through the loop.

Result is the best so far on the reserved training data, 40% error rate,
but nothing special on the vardial3 test data, ~60% error rate, more than
wentropy.py.

I'd like to compare this with the "baseline" code, next.
Had to modify code for -test flag also.  

January 7
Reading through the run.sh file, I note that it generates a file
hypothesis
in the following format:
7 fields, space separated.
first field, metadata from dev*/* file.
second field, dialect choice, an integer from 1 to 5
third through seventh fields, a figure-of-merit for each dialect? ranges from
	at most -121.102119 to at least +105.570640.  Largest figure of merit
	is index of dialect choice.
DialectID/scripts/eval.py reads the hypothesis file and a reference file
and generates statistics.

Format of the reference file
two fields.
first field: metadata
second field: integer

I think I'll write some python code to convert these guys to match my file 
formats from vardial 3

January 21, 2017
Did some development on swiss-german.  Files in v17/DSL/GDI transform
the corpus to vardial3 formats.  Wentropy.py gives an error rate of 20%!
The wentropy file has some edits which should be merged with the vardial4 files,
which should make their way to the github site.
chars.c compiles to charsA and charsG.  For some reason charsG gets a 
segmentation fault during training.  the Swiss-German data contains utf-8 
sequences, which are not found in the Arabic dialect code, but it successfully
reads through 8020 lines before bombing.
I think I've found the problem.  The bounds are compiled into the chars.c
code, and the compiled max number of training lines is 8000.  I really always 
knew I was going to have to make this dynamic, so I'll take a look...

Now make a trial run through the input to decide size of training file, number 
of lines.  This lets the german code run.  I get some "Mysteriously" messages,
which may actually be correct; there could be characters which are not
in the training data occurring in the test data.  But I should examine this
more carefully:  the problem is that unicode sequences should not be broken,
but there is nothing in the code to prevent it, since there were previously
no unicode seqences to break.  The strategy to prevent this should be:
1) check the beginning of substrings, and never begin on a utf-8 continuation
character (high order two bits 1,0)
2) check the end of substrings, and never end on an incomplete utf-8 sequence.
2a) do not end on a utf-8 start sequence (high order two bits 1,1)
2b) if the end byte is a utf-8 continuation character, make sure that the
    utf-8 sequence is complete:
    2b1) if the byte [end-1]is a utf-8 leading character for a 2-char sequence
       (high-order bits 1,1,0), then okay, else
    2b2) if the byte [end-1] is a utf-8 continuation character, (hi 1,0)
         and the byte [end-2] is leading byte for a 3-char seq (hi 1,1,1,0),
         then okay else
    2b3) if the byte [end-2] is a utf-8 continuation character
         and the byte [end-3] is the leading byte for 4-char sq (hi 1,1,1,1,0)
         then okay, else 
I think that there are no 3 or 4 byte sequences in the GDI data, so it may
be sufficient to check 2b1: byte [end-1] must be a utf-8 leading char for a 2-sq
However, I got "long utf-8 sequence" reports for lines 0, 1371,9861,10900

line zero is BOM, the byte-order mark, which is FEFF in utf-16,
and 357 273 277 in octal,
line 1371 contains the character ẽ, lower case e with tilde, U+1EBD, a three-character sequence.  9861 does too.

Modified the code to disallow broken 3 and 4 octet utf-8 sequences, flagging
4-octet sequences with an error, so that I can find if they occur.

I still get "Mysteriously..." messages, which cite the first char of a two-sequence.  This has to happen because the other character of two-sequence has been 
matched?  But it should not be in the hash table ...
No, the problem seems to be a 3-octet sequence which is not in the training
data for some dialect.  One such is ǜ, which it is unsurprizing to find missing from some corpus.  Probably I should quietly just penalize the character and
move on.  How does one handle the penalties for multi-byte characters?

Currently I return 2 for that error, but should return a negative log.
added that code.  The return value is added to the entropy for the dialect.

--
So swiss-german (GDI) data seems to work, but it looks like I didn't 
finish converting the DSL/dialectID/data/train.varDial2017 files to 
vardial3 format.

So back to that task.  DSL/dialect/data/Makefile claims to do it but doesn't.
reference2gold.py fails, missing (sys.) on argv, adding 1 instead of subtracting
code clearly undebugged...
but it seems easy.

7PM: Now running on the development data for wentropy.py and charsA programs;
neither gives results as good as the "baseline"
See v17/dialectID/Makefile

January 24

combined base word file and base ivec file with wentropy and chars output
output is dialectID/test.f4

made v17/DSL/GDI/GDI-test.{c,e}


How can I combine these with the baseline programs?  The hypothesis files
seem like a good scheme for conveying some of the basis of a decision, except
that I don't know how to interpret them.  

I could feed just the various answers/suggestions into a neural network, and
try to train it on the development data.  I could output hypothesis-file like
files, which for example would contain the relative entropies of the
various choices, into a neural net, and train with more data.

Without a neural net, a simple combination function could use the
matrix of successes and failures to discount an answer:
so if the wentropy program predicts MSA, it's right 246 out of 511 times;
if it predicts NOR it is right 87/176 times; LAV, 148/253 times, etc.
Then disagreement is slightly less likely to result in a tie, and more
reliable guessers are more likely to win.
So I'll try that...
One obstacle is that the data may not be in the same order...
The hypothesis file includes the meta-data, whereas the test{e,c} files
contain the data itself.  (Did I already write this code?)

So I wrote dialectID/vote.py
and made appropriate changes to dialectID/Makefile
make vstat shows 673 errors, whereas ./run.sh shows 651 errors.
(in other words, using the additional files actually makes things worse.)
I had this same experience with combiner.py during vardial3.  Then I wrote
a neural network which worked a little better.

Sunday Jan 22, 2017

Before I start on the neural network idea, I thought maybe I'm voting wrong.
So my current algorithm is, find guess for each of four files.  Weight each
guess by the probability that that source is correct for that guess.
*Then add them all up*
Clearly the procedure of adding does not give a probability.  And three 
sources which are all near chance, 20% (though none of mine are) would add to 
60%, outweighing a source with a 50% weight, which is much better than chance.
So maybe the weighting isn't right.  (But it covers a fairly narrow range, 0.4-0.6 anyway.)
But also you can't add probabilities.  I think you *can* multiply complements.
So if source one predicts A with prob 0.5 and source two predicts A with prob
0.4, 
>They agree, so either both are right or both are wrong.
>One is wrong with prob 0.5 and two is wrong with prob 0.6, 
>so both are wrong with prob 0.3, 
>and both are right with prob 0.7.

That change does change the voting errors from 671 to 658, but it is still
worse than the baseline.

Conversation with Abualsoud.  He suggests using matlab package for multiple 
linear regression to train the coefficients for combining packages.

Aziz writes that he has achieved accuracy of 63.7% on the development set.

Abualsoud suggests that it would be nice to use a dnn, maybe an rnn on
a sequence of gmm coefficients.  He is examining the wav files, using 256
gmms to obtain a sequence of pre-phone values, with which he has been able to
classify with an accuracy inthe 40% range.  He is trying again with 2048 gmms.

He suggests training a combiner on the development set.  But need a test set as well.

Some ideas for experiments:
He says that training segments shorter than dev segments, might be 
codeswitching in the dev segments.  
He says that Ali reported:
1) Arabic vs English 100%, no errors.
2) MSA vs dialect 100%, no errors;
under those circumstances, should be able to build MSA vs all classifier,
with low error rate; then there are fewer dialects to distinguish from each
other, should be easier.

Maybe codeswitching is into and out of MSA, only one dialect per segment.
Can we exploit this?



summary of errors on dev set:
charsA		861 56.5% wrong.
wentropy 	772 50.7% wrong
baseline ivec 	651 42.7% wrong
baseline words	786 51.6% wrong

So wentropy isn't so bad ... the error is quite close to (though lower than)
the baseline words.  But is it doing bigrams?  Because if I add the
-max_n_gram 2 flag I still get 772 errors.  So at best it is ignoring the flag.

Reviewed the code; it was messing up, searching for unigrams in bigram 
and trigram tables, and of course always failing.

however, there seems to be a problem, now that I've fixed the lookup:
much bigger error rates for bigrams and trigrams.
wentropy.py -max_n_gram 1	772
wentropy.py -max_n_gram 2	1071
wentropy.py -max_n_gram 3	1122
This could be due to assorted factors.  It's certainly astounding.
possible problems I know about:  
)I shingle the n-grams, don't overlap them.
If I allow overlap, I'll need a per-character idea of smallest character entropy
)igncnt could be broken.  (It was, wasn't skipping.  So finding a bigram
meant just adding an extra penalty.)
)many words are OOV, and of course many bigrams also.  If we find a bigram,
 it is quite likely to be OOV for several dialects.  Since we are shingling,
do we miss the chance to accumulate in-vocabulary words for the dialect?
 -- no, we shingle each dialect separately.

After fixing igncnt, the error count rose
wentropy.py -max_n_gram 2	1236
wentropy.py -max_n_gram 3	1244
These are chance or worse.  Only one diagonal position is the max for its column, LAV; and not by much.

There is a sensible-looking comment which says that the p array values
range from -infinity to zero.  But in fact, we take -log(2,n/d), so they
are positive.  So we should seek the smallest, but in the code we choose the
largest -- which makes sense if we're choosing the largest negative value...

Jan 23, 2017
Turns out that I have a python braino.  -math.log(2,p) is log 2 base p, not
log p base 2.  Still monotonic, opposite direction.  But since they aren't log
probabilities, they don't add.
 I'm going to commit the current state of wentropy, and then see if the
identified fixes help.

After editing the log function calls, I see improvements, but still bigrams
and trigrams dont work.
wentropy -max_n_gram 1	737 errors
wentropy -max_n_gram 2	798 errors
wentropy -max_n_gram 3	806 errors

Looking at the first dev sentence I see that it (and all the first 5 also) is 
EGY.  But it is diagnosed as LAV.  Second sentence is correctly guessed.

(glancing at the wc for the training files, we see that the NOR segments are
significantly shorter than the others.   MSA has the fewests segments, followed by GLF )

Experimenting with the -cutoff parameter, I see small values don't affect
recognition, but at -cutoff 10 and -cutoff 15 I see higher error rates overall,
but bigger correct answers for GLF and NOR.

walking through first and second test segments for EGY.
first segment (should be EGY, guesses LAV):
WORD		EGY			LAV			COMMENT
tthdm, 		-16.446550255546747	-16.004110714772633	(not in tables)
AlmsAjd 	-16.446550255546747	-15.004110714772633	in LAV 2
fy		-5.145054060564196	-5.3152930344173255
synA		-14.446550255546747	-16.004110714772633	in EGY 4
wAl>bAt$y	-16.446550255546747     -16.004110714772633
sxryp		-16.446550255546747     -16.004110714772633
mn		-5.933809792743247	-5.870968502372031
Alhjrp		-15.446550255546747	-16.004110714772633
Alnbwyp		-16.446550255546747	-16.004110714772633
fy              -5.145054060564196      -5.3152930344173255
Aljryda		-15.446550255546747	-16.004110714772633
Alrsmya		-14.446550255546747	-13.419148214051475
lma		-9.237096889917796	-8.992883459349377
mAdty		-16.446550255546747	-16.004110714772633
Altrbya		-14.861587754825589	-12.303670996631539
Al<slAmyp	-11.98711863690945	-12.19675579271503
mn              -5.933809792743247      -5.870968502372031
AlmdArs		-13.124622160659383	-10.959716595414179

>Most of the differences here might have to do with differences in topics
in the training files.  So Al<slamyp insignificantly more common in EGY,
Altrbya (education) is six times as common in the LAV training.
>Since there are more EGY words in training, the not-found penalty is bigger for
EGY than LAV; it occurs the same number of times in both samples, though
not for the same words, and the difference is half of the difference
between samples.  
>Since the penalty is the same as the single-word cost,
we can't easily distinguish them in this table.

I tried a fixed penalty for all dialects of 17, but got an amazing number 
of errors.  switched to variable 1/2 the frequency of singletons, different 
#'s of errors, approximately the same as before.  Regressed to penalty of 
singletons.  Gives identical output for cutoff = 1 and -cutoff=2, a couple more
for -cutoff 3.

Coded -bag switch.  It adds the log-prob for each n-gram, including penalties
for misses, into the segment cross-entropy. Seems like it should work, but 
doesn't.  Tried playing with the penalties, but my strategies didn't work.
all those high penalties swept many segments into NOR, which has smallest # of
training words, hence lowest singleton penalty.
Will recode, so that it uses best probability for each gram (a flavor
of shingling.)
However, it's necessary to make sure that there's a penalty!
Coded the penalty into the bag code.  Currently -bag gives 
wentropy -bag -max_n_gram 1 -cutoff 1  737 errors
wentropy -bag -max_n_gram 2 -cutoff 1  802 errors
wentropy -bag -max_n_gram 3 -cutoff 1  833 errors

So bigrams *Still* don't work.  It's hard to see how you lose information 
considering bigrams!

Jan 24, 2017  
Abualsoud sent me a package for combining classifiers, "focal"
Spent the day considering combining packages.
settled on focal_multiclass.
made some tiny edits to port from matlab to octave:
  > added do_braindead_shortcircuit_evaluation(1,"local") to train_nary...
  > changed a couple of 
     (nargs > ...) & ~isempty(...) ... #matlab does "short-circuit" here
to   ....          && ...              # this is octave explicit "short-circuit"

Finally, about 10PM succeeded in combining the two baseline programs.
The file is dialectID/fusem.m  -- run with octave fusem.m

I'd like to complete this by combining at least the wentropy output, maybe
chars;  I'd like to see how much improvement the combination produced in
error rate.  I could do an "open" run by training the fusion on 
the vardial3 data/test  files.

Need to see how to train, test, on arbitrary files for the baseline programs.
Otherwise difficult to evaluate results.

Jan 25, 2017  (I expect to see the test data today!)
In answer to my "need to see how" of yesterday:
    svm_multiclass_learn -c 1000 train model
    svm_multiclass_classify test model hypothesis

But it is really just the test  part I need to handle.  Commented the tidy up
code at the bottom the run.sh which deletes the test and train files, so 
that I can review the formats.

The train file for multiclass learn  (for .ivec) consists of 13825 lines.
The first line(s) are an answer and 400 space separated features, the answer
is an int, for Arabic dialects from 1 to 5, each feature of the form:
362:0.104703

The train file for multiclass learn for .words consists of 14000 lines.
The lines consist of a class field followed by feature fields.
the class field is an int, 1-5.
The feature fields are of the form 96859:1
with the feature numbers, believed to correspond to unique words or bigrams in the 
text, all in order on the line.  The value for the feature appears to be the
number of times that the word occurs on the line.
the last lines seem to be in the same format.

Okay:  The word features are listed in dict.words.2.  They include
words and bigrams.  The words in a bigram are in reading order, connected with
two underscores.  
all.words.<process> is a list of the training files without anything but the words, no meta-tags, no class labelling.

for the released training data, the last feature number is 230536
Its not clear whether we can test a file with OOV words; we could
conceivably invent new feature numbers, or just omit any features for the 
new words.  It does seem like this discards information...

I notice that my latest run of the words baseline gave 738 errors, versus
786 recorded earlier?   Braino?  random numbers? cosmic rays?

I think I want to build a .wf file from a test file, using dict.words.2
I'm going to write a python program.  As a preliminary, I'll glance at the
makeDictPrepSVM.py file.  Notice that the model and the dictionary have to 
match.  And preparing stuff doesn't take very long... so maybe I don't 
need my script.

9:40 PM
dialectID/Makefile
contains instructions to make test.f4, which is a fusion of the two baseline 
files and my two files, wentropy.py and charsA on the ADI testset.

The program fails; chars.c seems to include the metatags in its input, which
is the fault of my makefile, not of anything else... so probably wentropy
does also.  Check it and fixit.

Jan 24

created a vardial4/submission directory, which holds 2 GDI runs and an ADI run,
the latter is dialectID/test.f4
