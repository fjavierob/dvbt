clear, close all
%% PRBS

% NPORTADORAS = 15; 
%     
% sec  = ones(1,11);
% prbs = zeros(1, NPORTADORAS);
% 
% for k = 1:NPORTADORAS
%     prbs(k) = sec(end);
%     p = xor(sec(1,end), sec(1,end-2));
%     sec(2:end) = sec(1:end-1);
%     sec(1) = p;
% end

%% Símbolos

% NUM_SYMB = 4;
% NPORTADORAS = 12;
% NDATA = 9;
% 
% pos_pilotos = [1 5 9];
% pilotos = [1 -1 1];
% 
% % NUM_SYMB * NDATA puntos de la constelación que vamos a transmitir de
% % datos. 
% const_points = [3 -3 3 3 -3 3 3 -3 -3 3 -3 3 3 -3 3 3 -3 -3 3 -3 3 3 -3 3 3 -3 -3 3 -3 3 3 -3 3 3 -3 -3];
% 
% SYMB = zeros(NPORTADORAS, NUM_SYMB);
% % Introducimos los pilotos
% pilotos_tx = repmat(pilotos, NUM_SYMB, 1)';
% SYMB(pos_pilotos,:) = pilotos_tx;
% % Introducimos los pilotos
% SYMB(SYMB==0) = reshape(const_points, NDATA, NUM_SYMB);
% 
% SYMB1 = SYMB;
% 
% SYMB = zeros(NUM_SYMB, NPORTADORAS);
% 
% % Introducimos los pilotos
% SYMB(:,pos_pilotos) = repmat(pilotos, NUM_SYMB, 1);
% % Introducimos los datos
% SYMB(SYMB==0) = reshape(const_points, NUM_SYMB, NDATA);
% 
% %% Estimador canal
% % Rx = SYMB1;
% Rx = SYMB1*2;
% % Rx = SYMB1+randn(NPORTADORAS, NUM_SYMB);
% 
% pilotos_rx = Rx(pos_pilotos,:);
% 
% Hp = pilotos_rx./pilotos_tx;
% 
% H = zeros(NPORTADORAS, NUM_SYMB);
% H(pos_pilotos,:) = Hp;

%% Constelaciones


