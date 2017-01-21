all:	data_LAV training testform.txt

training:	task2-train.txt split-task.py
	python3 split-task.py <task2-train.txt

data_LAV:	training
	python3 xliterate.py -infile training

# 'training' is a proxy for 'testing' file
#  and testform.py always write test.txt file
test.txt:	training
	python3 testform.py <testing


#
charsA:	chars.c
	gcc -D ARABIC chars.c -lm -o charsA

charsG:	chars.c
	gcc -D GDI chars.c -lm -o charsG

%.stat:	cv/%.t7
	th test.lua -init_from $^ < varDialTrainingData/test.txt | (cd varDialTrainingData; th statistics.lua )

phstats1:	charsA
	./charsA   | (cd varDialTrainingData; th statistics.lua  ) 

phstats2:	charsA
	./charsA  -test ctxt | (cd varDialTrainingData; th statistics.lua -gold ../dtest.txt ) 

wenstats7:	
	python3 wentropy.py -max_n_gram 3 -test ctxt | (cd varDialTrainingData; th statistics.lua -gold ../dtest.txt ) 

wenstats6:	
	python3 wentropy.py -max_n_gram 3  | (cd varDialTrainingData; th statistics.lua  ) 

wenstats5:	
	python3 wentropy.py -max_n_gram 2 -test ctxt | (cd varDialTrainingData; th statistics.lua -gold ../dtest.txt ) 

wenstats4:	
	python3 wentropy.py -max_n_gram 2  | (cd varDialTrainingData; th statistics.lua  ) 

wenstats3:	
	python3 wentropy.py  -test ctxt | (cd varDialTrainingData; th statistics.lua -gold ../dtest.txt ) 

wenstats2:	
	python3 wentropy.py   | (cd varDialTrainingData; th statistics.lua  ) 

wenstats1:	
	python3 varDial3/wentropy.py -test ctxt | (cd varDialTrainingData; th statistics.lua -gold ../dtest.txt ) 

wenstats0:	
	python3 wentropy.py | (cd varDialTrainingData; th statistics.lua ) 


wordstats3:	
	python3 wordfreq.py  -test ctxt | (cd varDialTrainingData; th statistics.lua -gold ../dtest.txt ) 

wordstats2:	
	python3 wordfreq.py   | (cd varDialTrainingData; th statistics.lua  ) 

wordstats1:	
	python3 ../varDial3/wordfreq.py -test ctxt | (cd varDialTrainingData; th statistics.lua -gold ../dtest.txt ) 

wordstats0:	
	python3 ../varDial3/wordfreq.py | (cd varDialTrainingData; th statistics.lua ) 

p88.txt:	wordfreq.py
	python3 wordfreq.py -test varDialTrainingData/valid.txt -pout p88.txt > q88.txt

p76.txt:	varDialTrainingData/valid.txt
	th test.lua -init_from cv/lm_lstm_epoch0.16_1.3176.t7 -probs_file p76.txt < varDialTrainingData/valid.txt > q76.txt

p69.txt:	varDialTrainingData/valid.txt
	th test.lua -init_from cw/lm_lstm_epoch0.32_1.4369.t7 -probs_file p69.txt < varDialTrainingData/valid.txt > q69.txt

c3data.mat:	p88.txt p76.txt p69.txt varDialTrainingData/validation
	(cd ex4; python3 make_mat_file.py > $@)



vprobs:	p88.txt p76.txt p69.txt

c3train:	c3data.mat
	(cd ex4; octave ex4.m)

%.c3:	%
	python3 wordfreq.py -test varDialTrainingData/valid.txt -pout ex4/m1.txt -test $< > q88.txt
	th test.lua -init_from cv/lm_lstm_epoch0.16_1.3176.t7 -probs_file ex4/m2.txt < $<  > q76.txt
	th test.lua -init_from cw/lm_lstm_epoch0.32_1.4369.t7 -probs_file ex4/m3.txt < $<  > q69.txt
	(cd ex4; octave combiner.m; python3 make_output.py ../$< > ../$@)
