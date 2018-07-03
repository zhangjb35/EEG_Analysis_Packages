%----- Usage of the script
% 1. Check the setup for new analysis, include:
%   1) Location of .cnt folder (naming with sub*)
%   2) Chose which temp file need to store (input 1 for that file)
%   3) If need temp file, please setup the rules of naming for temp files
%   4) Check Bin Define File (BDF). Please comfirm the rule used to define
%   the bin matched with the real data and design of experiment
%   5) Setup profix for different ERPs defined by BDF (e.g. cue or target)
%   6) Check the time range and baseline setup for different ERPs
%   7) Check the setup for the filter (range, type, and design)

% 2. Confirm the core step need to performed for your experiment
%   The scripts based on EEGLAB and ERPLAB, core step include:
%	1) import and merge it if necessary
%	2) clean record error
%	3) re-reference
%	4) high-pass filtering with 0.05 Hz, with IIR, Order 2
%	5) run ICA
%	6) perferm ICA-based EOG correction
%	7) generate event list file
%	8) assign bin to data based on BDF
%	9) epoch data
%	10) band pass filtering with 0.05 to 30 Hz, with IIR, Order 2
%	11) remove artifacts
%	12) averaging and output ERPs files

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

%% ----- clean evn
clc
clear
%% ----- collect system info and data location
eeglabpath = fileparts(which('eeglab')); % eeglab path

h=helpdlg('Please choose raw data folder');
rawPath = uigetdir(pwd,'Choose raw data folder'); % raw data path
delete(h); 

cntFolders =g_ls([rawPath filesep 'sub*']); % search data in raw data path

h=helpdlg('Please choose temp file store folder');
tempPath = uigetdir(pwd,'Choose temp file store folder'); % path to store temp data
delete(h); 

h=helpdlg('Please choose ERP file store folder');
erpPath =  uigetdir(pwd,'Choose ERP store folder'); % path to put finnal ERPs files
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
    0;...% Band pass filtering with 0.05 to 30 Hz, wit IIR, Order 2
    1;...% Remove artifacts
    1]; % Averaging and output ERPs files
% filter parameter
filt_1 = 0.05;
filt_1_order = 2;
filt_2 = [ 0.05 30];
filt_2_order = 2;

% ica method used
ica_method = inputdlg({'ICA Method'},'Setup ICA Method',[1 50],{'binica'});

h=helpdlg('Please choose saica_cfg file');
[filename, pathname, ~] = uigetfile('*.mat','Choose ''saica_cfg.mat''');% config file for ICA-based EOG correction
corEOGconfig = [pathname filename];
delete(h); 

% setup bdffile for define epoch rule
bdfNum = inputdlg({'BDF Number'},'How many BDF file need',[1 50],{'2'});
subLockObject = {'_target' '_cue'}; % Profix for output ERPs files
bdfFile = cell(str2double(cell2mat(bdfNum)),1);
for j = 1:str2double(cell2mat(bdfNum))
    h = helpdlg(['Please choose BDF # ' num2str(j)]);
    [filename, pathname, ~] = uigetfile('*.txt',['Choose ''*.txt BDF''#' num2str(j)]);
    bdfFile{j} = [pathname filename];
    delete(h); 
end
for j = 1:str2double(bdfNum{1})
    inputdlg({['Profix of ERP #' num2str(j)]}, 'Profix of Naming',[1 50],{'_XXX'});
end
% cue time window
cueRange =  [-100  300];
cueBaseline = [ -100 0];
% target time window
targetRange = [-1350  800];
targetBaseline = [-1200 -1000];

% artifacts theshold used
artTheshold = 75; % for channels except HEO, VEO; in uV
artTheshold_HEO = 100;
artTheshold_VEO = 200;
%% Path Error Detection
if numel(cntFolders) == 0
    errordlg('No rawdata detected !!! Please check input.')
else
    %% ---- Batch Analysis Start
    steps=numel(cntFolders);
    step=steps/100;
    hwait=waitbar(0,'Processing Data...Please Wait');
    for subjNumber = 1:steps
        % get specific data source
        cntFolder =cntFolders{subjNumber};
        % choose need temp file and create the naming rules
        subjID = cntFolder(end-1:end);
        
        fileNaming = {['subj' subjID '_r'];... % meaning of naming used to mark temp file. See 'which temp file to save' part
            ['subj' subjID '_rc'];...
            ['subj' subjID '_rcr'];....
            ['subj' subjID '_rcrf'];...
            ['subj' subjID '_rcrfi'];...
            ['subj' subjID '_rcrfic'];...
            ['subj' subjID '_rcrfice'];...
            ['subj' subjID '_rcrficea'];...
            ['subj' subjID '_rcrficeab'];...
            ['subj' subjID '_rcrficeabf'];...
            ['subj' subjID '_rcrficeabft'];...
            ['subj' subjID '_rcrficeabftv'];...
            };
        
        %% ----- Step#01: load .cnt file and merge it if necessary
        dataFile = g_ls([cntFolder,filesep,'subj*.cnt']);
        if length(dataFile) > 1
            append_EEG =pop_loadcnt(dataFile{1}, 'dataformat', 'auto', 'memmapfile', '');
            for i=2:length(dataFile)
                EEG = pop_loadcnt(dataFile{i}, 'dataformat', 'auto', 'memmapfile', '');
                append_EEG = pop_mergeset(append_EEG, EEG);
            end
            EEG = append_EEG;
            clear append_EEG
        else
            EEG = pop_loadcnt(dataFile{1}, 'dataformat', 'auto');
        end
        EEG.setname=fileNaming{1};
        if savingOpt(1) == 1
            pop_saveset(EEG, 'filename', EEG.setname, 'filepath', tempPath);
        end
        %% ----- Step#02: clean error in the data
        EEG = pop_select( EEG,'nochannel',{'M1' 'EKG' 'EMG'});
        EEG=pop_chanedit(EEG, 'lookup',...
            [eeglabpath '' filesep 'plugins' filesep 'dipfit2.3' filesep 'standard_BESA' filesep 'standard-10-5-cap385.elp'],...
            'changefield',{63 'labels' 'AF8'},'changefield',{59 'labels' 'AF7'},...
            'changefield',{57 'labels' 'PO10'},'changefield',{53 'labels' 'PO9'},'lookup',...
            [eeglabpath '' filesep 'plugins' filesep 'dipfit2.3' filesep 'standard_BESA' filesep 'standard-10-5-cap385.elp']);
        EEG.setname=fileNaming{2};
        if savingOpt(2) == 1
            pop_saveset(EEG, 'filename', EEG.setname, 'filepath', tempPath);
        end
        %% ----- Step#03: re-reference to linked earlobe
        % calc semi M2 with erplab
        EEG = pop_eegchanoperator( EEG,...
            { 'ch66 = ch42/2.0 label semiM2'} , ...
            'ErrorMsg', 'popup', 'Warning', 'off' );
        %% re-ref
        EEG = pop_reref( EEG, 66,'exclude',[64 65] );
        %% remove m2 from datasets
        EEG = pop_select( EEG,'nochannel',{'M2'});
        EEG.setname=fileNaming{3};
        if savingOpt(3) == 1
            pop_saveset(EEG, 'filename', EEG.setname, 'filepath', tempPath);
        end
        %% ----- Step#04: high pass filter .05 Hz
        EEG  = pop_basicfilter( EEG,  1:64 , 'Cutoff',  filt_1, 'Design', 'butter', 'Filter', 'highpass', 'Order',  filt_1_order, 'RemoveDC', 'on');
        %% save raw data
        EEG.setname = fileNaming{4};
        if savingOpt(4) == 1
            pop_saveset(EEG, 'filename', EEG.setname, 'filepath', tempPath);
        end
        %% ----- Step#05 & 06: run ICA and correct EOG
        EEG = pop_runica(EEG, 'icatype',cell2mat(ica_method),'chanind',1:64);
        EEG_origin = EEG;
        EEG.setname =fileNaming{5};
        if savingOpt(5) == 1
            pop_saveset(EEG, 'filename', EEG.setname, 'filepath', tempPath);
        end
        % correct EOG
        load(corEOGconfig)
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
        EEG_origin = EEG;
        clear EEG
        for i=1:2
            %% get EEG data
            EEG = EEG_origin;
            %% ----- Step#08&09: Epoch data
            %% assign bin
            EEG  = pop_binlister( EEG , 'BDF', bdfFile{i}, 'IndexEL',  1, 'SendEL2', 'EEG', 'Voutput',...
                'EEG' );
            EEG.setname =[fileNaming{8} subLockObject{i}];
            if savingOpt(8) == 1
                pop_saveset(EEG, 'filename', EEG.setname, 'filepath', tempPath);
            end
            %% extract bin
            if i==1
                EEG = pop_epochbin( EEG , targetRange, 'none');
            else
                EEG = pop_epochbin( EEG , cueRange, 'none');
            end
            EEG.setname =[fileNaming{9} subLockObject{i}];
            if savingOpt(9) == 1
                pop_saveset(EEG, 'filename', EEG.setname, 'filepath', tempPath);
            end
            %% ----- Step#10: filter after epoch
            EEG  = pop_basicfilter( EEG,  1:64 , 'Cutoff', filt_2, 'Design', 'butter', 'Filter', 'bandpass', 'Order',  filt_2_order, 'RemoveDC', 'on' );
            EEG.setname =[fileNaming{10} subLockObject{i}];
            if savingOpt(10) == 1
                pop_saveset(EEG, 'filename', EEG.setname, 'filepath', tempPath);
            end
			% Remove Baseline
			if i==1
                EEG = pop_rmbase(EEG, targetBaseline);
            else
				EEG = pop_rmbase(EEG, cueBaseline);
            end
            %% ----- Step#11: mark EOG artifacts
            if i==1
                EEG  = pop_artextval( EEG , 'Channel',  1:62, 'Flag', [ 1 3], 'Threshold', [ -1*artTheshold artTheshold], 'Twindow', targetBaseline );
                EEG  = pop_artextval( EEG , 'Channel',  63, 'Flag', [ 1 7], 'Threshold', [ -1*artTheshold_HEO artTheshold_HEO], 'Twindow', targetBaseline );
                EEG  = pop_artextval( EEG , 'Channel',  64, 'Flag', [ 1 8], 'Threshold', [ -1*artTheshold_VEO artTheshold_VEO], 'Twindow', targetBaseline );
                
                EEG  = pop_artextval( EEG , 'Channel',  1:62, 'Flag', [ 1 4], 'Threshold', [ -1*artTheshold artTheshold], 'Twindow', [0 1000*EEG.xmax] );
                EEG  = pop_artextval( EEG , 'Channel',  63, 'Flag', [ 1 5], 'Threshold', [ -1*artTheshold_HEO artTheshold_HEO], 'Twindow', [0 1000*EEG.xmax] );
                EEG  = pop_artextval( EEG , 'Channel',  64, 'Flag', [ 1 6], 'Threshold', [ -1*artTheshold_VEO artTheshold_VEO], 'Twindow', [0 1000*EEG.xmax] );
                
            else
                EEG  = pop_artextval( EEG , 'Channel',  1:62, 'Flag', [ 1 3], 'Threshold', [ -1*artTheshold artTheshold], 'Twindow', [cueBaseline(1) 1000*EEG.xmax] );
                EEG  = pop_artextval( EEG , 'Channel',  63, 'Flag', [ 1 7], 'Threshold', [ -1*artTheshold_HEO artTheshold_HEO], 'Twindow', [cueBaseline(1) 1000*EEG.xmax] );
                EEG  = pop_artextval( EEG , 'Channel',  64, 'Flag', [ 1 8], 'Threshold', [ -1*artTheshold_VEO artTheshold_VEO], 'Twindow', [cueBaseline(1) 1000*EEG.xmax] );
            end
            
            EEG.setname =[fileNaming{11} subLockObject{i}];
            if savingOpt(11) == 1
                pop_saveset(EEG, 'filename', EEG.setname, 'filepath', tempPath);
            end
            EEG = pop_summary_AR_eeg_detection(EEG, [tempPath filesep 'AR_summary_' EEG.setname '.txt']);
            %% ----- Step#12: generate average ERP
            ERP = pop_averager( EEG , 'Criterion', 'good', 'ExcludeBoundary', 'on', 'SEM', 'on' );
            if savingOpt(12)==1
                ERP = pop_savemyerp(ERP, 'erpname',...
                    [fileNaming{12} subLockObject{i}], 'filename', [fileNaming{12} subLockObject{i} '.erp'], 'filepath',erpPath, 'Warning', 'off');
            end
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
%% ----- Extent Code for More Optional Analyzing
% 3. There are some code you can used to do debug
%   1) Check plot of EEG data
%       pop_eegplot(EEG)
%   2) Save Temp File for detail check
%       pop_saveset(EEG);
% 4. There are some append code you can used to do refine preprocess
%   1) clean up for ICA run
% EEG = pop_continuousartdet( EEG , 'ampth', [ -300 300], 'chanArray',  1:62, 'colorseg', [ 1 0.9765 0.5294], 'forder',  100, 'numChanThreshold'];...
%     1, 'stepms',  250, 'threshType', 'peak-to-peak', 'winms',  500 );
%   2) blink check
% EEG  = pop_artblink( EEG , 'Blinkwidth',  400, 'Channel',  64, 'Crosscov',  0.7, 'Flag', [ 1 8], 'Twindow', [ -200 200] ); % VEO