%--------------------------------------------------
% FILE:         thyrosim_core.m
% AUTHOR:       Simon X. Han
% DESCRIPTION:
%   The core solver, for calling by other scripts, such as
%   thyrosim_oral_repeat.m.
%
%   THYROSIM implmentation based on:
%   All-Condition Thyroid Simulator Eqns 2015-06-29.pdf
%-------------------------------------------------- 

function [t,q] = thyrosim_core(ic,dial,inf1,inf4,tspan)

% Initialize
global u1 u4 kdelay d p;
[u1,u4,kdelay,d,p] = initParams(inf1,inf4,dial);

% Solve ODE
[t,q] = ode45(@ODEs, tspan, ic);
end

% Initialize parameter values
function [u1,u4,kdelay,d,p] = initParams(inf1,inf4,dial)

u1 = inf1;
u4 = inf4;
kdelay = 5/8;           %(n-1)/k = t; n comps, t = 8hr
d(1) = dial(1);
d(2) = dial(2);
d(3) = dial(3);
d(4) = dial(4);

p(1) = 0.00174155;      %S4
p(2) = 8;               %tau
p(3) = 0.868;           %k12
p(4) = 0.108;           %k13
p(5) = 584;             %k31free
p(6) = 1503;            %k21free
p(7) = 0.000289;        %A
p(8) = 0.000214;        %B
p(9) = 0.000128;        %C
p(10) = -8.83*10^-6;    %D
p(11) = 0.88;           %k4absorb; originally 0.881
p(12) = 0.0189;         %k02
p(13) = 0.00998996;     %VmaxD1fast
p(14) = 2.85;           %KmD1fast
p(15) = 6.63*10^-4;     %VmaxD1slow
p(16) = 95;             %KmD1slow
p(17) = 0.00074619;     %VmaxD2slow
p(18) = 0.075;          %KmD2slow
p(19) = 3.3572*10^-4;   %S3
p(20) = 5.37;           %k45
p(21) = 0.0689;         %k46
p(22) = 127;            %k64free
p(23) = 2043;           %k54free
p(24) = 0.00395;        %a
p(25) = 0.00185;        %b
p(26) = 0.00061;        %c
p(27) = -0.000505;      %d
p(28) = 0.88;           %k3absorb; originally 0.882
p(29) = 0.207;          %k05
p(30) = 1166;           %Bzero
p(31) = 581;            %Azero
p(32) = 2.37;           %Amax
p(33) = -3.71;          %phi
p(34) = 0.53;           %kdegTSH-HYPO
p(35) = 0.037;          %VmaxTSH
p(36) = 23;             %K50TSH
p(37) = 0.118;          %k3
p(38) = 0.29;           %T4P-EU
p(39) = 0.006;          %T3P-EU
p(40) = 0.037;          %KdegT3B
p(41) = 0.0034;         %KLAG-HYPO
p(42) = 5;              %KLAG
p(43) = 1.3;            %k4dissolve
p(44) = 0.12*d(2);      %k4excrete; originally 0.119
p(45) = 1.78;           %k3dissolve
p(46) = 0.12*d(4);      %k3excrete; originally 0.118
p(47) = 3.2;            %Vp
p(48) = 5.2;            %VTSH
end

% ODEs
function dqdt = ODEs(t, q)

global u1 u4 kdelay d p;

% Auxillary equations
q4F = (p(24)+p(25)*q(1)+p(26)*q(1)^2+p(27)*q(1)^3)*q(4);        %FT3p
q1F = (p(7) +p(8) *q(1)+p(9) *q(1)^2+p(10)*q(1)^3)*q(1);        %FT4p
SR3 = (p(19)*q(19))*d(3);                                       % Brain delay
SR4 = (p(1) *q(19))*d(1);                                       % Brain delay
fCIRC = 1+(p(32)/(p(31)*exp(-q(9)))-1)*(1/(1+exp(10*q(9)-55)));
SRTSH = (p(30)+p(31)*fCIRC*sin(pi/12*t-p(33)))*exp(-q(9));
fdegTSH = p(34)+p(35)/(p(36)+q(7));
fLAG = p(41)+2*q(8)^11/(p(42)^11+q(8)^11);
f4 = p(37)+5*p(37)/(1+exp(2*q(8)-7));
NL = p(13)/(p(14)+q(2));

% ODEs
qdot(1) = SR4+p(3)*q(2)+p(4)*q(3)-(p(5)+p(6))*q1F+p(11)*q(11)+u1;       %T4dot
qdot(2) = p(6)*q1F-(p(3)+p(12)+NL)*q(2);                                %T4fast
qdot(3) = p(5)*q1F-(p(4)+p(15)/(p(16)+q(3))+p(17)/(p(18)+q(3)))*q(3);   %T4slow
qdot(4) = SR3+p(20)*q(5)+p(21)*q(6)-(p(22)+p(23))*q4F+p(28)*q(13)+u4;   %T3pdot
qdot(5) = p(23)*q4F+NL*q(2)-(p(20)+p(29))*q(5);                         %T3fast
qdot(6) = p(22)*q4F+p(15)*q(3)/(p(16)+q(3))+p(17)*q(3)/(p(18)+q(3))-(p(21))*q(6);%T3slow
qdot(7) = SRTSH-fdegTSH*q(7);                                           %TSHp
qdot(8) = f4/p(38)*q(1)+p(37)/p(39)*q(4)-p(40)*q(8);                    %T3B
qdot(9) = fLAG*(q(8)-q(9));                                             %T3B LAG
qdot(10)= -p(43)*q(10);                                                 %T4PILLdot
qdot(11)=  p(43)*q(10)-(p(44)+p(11))*q(11);                             %T4GUTdot
qdot(12)= -p(45)*q(12);                                                 %T3PILLdot
qdot(13)=  p(45)*q(12)-(p(46)+p(28))*q(13);                             %T3GUTdot

% Delay ODEs
qdot(14)= -kdelay*q(14) +q(7);                                          %delay1
qdot(15)= kdelay*(q(14) -q(15));                                        %delay2
qdot(16)= kdelay*(q(15) -q(16));                                        %delay3
qdot(17)= kdelay*(q(16) -q(17));                                        %delay4
qdot(18)= kdelay*(q(17) -q(18));                                        %delay5
qdot(19)= kdelay*(q(18) -q(19));                                        %delay6

% ODE vector
dqdt = qdot';
end
