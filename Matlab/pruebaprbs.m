% Cada ejecución es una iteración en el prbs para sacar el signo de un
% piloto. Inicializar primero, y luego comentar las líneas para
% inicializar.

%% Inicializar
secuencia         = ones(1,11);
ESPACIADO_PILOTOS = 12;
NPORTADORAS       = 1705;
NPILOTOS          = ceil(NPORTADORAS/ESPACIADO_PILOTOS);

pilotos = zeros(1,NPILOTOS);
for p = 1:NPILOTOS
    pilotos(1,p) = secuencia(11);
    for k = 1:ESPACIADO_PILOTOS
        aux = xor(secuencia(9), secuencia(11));
        secuencia(2:end) = secuencia(1:end-1);
        secuencia(1) = aux;
    end
end