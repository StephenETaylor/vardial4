#!th
-- this is a lua file whose job it is to examine the test input for the
-- second varDial task, distinguishing dialects of Arabic.

variants = {}   -- number of different dialects found in the training data
vocab = {}      -- individual characters occuring in training data
nextVocab = 1   -- the index for the next vocabulary item we will encounter
largest = 0     -- the length of the longest training string seen so far
trlens = {}      -- training data length list
trlenp = 1      -- next index for a training data length item
totlen = 0      -- total number of characters in all training items

fn = io.open('varDialTrainingData/task2-train.txt','r')
st = fn:read()
while st do
    t1 = st:find('\t')
    t2 = st:find('\t',t1+1)
    q = st:sub(t1+1,t2-1)
    if q ~= 'Q' then
        print (t1, t2, q, q:len())
    end -- if q ~=
    dial = st:sub(t2,-1)
    if nil ~=  (variants[dial]) then 
        variants[dial] = 1 + variants[dial]
    else
        -- print(dial)
        variants[dial] = 1
    end -- if not exists

    -- keep track of number of characters in training set
    for t = 1, t1-1 do
        c = st:sub(t,t) 
        if nil == vocab[c] then
            -- print (c,string.byte(c),nextVocab)
            vocab[c] = nextVocab
            nextVocab = 1 + nextVocab
        end -- if 
    end -- for

    trlens[trlenp] = t1-1
    trlenp = 1 + trlenp
    totlen = t1-1 + totlen

    if largest < t1 then 
        largest =  t1 
        -- print(t1,st:sub(1,t1-1))
    end  -- length of largest training string
    st = fn:read()
end -- while
for k,v in pairs(variants) do 
    print (k,v)
end -- for

table.sort(trlens)
print ('total number of items', trlenp-1)
print ('smallest item', trlens[1])
print('ten %-tile', trlens[math.floor((trlenp-1)*0.1)])
print ('median size of items', trlens[math.floor((trlenp-1)/2)])
print('niney %-tile', trlens[math.floor((trlenp-1)*0.9)])
print ('longest training string is', largest-1, trlens[trlenp-1])
print ('total number of characters in training file', totlen)
print ('number of distinct characters in training set', nextVocab-1)
vv = string.rep('!',nextVocab-1)
for c,v in pairs(vocab) do

   vv = vv:sub(0,v-1) .. c .. vv:sub(v+1,-1)       -- vv:sub(v,v ) = c
end
--print (vocab)
print ('"'..vv..'"')
