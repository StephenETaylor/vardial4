STATSDIR =../../../varDialTrainingData
CHARDIR =../../..

all:	wenstats0

train3.txt:	GDI-TRAIN.txt silly.py
	python3 silly.py <GDI-TRAIN.txt >$@

# make training, validation, testing data split
testing:	split-task.py train3.txt
	python3 split-task.py <train3.txt

test.txt:	testing testform.py
	python3 testform.py 

wenstats0:	wentropy.py test.txt
	python3 wentropy.py -train training -test test.txt -nextDialect BE -nextDialect  BS -nextDialect LU -nextDialect ZH | (cd ${STATSDIR}; th statistics.lua -gdi  -gold ${PWD}/testing)

phstats:	${CHARDIR}/charsG test.txt
	${CHARDIR}/charsG -train training -test test.txt | (cd ${STATSDIR}; th statistics.lua -gdi  -gold ${PWD}/testing)
