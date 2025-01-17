%% 3D Line Formation Pioneer-Drone

% Pioneer is the reference of the formation
% The formation variables are:
% Q = [xf yf zf rhof alfaf betaf]

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  %

% Initial Comands

clear; close all; clc;

try
    fclose(instrfindall);
catch
end

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - %

% Look for root folder

PastaAtual = pwd;
PastaRaiz = 'AuRoRA 2018';
cd(PastaAtual(1:(strfind(PastaAtual,PastaRaiz)+numel(PastaRaiz)-1)))
addpath(genpath(pwd))


%% Load Classes

% Robots
P = Pioneer3DX(1);
A = ArDrone(30);

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - %

% Formation 3D
LF = LineFormationControl;

LF.pPar.K1 = diag([  1.0   1.0   0.0   1.0   1.0   1.0  ]);     % kinematic control gain  - controls amplitude
LF.pPar.K2 = diag([  0.1   0.1   0.0   0.1   0.1   0.1 ]);     % kinematic control gain - control saturation

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - %

% Robot/Simulator conection

% P.rConnect;

% Robot initial pose
% Pioneer P3DX
Xo = [0 0 0 pi/4];
P.rSetPose(Xo');
P.pSC.Ud = [0; 0];
P.rSendControlSignals;    % Pioneer

% ArDrone
A.pPos.X(1:3) = [-0.075 -0.075 0.25];
A.pPos.X(6) = pi/4;

%% Configure simulation window

fig = figure(1);
axis([-3 3 -3 3 0 3]);
view(-21,30);
hold on;
grid on;

% Draw robots
try
    A.mCADdel;
    P.mCADdel;
catch
end

% Pioneer
P.mCADplot(0.75,'k');

% ArDrone
A.mCADcolor([0 0 1]);
A.mCADplot;

drawnow;

%% Formation initial error

% Formation initial pose
LF.pPos.X = [P.pPos.X(1:3); A.pPos.X(1:3)];
LF.pPos.Xr = LF.pPos.X;

% Formation initial pose
LF.mDirTrans;
LF.pPos.Qda = LF.pPos.Qd;
% pause(3);

%% Simulation

fprintf('\nStart..............\n\n');

% Time variables initialization

T_PLOT = 2;       % Per�odo de plotagem em tempo real

% P.pPar.Ts = 0.100;
% LF.pPar.Ts = 0.200;
T_FORMATION = LF.pPar.Ts; % 200ms
T_PIONEER = P.pPar.Ts; %0.100;
T_ARDRONE = A.pPar.Ts; %1/30

rX = 1.0; % [m]
rY = 1.0; % [m]
rho = 1.5;
T = 60;   % [s]
Tf = 120;
w = 2*pi/T; % [rad/s]

T1 = 205.0;             % Lemniscata
T2 =  15.0 + T1;        % Aproxima��o + Emergency
T3 =  15.1 + T2;        % Andando com o Drone pousado
T4 =  5.0 + T3;         % Parando o Pioneer

caso = 1;

% Data variables
kk = 1;
data = zeros(round(T4/T_FORMATION),79); % Data matrix

t  = tic;
t_plot = tic;

t_Formation = tic;      % Formation control
t_Pioneer = tic;        % pioneer cycle
t_ArDrone = tic;        % ardrone cycle
t_integ = tic;

while toc(t)< T4
    % =====================================================================
    if toc(t_Pioneer) > T_PIONEER
        
        t_Pioneer = tic;
        
        P.rGetSensorData;    % Adquirir dados dos sensores - Pioneer
       
        % Controlador Din�mico        
        % Ganhos pr�-definidos
        cgains = [ 0.35  0.35  0.80  0.80  0.75  0.75  0.12  0.035 ];
        
        P = fDynamicController(P,cgains);     % Pioneer Dynamic Compensator        
        
%         P.pSC.Ud = [0; 0];

        % Send control signals to robots
        P.rSendControlSignals;
        
    end
    
    % =====================================================================
    if toc(t_ArDrone) > T_ARDRONE
        
        t_ArDrone = tic;
        
        A.rGetSensorData;    % Adquirir dados dos sensores - ArDrone
        
        % Drone
        A.pPos.Xda = A.pPos.Xd;    % save previous posture
        Agains =   [   0.1    2.00    0.1   2.00   5.00    2.00 ;  1   20   1   15   1   2.5]; % GANHOS QUENTE PELANDO
        A = cUnderActuatedController(A,Agains);  % ArDrone
        
        % Send control signals to robots        
        A.rSendControlSignals;
        
    end
        
    % =====================================================================
    % La�o de controle de forma��o
    if toc(t_Formation) > T_FORMATION
        t_Formation = tic;
        
        P.rGetSensorData;
        A.rGetSensorData;
        
        LF.pPos.X = [P.pPos.X(1:3); A.pPos.X(1:3)];   % Posi��o dos membros da forma��o
        LF.mDirTrans;                                 % Transformada Direta X --> Q
        
        %% Trajectory
        
        if toc(t) < T1
            
            if caso == 1
                fprintf('\n\nCaso 1: Leminiscata\n');
                caso = 2;
            end
            
            t_traj = toc(t);
            a = 3*(t_traj/Tf)^2 - 2*(t_traj/Tf)^3;
            tp = a*Tf;

            LF.pPos.Qda = LF.pPos.Qd;
            
            LF.pPos.Qd(1) = rX*sin(w*tp);                   % xF
            LF.pPos.Qd(2) = rY*sin(2*w*tp);                 % yF
            LF.pPos.Qd(3) = 0.00;                           % zF
            LF.pPos.Qd(4) = 1.50;                           % rho
            LF.pPos.Qd(5) = 0.00;                           % alpha (frente/tr�s)
            LF.pPos.Qd(6) = 0.00;                           % beta  (lateral)
            
            LF.pPos.dQd = (LF.pPos.Qd-LF.pPos.Qda)/LF.pPar.Ts;
            
        elseif toc(t) > T1 && toc(t) < T2
            
            if caso == 2
                fprintf('\n\nCaso 2: Aproxima��o + Emergency\n');
                caso = 3;
            end
            
            t_traj = toc(t);
            a = 3*(t_traj/Tf)^2 - 2*(t_traj/Tf)^3;
            tp = a*Tf;
            
            LF.pPos.Qda = LF.pPos.Qd;
            
            LF.pPos.Qd(1) = rX*sin(w*tp);                   % xF
            LF.pPos.Qd(2) = rY*sin(2*w*tp);                 % yF
            LF.pPos.Qd(3) = 0.00;                           % zF
            LF.pPos.Qd(4) = 0.50;                           % rho
            LF.pPos.Qd(5) = 0.00;                           % alpha (frente/tr�s)
            LF.pPos.Qd(6) = 0.00;                           % beta  (lateral)
                        
            LF.pPos.dQd = (LF.pPos.Qd-LF.pPos.Qda)/LF.pPar.Ts; 
            
        elseif toc(t) > T2 && toc(t) < T3
            
            if caso == 3
                fprintf('\n\nCaso 3: Andando com o Drone pousado\n');
                caso = 4;

            end
            
            t_traj = toc(t) - Tf;
            a = 3*(t_traj/Tf)^2 - 2*(t_traj/Tf)^3;
            tp = a*Tf;
            
            LF.pPos.Qda = LF.pPos.Qd;
            
            LF.pPos.Qd(1) = rX*sin(w*tp);                   % xF
            LF.pPos.Qd(2) = rY*sin(2*w*tp);                 % yF
            LF.pPos.Qd(3) = 0.00;                           % zF
            LF.pPos.Qd(4) = 0.50;                           % rho
            LF.pPos.Qd(5) = 0.00;                           % alpha (frente/tr�s)
            LF.pPos.Qd(6) = 0.00;                           % beta  (lateral)
                        
            LF.pPos.dQd = (LF.pPos.Qd-LF.pPos.Qda)/LF.pPar.Ts; 
            
        end
                
        %% Control
        
        % Formation Control
        LF.pPar.K1 = diag([   20.0   20.0   0    2.0   2.0   2.0   ]);     % kinematic control gain  - controls amplitude
        LF.pPar.K2 = diag([    .1    .1     0    .05    .05    .05   ]);     % kinematic control gain - control saturation
        
        LF.mFormationControl;                           
%         LF.mFormationControl_NullSpace('P');                           
        
        % Atribuindo posi��es desejadas
        % Pioneer
        P.pPos.Xd(1:3) = LF.pPos.Xr(1:3);             % Posi��o desejada
        P.pPos.Xd(7:9) = LF.pPos.dXr(1:3);            % Velocidade desejada

        % ArDrone
        A.pPos.Xda = A.pPos.Xd;    % save previous posture
        A.pPos.Xd(1:3) = LF.pPos.Xr(4:6);
        A.pPos.Xd(7:9) = LF.pPos.dXr(4:6);
                        
        if toc(t) > T3
            
            if caso == 4
                fprintf('\n\nCaso 4: Parando Pioneer\n');
                caso = 5;
            end
            
            LF.pPos.Qd = LF.pPos.Q;
            LF.pPos.dQd = zeros(6,1);
            P.pSC.Ud = [0; 0];
            
        end
               
        % Variable to feed plotResults function    
        data(kk,:) = [  P.pPos.Xd'     P.pPos.X'        P.pSC.Ud(1:2)'    P.pSC.U(1:2)'...
                        A.pPos.Xd'     A.pPos.X'        A.pSC.Ud'         A.pSC.U' ...
                        LF.pPos.Qd'    LF.pPos.Qtil'    LF.pPos.Xr'...
                        toc(t)];
        kk = kk + 1;
        
        % %         %   1 -- 12      13 -- 24     25 -- 26          27 -- 28
        % %             P.pPos.Xd'   P.pPos.X'    P.pSC.Ud(1:2)'    P.pSC.U(1:2)'
        % %
        % %         %   29 -- 40     41 -- 52     53 -- 56          57 -- 60
        % %             A.pPos.Xd'   A.pPos.X'    A.pSC.Ud'         A.pSC.U'
        % %
        % %         %   61 -- 66     67 -- 72       73 -- 78       79
        % %             LF.pPos.Qd'  LF.pPos.Qtil'  LF.pPos.Xd'    toc(t)  ]
        
    end
    
    %% Draw robots
    if toc(t_plot) > T_PLOT
        t_plot = tic;
        try
            delete(fig1);
            delete(fig2);
            delete(fig3);
            delete(fig4);
            delete(fig5);
            delete(pl);
            delete(rho_line);
        catch
        end
        
        % Pioneer
        P.mCADdel
        P.mCADplot(.75,'k');
        
        % ArDrone
        A.mCADplot;
        
        % Percourse made
        fig1 = plot3(data(1:kk,13),data(1:kk,14),data(1:kk,15),'r','LineWidth',1.0);
        fig2 = plot3(data(1:kk,41),data(1:kk,42),data(1:kk,43),'b','LineWidth',1.0);
        fig3 = plot3(data(1:kk,61),data(1:kk,62),data(1:kk,63),'k--','LineWidth',0.5);
        fig4 = plot3(data(1:kk,76),data(1:kk,77),data(1:kk,78),'c--','LineWidth',0.5);
        
        % Plotar linha rhof
        
        xl = [LF.pPos.X(1)   LF.pPos.X(4)];
        yl = [LF.pPos.X(2)   LF.pPos.X(5)];
        zl = [LF.pPos.X(3)   LF.pPos.X(6)];
        
        rho_line = line(xl,yl,zl);
        rho_line.Color = 'g';
        rho_line.LineStyle = '-';
        rho_line.LineWidth = 1.5;
        
        fig5 = plot3(LF.pPos.Xr(4),LF.pPos.Xr(5),LF.pPos.Xr(6),'b.','MarkerSize',20,'LineWidth',1.0);
        
        % Plotar linha rhof das posi��es desejadas
        xl = [LF.pPos.Xr(1)   LF.pPos.Xr(4)];
        yl = [LF.pPos.Xr(2)   LF.pPos.Xr(5)];
        zl = [LF.pPos.Xr(3)   LF.pPos.Xr(6)];
        
        pl = line(xl,yl,zl);
        pl.Color = 'k';
        pl.LineStyle = '--';
        pl.LineWidth = 1.5;
        
        drawnow;
    end
    
end

%% Send control signals
P.pSC.Ud = [0; 0];
P.rSendControlSignals;    % Pioneer

%% Plot results
% % % figure;
plotResultsLineControl(data);

% End of code xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
