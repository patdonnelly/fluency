%%
%
%
%
clear variables;
parentDir = '~/git/psychophys/rsvp';
%%

cd(parentDir);
figure(1); clf; hold on;
for iSpacing = 1: 2 % 1 unspaced, 2 spaced
    
    if iSpacing == 1
        intensities = [.05 .1 .15 .2 .25];
        pCorrect = [.5 .6 .7 .85 1];
        pBest.t = .16;
        pBest.b = 3.5;
    else
        pBest.t = .21;
        pBest.b = 4;
        intensities = [.05 .1 .15 .2 .25];
        pCorrect = [.5 .5 .6 .75 .9];
    end
    
    
    %loop through each intensity so each data point can have it's own size.
    for i=1:length(intensities);
        sz = 5; %nTrials(i)+2;
        if iSpacing == 1
            plot(intensities(i),100*pCorrect(i),'o','MarkerFaceColor','r','MarkerEdgeColor','k','MarkerSize',sz);
        else
            plot(intensities(i),100*pCorrect(i),'o','MarkerFaceColor','b','MarkerEdgeColor','k','MarkerSize',sz);
        end
    end
    
    %plot the parametric psychometric function
    % x = exp(linspace(log(min(results.intensity)),log(max(results.intensity)),101));
    x = linspace(min(intensities),max(intensities),101);
    y = Weibull(pBest,x);
    
    if iSpacing == 1
        plot(x,100*y,'r-','LineWidth',2);
    else
        plot(x,100*y,'b-','LineWidth',2);
    end
    
    %     plot([pBest.u,pBest.u],[50,0],'k--','LineWidth',2)
    
    %     plot([-1,pBest.u,pBest.u],[50,50,0],'k--','LineWidth',2)
    %     plot([mean(result.thresh)+1 mean(result.thresh)+1],[0 50], 'r--', 'LineWidth',2);
    
    set(gca,'XLim',[0 .4],'YLim',[40,100],'XTickLabel',{'5','10','15','20','25','30','35','40'},'TickDir','out','LineWidth',1,'FontName','Arial','FontSize',12);
    %         set(gca,'XLim',[min(intensities)-.05 max(intensities)+.1])
    
    xxx = get(gca,'XLim');
    
    if iSpacing == 1
        plot([xxx(1) pBest.t pBest.t],[75 75 40],'r--','LineWidth',1);
    else
        plot([xxx(1) pBest.t pBest.t],[75 75 40],'b--','LineWidth',1);
    end
    
    % logx2raw
    
    xlabel('Motion strength (% coherence)', 'FontName','Arial','FontSize',16);
    ylabel('Percent correct (%)','FontName','Arial','FontSize',16);
end

currDir = pwd;
cd('~/Dropbox/Publish/MSVisit')
filename = 'FakePsycho2.svg';
print(gcf,'-dsvg',filename,'-painters','-r300');
cd(currDir)