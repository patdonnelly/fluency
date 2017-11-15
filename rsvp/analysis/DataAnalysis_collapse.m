%%
%
%
%
clear variables;

parentDir = '~/git/psychophys/rsvp';
analDir = 'analysis';
dataDir = 'data';
resultDir = 'result';
ccolor = cbrewer('qual','Set1',9);

%%
subjectList = {'502_HW','503_AH','504_LM','509_MK','512_EG', ...
    '513_EO','514_LR','515_AB','516_TT','517_CT','518_ML','519_MF','520_AA','521_GP','522_JH','523_SK', ...
    '524_AG','527_RF','528_DO','529_NG','530_IH'}; % '602_JK'

badSubjects = {'602_JK','526_PM','511_RC','510_DT','508_RC','507_JP'};

for i = 1: length(subjectList)
    subjectNumber{i} = subjectList{i}(1:3);
end

%% Read reading scores
cd('~/git/psychophys/crowding/Result');

T = readtable('NLR_Scores.csv','Delimiter','\t');

wj.brs = NaN * ones(length(subjectList),1);
wj.wa = NaN * ones(length(subjectList),1);
wj.lwid = NaN * ones(length(subjectList),1);
twre.index = NaN * ones(length(subjectList),1);
twre.pde = NaN * ones(length(subjectList),1);
twre.swe = NaN * ones(length(subjectList),1);

for iSubject = 1: length(subjectList)
    wj.brs(iSubject) = nanmean(T.WJ_BRS(strcmp(T.Subject,subjectList{iSubject})),1);
    wj.wa(iSubject) = nanmean(T.WJ_WA_SS(strcmp(T.Subject,subjectList{iSubject})),1);
    wj.lwid(iSubject) = nanmean(T.WJ_LWID_SS(strcmp(T.Subject,subjectList{iSubject})),1);
    twre.index(iSubject) = nanmean(T.TWRE_INDEX(strcmp(T.Subject,subjectList{iSubject})),1);
    twre.pde(iSubject) = nanmean(T.TWRE_PDE_SS(strcmp(T.Subject,subjectList{iSubject})),1);
    twre.swe(iSubject) = nanmean(T.TWRE_SWE_SS(strcmp(T.Subject,subjectList{iSubject})),1);
end

%%
cd(sprintf('%s/%s',parentDir,dataDir));
out.thresh = NaN * ones(length(subjectList),1);
out.slope = NaN * ones(length(subjectList),1);

for iSubject = 1: length(subjectList)
    nogo = 0;
%     for iii = 1: length(badSubjects)
%         if strcmp(badSubjects{iii},subjectList{iSubject})
%             nogo = 1;
%         end
%     end
    if ~nogo
        d = dir(sprintf('%s*',subjectList{iSubject}));

        load(d(1).name);

        cd(parentDir);

        pInit.t = result.thresh;
        pInit.b = .5;
        pInit.shutup = 1;
        freeList ={'t','b'};

        h(iSubject) = figure(iSubject); clf; hold on;

        results.intensity = result.intensity(:);
        results.response = result.response(:);
        
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
        
        %plot the parametric psychometric function
        % x = exp(linspace(log(min(results.intensity)),log(max(results.intensity)),101));
        x = linspace(.05,max(results.intensity),101);
        y = Weibull(pBest,x);
        
        plot(x,100*y,'-','Color',[0 0 0],'LineWidth',2);
        
        %loop through each intensity so each data point can have it's own size.
        for i=1:length(intensities);
            sz = 9; %nTrials(i)+2;
            plot(intensities(i),100*pCorrect(i),'o','MarkerFaceColor',ccolor(1,:),'MarkerEdgeColor','k','MarkerSize',sz);
        end
        
        set(gca,'XLim',[-.02 .5],'YLim',[38,100],'TickDir','out','LineWidth',1,'FontName','Arial','FontSize',12);

        xxx = get(gca,'XLim');

        plot([xxx(1) pBest.t pBest.t],[75 75 40],'--','Color',ccolor(2,:),'LineWidth',1);
        
        hhh = get(gca,'XTick');
        
        set(gca,'XTickLabel',hhh);
        
        axis square
        % logx2raw
        
        xlabel('Stimulus Duration (s)','FontName','Arial','FontSize',16);
        ylabel('Percent correct (%)','FontName','Arial','FontSize',16);
%         title(sprintf('%s',config.fn));
        if pBest.t > min(x)
            out.thresh(iSubject) = pBest.t;
        end
        out.slope(iSubject) = pBest.b;
        out.pc(iSubject,:) = pCorrect;

    end
    cd(sprintf('%s/%s',parentDir,dataDir));
end

% out.thresh(6) = NaN;
% out.thresh(7) = NaN;
% out.slope(6) = NaN;
% out.slope(7) = NaN;

% currDir = pwd;
% cd('~/Dropbox/Publish/MSVisit')
% filename = 'Psychometric1.svg';
% print(h(1),'-dsvg',filename,'-painters','-r300');
% filename = 'Psychometric2.svg';
% print(h(18),'-dsvg',filename,'-painters','-r300');
% cd(currDir)


%%
figure(101); clf;

temp.id = find(~isnan(out.thresh));
k = 1;
for i = 1:length(temp.id)
    realS(k,:) = subjectList{temp.id(i)};
    k = k + 1;
end

subplot(2,3,1); hold on;
% [B,BINT,R,RINT,STATS] = regress(Y,X) R square, F, p, an estimate of the error variance
[B2,BINT2,R2,RINT2,STATS2] = regress(wj.brs(~isnan(out.thresh)),[ones(sum(~isnan(out.thresh)),1) out.thresh(~isnan(out.thresh))]);

x = linspace(min(out.thresh),max(out.thresh),101);
yHat = B2(1) + B2(2)*x;
plot(x,yHat,'-','Color',[0 0 0],'LineWidth',2);
plot(out.thresh(~isnan(out.thresh)),wj.brs(~isnan(out.thresh)),'o','MarkerFaceColor',ccolor(4,:),'MarkerEdgeColor',[0 0 0],'MarkerSize',9);
text(out.thresh(~isnan(out.thresh))+.01,wj.brs(~isnan(out.thresh))+.1,realS)
set(gca,'XLim',[.05 .35],'YLim',[50 130],'XTick',.05:.05:.35,'XTickLabel',{[],'0.1',[],'0.2',[],'0.3',[]},'YTick',50:20:130,'TickDir','out','LineWidth',1,'FontName','Arial','FontSize',12)
xlabel('Threshold (s)','FontName','Arial','FontSize',16)
ylabel('Reading score','FontName','Arial','FontSize',16)
text(.14,55,sprintf('r=%0.2f,p=%0.2f',sqrt(STATS2(1)),STATS2(3)),'FontName','Arial','FontSize',12)
title('Basic reading skill','FontName','Arial','FontSize',16)

subplot(2,3,2); hold on;
[B2,BINT2,R2,RINT2,STATS2] = regress(wj.lwid(~isnan(out.thresh)),[ones(sum(~isnan(out.thresh)),1) out.thresh(~isnan(out.thresh))]);

x = linspace(min(out.thresh),max(out.thresh),101);
yHat = B2(1) + B2(2)*x;
plot(x,yHat,'-','Color',[0 0 0],'LineWidth',2);
plot(out.thresh(~isnan(out.thresh)),wj.lwid(~isnan(out.thresh)),'o','MarkerFaceColor',ccolor(4,:),'MarkerEdgeColor',[0 0 0],'MarkerSize',9);
% text(out.thresh(~isnan(out.thresh))+.01,wj.lwid(~isnan(out.thresh))+.1,realS)
set(gca,'XLim',[.05 .35],'YLim',[50 130],'XTick',.05:.05:.35,'XTickLabel',{[],'0.1',[],'0.2',[],'0.3',[]},'YTick',50:20:130,'TickDir','out','LineWidth',1,'FontName','Arial','FontSize',12)
xlabel('Threshold (s)','FontName','Arial','FontSize',16)
ylabel('Reading score','FontName','Arial','FontSize',16)
text(.14,55,sprintf('r=%0.2f,p=%0.2f',sqrt(STATS2(1)),STATS2(3)),'FontName','Arial','FontSize',12)
title('Word ID','FontName','Arial','FontSize',16)

subplot(2,3,3); hold on;
[B2,BINT2,R2,RINT2,STATS2] = regress(wj.wa(~isnan(out.thresh)),[ones(sum(~isnan(out.thresh)),1) out.thresh(~isnan(out.thresh))]);

x = linspace(min(out.thresh),max(out.thresh),101);
yHat = B2(1) + B2(2)*x;
plot(x,yHat,'-','Color',[0 0 0],'LineWidth',2);
plot(out.thresh(~isnan(out.thresh)),wj.wa(~isnan(out.thresh)),'o','MarkerFaceColor',ccolor(4,:),'MarkerEdgeColor',[0 0 0],'MarkerSize',9);
% text(out.thresh(~isnan(out.thresh))+.01,wj.wa(~isnan(out.thresh))+.1,realS)
set(gca,'XLim',[.05 .35],'YLim',[50 130],'XTick',.05:.05:.35,'XTickLabel',{[],'0.1',[],'0.2',[],'0.3',[]},'YTick',50:20:130,'TickDir','out','LineWidth',1,'FontName','Arial','FontSize',12)
xlabel('Threshold (s)','FontName','Arial','FontSize',16)
ylabel('Reading score','FontName','Arial','FontSize',16)
text(.14,55,sprintf('r=%0.2f,p=%0.2f',sqrt(STATS2(1)),STATS2(3)),'FontName','Arial','FontSize',12)
title('Word attack','FontName','Arial','FontSize',16)

subplot(2,3,4); hold on;
[B2,BINT2,R2,RINT2,STATS2] = regress(twre.index(~isnan(out.thresh)),[ones(sum(~isnan(out.thresh)),1) out.thresh(~isnan(out.thresh))]);

x = linspace(min(out.thresh),max(out.thresh),101);
yHat = B2(1) + B2(2)*x;
plot(x,yHat,'-','Color',[0 0 0],'LineWidth',2);
plot(out.thresh(~isnan(out.thresh)),twre.index(~isnan(out.thresh)),'o','MarkerFaceColor',ccolor(4,:),'MarkerEdgeColor',[0 0 0],'MarkerSize',9);
% text(out.thresh(~isnan(out.thresh))+.01,twre.index(~isnan(out.thresh))+.1,realS)
set(gca,'XLim',[.05 .35],'YLim',[50 130],'XTick',.05:.05:.35,'XTickLabel',{[],'0.1',[],'0.2',[],'0.3',[]},'YTick',50:20:130,'TickDir','out','LineWidth',1,'FontName','Arial','FontSize',12)
xlabel('Threshold (s)','FontName','Arial','FontSize',16)
ylabel('Reading score','FontName','Arial','FontSize',16)
text(.14,55,sprintf('r=%0.2f,p=%0.2f',sqrt(STATS2(1)),STATS2(3)),'FontName','Arial','FontSize',12)
title('TWRE index','FontName','Arial','FontSize',16)

subplot(2,3,5); hold on;
[B2,BINT2,R2,RINT2,STATS2] = regress(twre.swe(~isnan(out.thresh)),[ones(sum(~isnan(out.thresh)),1) out.thresh(~isnan(out.thresh))]);

x = linspace(min(out.thresh),max(out.thresh),101);
yHat = B2(1) + B2(2)*x;
plot(x,yHat,'-','Color',[0 0 0],'LineWidth',2);
plot(out.thresh(~isnan(out.thresh)),twre.swe(~isnan(out.thresh)),'o','MarkerFaceColor',ccolor(4,:),'MarkerEdgeColor',[0 0 0],'MarkerSize',9);
% text(out.thresh(~isnan(out.thresh))+.01,twre.swe(~isnan(out.thresh))+.1,realS)
set(gca,'XLim',[.05 .35],'YLim',[50 130],'XTick',.05:.05:.35,'XTickLabel',{[],'0.1',[],'0.2',[],'0.3',[]},'YTick',50:20:130,'TickDir','out','LineWidth',1,'FontName','Arial','FontSize',12)
xlabel('Threshold (s)','FontName','Arial','FontSize',16)
ylabel('Reading score','FontName','Arial','FontSize',16)
text(.14,55,sprintf('r=%0.2f,p=%0.2f',sqrt(STATS2(1)),STATS2(3)),'FontName','Arial','FontSize',12)
title('TWRE SWE','FontName','Arial','FontSize',16)

subplot(2,3,6); hold on;
[B2,BINT2,R2,RINT2,STATS2] = regress(twre.pde(~isnan(out.thresh)),[ones(sum(~isnan(out.thresh)),1) out.thresh(~isnan(out.thresh))]);

x = linspace(min(out.thresh),max(out.thresh),101);
yHat = B2(1) + B2(2)*x;
plot(x,yHat,'-','Color',[0 0 0],'LineWidth',2);
plot(out.thresh(~isnan(out.thresh)),twre.pde(~isnan(out.thresh)),'o','MarkerFaceColor',ccolor(4,:),'MarkerEdgeColor',[0 0 0],'MarkerSize',9);
% text(out.thresh(~isnan(out.thresh))+.01,twre.pde(~isnan(out.thresh))+.1,realS)
set(gca,'XLim',[.05 .35],'YLim',[50 130],'XTick',.05:.05:.35,'XTickLabel',{[],'0.1',[],'0.2',[],'0.3',[]},'YTick',50:20:130,'TickDir','out','LineWidth',1,'FontName','Arial','FontSize',12)
xlabel('Threshold (s)','FontName','Arial','FontSize',16)
ylabel('Reading score','FontName','Arial','FontSize',16)
text(.14,55,sprintf('r=%0.2f,p=%0.2f',sqrt(STATS2(1)),STATS2(3)),'FontName','Arial','FontSize',12)
title('TWRE PDE','FontName','Arial','FontSize',16)

% currDir = pwd;
% cd('~/Dropbox/Publish/MSVisit')
% filename = 'ReadingMeasures-RSVP.svg';
% print(gcf,'-dsvg',filename,'-painters','-r300');
% cd(currDir)

%%
figure(102); clf; hold on;

temp.id = find(~isnan(out.thresh));
k = 1;
for i = 1:length(temp.id)
    realS(k,:) = subjectList{temp.id(i)};
    k = k + 1;
end

% [B,BINT,R,RINT,STATS] = regress(Y,X) R square, F, p, an estimate of the error variance
[B2,BINT2,R2,RINT2,STATS2] = regress(twre.index(~isnan(out.slope)),[ones(sum(~isnan(out.slope)),1) out.slope(~isnan(out.slope))]);
x = linspace(min(out.slope),max(out.slope),101);

yHat = B2(1) + B2(2)*x;
plot(x,yHat,'k-');
plot(out.slope(~isnan(out.slope)),twre.index(~isnan(out.slope)),'o','MarkerFaceColor',[0 0 1],'MarkerEdgeColor',[0 0 0],'MarkerSize',9);
text(out.slope(~isnan(out.slope))+.01,twre.index(~isnan(out.slope))+.1,realS)
% set(gca,'XLim',[0 .5],'YLim',[60 140])
xlabel('Slope')
ylabel('TRWE')
title(sprintf('r=%0.2f,p=%0.2f',sqrt(STATS2(1)),STATS2(3)));


%% 
% figure(100); clf; hold on;
% 
% x = linspace(0,1,101);
% 
% % [B,BINT,R,RINT,STATS] = regress(Y,X) R square, F, p, an estimate of the error variance
% [B1,BINT1,R1,RINT1,STATS1] = regress(wj.brs(~isnan(out.thresh)),[ones(sum(~isnan(out.thresh)),1) out.thresh(~isnan(out.thresh))]);
% yHat = B1(1) + B1(2)*x;
% plot(x,yHat,'k-');
% plot(out.thresh(~isnan(out.thresh)),wj.brs(~isnan(out.thresh)),'o','MarkerFaceColor',[0 0 1],'MarkerEdgeColor',[0 0 0],'MarkerSize',10);
% set(gca,'XLim',[0 1])
% xlabel('Thresh')
% ylabel('Basic reading skills')
% title(sprintf('r=%0.2f,p=%0.2f',sqrt(STATS1(1)),STATS1(3)));

%% Table
B = table(subjectList',out.thresh, wj.brs, wj.lwid, wj.wa, twre.index, twre.swe, twre.pde, ...
    'VariableNames',{'ID','rsvp','WJ_BRS','WJ_LWID','WJ_WA','TWRE_Index','TWRE_SWE','TWRE_PDE'}); 

cd('/home/sjjoo/git/psychophys/rsvp/result');

save('rsvp.mat','B')
