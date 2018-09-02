%% Pasar datos ecualizados a hex
    
    load datos_ec.mat;

    nbits = 10;
    datos = datos_ec;
    % Factor para normalizar: k
    k     = max( max(abs(real(datos))), max(abs(imag(datos))) );
    fprintf('Factor de normalizacion k = %f\n', k);
    % Rango del signed al que se van a truncar los datos: [-r, r] 
    r     =  2^(nbits-1)-1;              
    % Normalizamos a dicho rango
    data  = round(datos*r/k);

    % Número carácteres hexadecimales por cada valor.
    n     = ceil(nbits/4);
    % Separamos parte real e imaginaria
    rdata = real(data);
    idata = imag(data);
    % Convertimos a hexadecimal
    rhex  = dec2hex(mod(rdata, 2^nbits), n);
    ihex  = dec2hex(mod(idata, 2^nbits), n);
    
    % Concatenamos parte real e imaginaria: Valores hexadecimales de longitud
    % 2n: Primera mitad = Parte real; Segunda mitad = Parte imaginaria.
    hdata = strcat(rhex, ihex);
   
    % Guardamos el resultado en el fichero datos_hex y creamos también un
    % fichero .coe con los datos. 
    % Se guardan también los pilotos en el fichero pilotos.txt.
    
    f = fopen('datosec_hex.txt','w');
    for k = 1:size(hdata,1)-1
        fprintf(f,'%s\n',hdata(k,:));
    end
    fprintf(f,'%s', hdata(end,:));
    fclose(f);
    
    %% Comparación constelaciones ecualizadas 

% Datos ecualizados en VHDL
f = fopen('datosec_hex.txt','r');
re = zeros(1562, 1);
im = zeros(1562, 1);

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

datos = re + i*im;
% Deshacemos el escalado (parte decimal de 5 bits, entera de 3 con signo)
datos = k*datos/511/333;


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
load bits_tx.mat
load CONSTEL.mat
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
        load('S.mat');
        bits_rx = zeros(1, M*length(datos));
        for d = 1:length(datos)
            % Detectamos el símbolo
            [~, ind] = min((C-datos(d)).^2);
            bits_rx(1, M*(d-1)+1:M*d) = S(:,ind);
        end
end
load BER.mat
fprintf('BER Matlab = %f\n', BER);
BER = mean(xor(bits_rx, bits_tx.'));
fprintf(1, 'BER VHDL = %f\n', BER);