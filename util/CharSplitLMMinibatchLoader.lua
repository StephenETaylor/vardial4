-- modified on 10 Aug 2015 by Stephen Taylor (SET)
-- to allow for variable size batches and sequences
-- Modified from https://github.com/oxford-cs-ml-2015/practical6
-- the modification included support for train/val/test splits
-- SET: in my version, the split is removed again -- I split out the
-- test data separately.  but I do keep the arguments split 1 (training)
-- and split 2 (validation).

--[[
   SET: I continue to return sequences in batches of at most batch_size,
   with all sequences in a batch the same length, on the theory that
   those batches are relevant to torch optimization on graphics cards.
   But since the varDial sequences vary in length from one character to 
   18017 characters, I return sequences which are of various lengths.

   For every input character of every sequence, I return the number for the 
   dialect in the y array.  There are five dialects, and the number I return
   is 1-EGY, 2-GLF, 3-LAV, 4-MSA, 5-NOR -- table below.

   I always return the same batches, in the same order.  I never build new
   sequences by carving out subsequences of long training data, although
   my dsum program suggests that ten percent of the batches contain sequences
   of longer than 520 characters.  
]]--
local CharSplitLMMinibatchLoader = {}
CharSplitLMMinibatchLoader.__index = CharSplitLMMinibatchLoader

-- the 5 dialects from the varDial training set are assigned numbers:
dialects = {EGY = 1, GLF = 2, LAV = 3, MSA = 4, NOR = 5}


function CharSplitLMMinibatchLoader.create(data_dir, batch_size, seq_length, split_fractions)

    -- split_fractions is e.g. {0.9, 0.05, 0.05}

    local self = {}
    setmetatable(self, CharSplitLMMinibatchLoader)

    --SET: --local input_file = path.join(data_dir, 'input.txt')
    -- replaced with training and validation files
    local input_file = path.join(data_dir, 'training')
    local valid_file = path.join(data_dir, 'validation')

    local vocab_file = path.join(data_dir, 'vocab.t7')
    local tensor_file = path.join(data_dir, 'data.t7')

    -- fetch file attributes to determine if we need to rerun preprocessing
    local run_prepro = false
    if not (path.exists(vocab_file) or path.exists(tensor_file)) then
        -- prepro files do not exist, generate them
        print('vocab.t7 and data.t7 do not exist. Running preprocessing...')
        run_prepro = true
    else
        -- check if the input file was modified since last time we 
        -- ran the prepro. if so, we have to rerun the preprocessing
        -- SET : let modification time of input_file be surrogate for all edits
        local input_attr = lfs.attributes(input_file)
        local vocab_attr = lfs.attributes(vocab_file)
        local tensor_attr = lfs.attributes(tensor_file)
        if input_attr.modification > vocab_attr.modification or input_attr.modification > tensor_attr.modification then
            print('vocab.t7 or data.t7 detected as stale. Re-running preprocessing...')
            run_prepro = true
        end
    end
    if run_prepro then
        -- construct a tensor with all the data, and vocab file
        print('one-time setup: preprocessing input text file ' .. input_file .. '...')
        CharSplitLMMinibatchLoader.text_to_tensor(input_file, vocab_file, tensor_file)
    end

    print('loading data files...')
    local data = torch.load(tensor_file)
    --dbg()  -- When not commented out, this is a breakpoint for debugger.LUA
    self.vocab_mapping = torch.load(vocab_file)
    self.data_tab = data.data_tab
    self.longest_sequence = data.largest
    
    -- count vocab
    self.vocab_size = 0
    for _ in pairs(self.vocab_mapping) do 
        self.vocab_size = self.vocab_size + 1 
    end

    -- count number of sequences in training data
    self.ntrain = 0
    for i = 1, self.longest_sequence do
        local seq_table = self.data_tab[i]
        if seq_table then
            self.ntrain = self.ntrain + #seq_table
        end -- if seq_table
    end -- for i

--[[ SET much of this code now irrelevant...

    -- cut off the end so that it divides evenly
    local len = data:size(1)
    if len % (batch_size * seq_length) ~= 0 then
        print('cutting off end of data so that the batches/sequences divide evenly')
        data = data:sub(1, batch_size * seq_length 
                    * math.floor(len / (batch_size * seq_length)))
    end

    -- count vocab
    self.vocab_size = 0
    for _ in pairs(self.vocab_mapping) do 
        self.vocab_size = self.vocab_size + 1 
    end

    -- self.batches is a table of tensors
    print('reshaping tensor...')
    self.batch_size = batch_size
    self.seq_length = seq_length

    local ydata = data:clone()
    ydata:sub(1,-2):copy(data:sub(2,-1))
    ydata[-1] = data[1]
    self.x_batches = data:view(batch_size, -1):split(seq_length, 2)  -- #rows = #batches
    self.nbatches = #self.x_batches
    self.y_batches = ydata:view(batch_size, -1):split(seq_length, 2)  -- #rows = #batches
    assert(#self.x_batches == #self.y_batches)

    -- lets try to be helpful here
    if self.nbatches < 50 then
        print('WARNING: less than 50 batches in the data in total? Looks like very small dataset. You probably want to use smaller batch_size and/or seq_length.')
    end

    -- perform safety checks on split_fractions
    assert(split_fractions[1] >= 0 and split_fractions[1] <= 1, 'bad split fraction ' .. split_fractions[1] .. ' for train, not between 0 and 1')
    assert(split_fractions[2] >= 0 and split_fractions[2] <= 1, 'bad split fraction ' .. split_fractions[2] .. ' for val, not between 0 and 1')
    assert(split_fractions[3] >= 0 and split_fractions[3] <= 1, 'bad split fraction ' .. split_fractions[3] .. ' for test, not between 0 and 1')
    if split_fractions[3] == 0 then 
        -- catch a common special case where the user might not want a test set
        self.ntrain = math.floor(self.nbatches * split_fractions[1])
        self.nval = self.nbatches - self.ntrain
        self.ntest = 0
    else

        -- divide data to train/val and allocate rest to test
        self.ntrain = math.floor(self.nbatches * split_fractions[1])
        self.nval = math.floor(self.nbatches * split_fractions[2])
        self.ntest = self.nbatches - self.nval - self.ntrain -- the rest goes to test (to ensure this adds up exactly)
    end

]]--

    -- SET: these may not get exercised any more, but we'll see.
    self.split_sizes = {self.ntrain, self.nval, self.ntest}
    self.batch_ix = {0,0,0} -- SET: this turns out to be harmless
    self.batch_ix2 = {1,1,1} -- but first index is 1 for non-sparse Lua array

    -- print(string.format('data load done. Number of data batches in train: %d, val: %d, test: %d', self.ntrain, self.nval, self.ntest))
    collectgarbage()
    return self
end

function CharSplitLMMinibatchLoader:reset_batch_pointer(split_index, batch_index)
    batch_index = batch_index or 0
    self.batch_ix[split_index] = batch_index
    self.batch_ix2[split_index] = 1
end

function CharSplitLMMinibatchLoader:next_batch(split_index)
    if self.split_sizes[split_index] == 0 then
        -- perform a check here to make sure the user isn't screwing something up
        local split_names = {'train', 'val', 'test'}
        print('ERROR. Code requested a batch for split ' .. split_names[split_index] .. ', but this split has no data.')
        os.exit() -- crash violently
    end
    -- split_index is integer: 1 = train, 2 = val, 3 = test

    while true do 
        local seq_array = self.data_tab[self.batch_ix[split_index]]
        if seq_array == nil then 
            self.batch_ix[split_index] = self.batch_ix[split_index] + 1
            self.batch_ix2[split_index] = 1
        elseif self.batch_ix2[split_index] > #(seq_array) then 
            self.batch_ix[split_index] = self.batch_ix[split_index] + 1
            self.batch_ix2[split_index] = 1
        elseif self.batch_ix[split_index] > self.split_sizes[split_index] then
            return nil, nil -- warn caller we have finished, let her call reset_batch_pointer
            --self.batch_ix[split_index] = 1 -- cycle around to beginning
        else 

            local bat_siz = math.min(opt.batch_size, 1+#(seq_array) - self.batch_ix2[split_index])
            local seq_siz = math.min(opt.seq_length, self.batch_ix[split_index])
            -- construct a tensor holding the data
            -- it is wide enough for these sequences (all of which are
            --  self.batch_ix[split_index] long)
            -- and has one row for each item in the batch.
            --  (batch size is a least one, and at most opt.batch_size)
            local answer_x = torch.Tensor(bat_siz,seq_siz)
            local answer_y = torch.Tensor(bat_siz,seq_siz)
            for b =1, bat_siz do
                local seq_obj = seq_array[self.batch_ix2[split_index] + b -1]
                -- if not seq_obj then dbg() end
                local t = 0
                answer_x[b]:apply
                    (function(x) 
                        t = t + 1
                        return self.vocab_mapping[seq_obj.text:sub(t,t)]
                     end -- function
                    )
                answer_y[b]:fill(seq_obj.y)
            end -- for b
            self.batch_ix2[split_index] = bat_siz + self.batch_ix2[split_index]
            return answer_x, answer_y
        end -- else
    end -- while true

    --[[ SET: different mechanism...
    -- pull out the correct next batch
    local ix = self.batch_ix[split_index]
    if split_index == 2 then ix = ix + self.ntrain end -- offset by train set size
    if split_index == 3 then ix = ix + self.ntrain + self.nval end -- offset by train + val
    return self.x_batches[ix], self.y_batches[ix]
    ]]--
end

-- *** STATIC method ***
--[[
  SET:
  This method reads through the training file and builds 
   a vocabulary file
    written out with the torch.save, which defaults to saving a datum in a
    binary file.  
    The datum consists of a table, vocab_mapping, which 
     has one entry for each vocabulary character, the (dense) character number.
     Thus the vocab_mapping turns ASCII characters (Lua doesn't support Unicode)
     into numbers in the range 1-65 [for the varDial training data.]
     Probably I should consider the possibility of new characters in the input,
     possibly assigning them all a number of 0?  or 66?  (Since test data might
     include new characters.  Real Arabic often includes quotations or single 
     words in English or French, and Twitter Arabic often includes ritual
     punctuation, Arabish and emoticons.  The training data includes little 
     punctuation.  This is probably good, since otherwise the RNN would focus
     on the punctuation.)
    and
   a tensorfile
    written out with torch.save, and reloaded with torch.load
    The Karpathy version of this file was a single tensor, data, 
     pre-processed so that 
      a batch could be a view of the tensor, 
      although it looks like the batch wants to be contigous.
    my datastructure is a table/object data, with two attributes:
     attribute data_tab is a table, data_tab, with one entry per sequence length.
     attribute largest is a number, the largest index in this data_tab
      (#data_tab is not useful, because data_tab is sparse -- not every 
       possible length has an entry. [Lua tables are hash-maps.]
     Every sequence length which exists in the training data has a 
      sequence table in data_tab, that is data_tab[number] returns
         a sequence table.
       Each sequence table is a numbered list/array of sequence objects
       a sequence object has two attributes:
        text -- a string of characters
        y -- a number from 1 to 5

    Another significant difference between the Karpathy storage scheme and
    mine is that the character translation for my data must be reperformed
    at each use.  This is obviously avoidable, and I could keep the text string
    in the sequence objects in byte tensors, instead, if it proves to be a
    bottleneck -- but I want to avoid premature optimization, and keep
    the possibility of randomization of the input slightly open.

 The Karpathy scheme used the first part of the data tensor for the 
 training data, the next part for validation data, and the final part
 for test data (if any).  Since I've split off training, validation, and test
 into separate files, my plan is to duplicate the data_tab structure 
 for the validation data, and leave the test data for another program, which
 I'll write while watching how well this one trains.

 As of Aug 11, 2016 I don't actually read in the validation data.

]]--
function CharSplitLMMinibatchLoader.text_to_tensor(in_textfile, out_vocabfile, out_tensorfile)
    local timer = torch.Timer()

    print('loading text file...')
    local cache_len = 10000
    local rawdata
    local tot_len = 0
    local f = assert(io.open(in_textfile, "r"))

    -- create vocabulary if it doesn't exist yet
    print('creating vocabulary mapping...')
-- SET: I made this variable global, even though it is only used here...
-- defined at the beginning of this file
--    local dialects = {EGY = 1, GLF = 2, LAV = 3, MSA = 4, NOR = 5}
    local data_tab = {}
    local largest = 0     -- largest index in data_tab

    -- record all characters to a set

    local unordered = {}
    -- rawdata = f:read(cache_len)
    local line = ''
    local rix = 0
    -- SET:  replace the more efficient 10000 character reads
    -- with single line reads to simplify the logic
    -- repeat
    
    line = f:read()     -- read a  single line from file
    while line do
        -- break line into fields
        local t1 = line:find('\t')
        local t2 = line:find('\t',t1+1)
        local text = line:sub(1,t1-1)
        local ltext = text:len()
        local dial = line:sub(t2+1,-1)
        -- add characters to vocabulary
        for char in text:gmatch'.' do
            if not unordered[char] then unordered[char] = true end
        end
        -- store characters into sequence object, with y value;
        local seq_obj = {text = text, y = dialects[dial]}

        -- store sequence object into table of other sequences of same length
        local next_index
        if not data_tab[ltext] then -- if no entry yet for this length
            data_tab[ltext] = {}
            next_index = 0
        else
            local joe = data_tab[ltext]
            next_index = #joe
        end -- if not data_tab[ltext]
        data_tab[ltext][next_index+1] = seq_obj
        if ltext > largest then largest = ltext end

        line = f:read()     -- read the next line from file
    end -- of while loop

--[[  some code I am removing SET:
        for char in rawdata:gmatch'.' do
            if not unordered[char] then unordered[char] = true end
        end
        tot_len = tot_len + #rawdata
        rawdata = f:read(cache_len)
    until not rawdata
]]--
        
    f:close()
 
    -- sort vocabulary into a table (i.e. keys become 1..N)
    local ordered = {}
    for char in pairs(unordered) do ordered[#ordered + 1] = char end
    table.sort(ordered)
    -- invert `ordered` to create the char->int mapping
    local vocab_mapping = {}
    for i, char in ipairs(ordered) do
        vocab_mapping[char] = i
    end
-- SET: build a table/object containing the data, which, unlike the 
-- original scheme, will still have to be reprocessed with the vocabulary
    local data = {data_tab = data_tab, largest = largest}
-- construct a tensor with all the data

--    print('putting data into tensor...')
--    local data = torch.ByteTensor(tot_len) -- store it into 1D first, then rearrange
--    f = assert(io.open(in_textfile, "r"))
--    local currlen = 0
--    rawdata = f:read(cache_len)
--    repeat
--        for i=1, #rawdata do
--            data[currlen+i] = vocab_mapping[rawdata:sub(i, i)] -- lua has no string indexing using []
--        end
--        currlen = currlen + #rawdata
--        rawdata = f:read(cache_len)
--    until not rawdata
--    f:close()

    -- save output preprocessed files
    print('saving ' .. out_vocabfile)
    torch.save(out_vocabfile, vocab_mapping)
    print('saving ' .. out_tensorfile)
    torch.save(out_tensorfile, data)
end

return CharSplitLMMinibatchLoader

