%----- Usage of the script
% 1. Locate the file with profix '_rcrfi': only  data after ica
% 2. Redo eventlist extraction
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

h=helpdlg('Please choose a demo file with profix ''_rcrfi'' to identify batch pattern');
[filename, pathname, ~] = uigetfile('*.set','Choose demo file');
identifiyIt = regexp(filename,'_','split');
temp = identifiyIt{1}; subjID = [temp(1:end-2) '*'];

patternIt = [subjID '_' identifiyIt{2}];
dataList =g_ls([pathname patternIt]);
delete(h)

h=helpdlg('Please choose another temp file store folder');
tempPath = uigetdir(pwd,'Choose temp file store folder'); % path to store temp data
delete(h);

h=helpdlg('Please choose SAICA config file');
[filename_saica, pathname_saica] = uigetfile('*.mat','Choose SAICA config file');
corEOGconfig = [pathname_saica filename_saica];
delete(h);
%% ---- processing parameter
% which temp file to save
savingOpt = [1;...% import and merge
    1;...% clean record error
    1;...% re-reference
    1;...% high-pass filtering with 0.05 Hz, with IIR, Order 2
    1;...% run ICA
    1;...% ICA-based EOG correction
    1;...% Generate event list file
    1;...% Assign bin to data based on BDF
    1;...% Epoch data
    1;...% Band pass filtering with 0.05 to 30 Hz, wit IIR, Order 2
    1;...% Remove artifacts
    1]; % Averaging and output ERPs files
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
%% ----- 06: correct EOG with ICA
        % correct EOG
        load(corEOGconfig)
        EEG_origin = EEG;
        [EEG, ~] = eeg_SASICA(EEG,varargin{1,1});
        EEG = pop_subcomp( EEG,  find(EEG.reject.gcompreject>0), 0);
        % reimport EOG to ICA corrected data
        EEG.data(63:64,:) = EEG_origin.data(63:64,:);
        clear EEG_origin
        EEG.setname = fileNaming{6};
        if savingOpt(6) == 1
            pop_saveset(EEG, 'filename', EEG.setname, 'filepath', tempPath);
        end
        %% ----- Step#07: gen event list
        EEG = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99 }, 'BoundaryString', { 'boundary' }, 'Eventlist',...
            [tempPath filesep 'subj' subjID '_evenLst.txt']);
        EEG.setname = fileNaming{7};
        if savingOpt(7) == 1
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