% Máster en Ingeniería de Telecomunicación
%
% Electrónica Digital para Comunicaciones
% Proyecto: Estimador de Canal y Ecualizador para DVB-T
%
% Francisco Javier Ortiz Bonilla
%   uvus: fcoortbon

%%
close all, clear all

tic

% Parámetros

% Modo 2k ó 8k: {2, 8}.
modo    = 2; 
% Constelación: {'BPSK', 'QPSK', '16-QAM', '64-QAM'}
CONSTEL = 'QPSK';
save('datosMatlab/CONSTEL.mat','CONSTEL')
% Prefijo ciclico: {1/4, 1/8, 1/16, 1/32}
CP      = 1/32;
% SNR
SNR     = 30;
% Espaciado de los pilotos
ESPACIADO_PILOTOS = 12;

fprintf('Modo: %dk  ·  Constel: %s  ·  SNR: %.1fdB\n', modo, CONSTEL, SNR);


%% Ajustar variables según modo.

NPORTADORAS = 1705;
if (modo == 8)
    NPORTADORAS = 6817;
end

NFFT     = modo * 1024;
NCP      = NFFT * CP;
NPILOTOS = ceil(NPORTADORAS/ESPACIADO_PILOTOS);
NDATA    = NPORTADORAS - NPILOTOS;
NUM_SYMB = 10;


%% Constelación.

SEED    = 100;     % Semilla para aleatorio

% Inicializar los generadores pseudoaleatorios con la semilla
rand('seed', SEED);
randn('seed', SEED);

% Constelación
switch CONSTEL
    case 'BPSK'
        M=1;
        C=[1 -1];
    case 'QPSK'
        C=[1+1i 1-1i -1+1i -1-1i];
        %  "00"  "01" "10"  "11" -> Codificación Gray.
        % Por cada 2 bits que voy a transmitir -> Lo paso a decimal, le
        % sumo 1 y esto será el índice de C que voy a transmitir.
        
        % Los puntos más cercanos en la constelación sólo se diferencian en
        % un bit. -> Más robusto frente a ruido: Más probable equivocarse
        % en 1 bit en lugar de 2 bits.
        M=2;
    case '16-QAM'
        M = 4;
        S = de2bi(0:2^M-1, M);
        % Ponemos los símbolos en orden para que mapear y demapear sea
        % inmediato.
      % S =  0000 1000 0100  1100  0010  1010 0110  1110 0001  1001 0101   1101 0011  1011 0111  1111
        C = [3+3i -3+3i 3-3i -3-3i 1+3i -1+3i 1-3i -1-3i 3+1i -3+1i 3-1i  -3-1i 1+1i -1+1i 1-1i -1-1i];
        save('datosMatlab/S.mat', 'S');
    case '64-QAM'
        M = 6;
        S = de2bi(0:2^M-1, M);
        % Ponemos los símbolos en orden para que mapear y demapear sea
        % inmediato.
          %  000000 100000 010000 110000 001000 101000 011000 111000 000100 100100 010100 110100
          %  001100 101100 011100 111100 000010 100010 010010 110010 001010 101010 011010 111010
          %  000110 100110 010110 110110 001110 101110 011110 111110 000001 100001 010001 110001
          %  001001 101001 011001 111001 000101 100101 010101 110101 001101 101101 011101 111101
          %  000011 100011 010011 110011 001011 101011 011011 111011 000111 100111 010111 110111
          %  001111 101111 011111 111111
        C = [7+7i   -7+7i  7-7i   -7-7i  1+7i   -1+7i  1-7i   -1-7i  7+1i   -7+1i  7-1i   -7-1i ...
             1+1i   -1+1i  1-1i   -1-1i  5+7i   -5+7i  5-7i   -5-7i  3+7i   -3+7i  3-7i   -3-7i ...
             5+1i   -5+1i  5-1i   -5-1i  3+1i   -3+1i  3-1i   -3-1i  7+5i   -7+5i  7-5i   -7-5i ...
             1+5i   -1+5i  1-5i   -1-5i  7+3i   -7+3i  7-3i   -7-3i  1+3i   -1+3i  1-3i   -1-3i ...
             5+5i   -5+5i  5-5i   -5-5i  3+5i   -3+5i  3-5i   -3-5i  5+3i   -5+3i  5-3i   -5-3i ...
             3+3i   -3+3i  3-3i   -3-3i];
         save('datosMatlab/S.mat', 'S');
end

% Energía promedio = 1
C = C./(mean(abs(C)));

if isreal(C)
   C=complex(C);
end

save('datosMatlab/C.mat', 'C');

plot(C, 'or');
grid
switch CONSTEL
    case 'BPSK'
        axis(1.5*[min(real(C)) max(real(C)) -1 1]);
    otherwise
        axis(1.5*[min(real(C)) max(real(C)) min(imag(C)) max(imag(C))]);
end 
title('Constelación')
xlabel('I');
ylabel('Q');

%% Generar datos a transmitir.

% Generación bits aleatorios
NBITS = NUM_SYMB*NDATA*M; % num simbolos * num datos x portadora * num bits x portadora
bits_tx = rand(NBITS, 1); % vector columna (numbits filas, 1 columna)
bits_tx = bits_tx>0.5;      % pasar a 0 y 1 el vector
save('datosMatlab/bits_tx.mat','bits_tx')


% Bits to symbols
% Cambiar de vector columna de bits a M columnas
aux  = reshape(bits_tx, M, []).';   % Reshape siempre funciona por columnas: el
                      % M x NBITS/M % segundo parámetro (M) indica el número de filas.  
% Al final queda aux de NBTIS/M x M

% Elegimos el primer bit de cada par como el menos significativo.
% symb = zeros(size(aux, 1),1); % Vector columna NBITS x 1
% 
% % Esto no es óptimo, se puede hacer sin for.
% % Pasamos de binario a decimal cada par de bits -> 0 1 = 2
% for k = 1:M
%     symb = symb + (2^(k-1))*aux(:,k);
% end
symb = bi2de(aux);


% Mapper
const_points = C(symb+1);
% Estos son los puntos de la constelación que se transmiten (NBITS/M).
if isreal(const_points)
   const_points = complex(const_points);
end

figure
plot(const_points, 'or');
grid
switch CONSTEL
    case 'BPSK'
        axis(1.5*[min(real(C)) max(real(C)) -1 1]);
    otherwise
        axis(1.5*[min(real(C)) max(real(C)) min(imag(C)) max(imag(C))]);
end 
title('Constelación transmitida')
xlabel('I');
ylabel('Q');


%% Pilotos

pos_pilotos = 1:ESPACIADO_PILOTOS:(NPORTADORAS);

% Pseudo Random Binary Sequence (PRBS)
% Estándar: Apartado 4.5.2

sec  = ones(1,11);
prbs = zeros(1, NPORTADORAS);

for k = 1:NPORTADORAS
    prbs(k) = sec(end);
    p = xor(sec(1,end), sec(1,end-2));
    sec(2:end) = sec(1:end-1);
    sec(1) = p;
end
% Me quedo con los valores en los pilotos
prbs = prbs(pos_pilotos);

% Estándar: Apartado 4.5.3 
pilotos = 4/3*2*(0.5-prbs);
pilotos = complex(pilotos);
% Valor de los pilotos en cada portadora !!!

%% Generación de símbolos: Datos + pilotos.

SYMB = zeros(NPORTADORAS, NUM_SYMB);

% Introducimos los pilotos
pilotos_tx = repmat(pilotos, NUM_SYMB, 1).';
% pilotos_tx -> Cada fila es el piloto en una portadora, cada columna el
% símbolo.
SYMB(pos_pilotos,:) = repmat(pilotos, NUM_SYMB, 1).';
% Introducimos los datos
SYMB(SYMB==0) = reshape(const_points, NDATA, NUM_SYMB);

% Símbolos OFDM en frecuencia
ofdm_freq = zeros(NFFT, NUM_SYMB);
ofdm_freq(ceil((NFFT-NPORTADORAS)/2)+(1:NPORTADORAS),:) = SYMB;
% Reshape para que quede así
%   | 00000000000 |
%   | 00000000000 |
%   | ----------- |
%   | ----------- | 
%   | ----------- |   Las NPORTADORAS portadoras
%   | ----------- |
%   | ----------- |
%   | 00000000000 |
%   | 00000000000 |

figure
stem(abs(ofdm_freq(:,1)));
grid
xlabel('Portadoras OFDM');
ylabel('Amplitud');
title('Espectro OFDM enviado')

 
ofdm_freq=ifftshift(ofdm_freq, 1);
                              % Importante el 1 !!! Matriz unidimensional. 

% Modulacion OFDM

ofdm_time = ifft(ofdm_freq, NFFT, 1);

% Prefijo cíclico

ofdm_time = [ofdm_time(end-(NCP-1):end, :); ofdm_time]; % Cojo las NCP últimas filas y las copio 
                                                        % al principio.
                                                        
tx = ofdm_time(:); % Vector fila: Fila tras fila de ofdm_time.

figure
plot(real(tx), 'b-');
hold on
plot(imag(tx), 'r-');
xlabel('Muestras temporales');
ylabel('Amplitud');
legend('real', 'imag');
grid
title('Señal OFDM enviada')

% Espectro
figure
pwelch(tx);
% Se muestra en Matlab mode: negativas a la derecha y positivas a la izq:
% ___________          __________                 
%           |          |
%           |          |
%           |          |
%           |          |
%           |          |
%           ------------ 

% En realidad es así:
%       _____________________
%      |                     |
%      |                     |
%      |                     |
%      |                     |
%      |                     |
% -----                      -------

%% Modelar canal P 
    
% Parámetros
p     = [0.057662, 0.176809, 0.407163, 0.303585, 0.258782, ...
         0.061831, 0.150340, 0.051534, 0.185074, 0.400967, ... 
         0.295723, 0.350825, 0.262909, 0.225894, 0.170996, ...
         0.149723, 0.240140, 0.116587, 0.221155, 0.259730];       
        
tau   = [1.003019, 5.422091, 0.518650, 2.751772, 0.602895, ...
         1.016585, 0.143556, 0.153832, 3.324866, 1.935570, ...
         0.429948, 3.228872, 0.848831, 0.073883, 0.203952, ...
         0.194207, 0.924450, 1.381320, 0.640512, 1.368671];
    
theta = [4.855121, 3.419109, 5.864470, 2.215894, 3.758058, ...
         5.430202, 3.952093, 1.093586, 5.775198, 0.154459, ...
         5.928383, 3.053023, 0.628578, 2.128544, 1.099463, ...
         3.462951, 3.664773, 2.833799, 3.334290, 0.393889];       
    
deltaw   = 2*pi/(modo*112e-6);  % Separación portadoras. Modo = 2, 8.     
         
waux = 1024*modo/2*deltaw;
w = -waux:deltaw:waux;
w = w(1:end-1);
    
H = zeros(1, NFFT);
    
% Respuesta del canal en frecuencia
for k = 1:20
	H = H + p(k)*exp(-1i*theta(k))*exp(-1i*w*tau(k)*10^-6);
end
        
figure,
plot(w*10^-6/(2*pi), 20*log10(abs(H))) % representamos en frecuencia en dB
xlabel('f (MHz)');
ylabel('|H| (dB)');
title('Canal P1');
         
% Pasamos la H a formato matlab.
H = ifftshift(H); 
h = ifft(H, NFFT); 
       
htx = conv(tx,h);
% Quitamos la parte que sobra de la convolución.
% Porque el tau máx del canal es muy chico. No vamos a tener problemas
% de ISI.
htx = htx(1:length(tx)); 
tx  = htx;

% Ruido
noise = (randn(size(tx))+1i*randn(size(tx))) / sqrt(2);
Ps = mean(tx.*conj(tx));
nsr = 10^(-SNR/10); % Pn/Ps
noise = sqrt(Ps*nsr).*noise;
rx = tx+noise;


%% Receptor

% Deshacer todo lo que hemos venido haciendo:
% 1. Quitar prefijo ciclico
% 2. Demodular OFDM -> hacer fft
% 3. Extraer los pilotos 
% 4. Estimar el canal con los pilotos.
% hacer demapper de simbolos -> pasar de simbolos a bits


% Reshape para pasar de vector 1xA a matriz.
rx_t = reshape(rx, NFFT+NCP, NUM_SYMB);
% Quitar prefijo cíclico.
rx_t = rx_t(NCP+1:end,:); 

% Demodular OFDM
rx_f = fft(rx_t, NFFT, 1); % fft de ofdm
rx_f = fftshift(rx_f, 1);

figure
stem(abs(rx_f(:,1))); % Teníamos numeros complejos, un símbolo
grid
xlabel('Portadoras OFDM');
ylabel('Amplitud');
title('Espectro OFDM recibido')

% Obtener constelación: Símbolos recibidos (ceros+datos+pilotos)
% Quito los ceros.
rx_constel = rx_f(ceil((NFFT-NPORTADORAS)/2)+(1:NPORTADORAS),:);
% Guardo los datos recibidos del primer símbolo para la parte de VHDL.
datosrx = rx_constel(:,1).';
save('datosMatlab/datosrx.mat','datosrx')
% Extraigo los pilotos.
rx_pilotos = rx_constel(pos_pilotos,:);
% Extraigo los datos
rx_datos = rx_constel;
rx_datos(pos_pilotos,:) = [];

figure
plot(rx_datos(:), 'or');
grid
switch CONSTEL
    case 'BPSK'
        axis(1.5*[min(real(C)) max(real(C)) -1 1]);
    otherwise
        axis(1.5*[min(real(C)) max(real(C)) min(imag(C)) max(imag(C))]);
end 
title('Constelación recibida sin ecualizar')
xlabel('I');
ylabel('Q');


%% Estimar el canal: He.

He = zeros(NPORTADORAS, NUM_SYMB);

% H en los pilotos
Hp = rx_pilotos./pilotos_tx;
He(pos_pilotos,:) = Hp;

% Interpolar el resto de valores de H a partir de los valores en los
% pilotos.
ultimo = pos_pilotos(end);
for s = 1:NUM_SYMB
    for n = 1:NPILOTOS
        p = pos_pilotos(n);
        if (n == NPILOTOS)
            % Si hay más portadoras tras el último piloto...
            portadoras = size(He,1)-p;
            if (portadoras)
                % ... interpolo con la pendiente de la recta anterior.
                a = He(p,s);
                for dp = 1:portadoras
                   He(p+dp,s) = a + m*dp; 
                end
            end
        else
            a = He(p,s);
            b = He(p+ESPACIADO_PILOTOS,s);
            m = (b-a)/ESPACIADO_PILOTOS;
            for dp = 1:ESPACIADO_PILOTOS-1
                He(p+dp,s) = a + m*dp;
            end
        end
    end
end

% Prueba interpolador diferentes órdenes.

k_ = 1;
% %for k = [ 4 7 11 15 19 23 27 31 35 39 43 47 51 55 59 63 67 71 75 79 83 87 91 95 99 103 107 111 115 119 121 127 131 135 139 143] 
% for k = [4 8 11:4:143]
% %for k = [4 8:3:143]
% %for k = [3:2:143]
% %for k = [4:5:143 143]
% %for k = [5:6:143]
% %for k = [6:7:132 138 143]
%     p = polyfit(pos_pilotos(k_:k), He(pos_pilotos(k_:k),1)',length(k_:k)-1);
%     H_(pos_pilotos(k_):pos_pilotos(k)) = polyval(p, pos_pilotos(k_):pos_pilotos(k));
%     k_ = k;
% end

% Fin prueba

% Representamos una de las H estimadas (hay una por símbolo).
H_ = He(:,1);
% Guardamos el canal estimado en hexadecimal.
save('datosMatlab/H_.mat', 'H_');

% De las 2048/8192 portadoras, sólo usamos NPORTADORAS al transmitir, por
% lo que nuestra H estimada sólo se estima en estas portadoras, que son las
% portadoras centrales. A la hora de reprensentar, debemos tener esto en
% cuenta.
figure, 
p_sobra = NFFT-NPORTADORAS;
pinf = ceil((NFFT-NPORTADORAS)/2)+1;
psup = modo*1024-ceil((NFFT-NPORTADORAS)/2)+1;
w_ = w(pinf:psup);
plot(w_*10^-6/(2*pi), 20*log10(abs(H_))) % representamos en frecuencia en dB
hold on
plot(w*10^-6/(2*pi), 20*log10(abs(fftshift(H))), 'r') % representamos en frecuencia en dB
xlabel('f (MHz)');
ylabel('|H| (dB)');
title('Canal P1 estimado');
legend('Canal estimado', 'Canal real');

% Representar H estimada para cada símbolo
figure, plot(w_*10^-6/(2*pi), 20*log10(abs(He)))
xlabel('f (MHz)');
ylabel('|H| (dB)');
title('Canal P1 estimado para cada símbolo');


%% Ecualizar: Dividir por la H calculada.

rx_constel = rx_constel./He;
% Extraigo los datos
rx_datos = rx_constel;
rx_datos(pos_pilotos,:) = [];
datos_ec = rx_datos(:,1);
save('datosMatlab/datos_ec.mat', 'datos_ec');
rx_datos = rx_datos(:);


% Constelación tras ecualizar
figure
plot(rx_datos, 'or');
grid
switch CONSTEL
    case 'BPSK'
        axis(1.5*[min(real(C)) max(real(C)) -1 1]);
    otherwise
        axis(1.5*[min(real(C)) max(real(C)) min(imag(C)) max(imag(C))]);
end 
title('Constelacion recibida tras ecualizar')
xlabel('I');
ylabel('Q');

% Demap
switch CONSTEL
    case 'BPSK'
        bits_rx = rx_datos'<0;
    case 'QPSK'
        bits_rx = zeros(1,length(rx_datos)*2);
        bits_rx(2:2:end) = real(rx_datos)<0;
        bits_rx(1:2:end) = imag(rx_datos)<0;
    case {'16-QAM', '64-QAM'}
        bits_rx = zeros(1, M*length(rx_datos));
        for d = 1:length(rx_datos)
            % Detectamos el símbolo
            [~, ind] = min((C-rx_datos(d)).^2);
            bits_rx(1, M*(d-1)+1:M*d) = S(ind,:);
        end
end

BER = mean(xor(bits_rx, bits_tx.'));
fprintf(1, 'BER = %f\n', BER);
save('datosMatlab/BER.mat', 'BER');

toc

% Crear archivos con los datos en hexadecimal y el fichero .coe
pasarHex();
