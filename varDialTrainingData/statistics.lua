#!th statistics.lua
--[[
  Stephen Taylor 17 August 2016

  This program reads a test output file, and compares it to "testing"
  to determine hits and errors.
  Provides some statistics.

  The interesting file name is provided as the first argument on the cmd line
--]]

dbg = require "LuaDebugger.debugger"

dialects = {EGY = 1, GLF = 2, LAV = 3, MSA = 4, NOR = 5}
idialect = {}
for k,v in pairs(dialects) do idialect[v] = k end -- for k,v

crosserrors = {{0,0,0,0,0}, {0,0,0,0,0}, {0,0,0,0,0}, {0,0,0,0,0}, {0,0,0,0,0} }
totalerror = 0

finterest = io.stdin  --io.open(arg[1],'r')
fref = io.open('testing','r')
if not fref then print ('?cannot open "testing"') end --if not fref

-- read through the answer file
number = 0
refline = fref:read()
while refline do
    number = number + 1 -- don't count the number of reads, since last one fails
    local t1 = refline:find('\t')
    local t2 = refline:find('\t',t1+1)
    reftext = refline:sub(1,t1-1)
    refdial = refline:sub(t2+1,t2+3)

    intline = finterest:read()
    t1 = intline:find('\t')
    if not t1 then 
        print ('could not find tab in line:',intline)
    end -- if not t1
--    dbg()
    inttext = intline:sub(1,t1-1)
    intdial = intline:sub(t1+1,t1+3)

    if reftext ~= inttext then
        print ('?texts do not match in line', number)
    end -- if reftext
    local cr = dialects[refdial]
    local cc = dialects[intdial]
    crosserrors[cr][cc] = crosserrors[cr][cc] + 1
    if refdial ~= intdial then
        totalerror = totalerror + 1
    end -- if refdial

    -- get next reference line
    refline = fref:read()
end -- while refline

-- print summary
print('total number of lines',number)
print('total number of errors',totalerror)
print('fraction wrong', totalerror/number)
print()
io.write('ref\\test')

for c = 1,5 do io.write('     '..idialect[c]) end -- for c
io.write('\n')

for r = 1,5 do
    io.write(idialect[r]..'       ')
    for c = 1,5 do
        io.write(string.format("%5d   ",crosserrors[r][c]))
    end -- for c
    io.write('\n')
end -- for r
