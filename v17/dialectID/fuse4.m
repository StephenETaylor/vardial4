% the purpose of this file is to merge various input files, which include:
%  hypothesis (in this [dialectID] directory
%  hypothesisw (in this directory) 
%  teste.txt      (in this directory)
%  testc.txt      (in this directory)

% I plan to do it using the focal_multiclass toolkit, 
%   which is in the ../.. [~/spring17/vardial4/vardial4] directory
%  in the language of focal_multiclass, this is an identification problem
%  on a closed set.
% each of the hypothesis* files provides a table of five scores,
% and the largest score is the winning dialect.
%  The scores are definitely not log-likelihoods, so I'll need to 
%  appropriately calibrate them.
%  The wentropy.py code which produces teste.txt 
%    can output likelihoods, so obtaining log-likelihoods for
%    this is straightforward, and 
%  the chars.c code which maintains an array of entropies, which are 
%  certainly scores, and which I endeavor to treat as scaled log-likelihoods

% step one will be to combine the two hypothesis files

% FIRST put the foCal_multiclass toolkit into the path

addpath('/home/staylor/spring17/vardial4/varDial4/focal_multiclass/v1.0/matlab/multifocal/application');
addpath('/home/staylor/spring17/vardial4/varDial4/focal_multiclass/v1.0/matlab/multifocal/covariance');
addpath('/home/staylor/spring17/vardial4/varDial4/focal_multiclass/v1.0/matlab/multifocal/data_synthesis');
addpath('/home/staylor/spring17/vardial4/varDial4/focal_multiclass/v1.0/matlab/multifocal/examples');
addpath('/home/staylor/spring17/vardial4/varDial4/focal_multiclass/v1.0/matlab/multifocal/factor_analysis');
addpath('/home/staylor/spring17/vardial4/varDial4/focal_multiclass/v1.0/matlab/multifocal/fusion');
addpath('/home/staylor/spring17/vardial4/varDial4/focal_multiclass/v1.0/matlab/multifocal/hlda');
addpath('/home/staylor/spring17/vardial4/varDial4/focal_multiclass/v1.0/matlab/multifocal/hlda_backend');
addpath('/home/staylor/spring17/vardial4/varDial4/focal_multiclass/v1.0/matlab/multifocal/linear_backend');
addpath('/home/staylor/spring17/vardial4/varDial4/focal_multiclass/v1.0/matlab/multifocal/multiclass_cllr_evaluation');
addpath('/home/staylor/spring17/vardial4/varDial4/focal_multiclass/v1.0/matlab/multifocal/nist_lre');
addpath('/home/staylor/spring17/vardial4/varDial4/focal_multiclass/v1.0/matlab/multifocal/ppca');
addpath('/home/staylor/spring17/vardial4/varDial4/focal_multiclass/v1.0/matlab/multifocal/quadratic_backend');
addpath('/home/staylor/spring17/vardial4/varDial4/focal_multiclass/v1.0/matlab/multifocal/utils'); 

%first the three training files, hs, hw, rf
% read in the hypothesis file

[ choice, a,b,c,d,e] = textread('hs'); %, '%i %f %f %f %f %f');
scores = [a,b,c,d,e];

scores = scores';
scores(:,1)
size(scores)

% read in the hypothesisw file
[ choicew, aw,bw,cw,dw,ew] = textread('hw' ); % , '%i %f %f %f %f %f');
scoresw = [aw ,bw ,cw ,dw ,ew ];
scoresw = scoresw';

% read hc and he files
[ choicec, ac,bc,cc,dc,ec] = textread('hc' ); % , '%i %f %f %f %f %f');
scoresc = [ac ,bc ,cc ,dc ,ec ];
scoresc = scoresc';

[ choicee, ae,be,ce,de,ee] = textread('he' ); % , '%i %f %f %f %f %f');
scorese = [ae ,be ,ce ,de ,ee ];
scorese = scorese';


% read in the reference file
[rf] = textread('rf');  %,'%i');
rf = rf'


[alpha,beta] = train_nary_llr_fusion({scores,scoresw, scorese, scoresc},rf);
alpha
beta

%having trained, we are now ready to read in and combine the two test files
[ct1, a1,b1,c1,d1,e1] = textread('test.hyp');
test1 = [a1,b1,c1,d1,e1];
test1 = test1';

[ct2, a2,b2,c2,d2,e2] = textread('test.hyw');
test2 = [a2,b2,c2,d2,e2];
test2 = test2';

% read also test.hye and test.hyc
[ct3, a3,b3,c3,d3,e3] = textread('test.hye');
test3 = [a3,b3,c3,d3,e3];
test3 = test3';

[ct4, a4,b4,c4,d4,e4] = textread('test.hyc');
test4 = [a4,b4,c4,d4,e4];
test4 = test4';


dd = apply_nary_lin_fusion({test1,test2,test3, test4},alpha,beta);

[mx,imx] = max(dd);
%dlmwrite('test.fusion',imx');
fus = fopen("test.f4","w");
di = {"EGY","GLF","LAV","MSA","NOR"}; # dialect table
trials = size(imx,2);
for i=1:trials
   td = di{imx(1,i)};
   fprintf(fus, "%s\n",td);
endfor
fclose(fus);



