function varargout=Individuation_GUI(varargin)
% Individuation experiment for bedside testing
% Input:
% EXP>zeroF
% EXP>subj XX                           (subj)
% EXP>mvc                               (mvc)
% EXP>zeroFGili                         (zeroFGili)
% EXP>run X targetfile.tgt              (run 1 ID2b_run1.tgt)
% EXP>run_Synergy X synTargetFile.tgt   (run_Synergy 1 ID2b_run1_synergy.tgt)
% Exp>run_Automated_Training X XX       (run_Automated_Training E R) X=f or e, XX=R or L

% Initial version created by Prof. Joern Diedrichsen, j.diedrichsen@ucl.ac.uk
% Jing Xu@JHU,jing.xu@jhmi.edu, modified on 2012
% Firas Mawase@JHU, fmewasi@jhmi.edu, modified on 2016
% Firas Mawase@Technion, mawasef@bm.technion.ac.il, modified on 2018
% Gili Kamara@Technion,gilik@bm.technion.ac.il, modified on 2019

%%
daqreset;  % clearing up USB
delete(instrfindall); % clearing up serial ports
clear;
close all;
clc;
sca;

warning off;
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'SuppressAllWarnings', 1);

AssertOpenGL;                   % Child protection: check if OSX/OpenGL Psychtoolbox (abort if not).

global gExp;                    % These are the collection of global variables.
if (~isempty(gExp))             % Make sure it was properly closed the last time around
    Screen('CloseAll');
    gExp=[];                    % Clear doesn't do the job, the structure is still back
end
initExp;                        % initialize the gExp structure with global parameters
fprintf('Welcome to My Amazing Experiment\n');
initTextWindow;
initGraphics; % Open the screen window and initialize graphics parameter

if ~gExp.simulation     %If not a simulation, initiate board and forces
    initBoard;
end

updateTextWindow;
isDone = false;
while(~isDone)
    str=input('\nEXP>','s');
    if ~gExp.simulation     %If not a simulation, initiate board and forces
        updateTextWindow;
    end
    [command,param]=strtok(str);
    switch (command)
        case 'subj'
            gExp.subj_name=strtok(param);
            updateTextWindow;
            fprintf('What session number is this?\n')
            gExp.DaySTR=input('\nEXP>','s');
        case 'mvc'
            if ~gExp.simulation
                zeroFGili;
            end
            runMVC;
        case 'zero'
            zeroFGili;
            gExp.zeroVolts.*gExp.scaleV2N;
        case 'run'
            [bn_str,b]=strtok(param);
            gExp.BN=str2double(bn_str);       % Get the block number
            tgtfilename=strtok(b);         % Get the targetfile name
            
            % check if MVC task was run
            mvcdatfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_MVC.mat']); % Dat-file name, following the naming convention
            if (~exist(mvcdatfile,'file'))
                fprintf('MVC file does not exist. Run MVC task first.');
            else
                S=load(mvcdatfile);
                gExp.maxForce=gExp.percentMVC*S.mvcf;   % Maximal force level is 80% of MVC, [2x10]=[LF:p->t,E:p->t;RF:p->t,E:p->t]
                gExp.maxForce(abs(gExp.maxForce(:,1:5))<1.5)=-1.5;
                gExp.maxForce(logical([zeros(2,5),abs(gExp.maxForce(:,6:10))<1.5]))=1.5;
                gExp.maxForce(gExp.maxForce>30)=30; %Max
                gExp.PRESS_TIME=5;          % time for presenting a go cue
                runBlock(tgtfilename, command);
            end
            %             stop(gExp.AI)
        case 'run_Automated_Training'
            [drxn,hnd]=strtok(param);
            direction=strtok(drxn);
            hand=strtok(hnd);
            if (direction=='f') || (direction=='F')
                if (hand=='r') || (hand=='R')
                    d=["Gili_Run_TrainRF1.tgt";"Gili_Run_TrainRF2.tgt";"Gili_Run_TrainRF3.tgt";"Gili_Run_TrainRF4.tgt";"Gili_Run_TrainRF5.tgt"];    %"Gili_Run_TrainRF6.tgt";"Gili_Run_TrainRF7.tgt";"Gili_Run_TrainRF8.tgt"];
                    %                     d=["Gili_Run_TrainRF1_Short.tgt";"Gili_Run_TrainRF1_Short.tgt";"Gili_Run_TrainRF1_Short.tgt";"Gili_Run_TrainRF1_Short.tgt";"Gili_Run_TrainRF1_Short.tgt"];    %"Gili_Run_TrainRF6.tgt";"Gili_Run_TrainRF7.tgt";"Gili_Run_TrainRF8.tgt"];
                elseif (hand=='l') || (hand=='L')
                    d=["Gili_Run_TrainLF1.tgt";"Gili_Run_TrainLF2.tgt";"Gili_Run_TrainLF3.tgt";"Gili_Run_TrainLF4.tgt";"Gili_Run_TrainLF5.tgt"];    %"Gili_Run_TrainLF6.tgt";"Gili_Run_TrainLF7.tgt";"Gili_Run_TrainLF8.tgt"];
                end
            elseif (direction=='e') || (direction=='E')
                if (hand=='r') || (hand=='R')
                    d=["Gili_Run_TrainRE1.tgt";"Gili_Run_TrainRE2.tgt";"Gili_Run_TrainRE3.tgt";"Gili_Run_TrainRE4.tgt";"Gili_Run_TrainRE5.tgt"];    %"Gili_Run_TrainRE6.tgt","Gili_Run_TrainRE7.tgt";"Gili_Run_TrainRE8.tgt"];
                elseif (hand=='l') || (hand=='L')
                    d=["Gili_Run_TrainLE1.tgt";"Gili_Run_TraiLRE2.tgt";"Gili_Run_TrainLE3.tgt";"Gili_Run_TrainLE4.tgt";"Gili_Run_TrainLE5.tgt"];    %"Gili_Run_TrainLE6.tgt";"Gili_Run_TrainLE7.tgt";"Gili_Run_TrainLE8.tgt"];
                end
            else
                fprintf('%s is not a valid variable name.',varName);
            end
            
            mvcdatfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_MVC.mat']); % Dat-file name, following the naming convention
            if (~exist(mvcdatfile,'file'))                 % check if MVC task was run
                fprintf('MVC file does not exist. Run MVC task first.');
            else
                S=load(mvcdatfile);
                gExp.maxForce=gExp.percentMVC*S.mvcf;   % Maximal force level is 80% of MVC
                gExp.maxForce(abs(gExp.maxForce(:,1:5))<1.5)=-1.5;
                gExp.maxForce(logical([zeros(2,5),abs(gExp.maxForce(:,6:10))<1.5]))=1.5;
                gExp.maxForce(gExp.maxForce>30)=30; %Max
                gExp.PRESS_TIME=5;          % time for presenting a go cue
            end
            
            gExp.rmsThreshold=gExp.rmsThreshold.*(0.80^(str2double(gExp.DaySTR)-1)); %adjust Threshold limit to 85% of last day's training (3rd day- rms of 1.28 instead of 2)
            gExp.forcePadding=gExp.forcePadding.*(0.85^(str2double(gExp.DaySTR)-1));
            
            TotalBlocks=size(d,1);              % Get the block number
            i=1;
            gExp.SpaceBarRequired=0;            %for the first block, wait for space bar
            while i<=TotalBlocks
                gExp.BN=i;                      % Get the block number
                tgtfilename=d(i,:);             % Get the targetfile name
                runBlock(tgtfilename, command);
                FlushEvents('keyDown');
                WaitSecs(0.15);
                uiwait(msgbox('Press OK to move on to the next Block'));
                i=i+1;
                gExp.SpaceBarRequired=0;
            end
            
            gExp.SpaceBarRequired=1;
            
        case 'run_Automated_Testing'
            d=["Gili_Run_BaselineRF.tgt";"Gili_Run_BaselineRE.tgt";"Gili_Run_BaselineLF.tgt";"Gili_Run_BaselineLE.tgt";"Gili_Run_BaselineRFChords.tgt";"Gili_Run_BaselineREChords.tgt";"Gili_Run_BaselineLFChords.tgt";"Gili_Run_BaselineLEChords.tgt"];
            mvcdatfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_MVC.mat']); % Dat-file name, following the naming convention
            if (~exist(mvcdatfile,'file'))
                fprintf('MVC file does not exist. Run MVC task first.');
            else
                S=load(mvcdatfile);
                gExp.maxForce=gExp.percentMVC*S.mvcf;   % Maximal force level is 80% of MVC
                gExp.maxForce(abs(gExp.maxForce(:,1:5))<1.5)=-1.5;
                gExp.maxForce(logical([zeros(2,5),abs(gExp.maxForce(:,6:10))<1.5]))=1.5;
                gExp.maxForce(gExp.maxForce>30)=30; %Max
                gExp.PRESS_TIME=5;          % time for presenting a go cue
            end
            
            if gExp.DaySTR=='5'
                gExp.SpaceBarRequired=0;
            end
            
            gExp.SpaceBarRequired=1;
            TotalBlocks=size(d,1);       % Get the block number
            for i=1:TotalBlocks
                uiwait(msgbox('Press OK to start the next Block'));
                gExp.BN=i;       % Get the block number
                tgtfilename=char(d(i,:));         % Get the targetfile name
                runBlock(tgtfilename, command);
                gExp.SpaceBarRequired=0;
                
                FlushEvents('keyDown');
                WaitSecs(0.15);
            end
            
            if gExp.DaySTR=='5'     % Just for fun, at the end of ths study Handel's Halleluja is played
                load handel
                sound(y,Fs)
            end
            
        case 'run_Synergy'
            [bn_str,b]=strtok(param);
            gExp.BN=str2double(bn_str);       % Get the block number
            tgtfilename=strtok(b);         % Get the targetfile name
            
            % check if MVC task was run
            mvcdatfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_MVC.mat']); % Dat-file name, following the naming convention
            if (~exist(mvcdatfile,'file'))
                fprintf('MVC file does not exist. Run MVC task first.');
            else
                S=load(mvcdatfile);
                gExp.maxForce=gExp.percentMVC*S.mvcf;   % Maximal force level is 80% of MVC
                gExp.maxForce(abs(gExp.maxForce(:,1:5))<1.5)=-1.5;
                gExp.maxForce(logical([zeros(2,5),abs(gExp.maxForce(:,6:10))<1.5]))=1.5;
                gExp.maxForce(gExp.maxForce>30)=30; %Max
                gExp.PRESS_TIME=5;          % time for presenting a go cue
                runBlock(tgtfilename, command);
            end
            
        case 'set'                          % Sets any global variable the value specified
            [varName, value]= strtok(param);
            if isfield(gExp,varName)
                gExp.(varName)= str2double(value);
            else
                fprintf('%s is not a valid variable name.',varName);
            end
            updateTextWindow;
            
        case {'quit','exit'}
            isDone=true;
            
        case 'demo'
            runDemo;                        % Goes into demo mode
            
        case ''                             % just hit return: do nothing
            
        otherwise                           % Unknown command: give error message
            fprintf('Unknown command\n');
    end
end

exitExp;


function initExp                        % Set global variables
global gExp;
gExp.simulation = 0;    %if this flag==1, this is a simulation and is not using live data.

gExp.DateStart=clock;
gExp.DateSTR=strcat(num2str(gExp.DateStart(1,3)),'_',num2str(gExp.DateStart(1,2)),'_',num2str(gExp.DateStart(1,1)));

gExp.site='Tech';

% EXPERIMENTS DIR's; SUBJ_NAME; THRESHOLDS; POINTS
gExp.code='Gili';                          % Experimental code for data file names

% DIRECTORY
gExp.basedir='C:\Users\gilik\OneDrive - Technion\New Research\CodeG\SMARTS\Individuation\data';     % Base directory

% Verify base directory (Can be made a comment once verified)
fprintf('Individuation base directory: %s\n',gExp.basedir);
confirmed=input('Accept? (Y/N)','s');
while strcmpi(confirmed,'N')
    gExp.basedir=input('Enter new base directory: ','s');
    fprintf('Individuation base directory: %s\n',gExp.basedir);
    confirmed=input('Accept? (Y/N)','s');
end


gExp.targetdir=fullfile(gExp.basedir, 'bedside','target');        % For the target files
gExp.datadir=fullfile(gExp.basedir, 'bedside','data');            % For the data files
gExp.calibdir = fullfile(gExp.basedir,'Calibration','data');      % For the calibration files

gExp.subj_name=[];                              % Name of the subject
gExp.BN = 0;
gExp.points=0;                                  % Global number of points
gExp.pause=false;
gExp.WAIT_TIME = 1.5;                           % ISI
gExp.HOLD_TIME = 2;                             % time waiting after reaching the lower force
gExp.RELEASE_TIME=3;                            % time waiting for releasing
gExp.Next_Trial_TIME = 0.25;                          % time to wait between trials, when no space bar required
gExp.FB_TIME = 0.5;                             % Time for feedback after successful completion

% Forces:
% Loading the scaling factor of how many N correspond to 1 V:
% analyzed using calibrate_V2N_analyze.m

calibfileRight = '2021_04_07_Right_NoEpoxy_Calib.mat';
calibfileLeft = '2021_03_21_Left_NoEpoxy_Calib.mat';
Rcalibration=load(fullfile(gExp.calibdir, calibfileRight));
Lcalibration=load(fullfile(gExp.calibdir, calibfileLeft));

gExp.scaleV2N = [Lcalibration.Volts2N,Rcalibration.Volts2N];    %L;R Flex T->p, Ext T->p [2x10]
gExp.scaleV2NRL = [Rcalibration.Volts2N,Lcalibration.Volts2N];  %R;L Flex T->p, Ext T->p [2x10]
gExp.zeroVolts=zeros(1,20);    % These are the force baselines to be set with zeroF
gExp.force=zeros(2,5);         % Initialise the finger forces
gExp.maxForce = repmat(15,2,10);  % max forces for 10 digits
gExp.percentMVC=0.8;            % Percent MVC
gExp.forcePadding=0.1;          %padding -+ around target force, in % gili

%Color definitions:
gExp.myColor=[0,0,0;...   % 1: Black
    255,255,255;...		  % 2: White
    0,200,0;...   		  % 3: Green
    150,0,0;...			  % 4: Red
    50,50,50;...	      % 5: gray
    20,20,20;...          % 6: darkgray
    0,0,200;...           % 7: blue
    50,200,200];           % 8: Turquoise

% [gExp.mySndy,gExp.mySndFs]=audioread(fullfile(gExp.targetdir,'button.wav'));
[gExp.mySndy,gExp.mySndFs]=audioread(fullfile(gExp.targetdir,'tada.wav'));
[gExp.mySndySTOP,gExp.mySndFsSTOP]=audioread(fullfile(gExp.targetdir,'Windows Critical Stop.wav'));


% Point counter and thresholds reset
gExp.numPointsBlock=0;    % Points currently obtained in a Block
gExp.numPoints=0;         % Total number of points earned in this session
gExp.rmsThreshold = [1.5 1.5]; % RMS threshold for left and right hands
gExp.lastRMS= NaN;        % Last RMS (for feedback purposes only)
gExp.percentCorrect = 0;

gExp.thresholdFPress=2.3;       % Upper bound of the force region
gExp.thresholdFRelease=2.5;

gExp.showBoxes=1;
gExp.showFBars=1;
gExp.showLines=1;
gExp.showText=1;
gExp.giveFeedback=1;
gExp.showfbThreshold = 0;
gExp.showBothHands=1;           % whether to display both hands during a trial or not
gExp.showArrows=1;              % whether to display arrows
gExp.digitSignal = 0;           % signal which fingers will move. (needs to initialize as 0, go to states section to turn off entirely)
gExp.SpaceBarRequired=1;        % whether a space is required between trials.
gExp.showFingerNames=1;

% Text display on Screen:
gExp.numText=3;
gExp.text{1}=sprintf('Points: %d',gExp.numPointsBlock);     % First line of text
gExp.text{2}='';
gExp.text{3}='';                                            % Points total
gExp.text{4}=sprintf('Welcome! Have fun playing!');         % Only appears on graphicsInit
gExp.text{5}=sprintf('Zeroing Forces, stay still');         % Only appears when zeroing

% Default trial
gExp.T.hand=1;
gExp.T.digit=3;
gExp.T.targetForce=1;
gExp.T.lowForce=0;
gExp.T.highForce=1;

% Time stamps
gExp.currentTime=0;
gExp.baselineTime=0;

gExp.currentTimestamp=0;
gExp.baselineTimestamp=0;

% Chord Information for multiple fingers
gExp.chords=[eye(5);...
    1,1,0,0,0; 1,0,1,0,0; 1,0,0,1,0; 1,0,0,0,1; 0,1,1,0,0;...
    0,1,0,1,0; 0,1,0,0,1; 0,0,1,1,0; 0,0,1,0,1; 0,0,0,1,1;...
    0,0,1,1,1; 0,1,0,1,1; 0,1,1,0,1; 0,1,1,1,0; 1,0,0,1,1;...
    1,0,1,0,1; 1,0,1,1,0; 1,1,0,0,1; 1,1,0,1,0; 1,1,1,0,0;...
    0,1,1,1,1; 1,0,1,1,1; 1,1,0,1,1; 1,1,1,0,1; 1,1,1,1,0;...
    1,1,1,1,1;];
%4 finger chords:  ones(5)-eye(5)
gExp.chordname={'1','2','3','4','5',...
    '12','13','14','15','23','24','25','34','35','45',...
    '345','245','235','234','145','135','134','125','124','123',...
    '2345','1345','1245','1235','1234',...
    '12345'};

RAW.ZeroVolts{1}=[];


function exitExp                        % Clean up after the Experiment
global gExp;
gExp.DateEnd=clock;
% *save globals*

instrreset;
daqreset;  % clearing up USB
delete(instrfindall); % clearing up serial ports
Screen('CloseAll'); % same as: clear Screen or sca
close all;
clear global gExp;


function initBoard                      % Initialize the response board and USB device
global gExp;
daqreset;               % Reset all DAQ devices
daqs = daqlist('ni');   % check NI-DAQ devices avaliable to matlab

gExp.AI = daq("ni");      % Create a DataAcquisition object
gExp.AI.Rate = 250;       % Sampling rate, [hz]

%% Right Hand Channels Setup (add, name, terminal config)
gExp.ch = addinput(gExp.AI,'Dev2','ai4','Voltage');      %1 Right Thumb, Flexion
gExp.ch.Name = "Right Thumbs, Flex";
gExp.ch.TerminalConfig ="SingleEnded";
gExp.ch = addinput(gExp.AI,'Dev2','ai3','Voltage');      %2 Right Index, Flexion
gExp.ch.Name = "Right Index, Flex";
gExp.ch.TerminalConfig ="SingleEnded";
gExp.ch = addinput(gExp.AI,'Dev2','ai2','Voltage');      %3 Right Middle, Flexion
gExp.ch.Name = "Right Middle, Flex";
gExp.ch.TerminalConfig ="SingleEnded";
gExp.ch = addinput(gExp.AI,'Dev2','ai1','Voltage');      %4 Right Ring, Flexion
gExp.ch.Name = "Right Ring, Flex";
gExp.ch.TerminalConfig ="SingleEnded";
gExp.ch = addinput(gExp.AI,'Dev2','ai0','Voltage');      %5 Right Pinky, Flexion
gExp.ch.Name = "Right Pinky, Flex";
gExp.ch.TerminalConfig ="SingleEnded";
gExp.ch = addinput(gExp.AI,'Dev2','ai9','Voltage');      %1 Right Thumb, Extension
gExp.ch.Name = "Right Thumb, Ext";
gExp.ch.TerminalConfig ="SingleEnded";
gExp.ch = addinput(gExp.AI,'Dev2','ai8','Voltage');      %2 Right Index, Extension
gExp.ch.Name = "Right Index, Ext";
gExp.ch.TerminalConfig ="SingleEnded";
gExp.ch = addinput(gExp.AI,'Dev2','ai7','Voltage');      %3 Right Middle, Extension
gExp.ch.Name = "Right Middle, Ext";
gExp.ch.TerminalConfig ="SingleEnded";
gExp.ch = addinput(gExp.AI,'Dev2','ai6','Voltage');      %4 Right Ring, Extension
gExp.ch.Name = "Right Ring, Ext";
gExp.ch.TerminalConfig ="SingleEnded";
gExp.ch = addinput(gExp.AI,'Dev2','ai5','Voltage');      %5 Right Pinky, Extension
gExp.ch.Name = "Right Pinky, Ext";
gExp.ch.TerminalConfig ="SingleEnded";

%% Left Hand Channels Setup (add, name, terminal config)
gExp.ch = addinput(gExp.AI,'Dev1','ai4','Voltage');      %1 Left Thumb, Flexion
gExp.ch.Name = "Left Thumbs, Flex";
gExp.ch.TerminalConfig ="SingleEnded";
gExp.ch = addinput(gExp.AI,'Dev1','ai3','Voltage');      %2 Left Index, Flexion
gExp.ch.Name = "Left Index, Flex";
gExp.ch.TerminalConfig ="SingleEnded";
gExp.ch = addinput(gExp.AI,'Dev1','ai2','Voltage');      %3 Left Middle, Flexion
gExp.ch.Name = "Left Middle, Flex";
gExp.ch.TerminalConfig ="SingleEnded";
gExp.ch = addinput(gExp.AI,'Dev1','ai1','Voltage');      %4 Left Ring, Flexion
gExp.ch.Name = "Left Ring, Flex";
gExp.ch.TerminalConfig ="SingleEnded";
gExp.ch = addinput(gExp.AI,'Dev1','ai0','Voltage');      %5 Left Pinky, Flexion
gExp.ch.Name = "Left Pinky, Flex";
gExp.ch.TerminalConfig ="SingleEnded";
gExp.ch = addinput(gExp.AI,'Dev1','ai9','Voltage');      %1 Left Thumb, Extension
gExp.ch.Name = "Left Thumb, Ext";
gExp.ch.TerminalConfig ="SingleEnded";
gExp.ch = addinput(gExp.AI,'Dev1','ai8','Voltage');      %2 Left Index, Extension
gExp.ch.Name = "Left Index, Ext";
gExp.ch.TerminalConfig ="SingleEnded";
gExp.ch = addinput(gExp.AI,'Dev1','ai7','Voltage');      %3 Left Middle, Extension
gExp.ch.Name = "Left Middle, Ext";
gExp.ch.TerminalConfig ="SingleEnded";
gExp.ch = addinput(gExp.AI,'Dev1','ai6','Voltage');      %4 Left Ring, Extension
gExp.ch.Name = "Left Ring, Ext";
gExp.ch.TerminalConfig ="SingleEnded";
gExp.ch = addinput(gExp.AI,'Dev1','ai5','Voltage');      %5 Left Pinky, Extension
gExp.ch.Name = "Left Pinky, Ext";
gExp.ch.TerminalConfig ="SingleEnded";


function runBlock(targetfilename, command)       % Run a single Block
global gExp;

if ~gExp.simulation
    zeroFGili       %zero the forces at the beginning of each block
    gExp.zeroVoltsBlocks{gExp.BN}{1}=gExp.zeroVolts;
    start(gExp.AI,"continuous");
    fprintf('Done Zeroing\n');
    pause(0.25)
end

% set back to default
gExp.FScale=gExp.fBarHeight./abs(gExp.maxForce);
gExp.showfbThreshold=0;
gExp.showText=1;
gExp.giveFeedback=1;
gExp.numPointsBlock=0;
gExp.WAIT_TIME=1.5; % ISI (time between space and targets)
gExp.HOLD_TIME=2; % time waiting after pass the feedback threshold
gExp.text{1}=sprintf('Points: %d',gExp.numPointsBlock);
% gExp.thresholdFRelease=0.1*max(max(abs(gExp.maxForce)));

switch(command)
    case 'demo'
        datfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_' gExp.DaySTR '_Demo.mat']); % Dat-file name, following the naming convention
        movfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_' gExp.DaySTR '_' num2str(gExp.BN,'%02d') 'Demo.mat']);
        rawfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_' gExp.DaySTR '_Demo_RAW.mat']);
        temprawfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_' gExp.DaySTR '_Demo_TempRAW.mat']);
    case 'run'
        datfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_' gExp.DaySTR '.mat']); % Dat-file name, following the naming convention
        movfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_' gExp.DaySTR '_' num2str(gExp.BN,'%02d') '.mat']);
        rawfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_' gExp.DaySTR '_RAW.mat']);
        temprawfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_' gExp.DaySTR '_TempRAW.mat']);
    case 'run_Synergy'
        datfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_' gExp.DaySTR '_Synergy.mat']); % Dat-file name, following the naming convention
        movfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_' gExp.DaySTR '_' num2str(gExp.BN,'%02d') '_Synergy.mat']);
        rawfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_' gExp.DaySTR '_Synergy_RAW.mat']);
        temprawfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_' gExp.DaySTR '_Synergy_TempRAW.mat']);
    case 'run_Automated_Training'
        datfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_' gExp.DaySTR '_Automated_Training.mat']); % Dat-file name, following the naming convention
        movfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_' gExp.DaySTR '_' num2str(gExp.BN,'%02d') '_Automated_Training.mat']);
        rawfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_' gExp.DaySTR '_Automated_Training_RAW.mat']);
        temprawfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_' gExp.DaySTR '_Automated_Training_TempRAW.mat']);
    case 'run_Automated_Testing'
        datfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_' gExp.DaySTR '_Automated_Testing.mat']); % Dat-file name, following the naming convention
        movfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_' gExp.DaySTR '_' num2str(gExp.BN,'%02d') '_Automated_Testing.mat']);
        rawfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_' gExp.DaySTR '_Automated_Testing_RAW.mat']);
        temprawfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_' gExp.DaySTR '_Automated_Testing_TempRAW.mat']);
end

% Check if the block exists
if (exist(movfile,'file'))
    answer=input('Block exist! Run anyway? (Y/N)','s');
    if strcmpi(answer,'N')
        return;
    end
end

% Check if target file exists
if (~exist(fullfile(gExp.targetdir, targetfilename),'file'))
    fprintf('Target file %s does not exist!\n',fullfile(gExp.targetdir, targetfilename));
    files = dir(fullfile(gExp.targetdir,'*.tgt'));
    if (~isempty(files))
        fprintf('Target files available:');
        fprintf('%s\n',files(:).name);
    else
        fprintf('No target file in directory %s.', gExp.targetdir);
    end
    return;
end

T=dload(fullfile(gExp.targetdir, targetfilename));

if (isempty(T))
    fprintf('Could not find target file');
    files = dir(fullfile(gExp.targetdir,'*.tgt'));
    if (~isempty(files))
        fprintf('Target files available:\n');
        fprintf('%s\n',files(:).name);
    else
        fprintf('No target file in directory %s.', gExp.targetdir);
    end
    return;
end

if T.targetForce>0
    T.lowForce=(T.targetForce-gExp.forcePadding);    %calculate lowF with padding
    T.highForce=(T.targetForce+gExp.forcePadding);   %calculate highF with padding
else
    T.lowForce=(T.targetForce+gExp.forcePadding);    %calculate lowF with padding
    T.highForce=(T.targetForce-gExp.forcePadding);   %calculate highF with padding
end

if (exist(datfile,'file'))
    D=load(datfile);               % if a data file exists, append the new data to it.
else
    D.BN=[];                        % Otherwise start fresh
    D.TN=[];
end

fieldN=fieldnames(T);           % Check how many trials
numTrials=length(T.(fieldN{1}));
T.BN=ones(numTrials,1)*gExp.BN;
T.TN=(1:numTrials)';

gExp.force=zeros(2,5);

gExp.text{2}='';
gExp.showBoxes=1;
gExp.showFBars=1;

MOV={};

i=1;

while i<=numTrials
    tn=i;
    if gExp.pause  % if user broke out of the exp, back to >EXP environment
        gExp.numPointsBlock=0;
        gExp.text{1}='';
        gExp.pause=0;
        return;
    end
    
    if gExp.SpaceBarRequired==1        % press Space key to run each trial
        FlushEvents('keyDown');
        WaitSecs(0.1);
        uiwait(msgbox('Press OK to continue'));
        %         fprintf('Press space bar to move on\n');
        %         [~,keycode,~]=KbPressWait(-1);
        %         if keycode(KbName('space'))
        if rem(tn,12)==0
            zeroFGili;
            gExp.zeroVoltsBlocks{gExp.BN}{tn}=gExp.zeroVolts;
        end
        if ~gExp.simulation
            stop(gExp.AI)
            flush(gExp.AI)
            start(gExp.AI,"continuous")
            pause(0.15)
        end
        [d,MOV{tn}]=runTrial(getrow(T,tn), command);
        D=addstruct(D,d,'row','force');
        i=i+1;
        pause(gExp.Next_Trial_TIME);
        %         elseif keycode(KbName('q')) || keycode(KbName('Q'))
        %             gExp.numPointsBlock=0;
        %             gExp.text{1}='';
        %             gExp.pause=0;
        %             return;
        %         end
    else                                %If i don't require a space hit
        if rem(tn,12)==0
            zeroFGili;
            gExp.zeroVoltsBlocks{gExp.BN}{tn}=gExp.zeroVolts;
        end
        if ~gExp.simulation
            stop(gExp.AI)
            flush(gExp.AI)
            start(gExp.AI,"continuous") %start acquisition at beginning of trial
            pause(0.15)
        end
        [d,MOV{tn}]=runTrial(getrow(T,tn), command);
        tic
        D=addstruct(D,d,'row','force');
        i=i+1;
        pause(gExp.Next_Trial_TIME);
    end
    TempRAW.Times=gExp.rawTimes{gExp.BN};
    TempRAW.Data=gExp.rawData{gExp.BN};
    TempRAW.DataNewtons=gExp.rawDataNewtons{gExp.BN};
    
    save(datfile,'-struct','D');
    save(movfile,'MOV');
    save(temprawfile,'TempRAW');
end

RAW.Times=gExp.rawTimes;
RAW.Data=gExp.rawData;
RAW.ZeroVolts=gExp.zeroVoltsBlocks;
RAW.DataNewtons=gExp.rawDataNewtons;

save(datfile,'-struct','D');
save(movfile,'MOV');
save(rawfile,'RAW');

FlushEvents('keyDown');
WaitSecs(0.05);

gExp.numPoints=gExp.numPoints+gExp.numPointsBlock;
gExp.percentCorrect = (gExp.numPointsBlock/tn)*100;
gExp.text{1}=sprintf('Points Block: %d',gExp.numPointsBlock);         % Get stuff on the screen
gExp.text{3}=sprintf('Points Total: %d',gExp.numPoints);                    % Get stuff on the screen, only on last round
updateGraphics;


FlushEvents('keyDown');
fprintf('Block number %d ended\n',gExp.BN);
WaitSecs(0.05);
gExp.text{1}=sprintf('Points: %d',gExp.numPointsBlock);         % Get stuff on the screen
gExp.text{3}=sprintf('Points Total: %d',gExp.numPoints);    % Get stuff on the screen, only on last round
gExp.numPointsBlock=0;
updateGraphics;
gExp.MOVBlock=MOV;
gExp.text{3}=('');    % Get stuff on the screen, only on last round
if ~gExp.simulation
    stop(gExp.AI);
end


function [T,mov]=runTrial(T, command)            % Run a single Trial
global gExp;
if T.TN==1
    pause(0.15)
end

gExp.rawData{T.BN}{T.TN}=[];           % Initialize data struct
gExp.rawDataNewtons{T.BN}{T.TN}=[];
gExp.rawTimes{T.BN}{T.TN}=[];

% player = audioplayer(gExp.mySndy,gExp.mySndFs);
fprintf(['Trial #' num2str(T.TN) '\n']);

if gExp.simulation
    test = load('Simulation_Forces.mat');
    test = test.Simulation_Forces;
end

% Set all presses to NaN
T.pressTime=NaN;
T.signalTime=NaN;
T.releaseTime=NaN;
T.respHand=NaN;
T.respDigit=NaN;
T.rms=NaN;

isDone=false;
state=1;            % State of the trial

% Initialize data
dstate=zeros(50,1);
dtime=zeros(50,1);
sampdata=zeros(50,20);
ActiveSampData=zeros(50,10);
ddata=zeros(50,10);
SampIndx=0;

T.startTime=0;

while (~isDone)
    [keydown,~,keycode]=KbCheck;
    if keydown && (keycode(KbName('q'))||keycode(KbName('Q')))
        gExp.pause=true;
        break;
    end
    
    SampIndx = SampIndx+1;
    
    if gExp.simulation
        sampdata(SampIndx,:)=0.3*test{T.TN}(SampIndx,:);
        pause(0.1)
    else
        [sampdata(SampIndx,:),~]=updateForce(T.BN,T.TN);     %[1,20]=[Left (Flex TIMRP, ext TIMRP,; Right (flex, ext)]
    end
    
    for i=1:5       %for each finger, select either flex or ext forces based on abs value
        [~,indL]=max([abs(sampdata(SampIndx,i)),sampdata(SampIndx,i+5)]);
        [~,indR]=max([abs(sampdata(SampIndx,10+i)),sampdata(SampIndx,10+i+5)]);
        gExp.force(1,i)=sampdata(SampIndx,(i+(indL-1)*5));      %left hand active forces (with signs) (T->P)
        gExp.force(2,i)=sampdata(SampIndx,(10+i+(indR-1)*5));   %right hand active forces (with signs) (T->P)
    end
    
    ActiveSampData(SampIndx,:)=[gExp.force(1,:),gExp.force(2,:)];   %active forces [1,10]=[Left (t->p); Right (t->p)]
    
    updateTextWindow(T);
    gExp.currentTime=updateGraphics(T)-gExp.baselineTime;
    if T.startTime==0   %gili, to avoid the jumping screen at the beginning of each trial
        T.startTime=gExp.currentTime;
        reftime=gExp.currentTime-T.startTime;
    end
    time=gExp.currentTime-T.startTime;
    
    dtime(SampIndx,1)=time;
    dstate(SampIndx,1)=state;
    ddata(SampIndx,:)=ActiveSampData(SampIndx,:);
    
    % calculate the current chord to display
    chord = gExp.chords(T.digit,:);
    digit = find(chord == 1);           %active digits, by naming conventions: 1=thumb, 2=inx, 3=mid, 4=ring, 5=pinky!!
    passiveDigits = find(chord == 0);
    T.PositiveF=(T.targetForce>0);     %gili flag for positive or neg force
    
    switch(state)
        case 1 % WAIT_GO
            if (time-reftime > gExp.WAIT_TIME) % use this for fixed ISI
                gExp.showfbThreshold=1; % Show target and threshold lines
                T.signalTime=time;      % Signaltime indicates when it goes green
                reftime=time;           % Take the time from signal appearance
                state=2;
                %                 gExp.digitSignal = 0;   % Stop the signaling of the finger
            elseif (time-reftime > (0.5*gExp.WAIT_TIME))
                gExp.digitSignal = 1;   % Signal which fingers will need to move.
            end
        case 2 % WAIT_RESPONSE
            if (T.PositiveF)        %gili check if min force threshold was surpassed
                digitTF = (gExp.force(T.hand,digit)>=T.lowForce*gExp.maxForce(T.hand,5+digit));   % whether each digit reached the lower target force
            else
                digitTF = (gExp.force(T.hand,digit)<=T.lowForce*abs(gExp.maxForce(T.hand,digit)));   % whether each digit reached the lower target force
            end
            
            if (sum(digitTF) == length(digit)) % good response only when all instructed finger forces are above the minimum lower threshold
                pressIndx=SampIndx;
                T.pressTime=time;
                T.respHand=T.hand;
                T.respDigit=T.digit;            % saving the digit as it is a representation of the chord pressed (1-31)
                reftime=time;
                state=3;
            elseif(time-reftime>=gExp.PRESS_TIME)
                reftime=time;
                state=4;
                %                 sound(gExp.mySndySUCK,gExp.mySndFsSUCK);
                T.rms=NaN;
            end
        case 3 % WAIT_CUE_RELEASE
            if (time-reftime>gExp.HOLD_TIME)
                
                % Evaluate the rms of all fingers
                pattern=zeros(1,10);
                patternLow=zeros(1,10);
                patternHigh=zeros(1,10);
                
                if (T.PositiveF)
                    for d = 1:length(digit)
                        pattern(digit(d)+(T.hand-1)*5)=T.targetForce*gExp.maxForce(T.hand,5+digit(d));
                        patternLow(digit(d)+(T.hand-1)*5)=(T.lowForce)*gExp.maxForce(T.hand,5+digit(d));
                        patternHigh(digit(d)+(T.hand-1)*5)=(T.highForce)*gExp.maxForce(T.hand,5+digit(d));
                        A=(1:5)+(T.hand-1)*5; ActDig=(digit+(T.hand-1)*5); PassDig=setxor(A,ActDig);
                    end
                    for i=1:length(PassDig)
                        if PassDig(i)<=5 %left hand)
                            PassiveThreshold(i)=0.05*gExp.maxForce(1,5+PassDig(i));
                        else    %right hand
                            PassiveThreshold(i)=0.05*gExp.maxForce(2,PassDig(i));
                        end
                    end
                else
                    for d = 1:length(digit)
                        pattern(digit(d)+(T.hand-1)*5)=T.targetForce*abs(gExp.maxForce(T.hand,digit(d)));     %gili negative forces (target is signed)
                        patternLow(digit(d)+(T.hand-1)*5)=(T.lowForce)*abs(gExp.maxForce(T.hand,digit(d)));
                        patternHigh(digit(d)+(T.hand-1)*5)=(T.highForce)*abs(gExp.maxForce(T.hand,digit(d)));
                        A=(1:5)+(T.hand-1)*5; ActDig=(digit+(T.hand-1)*5); PassDig=setxor(A,ActDig);
                    end
                    for i=1:length(PassDig)
                        if PassDig(i)<=5 %left hand)
                            PassiveThreshold(i)=0.05*gExp.maxForce(1,PassDig(i));
                        else    %right hand
                            PassiveThreshold(i)=0.05*gExp.maxForce(2,PassDig(i)-5);
                        end
                    end
                end
                
                
                meanforce=mean(ActiveSampData(pressIndx:SampIndx,:));
                
                T.RMS=mean(sqrt(mean((pattern(PassDig)-meanforce(:,PassDig)).^2)));
                
                if (gExp.giveFeedback) % chords and individuation tasks
                    if (T.PositiveF)
                        %                         if ((all(meanforce(digit+(T.hand-1)*5) >= patternLow(digit+(T.hand-1)*5))) && (all(meanforce(digit+(T.hand-1)*5) <= patternHigh(digit+(T.hand-1)*5))) && (T.RMS < gExp.rmsThreshold(T.hand)))
                        if ((all(meanforce(digit+(T.hand-1)*5) >= patternLow(digit+(T.hand-1)*5))) && (all(meanforce(digit+(T.hand-1)*5) <= patternHigh(digit+(T.hand-1)*5))) && ((isempty(PassDig) || all(abs(meanforce(PassDig))<= abs(PassiveThreshold)))))
                            gExp.numPointsBlock=gExp.numPointsBlock+1; % count up number of points block
                            gExp.text{1}=sprintf('Points: %d', gExp.numPointsBlock); % present the current score on the screen
                            T.point=1;
                            sound(gExp.mySndy,gExp.mySndFs);
                        end
                    else
                        if ((all(meanforce(digit+(T.hand-1)*5) >= patternHigh(digit+(T.hand-1)*5))) && all(meanforce(digit+(T.hand-1)*5) <= patternLow(digit+(T.hand-1)*5)) && ((isempty(PassDig) || all(abs(meanforce(PassDig))<= abs(PassiveThreshold)))))
                            gExp.numPointsBlock=gExp.numPointsBlock+1; % count up number of points block
                            gExp.text{1}=sprintf('Points: %d', gExp.numPointsBlock); % present the current score on the screen
                            T.point=1;
                            sound(gExp.mySndy,gExp.mySndFs);
                        end
                    end
                end
                
                gExp.lastRMS=T.RMS;
                gExp.showfbThreshold=0;
                reftime=time;
                state=4;
            end
        case 4 % WAIT_RELEASE
            if (time-reftime<gExp.RELEASE_TIME)
                if (all(gExp.force<gExp.thresholdFRelease)) % release detected
                    T.releaseTime=time;
                    reftime=time;
                    state=5;
                    gExp.showfbThreshold=0; % Do not show target threshold anymore
                end
            elseif (time-reftime>=gExp.RELEASE_TIME) % passed release time
                reftime=time;
                state=5;
                gExp.showfbThreshold=0; % Do not show target threshold anymore
            end
        case 5 % WAIT FEEDBACK
            % wait for release
            gExp.digitSignal = 0;   % Stop the signaling of the finger
            if (all(all(gExp.force<gExp.thresholdFRelease))) && ((time-reftime)>=1.5) % release detected
                
                %if (time-reftime<gExp.FB_TIME)
                disp('Release detected');
                isDone=true;
            elseif (time-reftime>=2)
                isDone=true;
            end
            
    end
    %     updateTextWindow(T);
    updateGraphics(T);
end

mov=[dstate, dtime, ddata]; % Makes movement file
gExp.MOVTrial{T.TN}=mov;

% RealRate=1/mean(diff(gExp.MOVTrial{T.TN}(:,2)))  % When working to increase screen refresh rate

updateGraphics(T);


function initGraphics                   % Calculate the coordinates for updateGraphics
global gExp;
n_monitors = size(Screen('Screens'),2);
if (n_monitors == 3)
    [gExp.wPtr,gExp.ScreenRect]=Screen('OpenWindow',2,gExp.myColor(1,:)); % projecting on second screen
else
    [gExp.wPtr,gExp.ScreenRect]=Screen('OpenWindow',0,[0 0 0],[1100,100,1920,1040],kPsychGUIWindow); % [xpos,ypos,xpos,ypos] %originally [480,10,1400,980] 40,40,500,500
end

[gExp.ScreenWidth, gExp.ScreenHeight]=Screen('WindowSize', gExp.wPtr);
%for reference: 0,0 is top left corner. add [gExp.ScreenWidth/2,gExp.ScreenHeight/2] to center

gExp.textY=[860 880 900 100 150]/1024*gExp.ScreenHeight;   % Y-position 0: Top of the screen 1024: bottom
gExp.zeroing=0;

% Initialize the Screen: Depending on experimental setup,
% Size of instruction boxes
gExp.forcebaseline=800/1024*gExp.ScreenHeight;     % In pixels
gExp.fBarHeight=150/1024*gExp.ScreenHeight;
gExp.zeroforcebaseline=gExp.forcebaseline-gExp.fBarHeight;
gExp.rectBase=450/1024*gExp.ScreenHeight;
gExp.rectWidth=50/1280*gExp.ScreenWidth;
gExp.rectHeight=[105 198 229 198 136;105 198 229 198 136]/1024*gExp.ScreenHeight;
gExp.rectXPos=[-60 -150 -210 -270 -330;60 150 210 270 330]/1280*gExp.ScreenWidth;
gExp.FScale=gExp.fBarHeight./gExp.maxForce; % Visual scaling: this is scaling factor of how many pixels per N

%arrows denoting Extension and Flexion directions
tipExt   = [ (min(min(gExp.rectXPos))-60/1280*gExp.ScreenWidth+gExp.ScreenWidth/2), (gExp.zeroforcebaseline-0.75*gExp.fBarHeight) ]; % coordinates of head
width  = 25/1280*gExp.ScreenWidth;           % width of arrow head
gExp.pointsExt = [ tipExt-[width,0]         % left corner
    tipExt-[0,width]         % vertex
    tipExt+[width,0]         % right corner
    tipExt+[0.5*width,0]
    tipExt+[0.5*width,0.5*gExp.fBarHeight]
    tipExt+[-0.5*width,0.5*gExp.fBarHeight]
    tipExt-[0.5*width,0]];

tipFlex = [tipExt(1),gExp.zeroforcebaseline+0.75*gExp.fBarHeight];
gExp.pointsFlex = [ tipFlex-[width,0]         % left corner
    tipFlex+[0,width]         % vertex
    tipFlex+[width,0]         % right corner
    tipFlex+[0.5*width,0]
    tipFlex+[0.5*width,-0.5*gExp.fBarHeight]
    tipFlex+[-0.5*width,-0.5*gExp.fBarHeight]
    tipFlex-[0.5*width,0]];
Screen('FillPoly', gExp.wPtr,gExp.myColor(8,:)', gExp.pointsExt,0);
Screen('FillPoly', gExp.wPtr,gExp.myColor(8,:)', gExp.pointsExt+[780/1280*gExp.ScreenWidth,0],0);
Screen('FillPoly', gExp.wPtr,gExp.myColor(8,:)', gExp.pointsFlex,0);
Screen('FillPoly', gExp.wPtr,gExp.myColor(8,:)', gExp.pointsFlex+[780/1280*gExp.ScreenWidth,0],0);

Screen('TextSize', gExp.wPtr,round(28/1024*gExp.ScreenHeight));

gExp.LineXY=[];
for h=1:2
    for f=1:5
        gExp.LineXY(:,end+1)=[gExp.rectXPos(h,f)-gExp.rectWidth/2+gExp.ScreenWidth/2;...
            gExp.forcebaseline-gExp.force(h,f)*gExp.FScale(h,f)];
        gExp.LineXY(:,end+1)=[gExp.rectXPos(h,f)+gExp.rectWidth/2+gExp.ScreenWidth/2;...
            gExp.forcebaseline-gExp.force(h,f)*gExp.FScale(h,f)];
    end
end

gExp.HBox=[];     % hand boxes
for h=1:2
    for f=1:5
        gExp.HBox(:,end+1)=[gExp.rectXPos(h,f)-gExp.rectWidth/2+gExp.ScreenWidth/2;...  % left
            gExp.rectBase-gExp.rectHeight(h,f);...  % top
            gExp.rectXPos(h,f)+gExp.rectWidth/2+gExp.ScreenWidth/2;...  % right
            gExp.rectBase]; % bottom
    end
end
gExp.fBar=[];     % force bars
for h=1:2
    for f=1:5
        gExp.fBar(:,end+1)=[gExp.rectXPos(h,f)-gExp.rectWidth/2+gExp.ScreenWidth/2;...  % left
            gExp.forcebaseline-2*gExp.fBarHeight;...  % top
            gExp.rectXPos(h,f)+gExp.rectWidth/2+gExp.ScreenWidth/2;...  % right
            gExp.forcebaseline];  % bottom
    end
end

if (gExp.showBoxes)                             %show hands
    C=repmat(gExp.myColor(5,:)',1,10);
    Screen('FillRect', gExp.wPtr, C,gExp.HBox);
end

if (gExp.showFBars)
    if (~gExp.showfbThreshold)
        if (length(gExp.fBar)>10)
            gExp.fBar(:,11:end)=[];  % remove the cue
            gExp.showLines=1;
        end
        C=repmat(gExp.myColor(5,:)',1,10);
        Screen('FillRect',gExp.wPtr,C,gExp.fBar);
    else
        % calculate the current chord to display
        chord = gExp.chords(T.digit,:);
        digit = find(chord == 1);
        
        % cue for the fingers to press to go green
        for d = 1:length(digit)
            % bar to cue finger and force, superimposed on the corresponding digit
            % this highlights the target zone
            gExp.fBar(:,10+d) = ...
                [gExp.rectXPos(T.hand,digit(d))-gExp.rectWidth/2+gExp.ScreenWidth/2;...
                gExp.zeroforcebaseline-T.lowForce*gExp.fBarHeight;...
                gExp.rectXPos(T.hand,digit(d))+gExp.rectWidth/2+gExp.ScreenWidth/2;...
                gExp.zeroforcebaseline-T.highForce*gExp.fBarHeight];
            
            C(:,10+d)=gExp.myColor(3,:)'; % force cue, Green
            gExp.showLines=1;
            gExp.thresholdFRelease=1.0;
            
        end
        Screen('FillRect',gExp.wPtr,C,gExp.fBar);
        
        % drawing upper and lower limits on the force requiremens for the chord
        for d = 1:length(digit)
            XY(1,1)=gExp.rectXPos(T.hand,digit(d))-gExp.rectWidth/2+gExp.ScreenWidth/2;
            XY(1,2)=gExp.rectXPos(T.hand,digit(d))+gExp.rectWidth/2+gExp.ScreenWidth/2;
            XY(2,1:2)=gExp.zeroforcebaseline-T.targetForce*gExp.fBarHeight;
            Screen('DrawLines',gExp.wPtr,XY,4,[0 0 0]');
            XY(2,1:2)=gExp.zeroforcebaseline-T.lowForce*gExp.fBarHeight+1.5;
            Screen('DrawLines',gExp.wPtr,XY,3,[0 0 0]');
            XY(2,1:2)=gExp.zeroforcebaseline-T.highForce*gExp.fBarHeight-1.5;
            Screen('DrawLines',gExp.wPtr,XY,3,[0 0 0]');
        end
    end
end
if (gExp.showLines)
    a=gExp.force';
    b=gExp.FScale(:,1:5)';
    gExp.LineXY(2,1:2:20)=gExp.zeroforcebaseline-a(:).*b(:);
    gExp.LineXY(2,2:2:20)=gExp.zeroforcebaseline-a(:).*b(:);
    Screen('DrawLines',gExp.wPtr,gExp.LineXY,4,[255 255 255]');
end

if (gExp.showText)
    bounds=Screen('TextBounds',gExp.wPtr,gExp.text{4});     % Center text on screen
    Screen('DrawText', gExp.wPtr, gExp.text{4},round((gExp.ScreenWidth-bounds(3))/2),gExp.textY(4),[255 255 255]);
end

if (gExp.showFingerNames)
    % Finger Names
    gExp.FingerLetters={'T', 'I', 'M', 'R', 'P', 'T', 'I', 'M', 'R', 'P'};
    Screen('TextSize', gExp.wPtr,round(28/1024*gExp.ScreenHeight));
    for i=1:10
        Fbounds(i,:)=Screen('TextBounds',gExp.wPtr,gExp.FingerLetters{i});
        Screen('DrawText', gExp.wPtr, gExp.FingerLetters{i},(gExp.HBox(1,i)+gExp.HBox(3,i)-Fbounds(i,3))/2,gExp.HBox(4,1)-round(30/1024*gExp.ScreenHeight),[255 255 255]);
    end
    Screen('TextSize', gExp.wPtr,round(24/1024*gExp.ScreenHeight));
end

Screen('Flip',gExp.wPtr,0,0,2);
Screen('TextSize', gExp.wPtr,round(24/1024*gExp.ScreenHeight));


function [t]=updateGraphics(T)         % Refreshes the Screen
global gExp;
if (nargin==0)
    T=gExp.T;       % Take the default trial structure
end

% calculate the current chord to display
chord = gExp.chords(T.digit,:);
digit = find(chord == 1);
passiveDigits = find(chord == 0);

if (gExp.showBothHands)
    if (gExp.showBoxes)                             %show hands above bars
        C=repmat(gExp.myColor(5,:)',1,10);
        Screen('FillRect', gExp.wPtr, C,gExp.HBox);
        if gExp.digitSignal                         %gili signal which fingers need to move
            for d=1:length(digit)
                Screen('FillRect', gExp.wPtr, gExp.myColor(8,:)',gExp.HBox(:,(T.hand*5-5+digit(d))));
            end
            if (gExp.showArrows)
                if T.targetForce>0
                    Screen('FillPoly', gExp.wPtr,gExp.myColor(8,:)', gExp.pointsExt,0);
                    Screen('FillPoly', gExp.wPtr,gExp.myColor(8,:)', gExp.pointsExt+[780/1280*gExp.ScreenWidth,0],0);
                else
                    Screen('FillPoly', gExp.wPtr,gExp.myColor(8,:)', gExp.pointsFlex,0);
                    Screen('FillPoly', gExp.wPtr,gExp.myColor(8,:)', gExp.pointsFlex+[780/1280*gExp.ScreenWidth,0],0);
                end
            end
        end
    end
    
    if (gExp.showArrows && gExp.showfbThreshold)    %Arrows
        if T.targetForce>0
            Screen('FillPoly', gExp.wPtr,gExp.myColor(8,:)', gExp.pointsExt,0);
            Screen('FillPoly', gExp.wPtr,gExp.myColor(8,:)', gExp.pointsExt+[780/1280*gExp.ScreenWidth,0],0);
        else
            Screen('FillPoly', gExp.wPtr,gExp.myColor(8,:)', gExp.pointsFlex,0);
            Screen('FillPoly', gExp.wPtr,gExp.myColor(8,:)', gExp.pointsFlex+[780/1280*gExp.ScreenWidth,0],0);
        end
    end
    if (gExp.showFBars)
        if (~gExp.showfbThreshold)
            if (length(gExp.fBar)>10)
                gExp.fBar(:,11:end)=[];  % remove the cue
                gExp.showLines=1;
            end
            C=repmat(gExp.myColor(5,:)',1,10);
            Screen('FillRect',gExp.wPtr,C,gExp.fBar);
        else                            % cue for the fingers to press to go green
            for d = 1:length(digit)
                % bar to cue finger and force, superimposed on the corresponding digit
                % this highlights the target zone in green
                gExp.fBar(:,10+d) = ...
                    [gExp.rectXPos(T.hand,digit(d))-gExp.rectWidth/2+gExp.ScreenWidth/2;...
                    gExp.zeroforcebaseline-T.lowForce*gExp.fBarHeight;...
                    gExp.rectXPos(T.hand,digit(d))+gExp.rectWidth/2+gExp.ScreenWidth/2;...
                    gExp.zeroforcebaseline-T.highForce*gExp.fBarHeight];
                
                if abs(gExp.force(T.hand,digit(d)))<=14 %to verify forces aren't too high, and if they are, signal with red.
                    C(:,10+d)=gExp.myColor(3,:)'; % force cue, Green
                else
                    C(:,10+d)=gExp.myColor(4,:)'; % force cue, Red if too high
                    sound(gExp.mySndySTOP,gExp.mySndFsSTOP);
                end
                gExp.showLines=1;
                gExp.thresholdFRelease=1.0;
            end
            Screen('FillRect',gExp.wPtr,C,gExp.fBar);
            
            % drawing black upper and lower limits on the force requiremens for the
            % chord
            for d = 1:length(digit)
                XY(1,1)=gExp.rectXPos(T.hand,digit(d))-gExp.rectWidth/2+gExp.ScreenWidth/2;
                XY(1,2)=gExp.rectXPos(T.hand,digit(d))+gExp.rectWidth/2+gExp.ScreenWidth/2;
                XY(2,1:2)=gExp.zeroforcebaseline-T.targetForce*gExp.fBarHeight;
                Screen('DrawLines',gExp.wPtr,XY,3,[0 0 0]');    %black line in middle of target
                XY(2,1:2)=gExp.zeroforcebaseline-T.lowForce*gExp.fBarHeight;
                Screen('DrawLines',gExp.wPtr,XY,2,[0 0 0]');    %black line at low end of target
                XY(2,1:2)=gExp.zeroforcebaseline-T.highForce*gExp.fBarHeight;
                Screen('DrawLines',gExp.wPtr,XY,2,[0 0 0]');    %black line at high end of target
            end
            
            if passiveDigits
                gExp.REDfBar=[];
                for d = 1:length(passiveDigits)
                    % shows the non-movement zone in dark red
                    gExp.REDfBar(:,d) = ...
                        [gExp.rectXPos(T.hand,passiveDigits(d))-gExp.rectWidth/2+gExp.ScreenWidth/2;...
                        gExp.zeroforcebaseline-0.05*gExp.fBarHeight;...
                        gExp.rectXPos(T.hand,passiveDigits(d))+gExp.rectWidth/2+gExp.ScreenWidth/2;...
                        gExp.zeroforcebaseline+0.05*gExp.fBarHeight];
                end
                Screen('FillRect',gExp.wPtr,repmat([150, 75, 75]',1,length(passiveDigits)),gExp.REDfBar);
            end
            
        end
    end
    if (gExp.showLines) %show the forces as white lines
        a=gExp.force';
        if(T.targetForce>0)
            b=(gExp.FScale(:,6:10))';
        else
            b=(gExp.FScale(:,1:5))';
        end
        gExp.LineXY(2,1:2:20)=gExp.zeroforcebaseline-a(:).*b(:);
        gExp.LineXY(2,2:2:20)=gExp.zeroforcebaseline-a(:).*b(:);
        %         gExp.LineXY(2,1:10)=flip(gExp.LineXY(2,1:10),2);          %flip for display, because saved as L t->p, but displayed L p->t
        Screen('DrawLines',gExp.wPtr,gExp.LineXY,3,[255 255 255]');
    end
else
    if (gExp.showBoxes)                             %gili show only one hand
        C=repmat(gExp.myColor(5,:)',1,5);
        Screen('FillRect', gExp.wPtr, C,gExp.HBox(:,(T.hand*5-4):(T.hand*5)));
        C=repmat(gExp.myColor(6,:)',1,5);
        Screen('FillRect', gExp.wPtr, C,gExp.HBox(:,(11-T.hand*5):(15-T.hand*5)));
        
        if gExp.digitSignal                         %gili signal which fingers need to move
            % calculate the current chord to display
            chord = gExp.chords(T.digit,:);
            digit = find(chord == 1);
            passiveDigits = find(chord == 0);
            C=gExp.myColor(8,:)';
            for d=1:length(digit)
                Screen('FillRect', gExp.wPtr, C,gExp.HBox(:,(T.hand*5-5+digit(d))));
            end
        end
    end
    
    if (gExp.showArrows && gExp.showfbThreshold)
        if T.targetForce>0
            if T.hand==1
                Screen('FillPoly', gExp.wPtr,gExp.myColor(8,:)', gExp.pointsExt,0);
            else
                Screen('FillPoly', gExp.wPtr,gExp.myColor(8,:)', gExp.pointsExt+[780/1280*gExp.ScreenWidth,0],0);
            end
        else
            if T.hand==1
                Screen('FillPoly', gExp.wPtr,gExp.myColor(8,:)', gExp.pointsFlex,0);
            else
                Screen('FillPoly', gExp.wPtr,gExp.myColor(8,:)', gExp.pointsFlex+[780/1280*gExp.ScreenWidth,0],0);
            end
        end
    end
    
    if (gExp.showFBars)
        if (~gExp.showfbThreshold)
            if (length(gExp.fBar)>10)
                gExp.fBar(:,11:end)=[];  % remove the cue
                gExp.showLines=1;
            end
            C=repmat(gExp.myColor(5,:)',1,5);                   %gili show only one hand
            Screen('FillRect',gExp.wPtr,C,gExp.fBar(:,(T.hand*5-4):(T.hand*5)));    %gili show only one hand
            C=repmat(gExp.myColor(6,:)',1,5);
            Screen('FillRect', gExp.wPtr, C,gExp.fBar(:,(11-T.hand*5):(15-T.hand*5))); %show other hand in dark grey
        else
            % calculate the current chord to display
            chord = gExp.chords(T.digit,:);
            digit = find(chord == 1);
            passiveDigits = find(chord == 0);
            C=repmat(gExp.myColor(6,:)',1,5);
            Screen('FillRect', gExp.wPtr, C,gExp.fBar(:,(11-T.hand*5):(15-T.hand*5)));
            C=repmat(gExp.myColor(5,:)',1,5);
            % cue for the fingers to press to go green
            gExp.fBar2=gExp.fBar(:,(T.hand*5-4):(T.hand*5));      %Gili only one hand
            
            for d = 1:length(digit)
                % bar to cue finger and force, superimposed on the corresponding digit
                % this highlights the target zone
                gExp.fBar2(:,5+d) = ...
                    [gExp.rectXPos(T.hand,digit(d))-gExp.rectWidth/2+gExp.ScreenWidth/2;...
                    gExp.zeroforcebaseline-T.lowForce*gExp.fBarHeight;...
                    gExp.rectXPos(T.hand,digit(d))+gExp.rectWidth/2+gExp.ScreenWidth/2;...
                    gExp.zeroforcebaseline-T.highForce*gExp.fBarHeight];
                C(:,5+d)=gExp.myColor(3,:)'; % gili
                gExp.showLines=1;
                gExp.thresholdFRelease=1.0;
            end
            Screen('FillRect',gExp.wPtr,C,gExp.fBar2);
            
            if passiveDigits
                gExp.REDfBar=[];
                for d = 1:length(passiveDigits)
                    % shows the non-movement zone in dark red
                    gExp.REDfBar(:,d) = ...
                        [gExp.rectXPos(T.hand,passiveDigits(d))-gExp.rectWidth/2+gExp.ScreenWidth/2;...
                        gExp.zeroforcebaseline-0.05*gExp.fBarHeight;...
                        gExp.rectXPos(T.hand,passiveDigits(d))+gExp.rectWidth/2+gExp.ScreenWidth/2;...
                        gExp.zeroforcebaseline+0.05*gExp.fBarHeight];
                    
                    %                     CRED(:,d)=[150, 75, 75]'; % force cue, Red
                    
                end
                Screen('FillRect',gExp.wPtr,repmat([150, 75, 75]',1,length(passiveDigits)),gExp.REDfBar);
            end
            
            % drawing upper and lower limits on the force requiremens for the
            % chord
            for d = 1:length(digit)
                XY(1,1)=gExp.rectXPos(T.hand,digit(d))-gExp.rectWidth/2+gExp.ScreenWidth/2;
                XY(1,2)=gExp.rectXPos(T.hand,digit(d))+gExp.rectWidth/2+gExp.ScreenWidth/2;
                XY(2,1:2)=gExp.zeroforcebaseline-T.targetForce*gExp.fBarHeight;
                Screen('DrawLines',gExp.wPtr,XY,4,[0 0 0]');
                XY(2,1:2)=gExp.zeroforcebaseline-T.lowForce*gExp.fBarHeight+1.5;
                Screen('DrawLines',gExp.wPtr,XY,3,[0 0 0]');
                XY(2,1:2)=gExp.zeroforcebaseline-T.highForce*gExp.fBarHeight-1.5;
                Screen('DrawLines',gExp.wPtr,XY,3,[0 0 0]');
            end
        end
    end
    if (gExp.showLines)
        a=gExp.force';
        if(T.targetForce>0)
            b=(gExp.FScale(:,6:10))';
        else
            b=(gExp.FScale(:,1:5))';
        end
        gExp.LineXY(2,1:2:20)=gExp.zeroforcebaseline-a(:).*b(:);
        gExp.LineXY(2,2:2:20)=gExp.zeroforcebaseline-a(:).*b(:);
        gExp.LineXY(2,1:10)=flip(gExp.LineXY(2,1:10),2);          %flip for display, because saved as L t->p, but displayed L p->t
        Screen('DrawLines',gExp.wPtr,gExp.LineXY(:,(T.hand*10-9):(T.hand*10)),4,[255 255 255]');
    end
end

if (gExp.showText)
    for i=1:gExp.numText
        if (~isempty(gExp.text{i}))
            % Center text on screen
            if i==1
                Screen('TextSize', gExp.wPtr,round(30/1024*gExp.ScreenHeight));
            else
                Screen('TextSize', gExp.wPtr,round(24/1024*gExp.ScreenHeight));
            end
            bounds=Screen('TextBounds',gExp.wPtr,gExp.text{i});
            Screen('DrawText', gExp.wPtr, gExp.text{i},round((gExp.ScreenWidth-bounds(3))/2),gExp.textY(i),[255 255 255]);
        end
    end
end

if (gExp.zeroing)
    bounds=Screen('TextBounds',gExp.wPtr,gExp.text{5});     % Center text on screen
    Screen('DrawText', gExp.wPtr, gExp.text{5},round((gExp.ScreenWidth-bounds(3))/2),gExp.textY(5),[255 255 255]);
end

if (gExp.showFingerNames)
    % Finger Names
    gExp.FingerLetters={'T', 'I', 'M', 'R', 'P', 'T', 'I', 'M', 'R', 'P'};
    Screen('TextSize', gExp.wPtr,round(28/1024*gExp.ScreenHeight));
    for i=1:10
        Fbounds(i,:)=Screen('TextBounds',gExp.wPtr,gExp.FingerLetters{i});
        Screen('DrawText', gExp.wPtr, gExp.FingerLetters{i},(gExp.HBox(1,i)+gExp.HBox(3,i)-Fbounds(i,3))/2,gExp.HBox(4,1)-round(30/1024*gExp.ScreenHeight),[255 255 255]);
    end
    Screen('TextSize', gExp.wPtr,round(24/1024*gExp.ScreenHeight));
end

[~,~,t]=Screen('Flip',gExp.wPtr,0,0,2);       % LCD screen: do not wait for refresh


function initTextWindow                 % This function initializes the text window
global gExp;
figure(1); set(1,'Position',[10 400 500 400]);
set(gca,'YLim',[0 10],'Xlim',[0 10],'XTick',[],'YTick',[],'Color',[0.8 0.8 0.8],'Box','on','YDir','reverse');
gExp.textAxis=gca;


function updateTextWindow(T)           % Update the text window (Figure 1)
global gExp;
if (nargin==0)
    T=gExp.T;       % Take the default trial structure
end
cla(gExp.textAxis);
text(1,1,sprintf('Subj: %s   Block: %d',gExp.subj_name,gExp.BN));   %Subject Name and block #
text(1,2,sprintf('Zeroing Values[mV]: %1.2f %1.2f %1.2f %1.2f %1.2f',100*gExp.zeroVolts(1:5)));
text(1,2.5,sprintf('                          %1.2f %1.2f %1.2f %1.2f %1.2f',100*gExp.zeroVolts(6:10)));
text(1,3,sprintf('Left  H.: %2.2f %2.2f %2.2f %2.2f %2.2f',gExp.force(1,:)));   %Left hand forces, live
text(1,3.5,sprintf('Right H.: %2.2f %2.2f %2.2f %2.2f %2.2f',gExp.force(2,:)));   %Right hand foces, live
text(1,4,sprintf('RMS Threshold: %2.1f  %2.1f',gExp.rmsThreshold(1),gExp.rmsThreshold(2)));     %RMS Threshold
text(1,4.5,sprintf('RMS last: %2.2f',gExp.lastRMS));        %last RMS value
text(1,5.5,sprintf('Total Points: %1.f',gExp.numPoints));     %display total number of points (not including current block)


refresh;
drawnow;


function [current,t] = updateForce(bn,tn)                    % Reads one sample from the box, output is [1,20]=[left flex,ext, Right flex,ext]
global gExp;
pause(0.001)
[NewData,NewTimes]=read(gExp.AI,"all", "OutputFormat", "Matrix");   %output is [Mx20,Mx1]

gExp.rawData{bn}{tn}=[gExp.rawData{bn}{tn};NewData];        %output is a (N+M)x20 matrix (appended data)
gExp.rawTimes{bn}{tn}=[gExp.rawTimes{bn}{tn};NewTimes];     %output is a (N+M)x1 times vector

ForceReadings = gExp.rawData{bn}{tn}(end,:); % most current forces, all positive [Left:flex:thumb, index, mid, ring, pinky. ext:T,I,M,R,P. Right Flex TIMRP, Ext TIMRP]

% current = [zeros(1,10),-ForceReadings(1:5),ForceReadings(6:10)]; %rotem Right hand only [1x20] [Left Flex T ->Ext->Right ext t]
% current = [-ForceReadings(1:5),ForceReadings(6:10),zeros(1,10)]; %rotem Left hand only [Left Flex T ->Ext->Right ext t]
current=[-ForceReadings(11:15),ForceReadings(16:20),-ForceReadings(1:5),ForceReadings(6:10)];    %to use when using two rotem hands [Left Flex T ->Ext->Right ext t]

current = current-gExp.zeroVolts;    %Gili Fix zerovolts matrix size when 2 hands
% gExp.force(1,:)=current(1:5).*gExp.scaleV2N(1:5); %Gili scaling volts
% gExp.force(2,:)=current(6:10).*gExp.scaleV2N(6:10);

current = current.*gExp.scaleV2N;
t=gExp.rawTimes{bn}{tn}(end);
gExp.rawDataNewtons{bn}{tn}=((gExp.rawData{bn}{tn}-gExp.MeansZeroing).*gExp.scaleV2NRL).*repmat([-1 -1 -1 -1 -1 1 1 1 1 1 -1 -1 -1 -1 -1 1 1 1 1 1],size(gExp.rawData{bn}{tn},1),1);


function zeroFGili
global gExp;
gExp.zeroing=1;
updateGraphics;
stop(gExp.AI);
flush(gExp.AI);
fprintf('One Moment, Zeroing Forces...\n');
[ZeroData,~]=read(gExp.AI,seconds(2.5), "OutputFormat", "Matrix");   %output is [Mx20,Mx1]
gExp.MeansZeroing=mean(ZeroData);   %not according to finger conventions
gExp.zeroVolts=[-gExp.MeansZeroing(11:15),gExp.MeansZeroing(16:20),-gExp.MeansZeroing(1:5),gExp.MeansZeroing(6:10)];    %according to hand conventions
gExp.zeroing=0;


function runMVC
global gExp;
gExp.showBoxes=1;
gExp.showFBars=1;
gExp.showLines=1;
gExp.showText=0;
gExp.giveFeedback=0;
gExp.showfbThreshold = 0;

gExp.WAIT_TIME=1.5; % ISI - give longer waiting time for MVC task
gExp.HOLD_TIME=3; % (longer for mvc) time waiting after pass the feedback threshold
gExp.PRESS_TIME=5;          % time for presenting a go cue
gExp.maxForce = repmat(15,2,10);    % gili max forces for 10 digits, 2 directions: top row is left hand, 1-5 is ext, 6-10 is flex
gExp.FScale=gExp.fBarHeight./abs(gExp.maxForce);
gExp.baselineTime=updateGraphics;
command=0;

start(gExp.AI,'continuous')
pause(0.5)
% mvctargetfile='ID2_mvcWNeg.tgt';    % Gili right hand both directions
mvctargetfile='ID2_mvcWNegBothH.tgt';    % Gili Both hands Both directions

mvcdatfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_MVC.mat']); % Dat-file name, following the naming convention
mvcmovfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_MVC_' num2str(gExp.BN,'%2.2d') '.mat']);
mvcRAWfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_MVC_RAW.mat']); % RAW-file name, following the naming convention

% Check if the mvc block exists
if (exist(mvcmovfile,'file'))
    answer=input('MVC block exist! Run anyway? (Y/N)','s');
    if strcmpi(answer,'N')
        return;
    end
end
% Check if target file exists
if (~exist(fullfile(gExp.targetdir, mvctargetfile),'file'))
    fprintf('MVC target file %s does not exist!\n',fullfile(gExp.targetdir, mvctargetfile));
    files = dir(fullfile(gExp.targetdir,'*mvc*.tgt'));
    if (~isempty(files))
        fprintf('Target files available:');
        fprintf('%s\n',files(:).name);
    else
        fprintf('No target file in directory %s.', gExp.targetdir);
    end
    return;
end

fprintf('Loading MVC target file: %s.\n',mvctargetfile);
T=dload(fullfile(gExp.targetdir, mvctargetfile));
if (isempty(T))
    fprintf('Could not find MVC target file');
    files = dir(fullfile(gExp.targetdir,'*.tgt'));
    if (~isempty(files))
        fprintf('Target files available:');
        fprintf('%s\n',files(:).name);
    else
        fprintf('No MVC target file in directory %s.', gExp.targetdir);
    end
    return;
end

fieldN=fieldnames(T);           % Check how many trials
numTrials=length(T.(fieldN{1}));
T.TN=(1:numTrials)';
T.BN=repmat(1,numTrials,1);        %Gili - After MVC we save the MVC RAW, and then delete it from gExp.

gExp.baselineTime=updateGraphics;
gExp.text{2}='';
MOV={};
D=[];
mvcfPos=[];
mvcfNeg=[];
i=1;

while i<=numTrials
    tn=i;
    pause(0.15)
    if gExp.pause  % if user broke out of the exp, back to >EXP environment
        break;
    end
    % press key to run each trial
    FlushEvents('keyDown');
    fprintf('Press space bar to move on\n');
    [~,keycode,~]=KbPressWait;
    if keycode(KbName('space'))
        [d,MOV{tn}]=runTrial(getrow(T,tn), command);
        D=addstruct(D,d,'row','force');
        i=i+1;
        save(mvcmovfile,'MOV'); %Save MOV after each trial, just in case
        
        %compute MVCF off-line
        ftrace=MOV{tn}(:,(T.hand(tn)-1)*5+T.digit(tn)+2);  % find the MOV trace for moving digit
        if T.targetForce(tn)>0
            mvcfPos((T.hand(tn)-1)*5+T.digit(tn),end+1)=prctile(ftrace,95); % take mean of top 5% force
        else
            mvcfNeg((T.hand(tn)-1)*5+T.digit(tn),end+1)=prctile(ftrace,5); % take mean of top 5% force, resulting in [10x1]
        end
    elseif keycode(KbName('q')) || keycode(KbName('Q'))
        gExp.numPointsBlock=0;
        gExp.digitSignal=0;
        gExp.text{1}='';
        gExp.pause=0;
        return;
    end
    
end


% Save the final data, only after all the trials has been done
if tn==numTrials
    D.mvcfPos=max(mvcfPos,[],2); % Take the max of the available trials
    D.mvcfNeg=min(mvcfNeg,[],2); % Take the min of the available trials
    D.mvcf=[reshape(D.mvcfNeg,5,2)',reshape(D.mvcfPos,5,2)'];
    D.date=gExp.DateStart;
    
    RAW.Times=gExp.rawTimes;
    RAW.Data=gExp.rawData;
    RAW.DataNewtons=gExp.rawDataNewtons;
    
    save(mvcdatfile,'-struct','D');
    save(mvcmovfile,'MOV');
    save(mvcRAWfile,'RAW');
end

% Give Feedback on the whole BLOCK
FlushEvents('keyDown');
WaitSecs(0.15);
fprintf('MVC ended\n');
stop(gExp.AI);
flush(gExp.AI);
gExp.rawData=[];
gExp.rawDataNewtons=[];
gExp.rawTimes=[];
RAW=[];


function runDemo                        % Opens screen and runs the program in Demo mode
global gExp;
gExp.SpaceBarRequired=1;        %use a space bar between each trial

gExp.maxForce = repmat(10,2,10);    %Gili adapted to flex and ext
gExp.FScale=gExp.fBarHeight./abs(gExp.maxForce);

%if mvc file exists, then update maxforce accordingly
mvcdatfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_MVC.mat']); % Dat-file name, following the naming convention
if (exist(mvcdatfile,'file'))
    S=load(mvcdatfile);
    gExp.maxForce=gExp.percentMVC*S.mvcf;   % Maximal force level is 80% of MVC
    gExp.maxForce(abs(gExp.maxForce(:,1:5))<1.5)=-1.5;
    gExp.maxForce(logical([zeros(2,5),abs(gExp.maxForce(:,6:10))<1.5]))=1.5;
    gExp.maxForce(gExp.maxForce>30)=30; %Max
    gExp.PRESS_TIME=5;          % time for presenting a go cue
end

gExp.BN=1;       % Get the block number
tgtfilename='Gili_Demo.tgt';         % Get the targetfile name
gExp.PRESS_TIME=5;          % time for presenting a go cue
runBlock(tgtfilename,'demo');

%reset points
gExp.numPointsBlock=0;
gExp.numPoints=0;


%% Congrats! You're Done!