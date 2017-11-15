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
subjectList = {'502_HW','504_LM','507_JP','508_RC','509_MK','510_DT','511_RC','512_EG', ...
    '513_EO','514_LR','515_AB','516_TT','517_CT','518_ML','519_MF','520_AA','521_GP','522_JH','523_SK','526_PM'};

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
    if ~isnan(T.WJ_BRS(strcmp(T.Subject,subjectList{iSubject}) & T.Visit == 2))
        wj.brs(iSubject) = (T.WJ_BRS(strcmp(T.Subject,subjectList{iSubject}) & T.Visit == 1) + T.WJ_BRS(strcmp(T.Subject,subjectList{iSubject}) & T.Visit == 2))/2;
    else
        wj.brs(iSubject) = T.WJ_BRS(strcmp(T.Subject,subjectList{iSubject}) & T.Visit == 1);
    end
    wj.wa(iSubject) = T.WJ_WA_SS(strcmp(T.Subject,subjectList{iSubject}) & T.Visit == 1);
    wj.lwid(iSubject) = T.WJ_LWID_SS(strcmp(T.Subject,subjectList{iSubject}) & T.Visit == 1);
    twre.index(iSubject) = T.TWRE_INDEX(strcmp(T.Subject,subjectList{iSubject}) & T.Visit == 1);
    twre.pde(iSubject) = T.TWRE_PDE_SS(strcmp(T.Subject,subjectList{iSubject}) & T.Visit == 1);
    twre.swe(iSubject) = T.TWRE_SWE_SS(strcmp(T.Subject,subjectList{iSubject}) & T.Visit == 1);
end

%%
cd(sprintf('%s/%s',parentDir,dataDir));
out.thresh = NaN * ones(length(subjectList),2);
out.slope = NaN * ones(length(subjectList),2);

for iSubject = 1: length(subjectList)
    nogo = 0;
%     for iii = 1: length(badSubjects)
%         if strcmp(badSubjects{iii},subjectList{iSubject})
%             nogo = 1;
%         end
%     end
    if ~nogo
        d = dir(sprintf('%s*',subjectList{iSubject}));

        load(d.name);

        cd(parentDir);

        pInit.t = result.thresh;
        pInit.b = .5;
        pInit.shutup = 1;
        freeList ={'t','b'};

        h = figure(iSubject); clf; hold on;
        for iSpacing = 1: 2 % 1 unspaced, 2 spaced
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
    %         set(gca,'XLim',[min(intensities)-.05 max(intensities)+.1])

            xxx = get(gca,'XLim');

            if iSpacing == 1
                plot([xxx(1) pBest.t pBest.t],[75 75 40],'r--');
            else
                plot([xxx(1) pBest.t pBest.t],[75 75 40],'b--');
            end

            hhh = get(gca,'XTick');

            set(gca,'XTickLabel',hhh);
            set(gca,'XLim',[0 .7])

            % logx2raw

            xlabel('Stim Duration (s)', 'FontSize', 18);
            ylabel('Percent correct (%)', 'FontSize', 18);
            title(sprintf('%s',config.fn));
            out.thresh(iSubject,iSpacing) = pBest.t;
            out.slope(iSubject,iSpacing) = pBest.b;
            out.pc(iSubject,:,iSpacing) = pCorrect;
        end
    end
%     cd(sprintf('%s/%s',parentDir,resultDir));
%     print(h,'-dpdf',sprintf('%s',config.fn));
    cd(sprintf('%s/%s',parentDir,dataDir));
end
out.thresh(6,:) = NaN*ones(1,2);
out.thresh(7,:) = NaN*ones(1,2);
out.thresh(9,:) = NaN*ones(1,2);
out.thresh(19,:) = NaN*ones(1,2);
out.thresh(20,:) = NaN*ones(1,2);
out.slope(6,:) = NaN*ones(1,2);
out.slope(7,:) = NaN*ones(1,2);
out.slope(20,:) = NaN*ones(1,2);

%% Dyslexia
dys = twre.pde <= 85;
yy = [nanmean(out.thresh(dys,1)) nanmean(out.thresh(dys,2))];

figure(99);clf;
subplot(1,2,1); hold on;
xx = 1:2;
bar(xx,yy)
plot([xx(1) xx(1)],[yy(1)-nanstd(out.thresh(dys,1))/sqrt(sum(dys)) yy(1)+nanstd(out.thresh(dys,1))/sqrt(sum(dys))],'-','Color',[0 0 0],'LineWidth',1)
plot([xx(2) xx(2)],[yy(2)-nanstd(out.thresh(dys,2))/sqrt(sum(dys)) yy(2)+nanstd(out.thresh(dys,2))/sqrt(sum(dys))],'-','Color',[0 0 0],'LineWidth',1)
set(gca,'XLim',[0 3],'YLim',[0 .3],'XTick',1:2,'YTick',0:.1:.3,'XTickLabel',{'Unspaced','Spaced'},'TickDir','out','FontName','Arial',...
    'FontSize',12,'LineWidth',1)
ylabel('Threshold (s)','FontName','Arial','FontSize',14)
title('Dyslexic subjects','FontName','Arial','FontSize',12)

subplot(1,2,2); hold on;
yy = [nanmean(out.thresh(~dys,1)) nanmean(out.thresh(~dys,2))];

bar(xx,yy)
plot([xx(1) xx(1)],[yy(1)-nanstd(out.thresh(~dys,1))/sqrt(sum(~dys)) yy(1)+nanstd(out.thresh(~dys,1))/sqrt(sum(~dys))],'-','Color',[0 0 0],'LineWidth',1)
plot([xx(2) xx(2)],[yy(2)-nanstd(out.thresh(~dys,2))/sqrt(sum(~dys)) yy(2)+nanstd(out.thresh(~dys,2))/sqrt(sum(~dys))],'-','Color',[0 0 0],'LineWidth',1)
set(gca,'XLim',[0 3],'YLim',[0 .3],'XTick',1:2,'YTick',0:.1:.3,'XTickLabel',{'Unspaced','Spaced'},'TickDir','out','FontName','Arial',...
    'FontSize',12,'LineWidth',1)
ylabel('Threshold (s)','FontName','Arial','FontSize',14)
title('Typical readers','FontName','Arial','FontSize',12)

%% 
figure(100); clf; hold on;

y = nanmean(out.thresh);

bar(y)
set(gca,'XLim',[0 3])

figure(1000);clf;hold on;
bar(squeeze(mean(out.pc,2)))

temp = squeeze(mean(out.pc,2));

difff = temp(:,1) - temp(:,2);

k = 1;
for i = 1: length(subjectList)
	if difff(i) < 0
        sList{k} = subjectList{i};
        k = k+1;
    end
end