clear all
close all
clc

% Vari�veis do Rob�
X_robo = zeros(6,1); % posicao atual do robo
X_trailer1 = zeros(6,1); % posicao atual do trailer1
X_trailer1_centro = zeros(6,1); % posicao atual do trailer1
Xd_trailer1 = zeros(6,1); % posicao atual do trailer1
Vd_trailer1 = zeros(6,1); % velocidades desejadas do caminho
v = zeros(4,1); % Velocidades controle do Rob�
velocidade = zeros(4,1); % Velocidades controle do Rob�
U_robo = zeros(6,1); % Comandos do Rob�
dX_robo = zeros(6,1); % Variacoes posicoes do robo entre interacoes
U_trailer1 = zeros(6,1); % Comandos do trailer1
dX_trailer1 = zeros(6,1);% Variacoes posicoes do trailer1 entre interacoes
dX_trailer1_centro = zeros(6,1);
Xtil_trailer1 = zeros(6,1); % Erros trailer 1
dX_robo1_anterior = 0;
dX_robo4_anterior = 0;
U1_robo_anterior = 0;
U3_robo_anterior = 0;
K_vel = zeros(5,2);
U_robo_din = zeros(5,1);
% X_robo = [2.5 0.7 0 pi/2 0 0]';
X_robo = [3.5 1 0 0 0 0]';
Xd_aux = 0;
Vd_aux = 0;

% Vari�veis do Caminho
RaioX = 2;
RaioY = 1.5;
CentroX = 3;
CentroY = 0;
inc = 0.1; % Resolu��o do Caminho
inc_desvio = 0.1;
nCaminho = 350; % N�mero de pontos total no caminho
s = 0:inc:nCaminho; % Abcissa curvilinea
x = -RaioX*sin(pi*s/180) + CentroX;
y = RaioY*sin(2*pi*s/180) + CentroY;
% y = RaioY*cos(pi*s/180) + CentroY;
z = 0*ones(1,length(s));
C_normal = [x; y; z];
dist_fim = 0.1; % Dist�ncia ao ponto final onde considero que terminei a navega��o
dist_final = 1000;
tol_caminho = 0.2; % Toler�ncia na qual considero o rob� sobre o caminho
Ve = 0.3; % Velocidade desejada no caminho

% Cinem�tica estendida do pioneer
alpha = pi;
sat_v = 0.75;
sat_w = 100*pi/180;
b = 0.2;

% Variaveis para plot corpo
raio = 0.15;
circ = 0:0.01:2*pi;

% Variaveis de Ganho
K_1 = 0.8*diag([1 1 1]);
K_2 = 0.8*diag([1 1 1]);
k_u = 4;
k_w = 4;

% thetas primeira identificacao
theta_1 = 0.23025;
theta_2 = 0.22615;
theta_3 = 0.00028953;
theta_4 = 0.95282;
theta_5 = 0.021357;
theta_6 = 0.95282;

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

Theta_original = [theta_1;theta_2;theta_3;theta_4;theta_5;theta_6];
% Theta_original = [1;1;1;1;1;1];

% Vari�veis de hist�rico
t_hist = [];
Xd_trailer1_hist = [];
dX_robo_hist = [];
dX_trailer1_hist = [];
X_robo_hist = [];
X_trailer1_hist = [];
X_trailer1_centro_hist = [];
Xtil_trailer1_hist = [];
theta_1_hist =[];
Theta_est_hist = [];


% Vari�veis de Tempo
t = tic; % Temporizador de experimento
t_c = tic; % Temporizador de controle
t_sim = tic; % Temporizador de simula��o
T_c = 0.1; % Tempo de controle
t_der = tic;
t_derivada = tic;

%%%%% Adaptativo
Theta_til = [0;0;0;0;0;0];
Theta_est = Theta_original;

k=1;

parametros{k} = zeros(6,1);
G1{k} = zeros(1,3);
G2{k} = zeros(1,3);

Yfp1 = 0;
Yfp2 = 0;
      
Tfp1 = G1{1};
Tfp2 = G2{1};

Theta1 = classRLS(3);
    Theta1.inicializa(Yfp1(1),G1{1});
Theta2 = classRLS(3);
    Theta2.inicializa(Yfp2(1),G2{1});

theta = zeros(6,1);

X_robo_anterior = zeros(6,1);

n = 60;  %%%% numero de iteracoes para controle adaptativo

%%% dimensoes trailers
L0 = 0.3;
L1 = 0.455;
%%% dimensoes trailers simulacao
ret_lg = 0.415;
ret_lp = 0.285;

sat_angulo = pi/2;


while dist_final > dist_fim
    if toc(t_c) > T_c
        t_c = tic;
        k = k+1;
        
             %% Controlador Caminho
        % Velocidade desejada atual
        Vd = Ve;
        
        %%% ---- Calculo posicao no mundo do trailer 1 ------
        x_t1 = X_robo(1) - L0*cos(X_robo(4)) - (L1+b)*cos(X_trailer1(4));
        y_t1 = X_robo(2) - L0*sin(X_robo(4)) - (L1+b)*sin(X_trailer1(4));
        
        x_t1_c = X_robo(1) - L0*cos(X_robo(4)) - (L1)*cos(X_trailer1(4));
        y_t1_c = X_robo(2) - L0*sin(X_robo(4)) - (L1)*sin(X_trailer1(4));
        
        X_trailer1([1 2]) = ([x_t1 y_t1]);
        X_trailer1_centro([1 2]) = ([x_t1_c;y_t1_c]);  %%% plot
              
        % Distancia do rob� para o final do caminho
        dist_final = norm(C_normal(:,end) - X_trailer1(1:3));
        
        % Calcula o ponto do caminho mais pr�ximo do rob�
        [dist, ind] = calcula_ponto_proximo(C_normal(1:2,:),X_trailer1(1:2));
        
        % Define o ponto desejado
        Xd_trailer1(1:2) = C_normal(1:2,ind);
%         Xd_robo(1:2)
        
        % Calcula o angulo do vetor tangente ao caminho
        theta_caminho = atan2(C_normal(2,ind+1*sign(Vd)) - C_normal(2,ind),C_normal(1,ind+1*sign(Vd)) - C_normal(1,ind));
        
        % Calcula as proje��es nos eixos x e y do vetor velocidade tangente
        % ao caminho
        Vx = abs(Vd)*cos(theta_caminho);
        Vy = abs(Vd)*sin(theta_caminho);
        
        % Define a velocidade desejada no referencial do mundo. Isto �
        % dividido nos casos onde o rob� esta fora do caminho e onde ele
        % est� sobre o caminho
        
%         if dist > tol_caminho
%             Vd_robo(1:2) = [5*Vx 5*Vy]';
%         else
            Vd_trailer1(1) = Vx;
            Vd_trailer1(2) = Vy;
%         end
        
        % Calcula o erro de posi��o
%         Xtil(1:3) = Xd_robo(1:3) - X_robo(1:3);
        
        %%%% calculo erro de posicao do trailer1
        Xtil_trailer1(1:3) = Xd_trailer1(1:3) - X_trailer1(1:3);
        
        % Lei de Controle posicao
        v(1:3) = Vd_trailer1(1:3) + K_1*tanh(K_2*Xtil_trailer1(1:3));
        
        % Lei de Controle orientacao
        v_fi = (-v(1)/(b*cos(alpha)))*sin(X_trailer1([4])) +  (v(2)/(b*cos(alpha)))*cos(X_trailer1([4]));
        
        velocidade([1 2 4]) = [v(1) v(2) v_fi];
        
        K = [ cos(X_trailer1([4])), sin(X_trailer1([4])), b*sin(alpha); ...
            -sin(X_trailer1([4])), cos(X_trailer1([4])), -b*cos(alpha); ...
            0, 0, 1];
      
       %%%% sinal de controle cinematico
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
       
         %%%% -------------   compensador din�mico ---------------
          U1_robo_ref = (U_robo(1) - U1_robo_anterior)/toc(t_derivada);
          U3_robo_ref = (U_robo(3)- U3_robo_anterior)/toc(t_derivada);
          t_derivada = tic;
          U1_robo_anterior = U_robo(1);
          U3_robo_anterior = U_robo(3);
          
          G = [0 0 -X_robo(6)^2 X_robo(5) 0 0; ...
               0 0 0 0 X_robo(6)*X_robo(5) X_robo(6)];
          
          delta_1 = U1_robo_ref  + k_u*(U_robo(1) - X_robo(5));
          delta_2 = U3_robo_ref + k_w*(U_robo(3)- X_robo(6));
        
        %%% -----  Controle Adaptativo -------
        
        Theta = Theta_est;
        
        %%%%% a partir de k - comeca processo de adaptacao
        if k>=n
          [parametros{k}, G1{k}, G2{k}] = calculo_parametros_simulacao([dX_robo(5); dX_robo(6)], [X_robo(5); X_robo(6)], [U_robo(1); U_robo(3)]);
          [Theta_est,Y1,Y2,T1,T2] = RLS_recursivo_simulacao(parametros{k},G1{k},G2{k},[U_robo(1); U_robo(3)],k,Theta1,Theta2,Yfp1,Yfp2,Tfp1,Tfp2);
            Yfp1 = Y1;
            Yfp2 = Y2;
            Tfp1 = T1;
            Tfp2 = T2;
         end
         
          Theta_til = Theta_est - Theta;
          A_est = [Theta_est(1) 0; 0 Theta_est(2)];
          
          Theta_est
                    
          %%%%% ----- Adaptativo come�a a partir da iteracao k ---------
          
          %%%%% comeca com controlador dinamico normal - ate k
          if k<2*n
          A_din = [Theta_original(1) 0; 0 Theta_original(2)];   
          U_robo([1 3]) = A_din*[delta_1;delta_2] + G*Theta_original;
          disp('dinamico');
          end
          
          %%%%% a partir de k - comeca com controlador adaptativo
          if k>=2*n
          U_robo([1 3]) = A_est*[delta_1;delta_2] + G*Theta_est + G*Theta_til;
          disp('adaptativo');
          end
        
        %Satura��o
        if abs(U_robo(1)) > sat_v
            U_robo(1) = sat_v*sign(U_robo(1));
        end
        
        if abs(U_robo(3)) > sat_w
            U_robo(3) = sat_w*sign(U_robo(3));
        end
        
%         if k>50 && k<100
%             U_robo([1 3]) = [0;0];
%         end
%         
%          if k>250 && k<300
%             U_robo([1 3]) = [0;0];
%          end
%          
%          k
        
        %%% Modelo Dinamico Pioneer
        K_din = [(Theta_original(3)/Theta_original(1))*X_robo(6)^2 - (Theta_original(4)/Theta_original(1))*X_robo(5); -(Theta_original(5)/Theta_original(2))*X_robo(6)*X_robo(5) - (Theta_original(6)/Theta_original(2))*X_robo(6)];
        K_vel = [1/Theta_original(1) 0; 0 1/Theta_original(2)];
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
        
        K_centro = [ cos(X_trailer1([4])), sin(X_trailer1([4])), 0; ...
            -sin(X_trailer1([4])), cos(X_trailer1([4])), 0; ...
            0, 0, 1];
        
        %% Simula��o
        
        % Velocidade do rob� na referencia do mundo
        dX_robo([1 2 3 4 5 6]) = K_robo;
        dX_trailer1([1 2 4]) = K\U_trailer1([1 2 3]);
        dX_trailer1_centro([1 2 4]) = K_centro\U_trailer1([1 2 3]);
        dX_trailer1_centro(3) = 0;
        dX_trailer1(3) = 0;
        dX_robo(3) = 0;
        
        % C�lculo de posi��o na refer�ncia do mundo
        X_robo = X_robo + dX_robo*toc(t_sim);
        X_trailer1 = X_trailer1 + dX_trailer1*toc(t_sim);
        X_trailer1_centro = X_trailer1_centro + dX_trailer1_centro*toc(t_sim);
        t_sim = tic;
        
            %Satura��o
        if abs(X_robo(5)) > sat_v
            X_robo(5) = sat_v*sign(X_robo(5));
        end
        
        if abs(X_robo(6)) > sat_w
            X_robo(6) = sat_w*sign(X_robo(6));
        end      
        
        
        t_hist = [t_hist toc(t)];
        Xd_trailer1_hist = [Xd_trailer1_hist Xd_trailer1(1:2)];
        dX_robo_hist = [dX_robo_hist dX_robo];
        dX_trailer1_hist = [dX_trailer1_hist dX_trailer1];
        X_robo_hist = [X_robo_hist X_robo];
        X_trailer1_hist = [X_trailer1_hist X_trailer1];
        X_trailer1_centro_hist = [X_trailer1_centro_hist X_trailer1_centro];
        Xtil_trailer1_hist = [Xtil_trailer1_hist Xtil_trailer1];
        theta_1_hist =[theta_1_hist theta_1];
        Theta_est_hist = [Theta_est_hist Theta_est];
        
        %%
        Corpo1 = [raio*cos(circ);raio*sin(circ)] + X_robo(1:2);
        Corpo_frente = X_robo(1:2) + [(raio+0.15)*cos(X_robo(4));(raio+0.15)*sin(X_robo(4))];
        
        Corpo2 = [cos(X_trailer1(4)) -sin(X_trailer1(4));sin(X_trailer1(4)) cos(X_trailer1(4))]*[-ret_lg/2 ret_lg/2 ret_lg/2 -ret_lg/2 -ret_lg/2;-ret_lp/2 -ret_lp/2 ret_lp/2 ret_lp/2 -ret_lp/2] + X_trailer1_centro(1:2);
        haste_L0 = L0*[cos(X_robo(4)) -sin(X_robo(4));sin(X_robo(4)) cos(X_robo(4))]*[-1;0] + X_robo(1:2);
        haste_L1 = L1*[cos(X_trailer1(4)) -sin(X_trailer1(4));sin(X_trailer1(4)) cos(X_trailer1(4))]*[1;0] + X_trailer1_centro(1:2);
       
        plot(X_trailer1(1,:),X_trailer1(2,:),'-')
        hold on
        grid on
        plot(C_normal(1,:),C_normal(2,:),'--')
        plot(Corpo1(1,:),Corpo1(2,:),'k','LineWidth',2)
        plot(X_trailer1_hist(1,:),X_trailer1_hist(2,:),'-')
        plot(Corpo2(1,:),Corpo2(2,:),'k','LineWidth',2)
        plot([X_robo(1) Corpo_frente(1)],[X_robo(2) Corpo_frente(2)],'k','LineWidth',2)
        plot([X_robo(1) haste_L0(1)],[X_robo(2) haste_L0(2)],'k','LineWidth',2)
        plot([X_trailer1_centro(1) haste_L1(1)],[X_trailer1_centro(2) haste_L1(2)],'k','LineWidth',2)
        plot([haste_L0(1)],[haste_L0(2)],'ko')
        axis([0 6 -2 2])
%         axis([-4.5 10.5 -3.5 3.5])
%         axis([-10 20 -10 20])
        hold off
        
        
%         hold on
%         grid on
%         plot(t_hist(1,:),Theta_est_hist(1,:))
%         plot(t_hist(1,:),Theta_est_hist(2,:))
%         plot(t_hist(1,:),Theta_est_hist(3,:))
%         plot(t_hist(1,:),Theta_est_hist(4,:))
%         plot(t_hist(1,:),Theta_est_hist(5,:))
%         plot(t_hist(1,:),Theta_est_hist(6,:))
%         axis([0 t_hist(end) -10 10])
%         hold off
                
%         hold on
%         grid on
%         plot(t_hist(1,:),Xtil_hist(1,:))
%         plot(t_hist(1,:),Xtil_hist(2,:))
%         axis([0 20 -0.5 0.5])
%         hold off

        drawnow   
        
        
    end
    
end
