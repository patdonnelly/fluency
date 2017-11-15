function [config, result] = RunStairs(config, result, temp)

config.stair.stepSize = [.06 .03 .02];
config.stair.endReversal = 7;
config.stair.initStimDur = .4;
config.stair.trial = 1;
config.stair.maxTrial = 40;

for j = 1: config.stair.maxTrial
    if floor((j-1)/(config.stair.maxTrial/2)) == 0
        config.stair.list{j} = config.word.list{200+j};
        config.stair.wordNonword(j) = 1;
    else
        config.stair.list{j} = config.nonword.list{200+j};
        config.stair.wordNonword(j) = 0;
    end
end
config.stair.wordOrder = Shuffle(1:config.stair.maxTrial);

temp.reversal = 0;
temp.correct = 0;
% config.stair.stimDur(1) = config.stair.initStimDur;

str{1} = 'Practice session';
str{2} = 'On each trial you will see a stream of letters.';
str{3} = 'Either a real word or a make-up word is inserted';
str{4} = 'within the letter stream.';
str{5} = 'Sometimes the stream is slow, but sometimes the stream is so fast.';
str{6} = 'It is okay to guess but please do your best.';
str{7} = 'Press "w" if you think you saw a real word.';
str{8} = 'Press "p" if you think you saw a make-up word.';
str{9} = 'Press space key when you are ready.';
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

while temp.reversal < config.stair.endReversal && config.stair.trial <= config.stair.maxTrial
    if config.stair.trial <= 10
        config.stair.stimDur(config.stair.trial) = .5;
    elseif config.stair.trial == 11
        config.stair.stimDur(config.stair.trial) = config.stair.initStimDur;
    end
    for i = 1: config.exp.nWordsInStream
        temp.noiseOrder = Shuffle(1:length(temp.noise));
        config.stair.stream{i,config.stair.trial} = temp.noise(temp.noiseOrder(1:config.exp.wordLength));
    end
    temp.targetLoc = Shuffle(config.exp.targetLocRange);
    config.stair.targetLoc(config.stair.trial) = temp.targetLoc(1);
    
    for i = 1: config.exp.wordLength
        Screen('DrawText', config.display.wPtr, config.exp.startEnd(i), config.xLoc(i), config.display.cy, [0 0 0]);
    end
    Screen('Flip', config.display.wPtr);
    
    if config.stair.trial ==1 
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
    if config.stair.stimDur(config.stair.trial) <= 0
        config.stair.stimDur(config.stair.trial) = .05;
    end
    config.stair.stimFrames(config.stair.trial) = round(config.stair.stimDur(config.stair.trial) * config.display.frameRate);
    
    % Display word string
    for iWord = 1: config.exp.nWordsInStream
        if iWord == config.stair.targetLoc(config.stair.trial)
            config.stair.stream{iWord,config.stair.trial} = config.stair.list{config.stair.wordOrder(config.stair.trial)};
        end
        
        for iFrame = 1: config.stair.stimFrames(config.stair.trial)
            for i = 1: config.exp.wordLength
                Screen('DrawText', config.display.wPtr, config.stair.stream{iWord,config.stair.trial}(i), config.xLoc(i), config.display.cy, [0 0 0]);
            end
            Screen('Flip', config.display.wPtr);
        end
        
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
            end
        end
    end
    
    result.stair.intensity(config.stair.trial) = config.stair.stimDur(config.stair.trial);
    result.stair.response(config.stair.trial) = response == config.stair.wordNonword(config.stair.wordOrder(config.stair.trial));
    
    if result.stair.response(config.stair.trial)
        config.stair.trial = config.stair.trial + 1;
        for i = 1: config.exp.wordLength
            Screen('DrawText', config.display.wPtr, config.exp.startEnd(i), config.xLoc(i), config.display.cy, [0 200 0]);
        end
        Screen('Flip', config.display.wPtr);
        if config.stair.trial > 10
            temp.correct = temp.correct + 1;
            if temp.correct == 2
                switch temp.reversal
                    case 0
                        config.stair.stimDur(config.stair.trial) = config.stair.stimDur(config.stair.trial-1) - config.stair.stepSize(1);
                    case {1,2}
                        config.stair.stimDur(config.stair.trial) = config.stair.stimDur(config.stair.trial-1) - config.stair.stepSize(2);
                    otherwise
                        config.stair.stimDur(config.stair.trial) = config.stair.stimDur(config.stair.trial-1) - config.stair.stepSize(3);
                end
                temp.correct = 0;
            else
                config.stair.stimDur(config.stair.trial) = config.stair.stimDur(config.stair.trial-1);
            end
        end
    else
        config.stair.trial = config.stair.trial + 1;
        temp.correct = 0;
        for i = 1: config.exp.wordLength
            Screen('DrawText', config.display.wPtr, config.exp.startEnd(i), config.xLoc(i), config.display.cy, [255 0 0]);
        end
        Screen('Flip', config.display.wPtr);
        if config.stair.trial > 10
            switch temp.reversal
                case {0,1}
                    config.stair.stimDur(config.stair.trial) = config.stair.stimDur(config.stair.trial-1) + config.stair.stepSize(1);
                case {2,3}
                    config.stair.stimDur(config.stair.trial) = config.stair.stimDur(config.stair.trial-1) + config.stair.stepSize(2);
                otherwise
                    config.stair.stimDur(config.stair.trial) = config.stair.stimDur(config.stair.trial-1) + config.stair.stepSize(3);
            end
        end
    end
    
    if config.stair.trial > 13
        temp.diff = diff(config.stair.stimDur);
        if sign(temp.diff(end))*sign(temp.diff(end-1)) < 0
            temp.reversal = temp.reversal + 1;
            result.stair.reversalIntensity(temp.reversal) = config.stair.stimDur(config.stair.trial-1);
        elseif sign(temp.diff(end)-temp.diff(end-1))*sign(temp.diff(end-2)) < 0
            temp.reversal = temp.reversal + 1;
            result.stair.reversalIntensity(temp.reversal) = config.stair.stimDur(config.stair.trial-1);
        end
    end
    
    WaitSecs(.5);
end

h = figure(1); clf;
plot(result.stair.intensity);

xlabel('Trial', 'FontSize', 18);
ylabel('Stim Dur (s)', 'FontSize', 18);
title(sprintf('%s',config.fn));

cd('result');
print(h,'-dpdf',sprintf('%s-staircase',config.fn));
cd(config.mainDir);
close(h);
