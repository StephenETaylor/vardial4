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

GDI-test.te:	wentropy.py training GDI-test.txt
	python3 wentropy.py -train training -test GDI-test.txt -nextDialect BE -nextDialect  BS -nextDialect LU -nextDialect ZH > $@

GDI-test.tc:	${CHARDIR}/charsG training GDI-test.txt
	${CHARDIR}/charsG -train training -test GDI-test.txt > $@

GDI-test.e:	GDI-test.te
	cat $^ | cut -d '	' -f2 > $@

GDI-test.c:	GDI-test.tc
	cat $^ | cut -d '	' -f2 > $@

