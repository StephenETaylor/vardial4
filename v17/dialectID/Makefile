v4	=../..
v4v	=${v4}/varDialTrainingData
dt	=data/train.vardial2017
dd	=data/dev.vardial2017
this	=${PWD}

all:	teste

hypothesis:
	./run.sh

hypothesisw:
	./runw.sh

testc:	${dt}/train17.txt ${v4}/charsA
	${v4}/charsA -train ${dt}/train17.txt -test ${dd}/test.txt | (cd ${v4v};th statistics.lua -gold ${this}/${dd}/gold.txt)

teste:	${dt}/train17.txt ${v4}/wentropy.py
	python3 ${v4}/wentropy.py -train ${dt}/train17.txt -test ${dd}/test.txt | (cd ${v4v};th statistics.lua -gold ${this}/${dd}/gold.txt)

testc.txt:	${dt}/train17.txt ${v4}/charsA
	${v4}/charsA -train ${dt}/train17.txt -test ${dd}/test.txt >testc.txt

teste.txt:	${dt}/train17.txt ${v4}/wentropy.py
	python3 ${v4}/wentropy.py -train ${dt}/train17.txt -test ${dd}/test.txt >teste.txt

voted.txt:	vote.py hypothesis hypothesisw teste.txt testc.txt
	python3 vote.py > voted.txt

vstats:	voted.txt
	cat voted.txt | (cd ${v4v};th statistics.lua -gold ${this}/${dd}/gold.txt)

# build the train17.txt, gold.txt, test.txt files from released training, dev
data:	
	(cd data; make)
 

