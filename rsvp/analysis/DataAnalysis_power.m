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
subjectList = {'502_HW','504_LM','507_JP','508_RC','510_DT','511_RC','512_EG', ...
    '513_EO','515_AB','516_TT','517_CT','518_ML','519_MF','520_AA','521_GP','522_JH','602_JK','526_PM'};

for i = 1: length(subjectList)
    subjectNumber{i} = subjectList{i}(1:3);
end

%%
cd(sprintf('%s/%s',parentDir,dataDir));

for iSubject = 1: length(subjectList)
    d = dir(sprintf('%s*',subjectList{iSubject}));
    
    load(d.name);
    
    cd(parentDir);
    
    pInit.p = 1;
    pInit.c = .5;
    pInit.shutup = 1;
    freeList ={'p','c'};

    h = figure(iSubject); clf; hold on;
    for iSpacing = 1: 2 % 1 unspaced, 2 spaced
        results.intensity = result.intensity(:,iSpacing);
        results.response = result.response(:,iSpacing);

        % Call the 'fit' function
%         [pBest,logLikelihoodBest] = fit('fitPsychometricFunction',pInit,freeList,results,'power_func');

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
                plot(intensities(i),pCorrect(i),'o','MarkerFaceColor','r','MarkerEdgeColor','k','MarkerSize',sz);
            else
                plot(intensities(i),pCorrect(i),'o','MarkerFaceColor','b','MarkerEdgeColor','k','MarkerSize',sz);
            end
        end
        
        % fit power function
        options = optimset('MaxFunEvals',1e7,'MaxIter',1e7);
        
        x = intensities;
        obs = pCorrect;
        
        p0 = [1 1]; % c, p
        
        f = @(x,p)p(1)*x.^p(2);
        errf = @(p,x,y)sum((obs(:)-f(x(:),p)).^2);
        
%         p = fminsearch(errf,p0,options,x,obs);
        p = fminunc(errf,p0,options,x,obs);

        %plot the parametric psychometric function
        % x = exp(linspace(log(min(results.intensity)),log(max(results.intensity)),101));
        x = linspace(min(results.intensity),max(results.intensity),101);
        
        y = p(1)*x.^p(2);
        
        pBest.t = interp1(y,x,.75);
        
        if iSpacing == 1
            plot(x,y,'r-','LineWidth',2);
        else
            plot(x,y,'b-','LineWidth',2);
        end

        %     plot([pBest.u,pBest.u],[50,0],'k--','LineWidth',2)

        %     plot([-1,pBest.u,pBest.u],[50,50,0],'k--','LineWidth',2)
        %     plot([mean(result.thresh)+1 mean(result.thresh)+1],[0 50], 'r--', 'LineWidth',2);

        set(gca,'YLim',[.4,1],'YTick',.4:.1:1,'YTickLabel',40:10:100);
%         set(gca,'XLim',[min(intensities)-.05 max(intensities)+.1])

        xxx = get(gca,'XLim');

        if iSpacing == 1
            plot([xxx(1) pBest.t pBest.t],[.75 .75 .4],'r--');
        else
            plot([xxx(1) pBest.t pBest.t],[.75 .75 .4],'b--');
        end

        hhh = get(gca,'XTick');

        set(gca,'XTickLabel',hhh);
        set(gca,'XLim',[0 .7])

        % logx2raw

        xlabel('Stim Duration (s)', 'FontSize', 18);
        ylabel('Percent correct (%)', 'FontSize', 18);
        title(sprintf('%s',config.fn));
    end
%     cd(sprintf('%s/%s',parentDir,resultDir));
%     print(h,'-dpdf',sprintf('%s',config.fn));
    cd(sprintf('%s/%s',parentDir,dataDir));
end