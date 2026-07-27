%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% CALIBRACION PARA MINI-MEP CHILE %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [m, p, mss] = readmodel_alternativo(filter)

%% Filtration on/off
% filter = true - Kalman filter ON
% filter = false - Kalman filter OFF
p.filter = filter;

%% Typical and specific parameter values be used in calibrations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. Aggregate demand equation (the IS curve) (modelo1)
% CHECK POINT ESTIMATES WITH PABLO GARCIA
% L_GDP_GAP = b1*L_GDP_GAP{-1} - b2*(TPM-TPMN1) + b3*(CRECSC-ss_CRECSC) + ...
%             b4*(FFR{-1}-ss_FFR) + b5*(VIX{-1}-ss_VIX) + b6*(UST10{-1}-ss_UST10) + ...
%             b7*(L_PCU-ss_L_PCU) + b8*(L_WTI-ss_L_WTI) + b9*(T_COLOC-ss_T_COLOC) + ...
%             SHK_L_GDP_GAP;
% output persistence;
p.b1 = 0.704405;

% policy passthrough (the impact of monetary policy on real economy);
p.b2 = 0.087592;

% the impact of external demand on domestic output;
p.b3 = 0.105359;

p.b4 =0.168436;
p.b5 =-0.010915 ;
p.b6 = -0.3;
p.b7 =  0.002304*1.5;   % 0.016
p.b8 = -0.0077;
p.b8_b = 0.0065;
p.b9 = 0.3;
p.b10 = 0.021206;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Aggregate supply equation (the Phillips curve) (modelo4)
% CHECK POINT ESTIMATES WITH PABLO GARCIA
% DLA_CPIXFE = a1*DLA_CPIXFE{-1} + (1-a1)*DLA_CPIXFE{1} + a2*L_GDP_GAP{-1} + ...
%              a3*(L_Z_GAP) +  a8*(L_Food{-1}) +a4*Q1 + a5*Q2 + a6*Q3 + a7*Q4 + SHK_DLA_CPIXFE;

% inflation persistence;
% a1 varies between 0.4 (implying low persistence) to 0.9 (implying high persistence)
p.a1 = 0.49;

% policy passthrough (the impact of rmc on inflation);
% a2 varies between 0.1 (a flat Phillips curve and a high sacrifice ratio) 
% to 0.5 (a steep Phillips curve and a low sacrifice ratio)
p.a2 =0.1;

% the ratio of imported goods in firms' marginal costs (1-a3);
% a3 varies between 0.9 for a closed economy to 0.5 for an open economy
p.a3 =0.075;

p.a8 = 0.010801;

lambda_seas = 1.1;
% QUARTERLY DUMMYS;
p.a4 = lambda_seas *0.76284;   % Q1
p.a5 = lambda_seas *0.92907;   % Q2
p.a7 = lambda_seas *-1.25604;   % Q3
p.a6 = lambda_seas *-0.4358;   % Q4

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4. Monetary policy reaction function
%% A. The standard rule (modelo8)
% TPM = g1*TPM{-1} + (1-g1)*(TPMN1 + g2*(D4L_CPI{+3} - ss_D4L_CPI_TAR) + ...
%       g3*L_GDP_GAP) + SHK_TPM;
% TPM = g1*TPM{-1} + (1-g1)*TPMN1 + (1-g1)*g2*(D4L_CPI{+3} - ss_D4L_CPI_TAR) + ...
%       (1-g1)*g3*L_GDP_GAP + SHK_TPM;

% policy persistence;
% g1 varies from 0 (no persistence) to 0.8 ("wait and see" policy)
p.g1 = 0.8251567;

% policy reactiveness: the weight put on inflation by the policy maker);
% g2 has no upper limit but must be always higher then 0 (the Taylor principle)
p.g2 = 0.1737984 /(1 -0.8251567);  % 0.4140603/(1-0.75) 0.25 o 0.32 ??
%p.g2b =  0.06434/(1 - 0.81733);  % 0.4140603/(1-0.75) 0.25 o 0.32 ??

% policy reactiveness: the weight put on the output gap by the policy maker);
% g3 has no upper limit but must be always higher then 0
p.g3 = 0.0780615/ (1 - 0.8251567);  % 0.1388662/(1-0.75) 0.25 o 0.32 ??

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 5. Speed of convergence of selected variables to their trend values
p.rho_DLA_GDP_BAR = 0.7;
p.rho_L_Z = 0.6;

% persistence in foreign GDP
% L_GDP_RW_GAP = h2*L_GDP_RW_GAP{-1} + SHK_L_GDP_RW_GAP;
p.rho_CRECSC = 0.68414;

p.rho_TPMN1 = 0.01;
p.rho_DLA_CPIRES = 0.25;
p.rho_Coloc = 0.65;

p.rho_FFR = 0.96;
p.rho_VIX = 0.55431;
p.rho_UST10 = 0.9;
p.rho_L_PCU = 0.75;
p.rho_L_WTI =  0.69829;
p.rho_L_Food =  0.69829;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The inflation target and other observed economic trends
% These "steady-state" values are all calibrated

% Trend level of domestic real interest rate
p.ss_TPMN1 = 4.0;

% Trend change in the real ER (negative number = real appreciation)
p.ss_L_Z = 100 * log(102);  % 101

% Potential output growth
p.ss_DLA_GDP_BAR = 2;  % 1

% Domestic inflation target
p.ss_D4L_CPI_TAR = 3;

p.ss_CRECSC = 3;
p.ss_T_COLOC = 4;

p.ss_FFR = 3.5;  % 4.5 original
p.ss_VIX = 17;   % 100 original
p.ss_UST10 = 4.0;
p.ss_L_PCU = 100 * log(3.75);
p.ss_L_WTI = 100 * log(50);
p.ss_L_Food = 3.1;
 
%% Model solving--a brief description of commands
% Command 'model' reads the text file 'model.mod' (contains the model's
% equations), assigns the parameters and trend values preset in the database
% 'p' (see readmodel) and transforms the model for the matrix algebra.
% Transformed model is written in the object 'm'.

% Carga robusta del archivo .model. No depende del directorio actual (pwd).
if exist('config_ipom', 'file') == 2
    cfg_ipom = config_ipom();
    modelFile = cfg_ipom.modelFile;
else
    modelFile = 'minimep0.model';
end

if exist(modelFile, 'file') ~= 2
    error('No existe el archivo de modelo: %s', modelFile);
end

m = model(modelFile, 'linear=', false, 'assign', p);

% Command 'sstate' takes the transformed model in object 'm', calculates the model's
% steady-state and writes everything back in the object 'm'. Typing 'mss' in
% Matlab command window provides the steady-state values.
m = sstate(m, 'growth', true, 'MaxFunEvals', 2000);
mss = get(m, 'sstate');

%% Check steady state
[flag, discrep, eqtn] = chksstate(m);

if ~flag
    error('Equation fails to hold in steady state: "%s"\n', eqtn{:});
end

% Command 'solve' takes the model saved in object 'm' and solves the model
% for its reduced form (Blanchard-Kahn algorithm). The reduced form is again
% written in the object 'm'
m = solve(m);

if mss.L_GDP_GAP ~= 0 || mss.L_Z_GAP ~= 0 || mss.L_RPXFE_GAP ~= 0 || mss.L_RPF_GAP ~= 0
    disp('WARNING');
end
