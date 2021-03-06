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

% read in the reference file
[rf] = textread('rf');  %,'%i');
rf = rf'

% test example:
%multifocal_example1_fusion

[alpha,beta] = train_nary_llr_fusion({scores,scoresw},rf);
alpha
beta

discr_fusion = apply_nary_lin_fusion({scores,scoresw},alpha,beta);

calref_plot({scores,scoresw,discr_fusion},rf,{'hs','hw','1+2'},1);
size(discr_fusion)
pause;
dd = discr_fusion';
dlmwrite('fusion',dd);



