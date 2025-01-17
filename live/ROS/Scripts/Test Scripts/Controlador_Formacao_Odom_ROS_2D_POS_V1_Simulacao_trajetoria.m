%% 3D Line Formation Pioneer-Drone
% Pioneer is the reference of the formation
% The formation variables are:
% Q = [ xf yf zf rho alfa beta ]
% Initial Comands

clear; close all; clc;
try
    fclose(instrfindall);
catch
end

% Look for root folder
PastaAtual = pwd;
PastaRaiz = 'AuRoRA 2018';
cd(PastaAtual(1:(strfind(PastaAtual,PastaRaiz)+numel(PastaRaiz)-1)))
addpath(genpath(pwd))

%% Load Classes

%% Load Class
try
    % Load Classes
    RI = RosInterface;
%     setenv('ROS_IP','192.168.0.101')
%     setenv('ROS_MASTER_URI','192.168.0.103')
    RI.rConnect('192.168.0.102');
    B{1} = Bebop(1,'B1');
    B{2} = Bebop(1,'B2');
        
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
B{1}.rTakeOff;
B{2}.rTakeOff;
pause(3);
disp('Taking Off End Time....');

%% Variable initialization
data1 = [];
qd_hist = [];
q_hist = [];
t_hist = [];
X1_hist = [];
X2_hist = [];
dX1_hist = [];
dX2_hist = [];
U1_hist = [];
U2_hist = [];

B{1}.rGetSensorDataLocal;
B{2}.rGetSensorDataLocal;

% Time variables initialization
T_CONTROL = 0.2; % 200 ms de Amostragem | 5 Hz de Frequ�ncia
T_MAX = 60;

% T = 20;
% w = 2*pi/T;

fprintf('\nStart..............\n\n');

% Parametros dos Controladores 
model = [ 0.8417 0.18227 0.8354 0.17095 3.966 4.001 9.8524 4.7295 ];
%          X     Y     Z    Psi
gains = [  1.2     1.2     2     2 ...
           1.5   1.5   3     2 ...
           1     1     1     1 ...
           1     1     1     1];

% qd = [0 4 5 5 0 pi/6]';
% dqd = [0 0 0 0 0 0]';

% qd = [6 3 5 3 0 0]';
% qd = [0 0 20 5 0 0]';
% dqd = [0 0 0 0 0 0]';

L1 = diag([.5 .5 .5 .5 .5 .6]);
L2 = diag([1 1 1 1 1 1]);
K = diag([.8 .8 .8 .8]);

% Dinamica Interna N�o Modificar
Ku = diag([0.8417 0.8354 3.966 9.8524]);
Kv = diag([0.18227 0.17095 4.001 4.7295]);
 
t_Formation = tic;      % Formation cycle
t_integF = tic;
t_incB = tic;
t  = tic;
t_control = tic;

Vd1A = 0;
Vd2A = 0;

T = 20;
w = 2*pi/T;

try    
    while toc(t) < T_MAX

        if toc(t_control) > T_CONTROL             

            B{1}.pPar.Ts = toc(t_incB);
            B{2}.pPar.Ts = toc(t_incB);
            t_incB = tic;
            t_control = tic;
            
%             if toc(t) > 20
% %                 qd = [0 0 2 9 pi/2 0]';
%                 qd = [0 9 20 5 0 0]';
%                 dqd = [0 0 0 0 0 0]';
%             end

            qd = [(2 + 3*cos(w*toc(t))) (5 + 3*sin(w*toc(t))) 18 2.5 0 -pi/6]';
            dqd = [-w*3*sin(w*toc(t)) w*3*cos(w*toc(t)) 0 0 0 0]';
            
            B{1}.rGetSensorDataLocal;
            B{2}.rGetSensorDataLocal;
            
            rho = norm(B{2}.pPos.X(1:3) - B{1}.pPos.X(1:3));
            alpha = atan2(B{2}.pPos.X(2) - B{1}.pPos.X(2),B{2}.pPos.X(1) - B{1}.pPos.X(1));
            beta = atan2(B{2}.pPos.X(3) - B{1}.pPos.X(3),norm(B{2}.pPos.X(1:2) - B{1}.pPos.X(1:2)));
            q = [B{1}.pPos.X(1) B{1}.pPos.X(2) B{1}.pPos.X(3) rho alpha beta]';
            
            qtil = qd - q;
            
            dqref = dqd + L1*tanh(L2*qtil);
            
            J_inv = [1 0 0           0                       0                          0          ;...
                     0 1 0           0                       0                          0          ;...
                     0 0 1           0                       0                          0          ;...
                     1 0 0 cos(alpha)*cos(beta) -rho*sin(alpha)*cos(beta) -rho*cos(alpha)*sin(beta);...
                     0 1 0 sin(alpha)*cos(beta)  rho*cos(alpha)*cos(beta) -rho*sin(alpha)*sin(beta);...
                     0 0 1       sin(beta)                   0                    rho*cos(beta)    ];
                 
            dXref = J_inv*dqref;
            
            F1 = [  cos(B{1}.pPos.X(6))   -sin(B{1}.pPos.X(6))     0     0; % Cinem�tica direta
                    sin(B{1}.pPos.X(6))    cos(B{1}.pPos.X(6))     0     0;
                            0                      0               1     0;
                            0                      0               0     1];
                        
            F2 = [  cos(B{2}.pPos.X(6))   -sin(B{2}.pPos.X(6))     0     0; % Cinem�tica direta
                    sin(B{2}.pPos.X(6))    cos(B{2}.pPos.X(6))     0     0;
                            0                      0               1     0;
                            0                      0               0     1];
                        
            dXd1 = [dXref(1:3); 0];
            dXd2 = [dXref(4:6); 0];
            
            Vd1 = F1\dXd1;
            Vd2 = F2\dXd2;
            
            %Derivando a velocidade desejada
            dVd1 = (Vd1 - Vd1A)/toc(t_incB);
            dVd2 = (Vd2 - Vd2A)/toc(t_incB);
            
            Vd1A = Vd1;
            Vd2A = Vd2;
            
            %Velocidade do rob� em seu pr�prio eixo
            Vb1 = F1\([B{1}.pPos.X(7:9);B{1}.pPos.X(12)]);
            Vb2 = F2\([B{2}.pPos.X(7:9);B{2}.pPos.X(12)]);
            
            Ud1 = Ku\(dVd1 + K*(Vd1 - Vb1) + Kv*Vb1);
            Ud2 = Ku\(dVd2 + K*(Vd2 - Vb2) + Kv*Vb2);
            
            B{1}.pSC.Ud = [Ud1(1:3)' 0 0 0]';
            B{2}.pSC.Ud = [Ud2(1:3)' 0 0 0]';
            
            % Zerando sinais de controle
%             B{1}.pSC.Ud = [0 0 0 0 0 0]';
%             B{2}.pSC.Ud = [0 0 0 0 0 0]';


            % Beboop
            % Joystick Command Priority
            B{1} = J.mControl(B{1});
            B{2} = J.mControl(B{2});% joystick command (priority)   
            B{1}.rCommand;
            B{2}.rCommand;
            
            data1 = [data1  ; qd'  q' toc(t)];
            qd_hist = [qd_hist; qd'];
            q_hist = [q_hist; q'];
            t_hist = [t_hist; toc(t)];
            X1_hist = [X1_hist; [B{1}.pPos.X(1:3);B{1}.pPos.X(6)]'];
            X2_hist = [X2_hist; [B{2}.pPos.X(1:3);B{2}.pPos.X(6)]'];
            dX1_hist = [dX1_hist; [B{1}.pPos.X(7:9);B{1}.pPos.X(12)]'];
            dX2_hist = [dX2_hist; [B{2}.pPos.X(7:9);B{2}.pPos.X(12)]'];
            U1_hist = [U1_hist; B{1}.pSC.Ud];
            U2_hist = [U2_hist; B{2}.pSC.Ud];
            
            drawnow

            % If push Emergency or ROS Emergency Stop On or Not Rigid Body tracked Stop loop
            if btnEmergencia ~= 0 || B{1}.pFlag.EmergencyStop ~= 0 || B{1}.pFlag.isTracked ~= 1
                disp('Bebop Landing through Emergency Command ');
                B{1}.rCmdStop;
                B{2}.rCmdStop;
                B{1}.rLand
                B{2}.rLand 
                break;
            end  
        end
    end
catch ME
    
    disp('Bebop Landing through Try/Catch Loop Command');
    B{1}.rCmdStop;
    B{2}.rCmdStop;
    B{1}.rLand
    B{2}.rLand         
    disp('');
    disp(ME);
    disp('');
   
end

% Send 3 times Commands 1 second delay to Drone Land
for i=1:nLandMsg
    disp("End Land Command");
    B{1}.rCmdStop;
    B{2}.rCmdStop;
    B{1}.rLand
    B{2}.rLand
end

% Close ROS Interface
RI.rDisconnect;
rosshutdown;

disp("Ros Shutdown completed...");

%%
% qtil = data1(:,1:6) - data1(:,7:end-1);


dataPath = strcat(pwd,'\ROS\Scripts\');
fileName = strcat('Simulacao_Forma��o_Trajetoria_1','.mat');
fullFileName = strcat(dataPath,fileName);
save(fullFileName,'qd_hist','q_hist','t_hist','X1_hist','X2_hist','dX1_hist','dX2_hist','U1_hist','U2_hist');
%%
qtil = qd_hist - q_hist;
figure();
hold on;
grid on;
plot(t_hist,qtil(:,1));
% plot(data1(:,13),qtil(:,2));
% plot(data1(:,13),qtil(:,3));
% plot(data1(:,13),qtil(:,4));
% plot(data1(:,13),qtil(:,5));
% plot(data1(:,13),qtil(:,6));
title('Erro de Posi��o');
legend('Pos X');
xlabel('Tempo[s]');
ylabel('Erro [m]');

figure();
hold on;
grid on;
plot(t_hist,qtil(:,2));
title('Erro de Posi��o');
legend('Pos Y');
xlabel('Tempo[s]');
ylabel('Erro [m]');

figure();
hold on;
grid on;
plot(t_hist,qtil(:,3));
title('Erro de Posi��o');
legend('Pos Z');
xlabel('Tempo[s]');
ylabel('Erro [m]');

figure();
hold on;
grid on;
plot(t_hist,qtil(:,4));
title('Erro de Forma');
legend('Rho');
xlabel('Tempo[s]');
ylabel('Erro [m]');

figure();
hold on;
grid on;
plot(t_hist,qtil(:,5));
title('Erro de Forma');
legend('Alpha');
xlabel('Tempo[s]');
ylabel('Erro [m]');

figure();
hold on;
grid on;
plot(t_hist,qtil(:,6));
title('Erro de Forma');
legend('Beta');
xlabel('Tempo[s]');
ylabel('Erro [m]');

figure();
hold on;
grid on;
plot3(X1_hist(:,1),X1_hist(:,2),X1_hist(:,3));
plot3(X2_hist(:,1),X2_hist(:,2),X2_hist(:,3));
title('Erro de Forma');
legend('Beta');
xlabel('Tempo[s]');
ylabel('Erro [m]');
