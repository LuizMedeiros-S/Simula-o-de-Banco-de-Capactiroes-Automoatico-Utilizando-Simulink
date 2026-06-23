function [com,FP_corrigido] = fcn(P, Q, ref)

% Memória para guardar o estado das chaves
persistent estado
if isempty(estado)
    estado = zeros(1,7); % Ajustado para 7 chaves
end


% --- Trava de Segurança Inicial ---


% --- Parâmetros Físicos Atualizados ---
% Vetor ordenado do MAIOR para o MENOR para ajuste inteligente
Banco = [2.5e3, 10e3, 60e3, 60e3, 60e3, 60e3 ,60e3 ];

liga = estado;
soma = sum(liga .* Banco);

% Estimativa da Carga Real
Q_carga = Q + soma;
Q_alvo = P * tan(acos(ref));
Qdsj = Q_carga - Q_alvo;

if Qdsj < 0
    Qdsj = 0;
end

% --- LÓGICA DE LIGAÇÃO (Testa os maiores degraus primeiro) ---
for t = 1:length(Banco)
    % A margem agora é dinâmica: 55% do tamanho do estágio avaliado
    margem_dinamica = Banco(t) * 0.6; 
    
    if soma < (Qdsj - margem_dinamica) && liga(t) == 0
        soma = soma + Banco(t);
        liga(t) = 1;
    end
end

% --- LÓGICA DE DESLIGAMENTO (Testa os menores degraus primeiro) ---
for t = length(Banco):-1:1
    margem_dinamica = Banco(t) * 0.55;
    
    if soma > (Qdsj + margem_dinamica) && liga(t) == 1
        soma = soma - Banco(t);
        liga(t) = 0;
    end
end

% Atualização de Memória
estado = liga;
com = liga'; % Saída de 7 vias

% Cálculo do FP estimado
Q_rede_estimado = Q_carga - soma; 
S_estimado = sqrt(P^2 + Q_rede_estimado^2);
if S_estimado > 0
    FP_corrigido = P / S_estimado;
else
    FP_corrigido = 1;
end


end