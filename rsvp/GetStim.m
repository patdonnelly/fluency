function GetStim
%%
clear variables

temp.word = readtable('Word.csv','delimiter','\t');
temp.nonword = readtable('Non-word.csv','delimiter','\t');

lowerBound = 70;
[temp.a, temp.id] = sort(temp.word.N3_F);

hack.word.list = upper(temp.word.STRING(temp.id(56:end)));
hack.nonword.list = upper(temp.nonword.STRING(~temp.nonword.Remove & temp.nonword.N3_F > lowerBound));
length(hack.nonword.list)

hack.word.n = length(hack.word.list);
hack.nonword.n = length(hack.nonword.list);

hack.word.N3_F = temp.word.N3_F(temp.id(56:end));
hack.nonword.N3_F = temp.nonword.N3_F(~temp.nonword.Remove & temp.nonword.N3_F > lowerBound);

[min(hack.word.N3_F) max(hack.word.N3_F); min(hack.nonword.N3_F) max(hack.nonword.N3_F)]
[median(hack.word.N3_F) median(hack.nonword.N3_F)]

for kk = 1:20
   temp.xxx(kk,:) = Shuffle(1:hack.nonword.n);
   temp.ttt(kk) = median(hack.nonword.N3_F(temp.xxx(kk,1:hack.word.n)));
end

config.word.list = hack.word.list;
config.nonword.list = hack.nonword.list(temp.xxx(1,1:hack.word.n));

config.word.n = hack.word.n;
config.nonword.n = length(config.nonword.list);

config.word.N3Freq = median(hack.word.N3_F);
config.nonword.N3Freq = median(hack.nonword.N3_F(temp.xxx(1,1:hack.word.n)));

edges = linspace(lowerBound,max(temp.word.N3_F),40);
figure(1);clf;
subplot(2,1,1);
hist(hack.word.N3_F,edges);
title('Word');
subplot(2,1,2);
hist(hack.nonword.N3_F(temp.xxx(16,1:hack.word.n)),edges);
title('Non-word');

save('WordList.mat','config');

%%
hFig2 = figure(2);
global trial rejectId
trial = 1;
rejectId = NaN*ones(hack.nonword.n,1);
while trial <= hack.nonword.n
    figure(hFig2);
     
    text(.4,.5,hack.nonword.list{trial},'FontSize',18);
    
    set(gca,'XTick',[],'XTickLabel',[]);
    set(gca,'YTick',[],'YTickLabel',[]);
    axis off;
    
    btn1 = uicontrol('Style', 'pushbutton', 'String', 'Reject',...
        'Position', [200 10 50 30],...
        'Callback', {@reject,trial,hFig2});
    
    btn2 = uicontrol('Style', 'pushbutton', 'String', 'Next',...
        'Position', [350 10 50 30],...
        'Callback', {@next,trial,hFig2});
    
    btn2 = uicontrol('Style', 'pushbutton', 'String', 'Prev',...
        'Position', [50 10 50 30],...
        'Callback', {@previous,trial,hFig2});
    drawnow;
    WaitSecs(.3);
end
close(hFig2);

config.word.list = hack.word.list;
config.nonword.list = hack.nonword.list{rejectId ~= 1};

save('WordList.mat','config');

end % function end

function reject(hObj, event, trial, hFig2)
disp('hahaha')

global rejectId trial
rejectId(trial) = 1;
trial = trial + 1;
clf(hFig2);
end

function previous(hObj, event, trial, hFig2)
% disp('hahaha')
% global isPrevious
% isPrevious = 1;
global trial
trial = trial -1;
clf(hFig2);
end

function next(hObj, event, trial, hFig2)
disp('hohoho')
global trial
trial = trial + 1;
clf(hFig2);
end