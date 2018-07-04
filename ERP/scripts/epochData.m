%----- Usage of the script
% 1. Locate the file with profix '_rcrficeab': filted data after epoching
% 2. Redo artifactMark and followed analysis
%-------------------------------------------------------------------------
%
% Welcome to find bugs, suggest improvements, and
% discuss with the author
%
%                      Jinbo Zhang
%
%   Website: https://www.jinboasltw.cc
%   Email: sopherwit@gmail.com
%   Github: https://github.com/Jinboasltw
%
%-------------------------------------------------------------------------
%% ----- collect system info and data location
eeglabpath = fileparts(which('eeglab')); % eeglab path

h=helpdlg('Please choose a demo file with profix ''_rcrficeab'' to identify batch pattern');
[filename, pathname, ~] = uigetfile('*.set','Choose demo file');
identifiyIt = regexp(filename,'_','split');
temp = identifiyIt{1}; subjID = [temp(1:end-2) '*'];
patternIt = [subjID '_' identifiyIt{2} '_' identifiyIt{3}];
dataList =g_ls([pathname patternIt]);
delete(h)

h=helpdlg('Please choose another temp file store folder');
tempPath = uigetdir(pwd,'Choose temp file store folder'); % path to store temp data
delete(h); 

h=helpdlg('Please choose another ERP file store folder');
erpPath =  uigetdir(pwd,'Choose ERP store folder'); % path to put finnal ERPs files
delete(h); 