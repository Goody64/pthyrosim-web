%--------------------------------------------------
% FILE:         thyrosim_oral_repeat.m
% AUTHOR:       Simon X. Han
% DESCRIPTION:
%   THYROSIM stand alone MATLAB version, with added ability to give a
%   repeating oral dose.
%
%   This script is a wrapper around the thyrosim_core solver. It takes the
%   end values of the previous run and set them as the initial conditions
%   of the current run plus adjustments in dosing, if any. You must
%   manually setup the conditions each run. See PARAMETERS.
% PARAMETERS:
%   Parameters are defined under "define" function.
%   tspans: the tspan (in hours) of each run
%   T4doses: in mols. Each element corresponds to a run.
%   T3doses: in mols. Each element corresponds to a run.
%
%   THYROSIM implmentation based on:
%   All-Condition Thyroid Simulator Eqns 2015-06-29.pdf
% RUN:          >> thyrosim_oral_repeat
%-------------------------------------------------- 

% Main - wrapper for oral doses
function thyrosim_oral_repeat()

% Clean workspace
clc; clear all;
close all;

% Initialize
[ic,dial] = init();
[tspans,T4doses,T3doses] = define();
inf1 = 0; % For oral doses, infs are 0
inf4 = 0; % For oral doses, infs are 0

% Some needed vars
t_last = 0;
T4max = 0;
T3max = 0;
TSHmax = 0;

% Run simulation for each defined run
for i=1:length(tspans)
    
    ic = updateIC(ic,T4doses(i),T3doses(i)); % Add drugs, if any
    [t,q] = thyrosim_core(ic,dial,inf1,inf4,tspans(1,:)); % Run simulation
    ic = q(end,:); % Set this run's values as IC for next run

    % Graph results and update values for next run
    t = t + t_last;
    graph(t,q);
    t_last = t(end);
    
    if max(q(:,1)) > T4max
        T4max = max(q(:,1));
    end
    if max(q(:,4)) > T3max
        T3max = max(q(:,4));
    end
    if max(q(:,7)) > TSHmax
        TSHmax = max(q(:,7));
    end
end
graphFin(T4max,T3max,TSHmax);

end

% Define run conditions.
% The default here is as follows:
% Total run time: 5 days.
% T4 dosing: 400 mcg daily starting at day 1.
% T3 dosing: none.
function [tspans,T4doses,T3doses] = define()

% Define each tspan and each tspan's T4/T3 doses (in mols)
tspans = [
    0, 24;
    0, 24;
    0, 24;
    0, 24;
    0, 24;
];

T4doses = [
    0;
    0.5148;
    0.5148;
    0.5148;
    0.5148
];

T3doses = [
    0;
    0;
    0;
    0;
    0
];
end

% Initialize initial conditions and dial values
function [ic,dial] = init()

% Corresponds to compartments 1-19
ic(1) = 0.322114215761171;
ic(2) = 0.201296960359917;
ic(3) = 0.638967411907560;
ic(4) = 0.00663104034826483;
ic(5) = 0.0112595761822961;
ic(6) = 0.0652960640300348;
ic(7) = 1.78829584764370;
ic(8) = 7.05727560072869;
ic(9) = 7.05714474742141;
ic(10) = 0;
ic(11) = 0;
ic(12) = 0;
ic(13) = 0;
ic(14) = 3.34289716182018;
ic(15) = 3.69277248068433;
ic(16) = 3.87942133769244;
ic(17) = 3.90061903207543;
ic(18) = 3.77875734283571;
ic(19) = 3.55364471589659;

% [T4 Secretion, T4 Absorption, T3 Secretion, T3 Absorption]
dial = [1, 0.88, 1, 0.88];
end

% Update initial conditions
function [ic] = updateIC(ic,T4dose,T3dose)
ic(11) = ic(11) + T4dose;
ic(13) = ic(13) + T3dose;
end

% Graph results
function graph(t,q)
global p

% Conversion factors
% 777: molecular weight of T4
% 651: molecular weight of T3
% 5.6: (q7 umol)*(28000 mcg/umol)*(0.2 mU/mg)*(1 mg/1000 mcg)
% where 28000 is TSH molecular weight and 0.2 is specific activity
T4conv  = 777/p(47);    % mcg/L
T3conv  = 651/p(47);    % mcg/L
TSHconv = 5.6/p(48);    % mU/L

% Outputs
y1 = q(:,1)*T4conv;     % T4
y2 = q(:,4)*T3conv;     % T3
y3 = q(:,7)*TSHconv;    % TSH
t  = t/24;              % Convert time to days

% General

% T4 plot
subplot(3,1,1);
hold on;
plot(t,y1);

% T3 plot
subplot(3,1,2);
hold on;
plot(t,y2);

% TSH plot
subplot(3,1,3);
hold on;
plot(t,y3);
end

function graphFin(T4max,T3max,TSHmax)
global p

T4conv  = 777/p(47);    % mcg/L
T3conv  = 651/p(47);    % mcg/L
TSHconv = 5.6/p(48);    % mU/L

% Outputs
p1max = T4max*T4conv;     % T4
p2max = T3max*T3conv;     % T3
p3max = TSHmax*TSHconv;    % TSH

% T4 plot
subplot(3,1,1);
ylabel('T4 mcg/L');
ylim([0 p1max*1.2]);

% T3 plot
subplot(3,1,2);
ylabel('T3 mcg/L');
ylim([0 p2max*1.2]);

% TSH plot
subplot(3,1,3);
ylabel('TSH mU/L');
ylim([0 p3max*1.2]);
xlabel('Days');
end
