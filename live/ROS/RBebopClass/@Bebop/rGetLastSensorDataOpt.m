%    ***************************************************************
%    *    Univeridade Federal do Esp�rito Santo - UFES             *                          
%    *    Course:  Master Science                                  *
%    *    Student: Mauro Sergio Mafra Moreira                      *
%    *    Email:   mauromafra@gmail.com                            *
%    *    Revision: 01                           Data 00/00/2019   *
%    ***************************************************************

% Description:


function rGetLastSensorDataOpt(obj)

% Assing data from rGetStatusRawData
% The output vector is an 8*1 array in which the structure looks like:
% [batteryLevel unit: %                     1
%  pitch        unit: angle    world ref    2
%  roll         unit: angle    world ref    3
%  yaw          unit: angle    world ref    4
%  altitude     unit: meter    surface ref  5
%  Vx           unit: m/s      body ref     6
%  Vy           unit: m/s      body ref     7
%  Vz           unit: m/s      body ref     8
%  Accx         unit: m/s^2    body ref     9
%  Accy         unit: m/s^2    body ref     10
%  Accz         unit: m/s^2    body ref     11
%  gyrox        unit: angle/s  world ref    12
%  gyroy        unit: angle/s  world ref    13
%  gyroz        unit: angle/s  world ref    14

if obj.pFlag.Connected
    
    % --------------------------------------------------------------------
    
    % Read Sensor Data From ROS Server
    % Values between [-1,1]    
    
    % Saturation values
    % pitch           | [-1,1] <==> [-35,35] degrees       -> Y
    % roll            | [-1,1] <==> [-35,35] degrees       -> X
    % altitude rate   | [-1,1] <==> [-6,6] m/s
    % yaw rate        | [-1,1] <==> [-200,200] degrees/s   -> Z
    
    %drone.pOdom = rostopic(drone.pTxtTopic.Echo, drone.pTxtTopic.Odom); 
%     obj.pOdom = obj.subOdom.LatestMessage;

    obj.pPos.Xa = obj.pPos.X;

    obj.pOdom = receive(obj.subOdomOpt);

    % Convert quaternion to Euler angles in radians
    quat = [obj.pOdom.Pose.Pose.Orientation.W
            obj.pOdom.Pose.Pose.Orientation.X
            obj.pOdom.Pose.Pose.Orientation.Y
            obj.pOdom.Pose.Pose.Orientation.Z;];
        
    eulXYZ = quat2eul(quat','XYZ');
    
    
    obj.pPos.X(1)  = obj.pOdom.Pose.Pose.Position.X;   
    obj.pPos.X(2)  = obj.pOdom.Pose.Pose.Position.Y;   
    obj.pPos.X(3)  = obj.pOdom.Pose.Pose.Position.Z;   
%     drone.pPos.X(4)  = drone.pOdom.Pose.Pose.Orientation.X; % Roll   
%     drone.pPos.X(5)  = drone.pOdom.Pose.Pose.Orientation.Y; % Pitch
%     drone.pPos.X(6)  = drone.pOdom.Pose.Pose.Orientation.Z; % Yaw
    obj.pPos.X(4)  = eulXYZ(1); % Roll   
    obj.pPos.X(5)  = eulXYZ(2); % Pitch
    obj.pPos.X(6)  = eulXYZ(3); % Yaw
    
%     for ii = 4:6
%         if abs(obj.pPos.X(ii)) > pi/2
%             if obj.pPos.X(ii) > 0
%             obj.pPos.X(ii) = -2*pi + obj.pPos.X(ii);
%             else 
%             obj.pPos.X(ii) = 2*pi + obj.pPos.X(ii);
%         end
%         end
%     end
    
    %drone.pPos.X(7) = drone.Pose.Pose.Orientation.W;  % Verificar o
    %significado de de w, 
    obj.pPos.X(7)  = obj.pOdom.Twist.Twist.Linear.X *  obj.pPar.uSat(4);
    obj.pPos.X(8)  = obj.pOdom.Twist.Twist.Linear.Y *  obj.pPar.uSat(5);
    obj.pPos.X(9)  = obj.pOdom.Twist.Twist.Linear.Z  * obj.pPar.uSat(3);
    obj.pPos.X(10) = (obj.pPos.X(4) - obj.pPos.Xa(4))/toc(obj.pPar.ti) * obj.pPar.uSat(1);
    obj.pPos.X(11) = (obj.pPos.X(5) - obj.pPos.Xa(5))/toc(obj.pPar.ti) * obj.pPar.uSat(2);
    obj.pPos.X(12) = (obj.pPos.X(6) - obj.pPos.Xa(6))/toc(obj.pPar.ti) * obj.pPar.uSat(3);

    
    % Velocity
    obj.pPos.dX(1)  = obj.pPos.X(7); % Vx [m/s]
    obj.pPos.dX(2)  = obj.pPos.X(8); % Vy [m/s]
    obj.pPos.dX(3)  = obj.pPos.X(9); % Vz [m/s]
    
    obj.pPos.dX(4)  = obj.pPos.X(10); % d(phi)/dt   [rad/s]
    obj.pPos.dX(5)  = obj.pPos.X(11); % d(theta)/dt [rad/s]
    obj.pPos.dX(6)  = obj.pPos.X(12); % d(psi)/dt   [rad/s]

else
    % Simulation    -----------------------------------------------------------------
    obj.pPos.X = obj.pPos.X;
end
