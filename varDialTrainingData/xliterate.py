#!/usr/bin/python3
#
# class m extracted from a python2 script
#
# this file intended to read the varDial training data for
# the arabic dialect task and separate the data into
# 5 files, one for each dialect,
# at the same time changing the text from the Buckwalter transliteration
# to Unicode

# It makes sense to glance over the data to see whether it actually
# seems to be in the appropriate dialect, and that's a lot easier 
# to do in Arabic script

import sys

#parse command line
ignore = True	# ignore the scriptname argument
infile = 'task2-train.txt'
for i,a in enumerate(sys.argv):
   if ignore: ignore = False; continue
   if a[0] == '-':
      if a == '-infile': infile = sys.argv[i+1]; ignore = True
      else: sys.stderr.write('?unknown flag '+ a)
   else: sys.stderr.write('? parameter without -\n')

class m:

   def __init__(self):
      return

   #utility functions Buckwalter-to-Unicode and vice versa
   alphabetBW  = "0123456789%'> <{|AY~btpvjHxd*rzs$SDTZEgfqklmnhw&y}FKNaiu"
   arabicA  = u"0123456789%ءأ إٱآاىّبتةثجحخدذرزسشصضطظعغفقكلمنهوؤيئًٌٍَُِ"

   # argument bw: string in Buckwalter transliteration
   # returns    : unicode string
   def b2u(self, bw ) :
        try:
            ans = u""
            for  ch  in bw:
                offset  = self.alphabetBW.index(ch)
                ans = ans + self.arabicA[offset]            
            return ans
        except:
            print("missing character in Buckwalter to Unicode ",ch, ord(ch))
            return "OOPS"

   # argument arabicText: string in Unicode consisting of only Arabic characters
   # returns            : string of Ascii characters, the Buckwalter transliteration
   def u2b(self,arabicText) :
            ans = ""
            for ch in arabicText :
                offset  = self.arabicA.index(ch)
                ans = ans + self.alphabetBW[offset]            
            return ans

   # accepts a string in Buckwalter transliteration and 
   # returns a string in Buckwalter transliteration without 
   #     vowels, tashdid, tatwil
   def removeDiacritics(self,arabicText) :
      ans = arabicText
      for i in range(len(ans)-1,0,-1):
         if ans[i] in "aiu 	~_'" : ans= ans[:i]+ans[i+1:]
      return ans

# end of class def m

#test scaffold to extract some data from training file
if __name__ == "__main__":
   count = 0
   x = m()
   # files to hold each of the dialect texts
   out = {}
   for k in ['NOR', 'EGY', 'GLF', 'LAV', 'MSA']:
      out[k] = open('data_'+k,'w')
      
   inf = open(infile)
   for line in inf:
      t1 = line.find('\t')
      t2 = line.find('\t',t1+1)
      text = line[:(t1)]
      utext = x.b2u(text)
      dialect = line[t2+1:t2+4]
      out[dialect].write(utext);
      out[dialect].write('\n')
      count += 1

   for k in out.keys():
      out[k].close()
   print("wrote",count,"lines")
   inf.close()
