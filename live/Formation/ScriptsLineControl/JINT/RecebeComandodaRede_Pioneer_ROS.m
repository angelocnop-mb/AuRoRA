%% Communication code between Pioneer and a Host using ROS 

% Valentim Ernandes Neto
% Date: jun-23-2019

% Work developed to Journal of Intelligent & Robotic Systems (JINT), with 
% a special section on Unmanned Systems. 

% ISSN: 0921-0296 (Print) 1573-0409 (Online)
% Publisher: Springer Netherlands
% Impact Factor: 2.020

% ----------------------------------------------------------------------- %

% Initial Comands
clear;
close all;
clc;

try
    fclose(instrfindall);
catch
end

PastaAtual = pwd;
PastaRaiz = 'AuRoRA 2018';
cd(PastaAtual(1:(strfind(PastaAtual,PastaRaiz)+numel(PastaRaiz)-1)))
addpath(genpath(pwd))

%% Load Classes
% Pioneer ID
ID = 1;
ID = num2str(ID);
% Loop increment
inc = 0.030;

try
    
    % ROS
    % Connect to a ROS network. Start global node at given IP and NodeName
    masterHost = '192.168.0.144';
    rosinit(masterHost, 'NodeHost','192.168.0.200',...
            'NodeName','/DELL_VALENTIM');
    fprintf('\n');
    % Defining publishers and subscribers for all related topics
    % Subscribers
    topic_Ud = rossubscriber(['/P',ID,'/Ud','geometry_msgs/Twist']);
        
catch EM
    
    fprintf('\n\nThe global ROS node is already initialized and connected to the master. \n\n');
    rosshutdown;
    fprintf('\n   ----> Shutdown completed...\n\n');

    fprintf('\n   ----> Trying to initializate global node again...\n\n');
    % ROS
    % Connect to a ROS network. Start global node at given IP and NodeName
    masterHost = '192.168.0.144';
    rosinit(masterHost, 'NodeHost','192.168.0.200',...
            'NodeName','/DELL_VALENTIM');
    fprintf('\n');
    
    % Defining publishers and subscribers for all related topics
    % Subscribers
    topic_Ud = rossubscriber(['/P',ID,'/Ud'],'geometry_msgs/Twist');
          
end

try

    % Pioneer
    P = Pioneer3DX(1); % Create the robot
    P.pPar.Ts = inc; % Loop increment
    P.rConnect;        % Connect to the robot
    nStopMsg = 5; % Number of redundant landing messages.

    fprintf('\n\n------------------------   Load Class Success   ------------------------\n');
    
catch EM
    
    fprintf('\n\n-------------------------   Load Class Issue   -------------------------\n');
    disp(EM);
    
    rosshutdown;
    return;
    
end


%% Main loop
fprintf('\n   ----> Simulation running....\n');
fprintf('\n         ...  ...  ...  ...  ...  ...  ...  ...  ...\n\n');

data = [];

tcontrol = tic; % General control loop timer
try
while true
    if toc(tcontrol) > P.pPar.Ts
        tcontrol = tic;
        try
           
            msg_Ud = topic_Ud.LatestMessage;
            P.pSC.Ud(1) = msg_Ud.Linear.X;
            P.pSC.Ud(2) = msg_Ud.Angular.Z;
            P.rSendControlSignals; 

% % %             disp(P.pSC.Ud(1));
% % %             disp(P.pSC.Ud(2));
% % %             disp('');
                
        catch
        end
        
        data = [data, P.pSC.U(1:2)'];
        
    end
end
catch EM
    
    disp(EM);
    fprintf('\n   ----> Pioneer Stopping through Try/Catch Loop Command\n');
    P.pSC.Ud = [0  ;  0];
    P.rSendControlSignals;
    
end

%% Stopping Pioneer
fprintf('\n-----------------------------   The End   ------------------------------\n');

for i=1:nStopMsg

fprintf(['\n   ----> Pioneer Stop Command (' num2str(i) ')\n']);
P.pSC.Ud = [0 ; 0];
P.rSendControlSignals;

end
rosshutdown;
fprintf('\n   ----> Shutdown completed...\n\n');