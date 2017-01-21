#!/usr/bin/env python3
"""
 convert the GDI-train file to the vardial3 arabic train format
 by substituting '\tQ\t' for '\t'
"""

import sys
for line in sys.stdin:
    line = line.strip()        # discard trailing spaces
    f = line.find('\t')
    print(line[:f]+'\tQ\t'+line[f+1:])

    
