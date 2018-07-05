%----- Usage of the script
% 1. Grand avg based on ERPs
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

h=helpdlg('Please choose a demo file with ''*.erp'' to identify batch pattern');
[filename, pathname, ~] = uigetfile('*.erp','Choose demo file');
identifiyIt = regexp(filename,'_','split');
temp = identifiyIt{1}; subjID = [temp(1:end-2) '*'];
subLockObject = identifiyIt{3}; subLockObject = ['_' subLockObject(1:end-4)];
patternIt = [subjID '_' identifiyIt{2} '_' identifiyIt{3}];
dataList =g_ls([pathname patternIt]);


delete(h)
h=helpdlg('Please choose grand ERP file store folder');
erpPath =  uigetdir(pwd,'Choose grand ERP store folder'); % path to put finnal ERPs files
delete(h);

erpListName = identifiyIt{3};
filePh = fopen([erpPath filesep 'grand_' erpListName(1:end-4) '.txt'],'w');
fprintf(filePh,'%s\n',dataList{:});
fclose(filePh);

%% grand average
ERP = pop_gaverager( [erpPath filesep 'grand_' erpListName(1:end-4) '.txt'] , 'Criterion',30, 'ExcludeNullBin', 'on', 'SEM', 'on' );
ERP = pop_savemyerp(ERP, 'erpname', erpListName, 'filename', ['grand_' identifiyIt{3}], 'filepath', erpPath);   