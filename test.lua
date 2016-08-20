#!th
--[[
This program is part of the code for a character based LSTM RNN language
classifier.  It evaluates the test data, based on previously trained
model.

The idea is to read test data from standard input 
in the format string\n
and
a checkpoint file, indicated with -init_from chkpt_path
and possibly other flags (-seg_length applies only to training?)
and write an output file  
 in the format 
string<tab>dialect
 where dialect is one of 
dialects = {EGY = 1, GLF = 2, LAV = 3, MSA = 4, NOR = 5}


This code strongly based on 
https://github.com/karpathy/char-rnn

See his comments for his sources;
I faintly remember that he might have said his code was released under MIT
license, but my additions are public domain.



--]]



dialects = {EGY = 1, GLF = 2, LAV = 3, MSA = 4, NOR = 5}
chkpt = 'cv/lm_lstm_epoch1.02_1.5529.t7'

require 'torch'
require 'nn'
require 'nngraph'
require 'optim'
require 'lfs'

require 'util.OneHot'
require 'util.misc'

dbg = require 'LuaDebugger.debugger'

-- invert dialects
idialects = {}
for k,v in pairs(dialects) do idialects[v] = k end -- for

-- parse command line
interactive = false
verbose = false
ignore = false
for i=1,#arg do 
    if not ignore then 
        if arg[i] == '-init_from' then
            chkpt = arg[i+1]
            ignore = true
        elseif arg[i] == '-verbose' then 
            verbose = true 
        elseif arg[i] == '-interactive' then 
            interactive = true 
        else 
            print('unknown flag', arg[i], 'usage:\nth test.lua -init_from chkpt')
        end -- if arg[i] = 'init_from'
    else -- ignore was true
        ignore = false
    end -- if not ignore
end -- for

-- read checkpoint file
checkpoint = torch.load(chkpt)

-- set up neural network from checkpoint
protos = checkpoint.protos
protos.rnn:evaluate() -- put in eval mode so that dropout works properly

-- initialize the vocabulary (and its inverted version)
local vocab = checkpoint.vocab
local ivocab = {}
for c,i in pairs(vocab) do ivocab[i] = c end

if verbose then
    print('creating an ' .. checkpoint.opt.model .. '...')
end -- if verbose

-- initialize the rnn state to all zeros
local current_state
current_state = {}
for L = 1,checkpoint.opt.num_layers do
    -- c and h for all layers
    local h_init = torch.zeros(1, checkpoint.opt.rnn_size):double()
--    if opt.gpuid >= 0 and opt.opencl == 0 then h_init = h_init:cuda() end
--    if opt.gpuid >= 0 and opt.opencl == 1 then h_init = h_init:cl() end
    table.insert(current_state, h_init:clone())
    if checkpoint.opt.model == 'lstm' then
        table.insert(current_state, h_init:clone())
    end
end
        
state_size = #current_state
local saved_init = clone_list(current_state)

-- read test lines from standard input
testInput = io.read()
while testInput do
    -- echo input
    if verbose then
        print(testInput)
    end -- if verbose

    -- convert to model vocabulary

    -- restart from blank state
    current_state = clone_list(saved_init)

    -- run neural network
    for t=1,string.len(testInput) do
        protos.rnn:evaluate() -- for dropout proper functioning
        local x = torch.Tensor {vocab[testInput:sub(t,t)]}
        local lst = protos.rnn:forward{x, unpack(current_state)}
        current_state = {}
        for i=1,state_size do table.insert(current_state, lst[i]) end
        prediction = lst[#lst]
        -- loss = loss + protos.criterion[t]:forward(prediction, y[t])

        -- report current prediction
        probs = torch.exp(prediction):squeeze()
        probs:div(torch.sum(probs)) -- renormalize so probs sum to one

        -- show partial results
        if verbose then
            print('char',t,'predict',probs[1],probs[2],probs[3],probs[4],probs[5])
        end -- if verbose
    end

-- print result
    max = 1
    for i = 2,5 do if probs[i] > probs[max] then max = i end end -- end if and end for
    if verbose then
        print (max,':',idialects[max])
    else
        print (testInput..'\t'..idialects[max]) -- standard output format
    end -- if

    if interactive then
        io.write('ready? ')
        io.read()
    end -- if interactive

-- get next input
    testInput = io.read()

end -- while testInput
