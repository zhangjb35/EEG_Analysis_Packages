%% clean evn
clc
clear
%% collect system info and data location
eeglabpath = fileparts(which('eeglab'));
cntFolders =g_ls([ 'G:' filesep 'EEG' filesep 'process' filesep 'rawData' filesep 'sub*']);
for subjNumber = 1:numel(cntFolders)
    cntFolder =cntFolders{subjNumber};
    subjID = cntFolder(end-1:end);
    fileNaming = {['subj' subjID '_r'];...
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
    bdfFile = {['G:\EEG\target.txt'];...
        'G:\EEG\cue.txt';...
        };
    subLockObject = {'_target' '_cue'};
    
    cueRange =  [-100  300.0];
    cueBaseline = [ -100 0];
    
    targetRange = [-1350.0  800.0];
    targetBaseline = [ -1200 -1000];
    %% Step#01: load .cnt file and merge it if necessary
    dataFile = g_ls([cntFolder,filesep,'subj*.cnt']);
    if length(dataFile) > 1
        append_EEG = [];
        append_EEG =pop_loadcnt(dataFile{1}, 'dataformat', 'auto', 'memmapfile', '');
        for i=2:length(dataFile)
            EEG = pop_loadcnt(dataFile{i}, 'dataformat', 'auto', 'memmapfile', '');
            append_EEG = pop_mergeset(append_EEG, EEG);
        end
        EEG = append_EEG;
    else
        EEG = pop_loadcnt(dataFile{1}, 'dataformat', 'auto');
    end
    EEG.setname=fileNaming{1};
    pop_saveset(EEG, 'filename', EEG.setname, 'filepath', ['.', filesep,'process' filesep 'log']);
    %% Step#02: clean error in the data
    EEG = pop_select( EEG,'nochannel',{'M1' 'EKG' 'EMG'});
    EEG=pop_chanedit(EEG, 'lookup',...
        [eeglabpath '' filesep 'plugins' filesep 'dipfit2.3' filesep 'standard_BESA' filesep 'standard-10-5-cap385.elp'],...
        'changefield',{63 'labels' 'AF8'},'changefield',{59 'labels' 'AF7'},...
        'changefield',{57 'labels' 'PO10'},'changefield',{53 'labels' 'PO9'},'lookup',...
        [eeglabpath '' filesep 'plugins' filesep 'dipfit2.3' filesep 'standard_BESA' filesep 'standard-10-5-cap385.elp']);
    EEG.setname=fileNaming{2};
    pop_saveset(EEG, 'filename', EEG.setname, 'filepath', ['.', filesep,'process' filesep 'log']);
    %% Step#03: re-reference to linked earlobe
    % calc semi M2 with erplab
    EEG = pop_eegchanoperator( EEG,...
        { 'ch66 = ch42/2.0 label semiM2'} , ...
        'ErrorMsg', 'popup', 'Warning', 'off' );
    %% re-ref
    EEG = pop_reref( EEG, 66,'exclude',[64 65] );
    %% remove m2 from datasets
    EEG = pop_select( EEG,'nochannel',{'M2'});
    EEG.setname=fileNaming{3};
    pop_saveset(EEG, 'filename', EEG.setname, 'filepath', ['.', filesep,'process' filesep 'log']);
    %% Step#04: high pass filter .05 Hz
    EEG  = pop_basicfilter( EEG,  1:64 , 'Cutoff',  0.05, 'Design', 'butter', 'Filter', 'highpass', 'Order',  2 );
    %% save raw data
    EEG.setname = fileNaming{4};
    pop_saveset(EEG, 'filename', EEG.setname, 'filepath', ['.', filesep,'process' filesep 'log']);
    %% Step#05 & 06: run ICA and correct EOG
    EEG = pop_runica(EEG, 'icatype','runica','chanind',[1:64]);
    EEG_origin = EEG;
    EEG.setname =fileNaming{5};
    pop_saveset(EEG, 'filename', EEG.setname, 'filepath', ['.', filesep,'process' filesep 'log']);
    % correct EOG
    load([pwd filesep 'setupFile' filesep 'saica_cfg.mat'])
    [EEG, ~] = eeg_SASICA(EEG,varargin{1,1});
    EEG = pop_subcomp( EEG,  find(EEG.reject.gcompreject>0), 0);
    % reimport EOG to ICA corrected data
    EEG.data(63:64,:) = EEG_origin.data(63:64,:);
    EEG.setname = fileNaming{6};
    pop_saveset(EEG, 'filename', EEG.setname, 'filepath', ['.', filesep,'process' filesep 'log']);
    %% Step#07: gen event list
    EEG = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99 }, 'BoundaryString', { 'boundary' }, 'Eventlist',...
        ['.' filesep 'process' filesep 'log' filesep 'subj' subjID '_evenLst.txt']);
    EEG.setname = fileNaming{7};
    pop_saveset(EEG, 'filename', EEG.setname, 'filepath', ['.', filesep,'process' filesep 'log']);
    EEG_origin = EEG;
    clear EEG
    for i=1:2
        %% get EEG data
        EEG = EEG_origin;
        %% Step#08&09: Epoch data
        %% assign bin
        EEG  = pop_binlister( EEG , 'BDF', bdfFile{i}, 'IndexEL',  1, 'SendEL2', 'EEG', 'Voutput',...
            'EEG' );
        EEG.setname =[fileNaming{8} subLockObject{i}];
        pop_saveset(EEG, 'filename', EEG.setname, 'filepath', ['.', filesep,'process' filesep 'log']);
        %% extract bin
        if i==1
            EEG = pop_epochbin( EEG , targetRange, targetBaseline);
        else
            EEG = pop_epochbin( EEG , cueRange, cueBaseline);
        end
        EEG.setname =[fileNaming{9} subLockObject{i}];
        pop_saveset(EEG, 'filename', EEG.setname, 'filepath', ['.', filesep,'process' filesep 'log']);
        %% Step#10: filter after epoch
        EEG  = pop_basicfilter( EEG,  1:64 , 'Cutoff', [ 0.05 40], 'Design', 'butter', 'Filter', 'bandpass', 'Order',  2, 'RemoveDC', 'on' );
        EEG.setname =[fileNaming{10} subLockObject{i}];
        pop_saveset(EEG, 'filename', EEG.setname, 'filepath', ['.', filesep,'process' filesep 'log']);
        %% Step#11: mark EOG artifacts
        if i==1
            EEG  = pop_artextval( EEG , 'Channel',  1:62, 'Flag', [ 1 2], 'Threshold', [ -75 75], 'Twindow', [ 0 EEG.xmax*1000] );
            EEG  = pop_artextval( EEG , 'Channel',  1:62, 'Flag', [ 1 3], 'Threshold', [ -75 75], 'Twindow', targetBaseline );
            EEG  = pop_artblink( EEG , 'Blinkwidth',  400, 'Channel',  64, 'Crosscov',  0.7, 'Flag', [ 1 8], 'Twindow', [ -200 200] );
        else
            EEG  = pop_artextval( EEG , 'Channel',  1:62, 'Flag', [ 1 2], 'Threshold', [ -75 75], 'Twindow', [ 0 EEG.xmax*1000] );
            EEG  = pop_artextval( EEG , 'Channel',  1:62, 'Flag', [ 1 3], 'Threshold', [ -75 75], 'Twindow', cueBaseline );
            EEG  = pop_artblink( EEG , 'Blinkwidth',  400, 'Channel',  64, 'Crosscov',  0.7, 'Flag', [ 1 8], 'Twindow', [ -200 200] );
        end
        EEG.setname =[fileNaming{11} subLockObject{i}];
        pop_saveset(EEG, 'filename', EEG.setname, 'filepath', ['.', filesep,'process' filesep 'log']);
        EEG = pop_summary_AR_eeg_detection(EEG, ['.' filesep 'process' filesep 'log' filesep 'AR_summary_' EEG.setname '.txt']);
        %% Step#12: generate average ERP
        ERP = pop_averager( EEG , 'Criterion', 'good', 'ExcludeBoundary', 'on', 'SEM', 'on' );
        ERP = pop_savemyerp(ERP, 'erpname',...
            [fileNaming{12} subLockObject{i}], 'filename', [fileNaming{12} subLockObject{i} '.erp'], 'filepath', '.\process\erp', 'Warning', 'off');
    end
end

%% Debug code
% pop_eegplot(EEG)
% pop_saveset(EEG);
%% Potiental code to clean data
% clean up for ICA run
% EEG = pop_continuousartdet( EEG , 'ampth', [ -300 300], 'chanArray',  1:62, 'colorseg', [ 1 0.9765 0.5294], 'forder',  100, 'numChanThreshold'];...
%     1, 'stepms',  250, 'threshType', 'peak-to-peak', 'winms',  500 );