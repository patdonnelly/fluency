%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear variables

%% Load word lists

load('WordList.mat');

% Let's remove any word including 'Q'
removeID.word = zeros(300,1);
removeID.nonword = zeros(300,1);
for i = 1: length(config.word.list)
    findQ.word = zeros(5,1);
    findQ.nonword = zeros(5,1);
    for j = 1: 5
        findQ.word(j) = strcmp('Q',config.word.list{i}(j));
        findQ.nonword(j) = strcmp('Q',config.nonword.list{i}(j));
    end
    if sum(findQ.word) > 0
        removeID.word(i) = 1;
    end
    if sum(findQ.nonword) > 0
        removeID.nonword(i) = 1;
    end
end
config.word.list(removeID.word==1) = [];
config.nonword.list(removeID.nonword==1) = [];

config.kb = InitKeyboard;

config.mainDir = pwd;

config.exp.randSeed = RandStream('mt19937ar','Seed',sum(100*clock));
RandStream.setGlobalStream(config.exp.randSeed);

%% Set up experiment
config.subjectID = input('Enter subject ID: ', 's');
config.order = input('Enter 1 or 0: ');

RestrictKeysForKbCheck([config.kb.wKey config.kb.pKey config.kb.spaceKey config.kb.escKey]);

config.fn = sprintf('%s-%s',config.subjectID,datestr(now,'yyyymmdd-HHMM'));

config.exp.practice = 1;

config.exp.nCategories = 2; % word vs. non-word

config.exp.nIntensities = 5;
config.exp.nReps = 30;

config.exp.nTrials = config.exp.nIntensities * config.exp.nReps; % Total 150 trials
config.exp.nSpacings = 2; % short vs. long

config.exp.nBlocks = 6; % 50 * 6 = 300 trials

% Let's set the list for word vs. nonword here
for i = 1: config.exp.nSpacings
    for j = 1: config.exp.nTrials
        if floor((j-1)/(config.exp.nTrials/2)) == 0
            config.exp.list{j,i} = config.word.list{j+(i-1)*(config.exp.nTrials/2)};
            config.exp.wordNonword(j,i) = 1;
        else
            config.exp.list{j,i} = config.nonword.list{j+(i-1)*(config.exp.nTrials/2)-config.exp.nTrials/2};
            config.exp.wordNonword(j,i) = 0;
        end
    end
    config.exp.wordOrder(:,i) = Shuffle(1:config.exp.nTrials);
end

if config.order
    config.exp.blockOrder{1} = config.exp.wordOrder(1:50,1);
    config.exp.blockOrder{2} = config.exp.wordOrder(1:50,2);
    config.exp.blockOrder{3} = config.exp.wordOrder(51:100,1);
    config.exp.blockOrder{4} = config.exp.wordOrder(51:100,2);
    config.exp.blockOrder{5} = config.exp.wordOrder(101:150,1);
    config.exp.blockOrder{6} = config.exp.wordOrder(101:150,2);
    config.exp.spacing = [1 2 1 2 1 2];
else
    config.exp.blockOrder{1} = config.exp.wordOrder(1:50,2);
    config.exp.blockOrder{2} = config.exp.wordOrder(1:50,1);
    config.exp.blockOrder{3} = config.exp.wordOrder(51:100,2);
    config.exp.blockOrder{4} = config.exp.wordOrder(51:100,1);
    config.exp.blockOrder{5} = config.exp.wordOrder(101:150,2);
    config.exp.blockOrder{6} = config.exp.wordOrder(101:150,1);
    config.exp.spacing = [2 1 2 1 2 1];
end

config.exp.wordLength = length(config.word.list{1});

% Let's set the intensity levels here
for i = 1: config.exp.nBlocks
    for j = 1: 10
        config.exp.randOrder{i}(config.exp.nIntensities*(j-1)+1:j*config.exp.nIntensities) = Shuffle(1:config.exp.nIntensities)';
    end
end

config.exp.startEnd = 'XXXXX';

config.exp.nWordsInStream = 10;
config.exp.targetLocRange = 3:8;

%% Set up display
config.display.screenNum = max(Screen('Screens'));
config.display.bkColor = [128 128 128];
config.display.dist = 56;
config.display.width = 53;
config.display.widthInVisualAngle = 2*atan(config.display.width/2/config.display.dist) * 180/pi;

config.display = OpenWindow(config.display);

HideCursor(config.display.wPtr);
ListenChar(2);

%% 
temp.spacing = 1;

[oldFontName,oldFontNumber,oldTextStyle] = Screen('TextFont', config.display.wPtr, 'Courier');
oldTextSize = Screen('TextSize', config.display.wPtr, 30);

temp.noise = 'BCDFGHJKLMNPRSTVWZ'; % Remove a, e, i, o, u, y, q, x
for i = 1: length(temp.noise)
    result.textBounds(i,:) = Screen('TextBounds',config.display.wPtr,temp.noise(i));
end

config.exp.maxWidth = round(max(result.textBounds(:,3)));
config.exp.wordWidth = temp.spacing * config.exp.maxWidth;

config.xLoc(1) =  config.display.cx - 2*config.exp.wordWidth - config.exp.wordWidth/2;
for i = 1: config.exp.wordLength-1
    config.xLoc(i+1) = config.xLoc(i) + config.exp.wordWidth; 
end

%% 2-down 1-up staircase to get an initial 75% performance threshold
[config, result] = RunStairs(config, result, temp);

result.thresh = mean(result.stair.intensity(end-4:end));
temp.min = max(.05, result.thresh - .07);
temp.max = result.thresh + .2;

str{1} = 'Now the practice is done.';
str{2} = 'You will do 6 blocks and each block has 50 trials.';
str{3} = 'There is 3 minute break between blocks.';
str{4} = 'Again, sometimes the stream is slow, but sometimes the stream is so fast.';
str{5} = 'It is okay to guess but please do your best.';
str{6} = 'Press "w" if you think you saw a real word.';
str{7} = 'Press "p" if you think you saw a make-up word.';
str{8} = 'Press space key when you are ready.';
for i = 1: length(str)
    strBounds{i} = Screen('TextBounds',config.display.wPtr,str{i});
    Screen('DrawText', config.display.wPtr, str{i}, config.display.cx-strBounds{i}(3)/2, config.display.cy-200+i*50, [0 0 0]);
end
Screen('Flip', config.display.wPtr);
% Wait to start
isResponded = 0;
FlushEvents('keyDown');
while ~isResponded
    [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
    if keyIsDown
        if keyCode(config.kb.spaceKey)
            isResponded = 1;
        end
    end
end

%% Real deal
temp.stimDur = linspace(log(temp.min), log(temp.max), 5);
config.exp.stimDur = exp(temp.stimDur);

result.intensity = NaN*ones(150,2);
result.response = NaN*ones(150,2);

for iBlock = 1: config.exp.nBlocks
    if config.exp.spacing(iBlock) == 1
        config.exp.wordWidth = 1 * config.exp.maxWidth;
    else
        config.exp.wordWidth = 1.5 * config.exp.maxWidth;
    end
    config.xLoc(1) =  config.display.cx - 2*config.exp.wordWidth - config.exp.wordWidth/2;
    for i = 1: config.exp.wordLength-1
        config.xLoc(i+1) = config.xLoc(i) + config.exp.wordWidth;
    end

    for iTrial = 1: length(config.exp.blockOrder{iBlock})
        temp.targetLoc = Shuffle(config.exp.targetLocRange);
        config.exp.targetLoc(iTrial,iBlock) = temp.targetLoc(1);
        for i = 1: config.exp.nWordsInStream
            if i == config.exp.targetLoc(iTrial,iBlock)
                config.exp.stream{i,iTrial,iBlock} = config.exp.list{config.exp.wordOrder(config.exp.blockOrder{iBlock}(iTrial),config.exp.spacing(iBlock)),config.exp.spacing(iBlock)};
            else
                temp.noiseOrder = Shuffle(1:length(temp.noise));
                config.exp.stream{i,iTrial,iBlock} = temp.noise(temp.noiseOrder(1:config.exp.wordLength));
            end
        end
        
        for i = 2: config.exp.nWordsInStream
            for j = 1: config.exp.wordLength
                while (strcmp(config.exp.stream{i,iTrial,iBlock}(j), config.exp.stream{i-1,iTrial,iBlock}(j))) && (i ~= config.exp.targetLoc(iTrial,iBlock))
                    config.exp.stream{i,iTrial,iBlock} = Shuffle(config.exp.stream{i,iTrial,iBlock});
                end
            end
        end
        
        for i = 1: config.exp.wordLength
            Screen('DrawText', config.display.wPtr, config.exp.startEnd(i), config.xLoc(i), config.display.cy, [0 0 0]);
        end
        Screen('Flip', config.display.wPtr);
        
        if iTrial == 1
            WaitSecs(1);
        end
        % Wait to start
        isResponded = 0;
        FlushEvents('keyDown');
        while ~isResponded
            [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
            if keyIsDown
                if keyCode(config.kb.spaceKey)
                    isResponded = 1;
                end
            end
        end

        % Get the frame number
        config.exp.stimFrames(iTrial,iBlock) = round(config.exp.stimDur(config.exp.randOrder{iBlock}(iTrial)) * config.display.frameRate);
        
        t = GetSecs;
        for iWord = 1: config.exp.nWordsInStream
            for iFrame = 1: config.exp.stimFrames(iTrial,iBlock)
                for i = 1: config.exp.wordLength
                    Screen('DrawText', config.display.wPtr, config.exp.stream{iWord,iTrial,iBlock}(i), round(config.xLoc(i)), config.display.cy, [0 0 0]);
                end
                Screen('Flip', config.display.wPtr);
            end
            result.timing(iWord,iTrial,iBlock) = GetSecs -t;
        end

        for i = 1: config.exp.wordLength
            Screen('DrawText', config.display.wPtr, config.exp.startEnd(i), config.xLoc(i), config.display.cy, [0 0 0]);
        end
        Screen('Flip', config.display.wPtr);
        
        isResponded = 0;
        FlushEvents('keyDown');
        while ~isResponded
            [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
            if keyIsDown
                if keyCode(config.kb.wKey)
                    isResponded = 1;
                    response = 1;
                elseif keyCode(config.kb.pKey)
                    isResponded = 1;
                    response = 0;
                elseif keyCode(config.kb.escKey)
                    Screen('CloseAll');
                    ShowCursor;
                    ListenChar(1);
                    RestrictKeysForKbCheck([]);
                    break;
                end
            end
        end

        result.intensity(config.exp.blockOrder{iBlock}(iTrial),config.exp.spacing(iBlock)) = config.exp.stimDur(config.exp.randOrder{iBlock}(iTrial));
        result.response(config.exp.blockOrder{iBlock}(iTrial),config.exp.spacing(iBlock)) = response == config.exp.wordNonword(config.exp.wordOrder(config.exp.blockOrder{iBlock}(iTrial),config.exp.spacing(iBlock)),config.exp.spacing(iBlock));

        if result.response(config.exp.blockOrder{iBlock}(iTrial),config.exp.spacing(iBlock))
            for i = 1: config.exp.wordLength
                Screen('DrawText', config.display.wPtr, config.exp.startEnd(i), config.xLoc(i), config.display.cy, [0 200 0]);
            end
            Screen('Flip', config.display.wPtr);
        else
            for i = 1: config.exp.wordLength
                Screen('DrawText', config.display.wPtr, config.exp.startEnd(i), config.xLoc(i), config.display.cy, [255 0 0]);
            end
            Screen('Flip', config.display.wPtr);
        end
        WaitSecs(.5);
    end
    
    if iBlock ~= config.exp.nBlocks
        str2 = 'Let''s take 1 minute break.';
        str3 = sprintf('Finished %d/6 block',iBlock);
        t1 = GetSecs;
        while GetSecs - t1 < 1 * 60
            str1 = sprintf('Continue in %02d secs...', 61-mod(round(GetSecs-t1),60));
            strBounds3 = Screen('TextBounds',config.display.wPtr,str3);
            strBounds2 = Screen('TextBounds',config.display.wPtr,str2);
            strBounds1 = Screen('TextBounds',config.display.wPtr,str1);
            Screen('DrawText', config.display.wPtr, str3, config.display.cx-strBounds3(3)/2, config.display.cy-50, [0 0 0]);
            Screen('DrawText', config.display.wPtr, str2, config.display.cx-strBounds2(3)/2, config.display.cy, [0 0 0]);
            Screen('DrawText', config.display.wPtr, str1, config.display.cx-strBounds1(3)/2, config.display.cy+50, [0 0 0]);
            Screen('Flip', config.display.wPtr);
        end
        
        Screen('DrawText', config.display.wPtr, str{8}, config.display.cx-strBounds{8}(3)/2, config.display.cy-200, [0 0 0]);
        Screen('Flip', config.display.wPtr);

        isResponded = 0;
        FlushEvents('keyDown');
        while ~isResponded
            [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
            if keyIsDown
                if keyCode(config.kb.spaceKey)
                    isResponded = 1;
                end
            end
        end
        WaitSecs(.5);
    end
end

cd('data');
save(strcat(config.fn,'.mat'),'config','result');
cd(config.mainDir);

str3 = 'Thank you!';
strBounds = Screen('TextBounds',config.display.wPtr,str3);
Screen('DrawText', config.display.wPtr, str3, config.display.cx-strBounds(3)/2, config.display.cy, [0 0 0]);
Screen('Flip', config.display.wPtr);
WaitSecs(1);

Screen('CloseAll');
ShowCursor;
ListenChar(1);
RestrictKeysForKbCheck([]);

%% Fit psychometric function
pInit.t = result.thresh;
pInit.b = .5;
pInit.shutup = 1;
freeList ={'t','b'};

h = figure(1); clf; hold on;
for iSpacing = 1: 2
    results.intensity = result.intensity(:,iSpacing);
    results.response = result.response(:,iSpacing);
    
    % Call the 'fit' function
    [pBest,logLikelihoodBest] = fit('fitPsychometricFunction',pInit,freeList,results,'Weibull');

    intensities = unique(results.intensity(~isnan(results.intensity)));

    nCorrect = zeros(1,length(intensities));
    nTrials = zeros(1,length(intensities));

    for i=1:length(intensities)
        id = results.intensity == intensities(i) & isreal(results.response);
        nTrials(i) = sum(id);
        nCorrect(i) = sum(results.response(id));
    end

    pCorrect = nCorrect./nTrials;

    %loop through each intensity so each data point can have it's own size.
    for i=1:length(intensities);
        sz = 15; %nTrials(i)+2;
        if iSpacing == 1
            plot(intensities(i),100*pCorrect(i),'o','MarkerFaceColor','r','MarkerEdgeColor','k','MarkerSize',sz);
        else
            plot(intensities(i),100*pCorrect(i),'o','MarkerFaceColor','b','MarkerEdgeColor','k','MarkerSize',sz);
        end
    end

    %plot the parametric psychometric function
    % x = exp(linspace(log(min(results.intensity)),log(max(results.intensity)),101));
    x = linspace(min(results.intensity),max(results.intensity),101);
    y = Weibull(pBest,x);
    
    if iSpacing == 1
        plot(x,100*y,'r-','LineWidth',2);
    else
        plot(x,100*y,'b-','LineWidth',2);
    end

    %     plot([pBest.u,pBest.u],[50,0],'k--','LineWidth',2)

    %     plot([-1,pBest.u,pBest.u],[50,50,0],'k--','LineWidth',2)
    %     plot([mean(result.thresh)+1 mean(result.thresh)+1],[0 50], 'r--', 'LineWidth',2);

    set(gca,'YLim',[40,100]);
    set(gca,'XLim',[.05 .3])

    xxx = get(gca,'XLim');
    
    if iSpacing == 1
        plot([xxx(1) pBest.t pBest.t],[75 75 40],'r--');
    else
        plot([xxx(1) pBest.t pBest.t],[75 75 40],'b--');
    end

    hhh = get(gca,'XTick');

    set(gca,'XTickLabel',hhh);

    % logx2raw

    xlabel('Stim Duration (s)', 'FontSize', 18);
    ylabel('Percent correct (%)', 'FontSize', 18);
    title(sprintf('%s',config.fn));
end
cd('result');
print(h,'-dpdf',sprintf('%s',config.fn));
cd(config.mainDir);

%% Sanity check
for j = 1: 6
    for i = 1: 50
        a(i,j) = strcmp(config.exp.stream{config.exp.targetLoc(i,j),i,j},'HOTEL');
    end
end

sum(a)
