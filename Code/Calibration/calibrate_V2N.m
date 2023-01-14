function varargout=calibrate_V2N(varargin)
% This code is to calibrate the force sensors using specific weights
% Follow the instructions as they appear in the command window.
% 1. Start the code
% 2. type "subj ___". This will be the name of the output file.
% 3. to start with the first finger, type "run 1 cal_regress1.tgt" OR
%    "run_all" which will go through all 10 sensors (for one hand)
% 4. Place the weights carefully, and press space to begin measuring.
% 5. If you mess up a trial, press r or R to redo the trial.
% 6. If you want to quit, press q or Q.


daqreset;  % clearing up USB
clear all;
AssertOpenGL;
global gExp;                    % These are the collection of global variables
if (~isempty(gExp))             % Make sure it was properly closed the last time around
    delete(gExp.AI);
    Screen('CloseAll');
    gExp = [];
end
initExp;                       % initialize the gExp structure with global parameters
initGraphics;
fprintf('Welcome to calibrate box Experiment\n');
isDone=false;
% initBoard;
updateGraphics;

fprintf('Hey! Are you ready to start calibrating?\nFirst thing you need to do is type "subj ___" and then "run 1 cal_regress1.tgt" to run individual blocks.\nIf you want to automatically go through all fingers, type "run_all"\nGood Luck!!\n')

while(~isDone)
    % command='test_get';
    str=input('EXP>','s');
    [command,param]=strtok(str);
    switch (command)
        case 'subj'
            gExp.subj_name=strtok(param);
            fprintf('Which hand will you be calibrating?\n   1=left hand    2=right hand\n')
            gExp.Hand=input('EXP>');
            initBoard;
        case 'update'
            updateGraphics;
        case 'run'
            [bn_str,b]=strtok(param);
            gExp.BN=str2num(bn_str);            % Get the block number
            [tgtfilename,b]=strtok(b);     % Get the targetfile
            runBlock(tgtfilename);
        case 'run_all'
            alltargets={'cal_regress1.tgt','cal_regress2.tgt','cal_regress3.tgt','cal_regress4.tgt','cal_regress5.tgt','cal_regress6.tgt','cal_regress7.tgt','cal_regress8.tgt','cal_regress9.tgt','cal_regress10.tgt'};
            for bn=1:10
                gExp.BN=bn;
                tgtfilename=alltargets{bn};
                runBlock(tgtfilename);
                fprintf('Block has ended! Get ready to calibrate the next sensor\n')
            end
        case {'quit','exit'}
            isDone=true;
        case ''                     % just hit return: do nothing
        otherwise                   % Unknown command: give error message
            fprintf('Unknown command\n');
    end
end
exitExp;



function initTextWindow                 % This function initializes the text window
global gExp;
figure(1);
set(gca,'YLim',[0 10],'Xlim',[0 10],'XTick',[],'YTick',[],'Color',[0.8 0.8 0.8],'Box','on','YDir','reverse');
gExp.textAxis=gca;



function updateTextWindow               % Update the text window (Figure 1)
global gExp;
cla(gExp.textAxis);
text(1,1,sprintf('Subj: %s',gExp.subj_name));



function initExp                        % Set global variables
global gExp;
gExp.code='cfB';                                % Experimental code for data file names
gExp.basedir='C:\Users\gilik\OneDrive - Technion\New Research\CodeG\Individuation\Calibration';     % Directories
gExp.targetdir=fullfile(gExp.basedir, 'target');        % For the target files
gExp.datadir=fullfile(gExp.basedir, 'data');            % For the data files
gExp.subj_name=[];                                      % Name of the subject
gExp.points=0;                                          % Global number of points

gExp.myColor=[0,0,0;...   % 1: Black
    255,255,255;...		  % 2: White
    0,200,0;...   		  % 3: Green
    150,0,0;...			  % 4: Red
    50,50,50;...	      % 5: gray
    30,30,30];            % 6: darkgray

% Initialize the Screen
[gExp.wPtr,gExp.ScreenRect]=Screen('OpenWindow',0,[0 0 0],[1000,10,1400,500]); % [,,width,length]

% define the graphic state
[gExp.ScreenWidth, gExp.ScreenHeight]=Screen('WindowSize', gExp.wPtr);
% Size of instruction boxes
gExp.forcebaseline=800/1024*gExp.ScreenHeight;             % In pixels


gExp.zeroVolts=zeros(1,10);    % These are the force baselines to be set with zeroF

gExp.force=zeros(2,5);
gExp.rectBase=550/1024*gExp.ScreenHeight;                  
gExp.forcebaseline=gExp.rectBase;
gExp.rectWidth=50/1280*gExp.ScreenWidth;
gExp.rectHeight=[105 198 229 198 136;105 198 229 198 136]/1024*gExp.ScreenHeight.*[-1;1];
% gExp.rectXPos=[-60 -150 -210 -270 -330;60 150 210 270 330]/1280*gExp.ScreenWidth;
gExp.rectXPos=[-135 -45 15 75 135;-135 -45 15 75 135]/1280*gExp.ScreenWidth;
% Text display on Screen
gExp.numText=3;
gExp.text{1}='Calibrate box'; % First line of text
gExp.text{2}='';  % Second line of text
gExp.text{3}='';  % Third line of text
gExp.textY=[100 140 170]/1280*gExp.ScreenWidth;       % Y-position 0: Top of the screen 1024: bottom

gExp.T.finger=1;
gExp.T.weight=0;
% switch off the warning of peekdata, number of samples not availbale:
warning('off','daq:peekdata:requestedSamplesNotAvailable');



function initBoard                  % Initialize the response board and USB device
global gExp;
daqreset;               % Reset all DAQ devices


%%
daqreset;               % Reset all DAQ devices
daqs = daqlist('ni'); % check NI-DAQ devices avaliable to matlab


gExp.AI = daq("ni");      % Create a DataAcquisition object
gExp.AI.Rate = 200;       % Sampling rate, [hertz]

if gExp.Hand==1           % Left Hand Setup
    daqID='Dev1';
    gExp.ch = addinput(gExp.AI,daqID,'ai14','Voltage');      %1 Left Thumb, Flexion
    gExp.ch.Name = "Left Thumbs, Flex";
    gExp.ch.TerminalConfig ="SingleEnded";
    gExp.ch = addinput(gExp.AI,daqID,'ai13','Voltage');      %2 Left Index, Flexion
    gExp.ch.Name = "Left Index, Flex";
    gExp.ch.TerminalConfig ="SingleEnded";
    gExp.ch = addinput(gExp.AI,daqID,'ai12','Voltage');      %3 Left Middle, Flexion
    gExp.ch.Name = "Left Middle, Flex";
    gExp.ch.TerminalConfig ="SingleEnded";
    gExp.ch = addinput(gExp.AI,daqID,'ai11','Voltage');      %4 Left Ring, Flexion
    gExp.ch.Name = "Left Ring, Flex";
    gExp.ch.TerminalConfig ="SingleEnded";
    gExp.ch = addinput(gExp.AI,daqID,'ai10','Voltage');      %5 Left Pinky, Flexion
    gExp.ch.Name = "Left Pinky, Flex";
    gExp.ch.TerminalConfig ="SingleEnded";
    gExp.ch = addinput(gExp.AI,daqID,'ai9','Voltage');      %1 Left Thumb, Extension
    gExp.ch.Name = "Left Thumb, Ext";
    gExp.ch.TerminalConfig ="SingleEnded";
    gExp.ch = addinput(gExp.AI,daqID,'ai8','Voltage');      %2 Left Index, Extension
    gExp.ch.Name = "Left Index, Ext";
    gExp.ch.TerminalConfig ="SingleEnded";
    gExp.ch = addinput(gExp.AI,daqID,'ai7','Voltage');      %3 Left Middle, Extension
    gExp.ch.Name = "Left Middle, Ext";
    gExp.ch.TerminalConfig ="SingleEnded";
    gExp.ch = addinput(gExp.AI,daqID,'ai6','Voltage');      %4 Left Ring, Extension
    gExp.ch.Name = "Left Ring, Ext";
    gExp.ch.TerminalConfig ="SingleEnded";
    gExp.ch = addinput(gExp.AI,daqID,'ai5','Voltage');      %5 Left Pinky, Extension
    gExp.ch.Name = "Left Pinky, Ext";
    gExp.ch.TerminalConfig ="SingleEnded";
    
elseif gExp.Hand==2     % Right Hand setup
    daqID='Dev2';
    gExp.ch = addinput(gExp.AI,daqID,'ai4','Voltage');      %1 Right Thumb, Flexion
    gExp.ch.Name = "Right Thumbs, Flex";
    gExp.ch.TerminalConfig ="SingleEnded";
    gExp.ch = addinput(gExp.AI,daqID,'ai3','Voltage');      %2 Right Index, Flexion
    gExp.ch.Name = "Right Index, Flex";
    gExp.ch.TerminalConfig ="SingleEnded";
    gExp.ch = addinput(gExp.AI,daqID,'ai2','Voltage');      %3 Right Middle, Flexion
    gExp.ch.Name = "Right Middle, Flex";
    gExp.ch.TerminalConfig ="SingleEnded";
    gExp.ch = addinput(gExp.AI,daqID,'ai1','Voltage');      %4 Right Ring, Flexion
    gExp.ch.Name = "Right Ring, Flex";
    gExp.ch.TerminalConfig ="SingleEnded";
    gExp.ch = addinput(gExp.AI,daqID,'ai0','Voltage');      %5 Right Pinky, Flexion
    gExp.ch.Name = "Right Pinky, Flex";
    gExp.ch.TerminalConfig ="SingleEnded";
    gExp.ch = addinput(gExp.AI,daqID,'ai9','Voltage');      %1 Right Thumb, Extension
    gExp.ch.Name = "Right Thumb, Ext";
    gExp.ch.TerminalConfig ="SingleEnded";
    gExp.ch = addinput(gExp.AI,daqID,'ai8','Voltage');      %2 Right Index, Extension
    gExp.ch.Name = "Right Index, Ext";
    gExp.ch.TerminalConfig ="SingleEnded";
    gExp.ch = addinput(gExp.AI,daqID,'ai7','Voltage');      %3 Right Middle, Extension
    gExp.ch.Name = "Right Middle, Ext";
    gExp.ch.TerminalConfig ="SingleEnded";
    gExp.ch = addinput(gExp.AI,daqID,'ai6','Voltage');      %4 Right Ring, Extension
    gExp.ch.Name = "Right Ring, Ext";
    gExp.ch.TerminalConfig ="SingleEnded";
    gExp.ch = addinput(gExp.AI,daqID,'ai5','Voltage');      %5 Right Pinky, Extension
    gExp.ch.Name = "Right Pinky, Ext";
    gExp.ch.TerminalConfig ="SingleEnded";
end




function initGraphics                   % Calculate the coordinates for updateGraphics
global gExp;
gExp.LineXY=[];
for h=1:2
    for f=1:5
        gExp.LineXY(:,end+1)=[gExp.rectXPos(h,f)-gExp.rectWidth/2+gExp.ScreenWidth/2;...
            gExp.forcebaseline];
        gExp.LineXY(:,end+1)=[gExp.rectXPos(h,f)+gExp.rectWidth/2+gExp.ScreenWidth/2;...
            gExp.forcebaseline];
    end
end
    
gExp.Box=[];
for h=1:2
    for f=1:5
        gExp.Box(:,end+1)=[gExp.rectXPos(h,f)-gExp.rectWidth/2+gExp.ScreenWidth/2;...
            gExp.rectBase-gExp.rectHeight(h,f);...
            gExp.rectXPos(h,f)+gExp.rectWidth/2+gExp.ScreenWidth/2;...
            gExp.rectBase];     % Boxes
    end
end


function [t]=updateGraphics(T)
global gExp;
if (nargin==0)
    T=gExp.T;       % Take the default trial structure
end
% showBoxes
C=repmat(gExp.myColor(5,:)',1,10);
C(:,T.finger)=gExp.myColor(3,:)'; % Green

Screen('FillRect', gExp.wPtr, C,gExp.Box);

% showLines
Ext=gExp.force';
gExp.LineXY(2,1:2:20)=gExp.forcebaseline-Ext(:);
gExp.LineXY(2,2:2:20)=gExp.forcebaseline-Ext(:);
Screen('DrawLines',gExp.wPtr,gExp.LineXY,2,[255 255 255]');

% Flex=gExp.force';
% gExp.LineXY(2,1:2:20)=gExp.forcebaseline-Ext(:);
% gExp.LineXY(2,2:2:20)=gExp.forcebaseline-Ext(:);
% Screen('DrawLines',gExp.wPtr,gExp.LineXY,2,[255 255 255]');


for i=1:gExp.numText
    if (~isempty(gExp.text{i}))
        % Center text on screen
        bounds=Screen('TextBounds',gExp.wPtr,gExp.text{i});
        Screen('DrawText', gExp.wPtr, gExp.text{i},round((gExp.ScreenWidth-bounds(3))/2),gExp.textY(i),[255 255 255]);
    end
end

[t1,t2,t]=Screen('Flip',gExp.wPtr,0,0,2);       % LCD screen: do not wait for refresh



function runBlock(targetfilename)       % Run a single Block
% Attempt to load the target file
global gExp;
T=dload([gExp.targetdir '/' targetfilename]);
if (isempty(T))
    fprintf('Could not find target file\n');
    return;
end

datfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '.dat']); % Dat-file name
movfile=fullfile(gExp.datadir, [gExp.code '_' gExp.subj_name '_' num2str(gExp.BN) '.mat']);

% Check if the block exists
if (exist(movfile,'file'))
    answer=input('Block exist! Run anyway? (Y/N)\n','s');
    if strcmpi(answer,'N')
        return;
    end
end

D=[];                           % This is the data for the dat file
if (exist(datfile,'file'))
    D=dload(datfile);               % if a data file exists, append the new data to it.
else
    D.BN=[];                        % Otherwise start fresh
    D.TN=[];
end
DR=D;           %initializing struct for repeat offenders


fieldN=fieldnames(T);           % Check how many trials
numTrials=length(T.(fieldN{1}));
T.BN=ones(numTrials,1)*gExp.BN;
T.TN=[1:numTrials]';

% Now run all the trials
for tn=1:numTrials
    gExp.text{1}= sprintf('Finger: %d Weight: %d %d', T.finger(tn), T.weight(tn),tn);
    %     gExp.text{2}= sprintf('Press the Space key if ready');
    
    updateGraphics(getrow(T,tn));
    gExp.force=zeros(2,5);
    
    fprintf('Press the Space key if ready\n');
    [~,keycode,~]=KbPressWait(-1);
    if keycode(KbName('space'))
        updateGraphics(getrow(T,tn));
        fprintf('STARTED MEASURING!!\n');
        if ~gExp.AI.Running
            start(gExp.AI,"continuous")
        end
    elseif keycode(KbName('q')) || keycode(KbName('Q'))
        return;
    elseif keycode(KbName('r')) || keycode(KbName('R')) %if one trial was f'ed up
        fprintf('Press the Space key if ready\n');
        [~,keycode,~]=KbPressWait(-1);
        if keycode(KbName('space'))
            updateGraphics(getrow(T,tn-1));
            fprintf('*REDOING PREVIOUS TRIAL!!* STARTED MEASURING!!\n');
            if ~gExp.AI.Running
                start(gExp.AI,"continuous")
            end
            [d,MOV{tn-1}]=runTrial(getrow(T,tn-1),tn-1);
            updateGraphics(getrow(T,tn-1));
            D=addstruct(DR,d,'row','force');
        end
        fprintf('Press the Space key if ready\n');
        [~,keycode,~]=KbPressWait(-1);
        if keycode(KbName('space'))
            updateGraphics(getrow(T,tn));
            fprintf('STARTED MEASURING!!\n');
            if ~gExp.AI.Running
                start(gExp.AI,"continuous")
            end
        end
    end
    
    [d,MOV{tn}]=runTrial(getrow(T,tn),tn);
    updateGraphics(getrow(T,tn));
    DR=addstruct(DR,d,'row','force');   %in case I need to repeat a row
    D=addstruct(D,d,'row','force');

end
% Save the data
if gExp.AI.Running
    stop(gExp.AI);
end

dsave([gExp.datadir '/' gExp.code '_' gExp.subj_name '.dat'],D);
save(sprintf('%s/%s_%s_%2.2d.mat',gExp.datadir,gExp.code,gExp.subj_name,D.BN(end)),'MOV');
gExp.meanV=[];              %to clear the mean Volts before the next finger


function [T,mov]=runTrial(T,tn)                    % Run a single Trial
global gExp;

if gExp.AI.Running
    stop(gExp.AI);
    flush(gExp.AI);
end
[ddata,dtime]=read(gExp.AI,seconds(2), "OutputFormat", "Matrix");

% Multiply ddata with scaling factor scaleV2N

gExp.meanV(tn,:)= mean(ddata,1);
means=gExp.meanV
T.meanV1= gExp.meanV(tn,1);     %Thumb, Flex
T.meanV2= gExp.meanV(tn,2);     %index, flex
T.meanV3= gExp.meanV(tn,3);
T.meanV4= gExp.meanV(tn,4);
T.meanV5= gExp.meanV(tn,5);     %Pinky, Flex
T.meanV6= gExp.meanV(tn,6);     %Thumb, ext
T.meanV7= gExp.meanV(tn,7);
T.meanV8= gExp.meanV(tn,8);
T.meanV9= gExp.meanV(tn,9);
T.meanV10=gExp.meanV(tn,10);   %Pinky, Ext
gExp.force=150*reshape(mean(ddata,1),5,2)'.*[-1 ;1];        %so flexion forces are negative
mov=[dtime ddata];     % Makes movement file
fprintf("now, was that so difficult?\n \n")


function exitExp
global gExp;
delete(gExp.AI);
Screen('Close',gExp.wPtr);
clear('gExp');


