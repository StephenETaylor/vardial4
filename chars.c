/* 
 * a program to use quite long strings to prepare a character-based 
 * language model based on entropy 
 */
// moved this define into makefile.  should #define ARABIC or #define GDI
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
void perror(const char *s);
#include <errno.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

typedef int bool;
bool false = 0;
bool true = 1;

char* data; // array holds the training data
int Verbose; // command line flag
int maxTrainingSize = 1800000;
char trainFile[100]="varDialTrainingData/training";
char testFile[100]="varDialTrainingData/test.txt";
char houtFile[100]="";
FILE* fhout;
int maxLines = 8000;
// for the Arabic dialects case
#ifdef ARABIC
#define numDialects  (5)
#elif GDI
#define numDialects  (4)
#endif

int maxString = 25; // we'll try longer strings later.

typedef struct strptr {
    int base; // the beginning of the string (in the data array)
    int length; // number of characters in the string
    int count[numDialects];  // number of times this string duplicated (need count for each dialect)
} strptr;
int strptrSize; //strptrSize = sizeof(strptr) + (numDialects-1)*(sizeof(int));

typedef struct htab {
    strptr* base;
    int length;
    int numEntries;
} htab;

strptr* tstrings; // char* to base of training strings array
htab* hashtables;
int current_line=0;
int* totals; //[maxString][numDialects];totals for each size for each dialect;
                                    // over all string sizes at [0][dialect]


#ifdef ARABIC
char* dialects[] = {"EGY", "GLF", "LAV", "MSA", "NOR"};
int dialectLookup(strptr* st){
    unsigned char c0 = data[st->base];
    switch (c0){
    case 'E': return 0;
    case 'G': return 1;
    case 'L': return 2;
    case 'M': return 3;
    case 'N': return 4;
    default: fprintf(stderr,"?unrecognized dialect %c \n",c0);
         return 3;
    }
}
#elif GDI
char* dialects[] = {"BE", "BS", "LU", "ZH"};
int dialectLookup(strptr* st){
    unsigned char c0 = data[st->base];
    switch (c0){
    case 'B':
          if ('E' == data[1+st->base]) return 0;
          else return 1;
    case 'L': return 2;
    case 'Z': return 3;
    }
}
#endif

/*
//This is a terrible hash function...
//But I am still wondering about the scheme to use longs in the loop...
int hash(strptr* x){
    int answer = 0;  // below I assume that an int is 32 bits.
                     // and a long or char* is 64bits.
    int i=0;
    char* p = &data[x->base];
    if (x->length < 8){
        for (; i<x->length; i++)
            answer += (*p) << (i%4);
    } else {
        for (; ((long)p&3) !=0; i++)
            answer += (*p++) << (i%4);
        int* wp = (int*)p;
        for (; i<(x->length % 4); i+=4)
            answer += *wp++;
        p = (char*)wp;
        for (; i<x->length; i++)
            answer += (*p++) << (i%4);
    }
    return answer;
}
*/

// after djb2() by Dan Bernstein
unsigned long hash(strptr* str) {
    unsigned long hash = 5381;
    int i;
    int c;

    char* p = &data[str->base];
    for (i=0; i< str->length; i++){
        c = *p++;
        hash = ((hash << 5) + hash) + c; /* hash * 33 + c */
    }

    return hash;
}



bool isEq(strptr* x, strptr* y){
    int i;
    if (x->length != y->length) return false;
    char* px = &data[x->base];
    char* py = &data[y->base];
    for (i=0; i<x->length; i++){
        if (*px++ != *py++) return false;
    }
    return true;
}

// use closed hashing, instead of linking to next hash.
// hashSearch returns a null pointer if st is not in the hashtable ht
strptr* hashSearch(htab* ht, strptr* st){
    int i,j;
    strptr* answer;
    unsigned long h = hash(st);
    int idx = h % ht->length;
    int n1 = 1;
    while (ht->base[idx].length != 0){
        answer = (strptr*)&(ht->base[idx]);
        if (isEq(answer,st)) return answer;
        idx = (idx+n1)%ht->length;
        n1 += 2;
    }
    return 0;
}
        
// hashfind always returns a pointer to an entry in the appropriate hashtable,
// even if it must insert it before returning.
strptr* hashfind(htab* ht, strptr* st){
    int i,j;
    strptr* answer;
    unsigned long h = hash(st);
    int idx = h % ht->length;
    int n1 = 1;
    while (ht->base[idx].length != 0){
        answer = (strptr*)&(ht->base[idx]);
        if (isEq(answer,st)) return answer;
        idx = (idx+n1)%ht->length;
        n1 += 2;
    }
    // we found the spot, and it is empty.
    answer = (strptr*)&(ht->base[idx]);
    answer->base = st->base;
    answer->length = st->length;
    /*int* p = &(answer->count); // should be zero from calloc
    for (i=0; i<numDialects; i++){
        *p++ = 0;
    } */
    ht->numEntries ++;
    // if hash table exceeds load factor, rehash the table
    float lf = (float)ht->numEntries / ht->length;
    if (lf > 0.7){
        if (Verbose) printf("rehash at line %d for strings of length %d new table size %d\n",
                current_line, st->length, 2*ht->length);
        htab newH;
	strptr* newtable = (strptr*)calloc(ht->length*2,sizeof(strptr)/*+sizeof(int)*(numDialects-1)*/);
        newH.base = newtable;
        newH.numEntries = 0;
        newH.length = ht->length*2;
        for (i=0; i<ht->length; i++){
            strptr ns = ht->base[i];
            if (ns.length != 0){
                strptr* hp = hashfind(&newH,&ns);
                int* ca =  (hp->count);
                int* cb =  (ns.count);
                for (j=0; j<numDialects; j++){
                    *ca++ = *cb++;  
                }
            }
        }
        free(ht->base);
        ht->base = newH.base;
        ht->length = newH.length;
        ht->numEntries = newH.numEntries;
        answer = hashSearch(ht,st);
    }
    return answer;

}

// forward declaration
void compute_entropy(double entropy[], strptr* test, int ff);


int main(int nargs, char**argv){
    int i,j,k;
    // could put command line interface here.
    Verbose = false;
    int ignore = false;

    for (i=1; i<nargs; i++){
        if (ignore){// ignoring this argument
            ignore = false; // because it was parameter of previous
        }
        else if (0==strcmp(argv[i], "-hout")){
            strncpy(houtFile,argv[i+1],99);
            ignore = true;
        }
        else if (0==strcmp(argv[i], "-test")){
            strncpy(testFile,argv[i+1],99);
            ignore = true;
        }
        else if (0==strcmp(argv[i], "-train")){
            strncpy(trainFile,argv[i+1],99);
            ignore = true;
        }
        else if (0==strcmp(argv[i],"-verbose")){
            Verbose = true;
        }
        else {
            fprintf(stderr,"Unrecognized Switch %s\n",argv[i]);
            exit(1);
        }
    }
    // read in the training file

    int fin = open(trainFile,O_RDONLY);
    if (fin == -1){
        fprintf(stderr, "couldn't open training file %s\n", trainFile);
        return 1; 
    }
    /* do a quick dry run through the file to determine how many 
       characters and how many lines to allocate space for.
     */
    maxTrainingSize = 4096; // allow a litte extra space
    maxLines = 1024;        //
    {
        char buffer[4096];
        int i;
        int charsR = read(fin, buffer, 4096);
        while (charsR == 4096){
            maxTrainingSize += 4096;
            for (i=0; i<charsR; i++){
                if (buffer[i] == '\n') maxLines ++;
            }
            charsR = read(fin, buffer, 4096);
        }
        close(fin);
        fin = open(trainFile,O_RDONLY);
        if (fin == -1){
            fprintf(stderr, "couldn't open training file second try\n");
            return 1; 
        }

    }
    // allocate space in memory to store the whole training file
    data = malloc(maxTrainingSize);
    if (data == 0){
        fprintf(stderr, "couldnt allocate training data array");
        return 1; // error. bah. humbug.
    }
    

    int tchars = read(fin, data, maxTrainingSize);
    if (Verbose) printf("read %d chars\n",tchars);
    close(fin);

    // set up training strings
    tstrings = (strptr*) calloc(maxLines,
                    (sizeof(strptr)));
    if (tstrings == 0){
        fprintf(stderr, "could not allocate training strings table");
        return 1;
    }
    current_line = 0;
    for (i=0; i<tchars; ){
        strptr* pts = &tstrings[current_line];
        pts ->base = i;
        while (data[i] != '\t') i++;
        pts ->length = i-pts->base;
        for (j=0; j<numDialects; j++){
            //((int*)&(pts->count))[j] = 0;
            pts->count[j] = 0;  // see if this simpler form also fails sometimes

        }
        // dialect is stored at base + length + 3,4,5 as three-char string
        // find end of training string
        while (data[i] != '\n') i++;
        i++; // skip the newline, too.
        current_line++;  // for monitoring.
    }
    int totTestStr = current_line;
    if (Verbose) printf("number of training strings is %d\n", totTestStr);


    // do frequencies for dialects,
    // 1. allocate hashtables for each size of string
    strptrSize = sizeof(strptr);// + (numDialects-1)*(sizeof(int));
    hashtables = (htab*)calloc(maxString,sizeof(htab));
    if (hashtables == 0) {
        fprintf(stderr, "couldn't allocate hashtables array");
        return 1;
    }
    for (i=1; i<maxString; i++){
        // could have some code for short arrays here
        int len;
        //chose low sizes so that hash table wouldn't rehash when full
        //but saving  space in these small tables not very important
        switch (i){
        case 1: len = 102; break; 
        case 2: len = 720; break;
        case 3: len = 4800; break;
        default: len = 10000;
        }
        hashtables[i].base = (strptr*)calloc(len,strptrSize);
        if (hashtables[i].base == 0){
            fprintf(stderr,"can't allocate hashtable for string size %d of length %d\n",i,len);
            return 1;
        }
        hashtables[i].numEntries = 0;
        hashtables[i].length = len;
    }
    // 1a. clear totals by size
    totals = (int*)calloc(maxString*numDialects, sizeof(int));
    // 2. fill the hashtables
    for (i=0; i<totTestStr; i++){
        strptr* pts = &tstrings[i];
        current_line = i;
        // dialect is the same for every string subset of  the training string
        strptr d;
        d.base = pts->base+pts->length+3;
        d.length = 3;
        int dialect = dialectLookup(&d);
        for (j=1; j<maxString && j<pts->length-j; j++){
            for (k = 0; k<pts->length-j; k++){
                // before examining and counting this string, make sure
                // that it doesn't begin with a broken utf-8 sequence
                char byt = data[k+pts->base];
                if (0x80 == (byt & 0xC0)){// the first char a utf-8 continuation
                    continue; // it is, so ignore this string
                }
                // now make sure that it doesn't end with a leading utf-8 byte
                byt = data[k+j-1+pts->base];
                if (0xC0 == (byt & 0xC0)){// it does.  (this includes all leads)
                    continue;
                }
                // broken UTF-8 sequences of three: 
                if (0x80 == (byt & 0xC0) && // last byte continuation
                    0xE0 == (0xF0 & data[k+j-2+pts->base])){// lead-3-seq
                    continue; // ignore this broken three-sequence
                }

                //UTF-8 sequences of four bytes are possible,
                // but believed not to occur in the data.  rather than
                // code them now, I'll just check for existence and bomb.
                // broken UTF-8 4-sequence?
                   // checked for leading byte at k+j-1 above
                if (0xF0 == (0xF8 & data[k+j-2+pts->base])||// only 3 bad places
                    0xF0 == (0xF8 & data[k+j-3+pts->base] )){// for the 4-lead.
                    fprintf(stderr,"?long utf-8 seqence at line %d\n",current_line);
                    continue; // ignore this string
                }

                // hopefully no broken utf-8 sequences in this substring.
                strptr s;
                s.base = pts->base + k;
                s.length = j;
                strptr* p = hashfind(&hashtables[j],&s);
                p->count[dialect]++;
                totals[j*numDialects+dialect]++;
                totals[0+dialect]++;
            }
        }

    }
    // test
    // I opened the training file with "open" because I wanted to read the
    // whole thing into memory (although once the file can change with
    // a command line interface, I won't know the length anymore.)

    // open test file -- I only want to read it a line at a time.
    // so I use C library input  (isn't this buffered?)
    FILE* ftest = fopen(testFile,"r");
    if (houtFile[0]){ // if writing to houtFile
        fhout = fopen(houtFile,"w");
    }

    //in order to use the strptr structure, I read the test line into the 
    // data array.
    
    strptr test;
    test.base = tstrings[totTestStr-1].base + tstrings[totTestStr-1].length;
    int c = 0;
    while (c != -1)
    {
        // read test string
        char* bp = &data[test.base];
        c = fgetc(ftest);
        if (c == -1) break;

        while (c != '\n' && c != -1){
            *bp++ = c;
            c = fgetc(ftest);
        }
        test.length = bp-data-test.base;

        // set entropy to zero
        double entropy[numDialects];
        for (i=0; i<numDialects; i++){
            entropy[i] = 0;
        }
        int first_free = test.base+test.length; // first unused spot in data[]
        // compute cross-entropy for each dialect.
        compute_entropy(entropy, &test, first_free);

        // decide dialect based on best fit.  log prob = 0 is perfect.
        // other probs are negative.
        int dialect = 0;
        for (i=1; i<numDialects; i++){
            if (entropy[dialect] < entropy[i]){
                dialect = i;
            }
        }

        // possibly write houtFile
        if (houtFile[0]){// dialect entropy0 entropy1 ...}
            fprintf(fhout,"%d",dialect+1);
            for (i=0; i<numDialects; i++){
                fprintf(fhout," %lf",entropy[i]);
            }
            fprintf(fhout,"\n");
        }

        // write test string, tab, dialect to stdout
        for (i=0; i<test.length; i++){
            putchar(data[test.base+i]);
        }
        putchar('\t');
        puts(dialects[dialect]);
    }
}

/*
 * This recursively computes a figure related to the entropy, namely a sum of 
 * log probabilities for substrings of the string.
 * The entropy ought to be the negative log base 2 probability,
 * whereas this figure is the log base e probability.  
 * the difference between log2 and log is a constant factor,
 * Often we are interested in the per-character entropy, so as not
 * to be confused by strings of different length, but in this case, we're
 * eventually going to compare the magnitudes of the log-probabilities for
 * several different dialects for the same string, so there
 * is no need to divide by the number of characters.
 */

int compute_single_entropy(int dialect, double entropy[], strptr* x, int ff){
    // first find largest matching string for dialect.
    int i,j,k;
    strptr largest;

    int maxS = x->length;
    if (maxS > maxString-1) maxS = maxString-1;

    for (i=maxS; i>0; i--){
        for (j=0; j<x->length-i+1; j++){
            largest.base = x->base+j;
            largest.length = i;
            strptr* big = hashSearch(&hashtables[i],&largest);
            if (big !=0 && big->count[dialect] !=0){// looks good; include in entropy
                int n = big->count[dialect];
                // obtain denominator, which is number of times comparable
                // length strings occur in this dialect in training.
                int d = totals[i*numDialects+dialect];
                double prob = (double)n/d; // frequency in training approximates
                entropy[dialect] += log(prob); //def of entropy uses -log2...
                // now compute entropy of other two pieces
                if (0 < j){
                    strptr first;
                    first.base = x->base;
                    first.length = j;
                    int prblem = compute_single_entropy(dialect,entropy, &first, ff);
                }
                if (x->length > j+big->length){ // j is start of big string
                    strptr last;
                    last.base = x->base+j+big->length;
                    last.length = x->base+x->length - last.base;
                    int prblem = compute_single_entropy(dialect,entropy, &last, ff);
                }
                return 0;  // should really divide by number of characters here,
                        // but each of the figures in the array of entropies
                        // would have the same division, since all are entropies
                        // of the same string.  
            } // found a big string ... ends if n!=0
        } // end for j  trying offsets
    } // end for i, each length of string.
    // if we get here, there must be at least a character, which is not
    // found in the test data.
    {
    char copy[100];
    int j; 
    for (j=0; j<99 && j<x->length; j++) copy[j] = data[j+x->base];
    copy[j] = 0;
    
    fprintf(stderr, "Mysteriously, there must be a character which is not "
           "in the training data for dialect %d.  How about '%s' == %x?\n" ,
           dialect,  copy, data[x->base]);
    int d = totals[i*numDialects+dialect];
    entropy[dialect] += log(0.5/d);
    return 2;
    }
} // end of function.

void compute_entropy(double entropy[], strptr* x, int ff){
    int i;
    for (i=0; i<numDialects; i++){
        int problem = compute_single_entropy(i,entropy, x, ff);
        // if problem!= 0 ...
    }


}
