%----- Usage of the script
% 1. Locate the file with profix '_rcrficeab': only epoched data
% 2. Redo fileter on epoched data and correct baseline (Please check time range of baseline)
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
subLockObject = identifiyIt{3}; subLockObject = ['_' subLockObject(1:end-4)];
patternIt = [subjID '_' identifiyIt{2} '_' identifiyIt{3}];
dataList =g_ls([pathname patternIt]);
delete(h)

h=helpdlg('Please choose another temp file store folder');
tempPath = uigetdir(pwd,'Choose temp file store folder'); % path to store temp data
delete(h);

%% ---- processing parameter
% which temp file to save
savingOpt = [1;...% import and merge
    0;...% clean record error
    0;...% re-reference
    0;...% high-pass filtering with 0.05 Hz, with IIR, Order 2
    1;...% run ICA
    0;...% ICA-based EOG correction
    0;...% Generate event list file
    0;...% Assign bin to data based on BDF
    1;...% Epoch data
    1;...% Band pass filtering with 0.05 to 30 Hz, wit IIR, Order 2
    1;...% Remove artifacts
    1]; % Averaging and output ERPs files

% filter parameter
filt_1 = 0.05;
filt_1_order = 2;
filt_2 = [ 0.05 30];
filt_2_order = 2;

% cue time window
cueRange =  [-100  300];
cueBaseline = [ -100 0];

% target time window
targetRange = [-1350  800];
targetBaseline = [-1200 -1000];

% use baseline
% useBaseline = cueBaseline;
useBaseline = targetBaseline;

% artifacts theshold used
artTheshold = 75; % for channels except HEO, VEO; in uV
artTheshold_HEO = 100;
artTheshold_VEO = 200;

%% Path Error Detection
if numel(dataList) == 0
    errordlg('No rawdata detected !!! Please check input.')
else
    steps=numel(dataList);
    step=steps/100;
    hwait=waitbar(0,'Processing Data...Please Wait');
    for subjNumber = 1:steps
        %% ----- Load data
        [pathstr, name, ext] = fileparts(dataList{subjNumber});
        EEG = pop_loadset('filename',[name ext],'filepath',pathstr);
        %% ----- Naming output
        % choose need temp file and create the naming rules
        numID = name(5:6);
        
        fileNaming = {['subj' numID '_r'];... % meaning of naming used to mark temp file. See 'which temp file to save' part
            ['subj' numID '_rc'];...
            ['subj' numID '_rcr'];....
            ['subj' numID '_rcrf'];...
            ['subj' numID '_rcrfi'];...
            ['subj' numID '_rcrfic'];...
            ['subj' numID '_rcrfice'];...
            ['subj' numID '_rcrficea'];...
            ['subj' numID '_rcrficeab'];...
            ['subj' numID '_rcrficeabf'];...
            ['subj' numID '_rcrficeabft'];...
            ['subj' numID '_rcrficeabftv'];...
            };
        %% ----- Step#10: filter after epoch
        EEG  = pop_basicfilter( EEG,  1:64 , 'Cutoff', filt_2, 'Design', 'butter', 'Filter', 'bandpass', 'Order',  filt_2_order, 'RemoveDC', 'on' );
        EEG.setname =[fileNaming{10} subLockObject];
        % Remove Baseline
        EEG = pop_rmbase(EEG, useBaseline);
        if savingOpt(10) == 1
            pop_saveset(EEG, 'filename', EEG.setname, 'filepath', tempPath);
        end
        if steps-subjNumber<=5
            waitbar(subjNumber/steps,hwait,'Almost Done!');
            pause(0.05);
        else
            PerStr=fix(subjNumber/step);
            str=['Analyzing...',num2str(PerStr),'%'];
            waitbar(subjNumber/steps,hwait,str);
            pause(0.05);
        end
    end
     close(hwait);
end