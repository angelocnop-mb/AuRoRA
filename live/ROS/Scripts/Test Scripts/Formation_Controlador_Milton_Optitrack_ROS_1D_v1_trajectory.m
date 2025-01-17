%% 3D Line Formation Pioneer-Drone
% Pioneer is the reference of the formation
% The formation variables are:
% Q = [ xf yf zf rho alfa beta ]
% Initial Comands

clear; close all; clc;
% try
%     fclose(instrfindall);
% catch
% end
%
% % Look for root folder
% PastaAtual = pwd;
% PastaRaiz = 'AuRoRA 2018';
% cd(PastaAtual(1:(strfind(PastaAtual,PastaRaiz)+numel(PastaRaiz)-1)))
% addpath(genpath(pwd))

%% Load Classes

%% Load Class
try
    % Load Classes
    RI = RosInterface;
    RI.rConnect('192.168.0.144');
    B = Bebop(1,'B1');
    
    %P = Pioneer3DX(1);  % Pioneer Instance
    
    % Joystick
    J = JoyControl;
    
    % Create OptiTrack object and initialize
    OPT = OptiTrack;
    OPT.Initialize;
    
    disp('################### Load Class Success #######################');
    
catch ME
    disp(' ');
    disp(' ################### Load Class Issues #######################');
    disp(' ');
    disp(' ');
    disp(ME);
    
    RI.rDisconnect;
    rosshutdown;
    return;
    
end



%%%%%%%%%%%%%%%%%%%%%% Bot�o de Emergencia %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nLandMsg = 3;
btnEmergencia = 0;
ButtonHandle = uicontrol('Style', 'PushButton', ...
    'String', 'land', ...
    'Callback', 'btnEmergencia=1', ...
    'Position', [50 50 400 300]);
% Beboop
disp('Start Take Off Timming....');
B.rTakeOff;
pause(3);
disp('Taking Off End Time....');

%% Variable initialization
data = [];

% Time variables initialization
T_CONTROL = 0.2; % 200 ms de Amostragem | 5 Hz de Frequ�ncia
T_MAX = 60;

% T = 20;
% w = 2*pi/T;
% dXd_max = diag([w w 0.0 0.0]);

% dXd = [0 0 0 0];
% xp = [0 0 0 0];

rX = .5;           % [m]
rY = .5;           % [m]
T = 20;             % [s]
Tf = T*2;            % [s]
w = 2*pi/T;         % [rad/s]

% dXd_max = diag([w*6*rX 2*w*6*rY w*0.5 0.0]);
dXd_max = diag([w*rX 0.5*w*rY w*0.5 w*pi/6]);

Xd = [0 0 0 0];
dXd = [0 0 0 0];

fprintf('\nStart..............\n\n');

pause(5)

t_Formation = tic;      % Formation cycle
t_integF = tic;
t_incB = tic;
t  = tic;
t_control = tic;
B.pPar.ti = tic;

try
    while toc(t) < T_MAX
        
        if toc(t_control) > T_CONTROL
            
            t_control = tic;
%             t_traj = toc(t);
%             a = 3*(t_traj/Tf)^2 - 2*(t_traj/Tf)^3;
%             tp = a*Tf;
            
            % Trajectory Planner
            %             Xd = [cos(w*toc(t)) sin(w*toc(t)) 1.5 0]';
            %             dXd = [-w*sin(w*toc(t)) w*cos(w*toc(t)) 0 0]';
            %             ddXd = [-w^2*cos(w*toc(t)) -w^2*sin(w*toc(t)) 0 0]';
            
            %             Xd = [0 0 1 0]';
            %             dXd = [0 0 0 0]';
            %             ddXd = [0 0 0 0]';
            %
            
            Xd = [rX*sin(w*toc(t));
                rY*cos(0.5*w*toc(t));
                1.25 + 0.5*sin(w*toc(t));
                pi/6*sin(w*toc(t))];
            
            xdp_old = dXd;
            
            dXd = [w*rX*cos(w*toc(t));
                -0.5*w*rY*sin(0.5*w*toc(t));
                w*0.5*cos(w*toc(t));
                w*pi/6*cos(w*toc(t))];
            
            ddXd = [ (dXd(1) - xdp_old(1))/toc(t_incB) ...
                (dXd(2) - xdp_old(2))/toc(t_incB) ...
                -w^2*0.5*sin(w*toc(t)) ...
                0]';
            
% % %             Xd = [ rX*sin(w*tp) ...
% % %                 rY*sin(2*w*tp) ...
% % %                 1.25 + 0.5*sin(w*tp) ...
% % %                 0]';
% % %             
% % %             xdp_old = dXd;
% % %             dXd = [  w*6*((t_traj/Tf)-(t_traj/Tf)^2)*rX*cos(w*tp) ...
% % %                 2*w*6*((t_traj/Tf)-(t_traj/Tf)^2)*rY*cos(2*w*tp)...
% % %                 w*0.5*cos(w*tp) ...
% % %                 0]';
% % %             
% % %             ddXd = [ (dXd(1) - xdp_old(1))/toc(t_incB) ...
% % %                 (dXd(2) - xdp_old(2))/toc(t_incB) ...
% % %                 -w^2*0.5*sin(w*tp) ...
% % %                 0]';
            
            
            % Ardrone
            B.rGetSensorDataOpt;
            
            % Encontrando velocidade angular
            B.pPos.X(12) = (B.pPos.X(6) - B.pPos.Xa(6))/toc(t_incB);
            t_incB = tic;
            
            B.pPos.Xd(1:3) = Xd(1:3);
            B.pPos.Xd(6) = Xd(4);
            
            B.pPos.Xd(7:9) = dXd(1:3);
            B.pPos.Xd(12) = dXd(4);
            
            B.pPos.dXd(7:9) = ddXd(1:3);
            B.pPos.dXd(12) = ddXd(4);
            
%             B.cInverseDynamicController_Milton(dXd_max);
            B.cInverseDynamicController;
            B.pPar.ti = tic;
            
            %% Save data
            
            % Variable to feed plotResults function
            data = [  data  ; B.pPos.Xd'     B.pPos.X'        B.pSC.Ud'         B.pSC.U' ...
                toc(t)];
            
            % %         %   1 -- 12      13 -- 24     25 -- 26          27 -- 28
            % %             P.pPos.Xd'   P.pPos.X'    P.pSC.Ud(1:2)'    P.pSC.U(1:2)'
            % %
            % %         %   29 -- 40     41 -- 52     53 -- 56          57 -- 60
            % %             B.pPos.Xd'   B.pPos.X'    B.pSC.Ud'         B.pSC.U'
            % %
            % %         %   61 -- 66     67 -- 72       73 -- 78       79
            % %             LF.pPos.Qd'  LF.pPos.Qtil'  LF.pPos.Xd'    toc(t)  ];
            
            
            % Beboop
            % Joystick Command Priority
            B = J.mControl(B);                    % joystick command (priority)
            B.rCommand;
            
            % If push Emergency or ROS Emergency Stop On or Not Rigid Body tracked Stop loop
            if btnEmergencia ~= 0 || B.pFlag.EmergencyStop ~= 0 || B.pFlag.isTracked ~= 1
                disp('Bebop Landing through Emergency Command ');

                % Send 3 times Commands 1 second delay to Drone Land
                for i=1:nLandMsg
                    disp("End Land Command");
                    B.rCmdStop;
                    B.rLand;
                end
                break;
            end
            
            
        end
    end
catch ME
    
    disp('Bebop Landing through Try/Catch Loop Command');
    B.rCmdStop;
    disp('');
    disp(ME);
    disp('');
    B.rLand
    
end

% Send 3 times Commands 1 second delay to Drone Land
for i=1:nLandMsg
    disp("End Land Command");
    B.rCmdStop;
    B.rLand
end

% Close ROS Interface
RI.rDisconnect;
rosshutdown;

disp("Ros Shutdown completed...");

%% Plot results
Xtil = data(:,1:12) - data(:,13:24);

figure();
hold on;
grid on;
plot(data(:,35),Xtil(:,1));
plot(data(:,35),Xtil(:,2));
plot(data(:,35),Xtil(:,3));
plot(data(:,35),Xtil(:,6));
title('Erro de Posi��o');
legend('Pos X','Pos Y','Pos Z', 'Ori Z');
xlabel('Tempo[s]');
ylabel('Erro [m]');

figure();
hold on;
grid on;
plot(data(:,1),data(:,2));
plot(data(:,13),data(:,14));
title('XY');
xlabel('X [m]');
ylabel('Y [m]');

figure();
subplot(311)
hold on;
grid on;
plot(data(:,35),data(:,7));
plot(data(:,35),data(:,19));
xlabel('Tempo[s]');
ylabel('Velocidade [m/s]');
legend('dX', 'dXd');

subplot(312)
hold on;
grid on;
plot(data(:,35),data(:,8));
plot(data(:,35),data(:,20));
xlabel('Tempo[s]');
ylabel('Velocidade [m/s]');
legend('dY', 'dYd');

subplot(313)
hold on;
grid on;
plot(data(:,35),data(:,9));
plot(data(:,35),data(:,21));
xlabel('Tempo[s]');
ylabel('Velocidade [m/s]');
legend('dZ', 'dZd');

% figure
% hold on
% plot(tempo,poses(:,1))
% plot(tempo,poses(:,2))
% title('Posicoes')
% legend('Pos X','Pos Y','Pos Z', 'Ori Z');
% xlabel('Tempo(s)');
% ylabel('Pos');
% hold off
