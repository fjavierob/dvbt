% Máster en Ingeniería de Telecomunicación
%
% Electrónica Digital para Comunicaciones
% Proyecto: Estimador de Canal y Ecualizador para DVB-T
%
% Francisco Javier Ortiz Bonilla
%   uvus: fcoortbon

%%
close all, clear all
%
% Lee la estimación realizada en VHDL y la compara con la
% realizada en Matlab.
%

nbits = 10;

% Leemos los datos de la simulación en Matlab.
% Bits transmitidos.
load('datosMatlab/bits_tx.mat');
% Constelación utilizada: BPSK, QPSK, 16-QAM, 64-QAM
load('datosMatlab/CONSTEL.mat');
% Puntos de la constelación
load('datosMatlab/C.mat');
% BER obtenida
load('datosMatlab/BER.mat');
% Datos recibidos sin ecualizar.
load('datosMatlab/datosrx.mat');
% Datos recibidos y ecualizados.
load('datosMatlab/datos_ec.mat');
% Canal estimado.
load('datosMatlab/H_.mat');
% Factor de escala.
load('datosMatlab/k.mat');
k = 3.0856;

%% Comparación de los canales estimados

% Canal estimado en VHDL
f = fopen('datosVHDL/canal.txt','r');
re = zeros(1, 1704);
im = zeros(1, 1704);

dato = fgetl(f);
d    = 1;
while ischar(dato)
    rhex=char(dato(1:3));
    ihex=char(dato(4:6));
    % Pasamos de hexadecimal a binario
    re(d) = hex2dec(rhex);
    im(d) = hex2dec(ihex);
    d     = d+1;
    dato  = fgetl(f);
   
end

% Pasamos de decimal a binario
re = dec2bin(re);
im = dec2bin(im);

% Pasamos de binario (CA2) a decimal.
re = bin2dec(re)-(2^10)*(re(:,1)-'0');
im = bin2dec(im)-(2^10)*(im(:,1)-'0');

h_ = re + i*im;
% Deshacemos el escalado previo
h_ = h_*k/511;

% Comparamos ambos canales
eje_x = -852:852;

figure,  plot(eje_x, 20*log10(abs(H_))),
eje_x = eje_x(1:end-1);
hold on, plot(eje_x, 20*log10(abs(h_)), '--')
xlabel('f [a.u.]');
ylabel('|H| (dB)');
title('Canal P1 estimado');
legend('Matlab','VHDL'); 

error = 100*mean(abs(((H_(1:end-1)-h_)./H_(1:end-1))));
fprintf('Error entre estimaciones del canal de %.3f%%\n', error);

%% Comparación constelaciones ecualizadas 

% Datos ecualizados en VHDL
f = fopen('datosVHDL/datos.txt','r');
re = zeros(1562, 1);
im = zeros(1562, 1);

dato = fgetl(f);
d    = 1;

while ischar(dato)
    rhex=char(dato(1:2));
    ihex=char(dato(3:4));
    % Pasamos de hexadecimal a binario
    re(d) = hex2dec(rhex);
    im(d) = hex2dec(ihex);
    d     = d+1;
    dato  = fgetl(f);
end

% Pasamos de decimal a binario
re = dec2bin(re);
im = dec2bin(im);

% Pasamos de binario (CA2) a decimal.
re = bin2dec(re)-(2^8)*(re(:,1)-'0');
im = bin2dec(im)-(2^8)*(im(:,1)-'0');

datos = re + i*im;
% Deshacemos el escalado (parte decimal de 5 bits, entera de 3 con signo)
datos = datos/(2^6);


figure
subplot(1,2,1);
plot(datos_ec, 'or');
grid
axis([-2 2 -2 2])
title('Matlab: Constelación tras ecualizar')
xlabel('I');
ylabel('Q');

subplot(1,2,2);
plot(datos, 'or');
grid
title('VHDL: Constelación tras ecualizar')
xlabel('I');
ylabel('Q');

%% Comparación BER

bits_tx = bits_tx(1:end/10);

% Demap símbolos VHDL
switch CONSTEL
    case 'BPSK'
        bits_rx = datos'<0;
    case 'QPSK'
        bits_rx = zeros(1,length(datos)*2);
        bits_rx(2:2:end) = real(datos)<0;
        bits_rx(1:2:end) = imag(datos)<0;
    case {'16-QAM', '64-QAM'}
        % Cargamos matriz de símbolos
        load('datosMatlab/S.mat');
        bits_rx = zeros(1, M*length(datos));
        for d = 1:length(datos)
            % Detectamos el símbolo
            [~, ind] = min((C-datos(d)).^2);
            bits_rx(1, M*(d-1)+1:M*d) = S(:,ind);
        end
end

fprintf('BER Matlab = %f\n', BER);
BER = mean(xor(bits_rx, bits_tx.'));
fprintf(1, 'BER VHDL = %f\n', BER);