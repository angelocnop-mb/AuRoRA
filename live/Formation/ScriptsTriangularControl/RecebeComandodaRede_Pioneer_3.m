%% RECEBE COMANDOS PELA REDE E ENVIA DADOS DOS SENSORES
% Este programa apenas recebe comandos enviados de outro pc e os repassa ao
% pioneer. Al�m disso, envia para rede dados dos sensores do rob� (u e w)

clear
close all
clc
% Fecha todas poss�veis conex�es abertas
try
    fclose(instrfindall);
catch
end

%% Rotina para buscar pasta raiz
PastaAtual = pwd;
PastaRaiz = 'AuRoRA 2018';
cd(PastaAtual(1:(strfind(PastaAtual,PastaRaiz)+numel(PastaRaiz)-1)))
addpath(genpath(pwd))

%% Classes initialization
% Robot

serverID = 1; % Rob� Servidor
slaveID = 4; % Rob� Escravo

P = Pioneer3DX(slaveID);   % the ID must be diferent of the pioneer in the server machine to avoid conflict on NetDataShare

% Network data share
Rede =  NetDataShare;

%% Connect with robot or simulator MobileSim
P.rConnect;

%% Network communication check
% Only enter the loop after exchange data with server machine
tm = tic;
while true
    
    if isempty(Rede.pMSG.getFrom)
        Rede.mSendMsg(P);
        if toc(tm) > 0.100
            tm = tic;
            Rede.mReceiveMsg;
            disp('Waiting for message......')
        end
        
    elseif length(Rede.pMSG.getFrom) > 1
        
        if isempty(Rede.pMSG.getFrom{serverID})
            Rede.mSendMsg(P);
            Rede.mReceiveMsg;
            disp('Waiting for message......')
        else
            break
        end
    end
end
clc
disp('Data received. Continuing the program...');

%% Define robot initial position
X = Rede.pMSG.getFrom{serverID}(14+(1:12));  % get position from network (optitrack)
P.rSetPose(X([1 2 3 6]));             % set initial position

%% Variables initialization
% Time variables
tsim = 120;   % maximum simulation time
t    = tic;   % simulation current time
tc   = tic;   % sample time to send data to robot
tr   = tic;   % timer to reset pioneer pose
% Simulation data
data = [];    % save simulation data

%% Simulation
while true % toc(t) < tsim
    
    if toc(tc) > 0.030
        tc = tic;
        
        % Read sensors data
        P.rGetSensorData;
        
        % Send data to network
        Rede.mSendMsg(P);
        
        % Read Network
        Rede.mReceiveMsg;
        
        % Assign variables
        if ~isempty(Rede.pMSG.getFrom{serverID})
            
            P.pPos.Xd = Rede.pMSG.getFrom{serverID}(2+(1:12));    % desired [for plot purposes only]
            P.pSC.Ud  = Rede.pMSG.getFrom{serverID}(27:28);       % control signal
            X         = Rede.pMSG.getFrom{serverID}(14+(1:12));   % traveled (optitrack) [to correct odometry]
            
        end
        
        % Send commands to pioneer
        P.rSendControlSignals;

     end
    % Reset pioneer position periodically
    %     if toc(tr)> 10 && ~isempty(X)
    if toc(tr)> 1/30 && ~isempty(X)
        
        X(3) = 0;                             % z value from optitrack may be different non-zero
        P.rSetPose(X([1 2 3 6]));             % assign initial position
    end
    
end

%%  Stop
% Zera velocidades do rob�
P.pSC.Ud = [0 ; 0];
P.rSendControlSignals;


