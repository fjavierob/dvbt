% Máster en Ingeniería de Telecomunicación
%
% Electrónica Digital para Comunicaciones
% Proyecto: Estimador de Canal y Ecualizador para DVB-T
%
% Francisco Javier Ortiz Bonilla
%   uvus: fcoortbon

function pasarHex()

    load('datosMatlab/datosrx.mat');
    
    % Para el proyecto: nbits = 10, datos = portadoras recibidas en un símbolo.
    %                                       datos + pilotos
    %
    % Truncamos los datos de forma que tanto parte real como imaginaria estén
    % en el rango de un signed de 10 bits: -511, 511 y pasamos a hexadecimal
    % parte real y parte imaginaria.
    
    nbits = 10;
    datos = datosrx;
    % Factor para normalizar: k
    k     = max( max(abs(real(datos))), max(abs(imag(datos))) );
    fprintf('Factor de normalizacion k = %f\n', k);
    save('datosMatlab/k.mat', 'k');
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
    
    f = fopen('datosMatlab/datos_hex.txt','w');
    c = fopen('datosMatlab/datos.coe', 'w');
    p = fopen('datosMatlab/pilotos.txt', 'w');
    fprintf(c, 'memory_initialization_radix=16;\n');
    fprintf(c, 'memory_initialization_vector=\n');
    for k = 1:size(hdata,1)-1
        fprintf(f,'%s\n',hdata(k,:));
        fprintf(c,'%s,\n',hdata(k,:));
        if (mod(k-1,12) == 0)
            fprintf(p, '%s\n',hdata(k,:));
        end
    end
    fprintf(f,'%s', hdata(end,:));
    fprintf(p,'%s', hdata(end,:));
    fprintf(c,'%s;',hdata(end,:));
    fclose(f);
    fclose(c);
    fclose(p);
        
end

