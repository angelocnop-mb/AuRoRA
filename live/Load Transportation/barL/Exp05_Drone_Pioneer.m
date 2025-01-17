clear; close all; clc;
try
    fclose(instrfindall);
catch
end
rosshutdown;

%
% % Look for root folder
% PastaAtual = pwd;
% PastaRaiz = 'AuRoRA 2018';
% cd(PastaAtual(1:(strfind(PastaAtual,PastaRaiz)+numel(PastaRaiz)-1)))
% addpath(genpath(pwd))

%% Load Classes

%% Load Class
    % Load Classes
      % Create OptiTrack object and initialize
    OPT = OptiTrack;
    OPT.Initialize;
    
    % Initiate classes
    P = Pioneer3DX(1);
    A = ArDrone(1);
    idP = getID(OPT,P); % ID do Bebop
    idA = getID(OPT,ArDrone);
    
    % Joystick
    J = JoyControl;
    
% Network
r = ROSNetwork;
r.InitROS('/master')
r.InitROS('/robot1','192.168.0.158')
P.pSC.Ud = [0 0]';
r.PublisherROS(r.node,'robot1/vel');

%%%%%%%%%%%%%%%%%%%%%% Bot�o de Emergencia %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nLandMsg = 3;
btnEmergencia = 0;
ButtonHandle = uicontrol('Style', 'PushButton', ...
                         'String', 'land', ...
                         'Callback', 'btnEmergencia=1', ...
                         'Position', [50 50 400 300]);

%% Variable initialization
data = [];

% Time variables initialization
Xd = [0 0 0 0];
dXd = [0 0 0 0];

fprintf('\nStart..............\n\n');

A.pPar.Model_simp = [ 14.72 0.2766 6.233 0.53 2.6504 2.576 .3788 1.5216  ]';
%% Variable Initialization
barL.pPos.X = zeros(6,1);
barL.pPos.Xd = zeros(6,1);
barL.pPos.Xr = zeros(6,1);

barL.pPos.dXr = zeros(6,1);
barL.pPos.dXd = zeros(6,1);

barL.pPos.X_load = zeros(6,1);

barL.pPos.Qd = zeros(6,1);

%% Par�metros da Carga barL 
% Comprimento dos cabos
barL.pPar.l1 = 0;
barL.pPar.l2 = barL.pPar.l1;

% Comprimento da barL
barL.pPar.L = 1.45;  

% Massa da barL
barL.pPar.m = .155;      %Kg

% Bebop e Ardrone Takeoff
disp('Start Take Off Timming....');
A.pPar.ip = '192.168.1.61';
A.rConnect;
A.rTakeOff;
pause(5);
disp('Taking Off End Time....');

%% TAREFA: Posi��o desejada nas vari�veis generalizadas Q = (xc,yc,zc,alpha,gamma,L)
barL.pPos.Qd = [0 0 0 deg2rad(0) deg2rad(45) barL.pPar.L]';

% Transforma��o inversa Q -> X, i.e., (xc,yc,zc,alpha,gamma,L)_d-> (x1,y1,z1,x2,y2,z2)_d
        barL.pPos.Xd(1) = barL.pPos.Qd(1); 
        barL.pPos.Xd(2) = barL.pPos.Qd(2);
        barL.pPos.Xd(3) = barL.pPos.Qd(3);
        barL.pPos.Xd(4) = barL.pPos.Qd(1) + cos(barL.pPos.Qd(5))*sin(barL.pPos.Qd(4))*barL.pPos.Qd(6);
        barL.pPos.Xd(5) = barL.pPos.Qd(2) + cos(barL.pPos.Qd(5))*cos(barL.pPos.Qd(4))*barL.pPos.Qd(6);
        barL.pPos.Xd(6) = barL.pPos.Qd(3) + sin(barL.pPos.Qd(5))*barL.pPos.Qd(6) + barL.pPar.l2;
barL.pPos.dXd = [dXd(1) dXd(2) dXd(3) dXd(1) dXd(2) dXd(3)]';

% Povoando a vari�vel X e X_load da classe
barL.pPos.X = [P.pPos.X(1:3); A.pPos.X(1:3)];
% barL.pPos.X_load = [L{1}.pPos.X(1) L{1}.pPos.X(2) L{1}.pPos.X(3) L{2}.pPos.X(1) L{2}.pPos.X(2) L{2}.pPos.X(3)]';

% C�lculo do erro nos drones
barL.pPos.Xtil = barL.pPos.Xd - barL.pPos.X;

% timers
T_exp = 55; % tempo de experimento
T_run = 1/30; % per�odo de amostragem do experimento
t_run = tic;
t_total = tic; % tempo que o experimento est� rodando (running)
t_plot = tic; % 
T_plot = .3; % per�odo de plotagem
t_task = tic;
T_task = 13;
i_task = 0;
t_exp = tic;


t  = tic;

pgains = [1.5 1 1.5 1];
P.pPar.ti = tic;
A.pPar.ti = tic;
P.pPar.Ts = 1/30;
A.pPar.Ts = 1/30;

% Dados trajet�ria
rX = 1;           % [m]
rY = 1;           % [m]
T = 15;             % [s]
Tf = T*2;            % [s]
w = 2*pi/T;         % [rad/s]

    while toc(t) < T_exp
        
        if toc(t_run) > T_run
            
            t_run = tic;
            t_atual = toc(t);

            
%% TAREFA

%Trajet�ria           
                Xd = [rX*sin(w*t_atual);
                      rY*cos(.5*w*t_atual);
                    0;
                    0];
                
                
                
                dXd = [w*rX*cos(w*t_atual);
                       -.5*w*rY*sin(.5*w*t_atual);
                    0;
                    0];
            
% % Posi��o
%             dXd = [0;
%                 0;
%                 0;
%                 0];
%         
%             if toc(t) < 20
%                 
%                 Xd = [0;
%                     0;
%                     0;
%                     0];                        
%             end
%                     if toc(t) > 20
%                 
%                 Xd = [.5;
%                     .5;
%                     0;
%                     0];                        
%                     end
%                     
%                     if toc(t) > 40
%                 
%                 Xd = [-.5;
%                     -.5;
%                     0;
%                     0];                        
%             end
            

                
% Posi��o desejada nas vari�veis generalizadas Q = (xc,yc,zc,alpha,gamma,L)
        barL.pPos.Qd = [Xd(1) Xd(2) Xd(3) deg2rad(0) deg2rad(45) barL.pPar.L]';

% Transforma��o inversa Q -> X, i.e., (xc,yc,zc,alpha,gamma,L)_d-> (x1,y1,z1,x2,y2,z2)_d
        barL.pPos.Xd(1) = barL.pPos.Qd(1); 
        barL.pPos.Xd(2) = barL.pPos.Qd(2);
        barL.pPos.Xd(3) = barL.pPos.Qd(3);
        barL.pPos.Xd(4) = barL.pPos.Qd(1) + cos(barL.pPos.Qd(5))*sin(barL.pPos.Qd(4))*barL.pPos.Qd(6);
        barL.pPos.Xd(5) = barL.pPos.Qd(2) + cos(barL.pPos.Qd(5))*cos(barL.pPos.Qd(4))*barL.pPos.Qd(6);
        barL.pPos.Xd(6) = barL.pPos.Qd(3) + sin(barL.pPos.Qd(5))*barL.pPos.Qd(6) + barL.pPar.l2;
        barL.pPos.dXd = [dXd(1) dXd(2) dXd(3) dXd(1) dXd(2) dXd(3)]';


% Povoando a vari�vel X e X_load da classe
        barL.pPos.X = [P.pPos.X(1:3); A.pPos.X(1:3)];
%         barL.pPos.X_load = [L{1}.pPos.X(1) L{1}.pPos.X(2) L{1}.pPos.X(3) L{2}.pPos.X(1) L{2}.pPos.X(2) L{2}.pPos.X(3)]';

% C�lculo do erro nos drones
        barL.pPos.Xtil = barL.pPos.Xd - barL.pPos.X;
    
%% LEITURA DE POSI��O E VELOCIDADE
       
% OPTITRACK
        rb = OPT.RigidBody;
        if rb(idP).isTracked
            P = getOptData(rb(idP),P);
        end
%         
        if rb(idA).isTracked
            A = getOptData(rb(idA),A);
        end       


%% CONTROLE DIN�MICO DOS ROB�S
% Atribuindo trajet�ria
        P.pPos.Xd(1:2) = barL.pPos.Xd(1:2);
        A.pPos.Xd(1:3) = barL.pPos.Xd(4:6);
        
        P.pPos.Xd(7:8) = barL.pPos.dXd(1:2);
        A.pPos.Xd(7:9) = barL.pPos.dXd(4:6);

% Controladores         

% Pioneer
        P = fControladorCinematico(P,pgains);
        
        
% ArDrone
        if size(data,1) > 60 && A.pSC.Control_flag == 0
            A.pSC.Control_flag = 1;
        end
%           A = cInverseDynamicController_Compensador_ArDrone(A);
        A = cInverseDynamicController_Adaptativo_ArDrone(A);

          
        P.pPar.ti = tic;
        A.pPar.ti = tic;
        
        
% Atribuindo comandos
        A = J.mControl(A);                    % joystick command (priority)
        A.rSendControlSignals;
        r.SendROS('robot1/vel',P.pSC.Ud);
%% DATA            
            data = [  data  ; P.pPos.Xd(1:3)'     P.pPos.X(1:3)' ...
                              A.pPos.Xd(1:3)'     A.pPos.X(1:3)' zeros(6,1)'  ...
                              zeros(8,1)'  A.pPar.Model_simp' t_atual];
            
            %         %   1 -- 3      4 -- 6     
            %         B{1}.pPos.Xd'  B{1}.pPos.X' 
            %
            %         %   7 -- 9     10 -- 12        13 -- 18
            %         B{2}.pPos.Xd'  B{2}.pPos.X' barL.pPos.X_load'
            %
            %         %  19 -- 26             27 -- 34          35
            %      B{1}.pPar.Model_simp  B{2}.pPar.Model_simp  toc(t) ];
            
%% EMERG�NCIA
        drawnow
        if btnEmergencia == 1
            P.pFlag.EmergencyStop = 1;
        end
    
        if btnEmergencia ~= 0 || P.pFlag.EmergencyStop ~= 0 || A.pFlag.EmergencyStop ~= 0
            disp('Pioneer stopping by  ');

            % Send 3 times Commands 1 second delay to Drone Land
            for i=1:nLandMsg
                P.pSC.Ud = [0 0]';
                r.SendROS('robot1/vel',P.pSC.Ud);
                A.rLand;
            end
            break;
        end   
            
        end
    end
%% EMERG�NCIA FORA DO LA�O    
    for i=1:nLandMsg
        P.pSC.Ud = [0 0]';
        r.SendROS('robot1/vel',P.pSC.Ud);
        A.rLand;

    end
    
A.rLand;
        
%% PLOT
B1_Xtil = data(:,1:3) - data(:,4:6);
B2_Xtil = data(:,7:9) - data(:,10:12);
Load_Xtil = [data(:,1:3) - data(:,13:15) data(:,7:9) - data(:,16:18)];
Load_Xtil(:,[3 6]) = Load_Xtil(:,[3 6]) - barL.pPar.l1;


% 
figure();
hold on;
grid on;
plot(data(:,35),B1_Xtil(:,1));
plot(data(:,35),B1_Xtil(:,2));
plot(data(:,35),B1_Xtil(:,3));
title('Erro de Posi��o Q1');
legend('Pos X','Pos Y','Pos Z');
xlabel('Tempo[s]');
ylabel('Erro [m]');

figure();
hold on;
grid on;
plot(data(:,35),B2_Xtil(:,1));
plot(data(:,35),B2_Xtil(:,2));
plot(data(:,35),B2_Xtil(:,3));
title('Erro de Posi��o Q2');
legend('Pos X','Pos Y','Pos Z');
xlabel('Tempo[s]');
ylabel('Erro [m]');
% 
% figure();
% hold on;
% grid on;
% plot(data(:,35),Load_Xtil(:,1));
% plot(data(:,35),Load_Xtil(:,2));
% plot(data(:,35),Load_Xtil(:,3));
% title('Erro de Posi��o L1');
% legend('Pos X','Pos Y','Pos Z');
% xlabel('Tempo[s]');
% ylabel('Erro [m]');
% 
% figure();
% hold on;
% grid on;
% plot(data(:,35),Load_Xtil(:,4));
% plot(data(:,35),Load_Xtil(:,5));
% plot(data(:,35),Load_Xtil(:,6));
% title('Erro de Posi��o L2');
% legend('Pos X','Pos Y','Pos Z');
% xlabel('Tempo[s]');
% ylabel('Erro [m]');


% % 
% % figure();
% % hold on;
% % grid on;
% % plot(data(:,1),data(:,2));
% % plot(data(:,13),data(:,14));
% % title('XY');
% % xlabel('X [m]');
% % ylabel('Y [m]');
% % 
% % figure();
% % subplot(411)
% % hold on;
% % grid on;
% % plot(data(:,35),data(:,19));
% % plot(data(:,35),data(:,7));
% % xlabel('Tempo[s]');
% % ylabel('Velocidade [m/s]');
% % legend('dX', 'dXd');
% % 
% % subplot(412)
% % hold on;
% % grid on;
% % plot(data(:,35),data(:,20));
% % plot(data(:,35),data(:,8));
% % xlabel('Tempo[s]');
% % ylabel('Velocidade [m/s]');
% % legend('dY', 'dYd');
% % 
% % subplot(413)
% % hold on;
% % grid on;
% % plot(data(:,35),data(:,21));
% % plot(data(:,35),data(:,9));
% % xlabel('Tempo[s]');
% % ylabel('Velocidade [m/s]');
% % legend('dZ', 'dZd');
% % 
% % subplot(414)
% % hold on;
% % grid on;
% % plot(data(:,35),data(:,24));
% % plot(data(:,35),data(:,12));
% % xlabel('Tempo[s]');
% % ylabel('Velocidade [rad/s]');
% % legend('phi', 'dphi');
% % 
% % 
figure();
sgtitle('Q1')
subplot(311)
hold on;
grid on;
plot(data(:,end),data(:,4));
plot(data(:,end),data(:,1));
xlabel('Tempo[s]');
ylabel('Erro posi��o [m]');
legend('X', 'Xd');

subplot(312)
hold on;
grid on;
plot(data(:,end),data(:,5));
plot(data(:,end),data(:,2));
xlabel('Tempo[s]');
ylabel('Erro posi��o [m]');
legend('Y', 'Yd');

subplot(313)
hold on;
grid on;
plot(data(:,end),data(:,6));
plot(data(:,end),data(:,3));
xlabel('Tempo[s]');
ylabel('Erro posi��o [m]');
legend('Z', 'Zd');


figure();
sgtitle('Q2')
subplot(311)
hold on;
grid on;
plot(data(:,end),data(:,10));
plot(data(:,end),data(:,7));
xlabel('Tempo[s]');
ylabel('Erro posi��o [m]');
legend('X', 'Xd');

subplot(312)
hold on;
grid on;
plot(data(:,end),data(:,11));
plot(data(:,end),data(:,8));
xlabel('Tempo[s]');
ylabel('Erro posi��o [m]');
legend('Y', 'Yd');

subplot(313)
hold on;
grid on;
plot(data(:,end),data(:,12));
plot(data(:,end),data(:,9));
xlabel('Tempo[s]');
ylabel('Erro posi��o [m]');
legend('Z', 'Zd');
% 
% figure();
% subplot(421)
% grid on;
% plot(data(:,35),data(:,19));
% xlabel('Tempo[s]');
% ylabel('$K_1$','interpreter','latex')
% legend(['$K_1 = $' num2str(data(end,19))],'interpreter','latex')
% 
% subplot(422)
% grid on;
% plot(data(:,35),data(:,20));
% xlabel('Tempo[s]');
% ylabel('$K_2$','interpreter','latex')
% legend(['$K_2 = $' num2str(data(end,20))],'interpreter','latex')
% 
% subplot(423)
% grid on;
% plot(data(:,35),data(:,21));
% xlabel('Tempo[s]');
% ylabel('$K_3$','interpreter','latex')
% legend(['$K_3 = $' num2str(data(end,21))],'interpreter','latex')
% 
% subplot(424)
% grid on;
% plot(data(:,35),data(:,22));
% xlabel('Tempo[s]');
% ylabel('$K_4$','interpreter','latex')
% legend(['$K_4 = $' num2str(data(end,22))],'interpreter','latex')
% 
% subplot(425)
% grid on;
% plot(data(:,35),data(:,23));
% xlabel('Tempo[s]');
% ylabel('$K_5$','interpreter','latex')
% legend(['$K_5 = $' num2str(data(end,23))],'interpreter','latex')
% 
% subplot(426)
% hold on;
% grid on;
% plot(data(:,35),data(:,24));
% xlabel('Tempo[s]');
% ylabel('$K_6$','interpreter','latex')
% legend(['$K_6 = $' num2str(data(end,24))],'interpreter','latex')
% 
% subplot(427)
% hold on;
% grid on;
% plot(data(:,35),data(:,25));
% xlabel('Tempo[s]');
% ylabel('$K_7$','interpreter','latex')
% legend(['$K_7 = $' num2str(data(end,25))],'interpreter','latex')
% 
% subplot(428)
% hold on;
% grid on;
% plot(data(:,35),data(:,26));
% xlabel('Tempo[s]');
% ylabel('$K_8$','interpreter','latex')
% legend(['$K_8 = $' num2str(data(end,26))],'interpreter','latex')

figure();
subplot(421)
grid on;
plot(data(:,35),data(:,27));
xlabel('Tempo[s]');
ylabel('$K_1$','interpreter','latex')
legend(['$K_1 = $' num2str(data(end,27))],'interpreter','latex')

subplot(422)
grid on;
plot(data(:,35),data(:,28));
xlabel('Tempo[s]');
ylabel('$K_2$','interpreter','latex')
legend(['$K_2 = $' num2str(data(end,28))],'interpreter','latex')

subplot(423)
grid on;
plot(data(:,35),data(:,29));
xlabel('Tempo[s]');
ylabel('$K_3$','interpreter','latex')
legend(['$K_3 = $' num2str(data(end,29))],'interpreter','latex')

subplot(424)
grid on;
plot(data(:,35),data(:,30));
xlabel('Tempo[s]');
ylabel('$K_4$','interpreter','latex')
legend(['$K_4 = $' num2str(data(end,30))],'interpreter','latex')

subplot(425)
grid on;
plot(data(:,35),data(:,31));
xlabel('Tempo[s]');
ylabel('$K_5$','interpreter','latex')
legend(['$K_5 = $' num2str(data(end,31))],'interpreter','latex')

subplot(426)
hold on;
grid on;
plot(data(:,35),data(:,32));
xlabel('Tempo[s]');
ylabel('$K_6$','interpreter','latex')
legend(['$K_6 = $' num2str(data(end,32))],'interpreter','latex')

subplot(427)
hold on;
grid on;
plot(data(:,35),data(:,33));
xlabel('Tempo[s]');
ylabel('$K_7$','interpreter','latex')
legend(['$K_7 = $' num2str(data(end,33))],'interpreter','latex')

subplot(428)
hold on;
grid on;
plot(data(:,35),data(:,34));
xlabel('Tempo[s]');
ylabel('$K_8$','interpreter','latex')
legend(['$K_8 = $' num2str(data(end,34))],'interpreter','latex')


%% Send control signals
P.pSC.Ud = [0  ;  0];
for ii = 1:50
 r.SendROS('robot1/vel',P.pSC.Ud);
end
