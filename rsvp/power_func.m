function y = power_func(p,x)
%y = Weibull(p,x)
%
%Parameters:  p.c constant
%             p.p exponent
%             x   intensity values.

% g = 0.5;  %chance performance
% e = .75;%(.5)^(1/3);  %threshold performance ( ~80%)
% 
% %here it is.
% k = (-log( (1-e)/(1-g)))^(1/p.b);
% y = 1- (1-g)*exp(- (k*x/p.t).^p.b);

y = p.c .* (x .^ p.p);