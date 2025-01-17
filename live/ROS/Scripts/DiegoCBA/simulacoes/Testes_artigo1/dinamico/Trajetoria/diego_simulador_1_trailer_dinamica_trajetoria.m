clear all
close all
clc

% Vari�veis do Rob�
X_robo = zeros(6,1); % posicao atual do robo
X_trailer1 = zeros(6,1); % posicao atual do trailer1
Xd_trajetoria = zeros(6,1); % posicoes desejadas da trajetoria
Vd_trajetoria = zeros(6,1); % velocidades desejadas da trajetoria
Xtil = zeros(6,1); % Erros robo
Xtil_trailer1 = zeros(6,1); % Erros trailer 1
velocidade = zeros(4,1); % Velocidades controle
U_robo = zeros(6,1); % Comandos do Rob�
U_trailer1 = zeros(6,1); % Comandos do trailer1
dX_robo = zeros(6,1); % Variacoes posicoes do robo entre interacoes
dX_trailer1 = zeros(6,1);% Variacoes posicoes do trailer1 entre interacoes
U1_robo_anterior = 0;
U3_robo_anterior = 0;
K_vel = zeros(5,2);

% Cinem�tica estendida do pioneer
alpha = pi;
sat_v = 0.75;
sat_w = 100*pi/180;
b = 0.2;

% Variaveis para plot corpo
raio = 0.15;
circ = 0:0.01:2*pi;

% Variaveis de Ganho
K_1 = 0.8*diag([1 1]);
K_2 = 0.8*diag([1 1]);
k_u = 4;
k_w = 4;

% Vari�veis de Tempo
t = tic; % Temporizador de experimento
t_sim = tic; % Temporizador de simula��o
t_der = tic; % Temporizador de derivada
t_derivada2 = tic;
t_derivada = tic;
T_CONTROL = 1/10;
t_control = tic;
t_sim = tic; % Temporizador de simula��o

% thetas primeira identificacao - so pioneer
% theta_1 = 0.23025;
% theta_2 = 0.22615;
% theta_3 = 0.00028953;
% theta_4 = 0.95282;
% theta_5 = 0.021357;
% theta_6 = 0.95282;

% thetas primeira identificacao - pioneer + 1 trailer
% theta_1 = 0.076806;
% theta_2 = -0.016926;
% theta_3 = -0.32221;
% theta_4 = 0.82964;
% theta_5 = 0.096731;
% theta_6 = 0.91348;

% thetas identificacao joystick - pioneer + 1 trailer
% theta_1 = 0.023615;
% theta_2 = -0.0030998;
% theta_3 = -0.00062977;
% theta_4 = -0.028674;
% theta_5 = -0.31175;
% theta_6 = 0.71322;

% thetas identificacao De la Cruz- so pioneer com camera e laser em cima
% theta_1 = 0.26038;
% theta_2 = 0.25095;
% theta_3 = -0.00049969;
% theta_4 = 0.99646;
% theta_5 = 0.002629;
% theta_6 = 1.0768;

% theta_1 = 0.29844;
% theta_2 = 0.1221;
% theta_3 = -0.018223;
% theta_4 = 0.86781;
% theta_5 = -0.04395;
% theta_6 = 0.85486;

theta_1=0.23882;
theta_2=0.23938;
theta_3=0.0038418;
theta_4=0.9435;
theta_5=-0.007849;
theta_6=0.92249;

Theta = [theta_1;theta_2;theta_3;theta_4;theta_5;theta_6];

% Vari�veis de hist�rico
t_hist = [];
X_robo_hist = [];
Xtil_hist = [];
Xd_trajetoria_hist = [];
dX_robo_hist = [];
dX_trailer1_hist = [];
X_trailer1_hist = [];
Xtil_trailer1_hist = [];
theta_1_hist = [];

% Variaveis da trajetoria
%%%%% tempos limites para comparacao - tamanho lab - TMAX_lem = 50s/TMAX_cir = 35s
%%%%% dinamico - circulo chega ate 30s / lemniscata chega ate 40s / 
T_MAX = 30;
rX_l = 2;           % [m]
rY_l = 1.5;           % [m]
rX_c = 2;           % [m]
rY_c = 2;           % [m]
T = T_MAX;             % [s]
w = 2*pi/T;         % [rad/s]
ww = 1*w;
phase = 0;

%%% dimensoes trailers
L0 = 0.3;
L1 = 0.455;
%%% dimensoes trailers simulacao
ret_lg = 0.415;
ret_lp = 0.285;

sat_angulo = pi/2;

theta_1 = X_robo(4);
X_robo([1 2 4]) = [-(b+L1+L0)*(1-cos(0)) (b+L1+L0-0)*sin(0)-0.5 0];
X_trailer1(4) = 0;

while toc(t) < T_MAX
    if toc(t_control) > T_CONTROL
        
        t_control = tic;
        t_atual = toc(t);
        
         %%% ---- Trajetoria desejada ------
         
         %%%% circulo
%         Xd_trajetoria([1 2]) = [-rX_c*sin(ww*t_atual + phase) - (L0+L1+b); -rY_c*cos(ww*t_atual + phase)+rY_c];
%         Vd_trajetoria([1 2]) = [-ww*rX_c*cos(ww*t_atual + phase);ww*rY_c*sin(ww*t_atual + phase)];

        %%%% lemniscatta
        Xd_trajetoria([1 2]) = [-rX_l*sin(ww*t_atual + phase) - (L0+L1+b);-rY_l*sin(2*ww*t_atual + phase)];
        Vd_trajetoria([1 2]) = [-ww*rX_l*cos(ww*t_atual + phase);-2*ww*rY_l*cos(2*ww*t_atual + phase)];
%         
        %%% ---- Calculo posicao no mundo do trailer 1 ------
        x_t1 = X_robo(1) - L0*cos(X_robo(4)) - (L1+b)*cos(X_trailer1(4));
        y_t1 = X_robo(2) - L0*sin(X_robo(4)) - (L1+b)*sin(X_trailer1(4));
        
        x_t1_c = X_robo(1) - L0*cos(X_robo(4)) - (L1)*cos(X_trailer1(4));
        y_t1_c = X_robo(2) - L0*sin(X_robo(4)) - (L1)*sin(X_trailer1(4));
        
        X_trailer1([1 2]) = ([x_t1 y_t1]);
        X_trailer1_centro = ([x_t1_c;y_t1_c]);  %%% plot
               
       %%%% calculo erro de posicao do trailer1
       Xtil_trailer1 = Xd_trajetoria - X_trailer1;
                
       %%% Velocidades no mundo - lei de controle
       v = Vd_trajetoria([1 2]) + K_1*tanh(K_2*Xtil_trailer1([1 2]));
       vx = v([1]);
       vy = v([2]);
       v_fi = (-vx/(b*cos(alpha)))*sin(X_trailer1([4])) +  (vy/(b*cos(alpha)))*cos(X_trailer1([4]));
        
       velocidade([1 2 4]) = [vx vy v_fi];
        
       K = [ cos(X_trailer1([4])), sin(X_trailer1([4])), b*sin(alpha); ...
            -sin(X_trailer1([4])), cos(X_trailer1([4])), -b*cos(alpha); ...
            0, 0, 1];
      
       %%%% sinal de controle cinematico para o trailer1
       U_trailer1 = K*velocidade([1 2 4]);
       U_trailer1(2) = 0;
       
       %%%% transmissao de velocidade inversa - do trailer 1 para o robo
       theta_1 = X_robo(4)-X_trailer1(4);
       
       %Satura��o angulo
        if abs(theta_1) > sat_angulo
            theta_1 = sat_angulo*sign(theta_1);
        end 
        
       v0_c = U_trailer1(1)*cos(theta_1) + (U_trailer1(3))*(L1)*sin(theta_1);
       w0_c = U_trailer1(1)*sin(theta_1)/L0 - (U_trailer1(3))*(L1)*cos(theta_1)/L0;
                
       U_robo([1 2 3]) = [v0_c 0 w0_c];   %%%% sinal de controle cinematico para o robo1
       
       %%%% -------------   compensador din�mico do robo ---------------
       U1_robo_ref = (U_robo(1) - U1_robo_anterior)/toc(t_derivada);
       U3_robo_ref = (U_robo(3)- U3_robo_anterior)/toc(t_derivada);
       t_derivada = tic;
       U1_robo_anterior = U_robo(1);
       U3_robo_anterior = U_robo(3);
          
       G = [0 0 -X_robo(6)^2 X_robo(5) 0 0; ...
             0 0 0 0 X_robo(6)*X_robo(5) X_robo(6)];
          
       delta_1 = U1_robo_ref + k_u*(U_robo(1) - X_robo(5));
       delta_2 = U3_robo_ref + k_w*(U_robo(3) - X_robo(6));

       A = [Theta(1) 0; 0 Theta(2)];
         
       %%%% habilita sinal de controle dinamico para o robo
%        U_robo([1 3]) = A*[delta_1;delta_2] + G*Theta;
        
       %Satura��o
        if abs(U_robo(1)) > sat_v
        U_robo(1) = sat_v*sign(U_robo(1));
        end

        if abs(U_robo(3)) > sat_w
        U_robo(3) = sat_w*sign(U_robo(3));
        end
         
        %%
        %%% Modelo Dinamico Pioneer
        K_din = [(Theta(3)/Theta(1))*X_robo(6)^2 - (Theta(4)/Theta(1))*X_robo(5); -(Theta(5)/Theta(2))*X_robo(6)*X_robo(5) - (Theta(6)/Theta(2))*X_robo(6)];
        K_vel = [1/Theta(1) 0; 0 1/Theta(2)];
        ddXd_robo = K_din+K_vel*U_robo([1 3]);
        
        K_direta = [X_robo(5)*cos(X_robo([4]))-b*X_robo(6)*sin(X_robo([4])); ...
                X_robo(5)*sin(X_robo([4]))+b*X_robo(6)*cos(X_robo([4])); ...
                                    0;
                                X_robo(6)];
        K_robo = vertcat(K_direta,ddXd_robo);
        
        %%% transmissao velocidade direta do robo para o trailer1
        U_trailer1(1) = X_robo(5)*cos(theta_1) + (X_robo(6))*(L0)*sin(theta_1);
        U_trailer1(3) = X_robo(5)*sin(theta_1)/(L1) - (X_robo(6))*(L0)*cos(theta_1)/(L1);
        U_trailer1(2) = 0;
        %%
        % Velocidade do rob� na referencia do mundo
        dX_robo([1 2 3 4 5 6]) = K_robo;
        dX_trailer1([1 2 4]) = K\U_trailer1([1 2 3]);
        dX_trailer1(3) = 0;
        dX_robo(3) = 0;
        
        % C�lculo de posi��o na refer�ncia do mundo
        X_robo = X_robo + dX_robo*toc(t_sim);
        X_trailer1 = X_trailer1 + dX_trailer1*toc(t_sim);
        t_sim = tic;
        
        %Satura��o modelo
        if abs(X_robo(5)) > sat_v
            X_robo(5) = sat_v*sign(X_robo(5));
        end
        
        if abs(X_robo(6)) > sat_w
            X_robo(6) = sat_w*sign(X_robo(6));
        end
       
        t_hist = [t_hist toc(t)];
        Xd_trajetoria_hist = [Xd_trajetoria_hist Xd_trajetoria(1:2)];
        dX_robo_hist = [dX_robo_hist dX_robo];
        dX_trailer1_hist = [dX_trailer1_hist dX_trailer1];
        X_robo_hist = [X_robo_hist X_robo];
        X_trailer1_hist = [X_trailer1_hist X_trailer1];
        Xtil_hist = [Xtil_hist Xtil];
        Xtil_trailer1_hist = [Xtil_trailer1_hist Xtil_trailer1];
        theta_1_hist =[theta_1_hist theta_1];
        
        %%
        
        Corpo1 = [raio*cos(circ);raio*sin(circ)] + X_robo(1:2);
        Corpo_frente = X_robo(1:2) + [(raio+0.3)*cos(X_robo(4));(raio+0.3)*sin(X_robo(4))];
        
        Corpo2 = [cos(X_trailer1(4)) -sin(X_trailer1(4));sin(X_trailer1(4)) cos(X_trailer1(4))]*[-ret_lg/2 ret_lg/2 ret_lg/2 -ret_lg/2 -ret_lg/2;-ret_lp/2 -ret_lp/2 ret_lp/2 ret_lp/2 -ret_lp/2] + X_trailer1_centro(1:2);
        haste_L0 = L0*[cos(X_robo(4)) -sin(X_robo(4));sin(X_robo(4)) cos(X_robo(4))]*[-1;0] + X_robo(1:2);
        haste_L1 = L1*[cos(X_trailer1(4)) -sin(X_trailer1(4));sin(X_trailer1(4)) cos(X_trailer1(4))]*[1;0] + X_trailer1_centro(1:2);
       
        plot(Xd_trajetoria(1),Xd_trajetoria(2),'bh')
        hold on
        grid on
        plot(Xd_trajetoria_hist(1,:),Xd_trajetoria_hist(2,:),'b-')
%         plot(X_robo_hist(1,:),X_robo_hist(2,:),'k','LineWidth',2)
        plot(Corpo1(1,:),Corpo1(2,:),'k','LineWidth',2)
        plot(X_trailer1_hist(1,:),X_trailer1_hist(2,:),'r--','LineWidth',2)
        plot(Corpo2(1,:),Corpo2(2,:),'k','LineWidth',2)
        plot([X_robo(1) Corpo_frente(1)],[X_robo(2) Corpo_frente(2)],'k','LineWidth',2)
        plot([X_robo(1) haste_L0(1)],[X_robo(2) haste_L0(2)],'k','LineWidth',2)
        plot([X_trailer1_centro(1) haste_L1(1)],[X_trailer1_centro(2) haste_L1(2)],'k','LineWidth',2)
        plot([haste_L0(1)],[haste_L0(2)],'ko')
%         axis([-3.5 1.5 -0.5 4.5])  %%% circulo raiox=raioy=2
        axis([-3.5 1.5 -2 2])  %%% lemniscata raiox=2 e raioy=1,5
        hold off
                
%         hold on
%         grid on
%         plot(t_hist(1,:),Xtil_trailer1_hist(1,:))
%         plot(t_hist(1,:),Xtil_trailer1_hist(2,:))
%         legend('erro_x','erro_y')
%         axis([0 T_MAX -0.5 0.5])
%         hold off

%         hold on
%         grid on
%         plot(t_hist(1,:),theta_1_hist(1,:)*180/pi)
%         legend('\theta_1')
%         axis([0 T_MAX -1 90])
%         hold off

%         hold on
%         grid on
%         plot(t_hist(1,:),X_robo_hist(5,:))
%         plot(t_hist(1,:),X_robo_hist(6,:))
%         legend('u','w')
%         axis([0 T_MAX -2 2])
%         hold off


        drawnow   
        
        
    end
    
end
