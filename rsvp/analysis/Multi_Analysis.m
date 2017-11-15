%% Multi-variate analysis
clear variables

ccolor = cbrewer('qual','Set1',9);

subjectList1 = {'502_HW','504_LM','507_JP','508_RC','509_MK','510_DT','513_EO','514_LR', ... %'511_RC'
    '516_TT','517_CT','518_ML','519_MF','520_AA','521_GP','522_JH'}; 

%% Read reading scores
cd('~/git/psychophys/crowding/Result');

T = readtable('NLR_Scores.csv','Delimiter','\t');

wj.brs = NaN * ones(length(subjectList1),1);
wj.wa = NaN * ones(length(subjectList1),1);
wj.lwid = NaN * ones(length(subjectList1),1);
twre.index = NaN * ones(length(subjectList1),1);
twre.pde = NaN * ones(length(subjectList1),1);
twre.swe = NaN * ones(length(subjectList1),1);

for iSubject = 1: length(subjectList1)
    if ~isnan(T.WJ_BRS(strcmp(T.Subject,subjectList1{iSubject}) & T.Visit == 2))
        wj.brs(iSubject) = (T.WJ_BRS(strcmp(T.Subject,subjectList1{iSubject}) & T.Visit == 1) + T.WJ_BRS(strcmp(T.Subject,subjectList1{iSubject}) & T.Visit == 2))/2;
    else
        wj.brs(iSubject) = T.WJ_BRS(strcmp(T.Subject,subjectList1{iSubject}) & T.Visit == 1);
    end
    wj.wa(iSubject) = T.WJ_WA_SS(strcmp(T.Subject,subjectList1{iSubject}) & T.Visit == 1);
    wj.lwid(iSubject) = T.WJ_LWID_SS(strcmp(T.Subject,subjectList1{iSubject}) & T.Visit == 1);
    twre.index(iSubject) = T.TWRE_INDEX(strcmp(T.Subject,subjectList1{iSubject}) & T.Visit == 1);
    twre.pde(iSubject) = T.TWRE_PDE_SS(strcmp(T.Subject,subjectList1{iSubject}) & T.Visit == 1);
    twre.swe(iSubject) = T.TWRE_SWE_SS(strcmp(T.Subject,subjectList1{iSubject}) & T.Visit == 1);
end

%%
cd('~/git/psychophys/rsvp/data');
out.thresh = NaN * ones(length(subjectList1),1);
out.slope = NaN * ones(length(subjectList1),1);

for iSubject = 1: length(subjectList1)
    nogo = 0;
%     for iii = 1: length(badSubjects)
%         if strcmp(badSubjects{iii},subjectList{iSubject})
%             nogo = 1;
%         end
%     end
    if ~nogo
        d = dir(sprintf('%s*',subjectList1{iSubject}));

        load(d.name);

        cd('..');

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
    cd('~/git/psychophys/rsvp/data');
end

%%
cd('~/git/psychophys/rsvp/analysis')
load('Crowding.mat')

word.mean = mean(word.list,2);
pword.mean = mean(pword.list,2);
y(:,6) = [];
word.mean(6) = [];
pword.mean(6) = [];
y(:,16) = [];
word.mean(16) = [];
pword.mean(16) = [];
%% Plot the data
X = [wj.brs wj.lwid wj.wa twre.index twre.swe twre.pde out.thresh y(1,:)' y(2,:)' word.mean pword.mean];

T = clusterdata([X(:,7) X(:,8) X(:,9) X(:,11)],'maxclust',5);
% T = clusterdata(X(:,7:11),'maxclust',4);

figure(30); clf; hold on
scatter3(X(:,7),X(:,8),X(:,11),100,T,'filled')
text(X(:,7),X(:,8),X(:,11),subjectList1)
grid on

figure(31); clf; hold on
scatter(X(:,5),X(:,6),100,T,'filled')
text(X(:,5),X(:,6),subjectList1)
grid on;

dys = twre.pde<=85;

[idx,C] = kmeans(X,2);


