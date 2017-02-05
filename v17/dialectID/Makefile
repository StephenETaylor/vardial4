v4	=../..
v4v	=${v4}/varDialTrainingData
dt	=data/train.vardial2017
dd	=data/dev.vardial2017
this	=${PWD}
vd3	=/home/staylor/summer16/varDial
cv	=${vd3}/cv
 

all:	teste

hypothesis:
	./run.sh

hypothesisw:
	./runw.sh

testc:	${dt}/train17.txt ${v4}/charsA
	${v4}/charsA -train ${dt}/train17.txt -test ${dd}/test.txt | (cd ${v4v};th statistics.lua -gold ${this}/${dd}/gold.txt)

teste:	${dt}/train17.txt ${v4}/wentropy.py
	python3 ${v4}/wentropy.py -train ${dt}/train17.txt -test ${dd}/test.txt | (cd ${v4v};th statistics.lua -gold ${this}/${dd}/gold.txt)

hc:	${dt}/train17.txt ${v4}/charsA
	${v4}/charsA -train ${dt}/train17.txt -test ${dd}/test.txt -hout $@ >/dev/null

testc.txt:	${dt}/train17.txt ${v4}/charsA
	${v4}/charsA -train ${dt}/train17.txt -test ${dd}/test.txt >testc.txt

he:	${dt}/train17.txt ${v4}/wentropy.py
	python3 ${v4}/wentropy.py -train ${dt}/train17.txt -test ${dd}/test.txt -hout $@ >/dev/null

teste.txt:	${dt}/train17.txt ${v4}/wentropy.py
	python3 ${v4}/wentropy.py -train ${dt}/train17.txt -test ${dd}/test.txt >teste.txt

voted.txt:	vote.py hypothesis hypothesisw teste.txt testc.txt
	python3 vote.py > voted.txt

vstats:	voted.txt
	cat voted.txt | (cd ${v4v};th statistics.lua -gold ${this}/${dd}/gold.txt)

# build the train17.txt, gold.txt, test.txt files from released training, dev
data:	
	(cd data; make)
 
test.iv:	test.ivec Makefile
	cat test.ivec | awk '{printf("2 ");for (i=2;i<=NF;i++){printf "%d:%f ",i-1,$$i;if(i==NF){printf "\n"}}}' > $@

test.hyp:	test.iv
	./scripts/svm_multiclass_classify test.iv model3186 $@

test.wf:	ADI-test-words.txt Makefile
	python3 ./scripts/txt2wf.py < ADI-test-words.txt > $@

test.hyw:	test.wf
	./scripts/svm_multiclass_classify test.wf model4186 $@
	
test.f2:	test.hyp test.hyw
	octave fuse2.m 


# h? are files produced by classifying the dev.vardial2017 set.
# rf is the correct answers for that set
# test.hy? are files produced by classifying the test data
# test.f4 is a fusion of all four files
test.f4:	test.hyp test.hyw test.hye test.hyc hs hw hc he rf
	octave fuse4.m 


ADI-test-words.tx:	ADI-test-words.txt
	cat $^ | cut -d ' ' -f2- > $@

test.hye:	ADI-test-words.tx ${dt}/train17.txt ${v4}/wentropy.py
	python3 ${v4}/wentropy.py -train ${dt}/train17.txt -test ADI-test-words.tx -hout $@ >/dev/null

test.hyc:	ADI-test-words.tx ${dt}/train17.txt ${v4}/charsA
	${v4}/charsA -train ${dt}/train17.txt -test ADI-test-words.tx -hout $@ >/dev/null

# utilise (one of the) vardial3 neural networks
#   run nn on vardial3 data
%.stat: 
	(cd ${vd3}; th test.lua -init_from ${cv}/lm_lstm_epoch0.16_1.3176.t7 < varDialTrainingData/test.txt) | (cd ${v4v}; th statistics.lua )

#   run nn on vardial4/dev data
#   (this run fails.  I surmise that the character sets are incompatible.)
ndstats:
	(cd ${vd3}; th test.lua -init_from ${cv}/lm_lstm_epoch0.16_1.3176.t7 < ${this}/${dd}/test.txt) | (cd ${v4v}; th statistics.lua -gold ${this}/${dd}/gold.txt)

mtrain.txt:	${v4v}/training ${dt}/train17.txt
	cat $^ > $@

mstats:	mtrain.txt ${v4}/wentropy.py
	python3 ${v4}/wentropy.py -train mtrain.txt -test ${dd}/test.txt | (cd ${v4v};th statistics.lua -gold ${this}/${dd}/gold.txt)
