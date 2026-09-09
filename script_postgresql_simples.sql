CREATE TABLE usuario (
    id_usuario INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cpf VARCHAR(14) UNIQUE NOT NULL,
    senha VARCHAR(255) NOT NULL,
    nome_completo VARCHAR(200) NOT NULL,
    email VARCHAR(100),
    telefone VARCHAR(20),
    logradouro VARCHAR(150) NOT NULL,
    numero VARCHAR(10) NOT NULL,
    complemento VARCHAR(50),
    bairro VARCHAR(100) NOT NULL,
    cidade VARCHAR(100) NOT NULL,
    estado VARCHAR(2) NOT NULL,
    cep VARCHAR(10) NOT NULL,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ultimo_login TIMESTAMP,
    status VARCHAR(10) DEFAULT 'ativo'
        CHECK (status IN ('ativo', 'inativo', 'bloqueado'))
);

CREATE TABLE obra_arte (
    id_obra SERIAL PRIMARY KEY,
    id_vendedor INTEGER NOT NULL,
    titulo VARCHAR(200) NOT NULL,
    descricao TEXT,
    tecnica VARCHAR(100),
    dimensoes VARCHAR(50),
    ano_criacao INTEGER,
    preco DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'em_analise',
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_venda TIMESTAMP,
    visualizacoes INTEGER DEFAULT 0,
    CONSTRAINT check_obra_preco CHECK (preco >= 0),
    CONSTRAINT check_obra_status CHECK (status IN ('disponivel', 'vendida', 'reservada', 'em_analise')),
    CONSTRAINT fk_obra_vendedor FOREIGN KEY (id_vendedor) REFERENCES usuario(id_usuario)
);

CREATE TABLE imagem_obra (
    id_imagem SERIAL PRIMARY KEY,
    id_obra INTEGER NOT NULL,
    url_imagem VARCHAR(500) NOT NULL,
    ordem INTEGER DEFAULT 0,
    eh_capa BOOLEAN DEFAULT FALSE,
    CONSTRAINT fk_imagem_obra FOREIGN KEY (id_obra) REFERENCES obra_arte(id_obra) ON DELETE CASCADE
);

CREATE TABLE transacao (
    id_transacao SERIAL PRIMARY KEY,
    id_obra INTEGER NOT NULL,
    id_comprador INTEGER NOT NULL,
    id_vendedor INTEGER NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pendente',
    data_transacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_finalizacao TIMESTAMP,
    forma_pagamento VARCHAR(50),
    CONSTRAINT check_transacao_valor CHECK (valor >= 0),
    CONSTRAINT check_transacao_status CHECK (status IN ('pendente', 'aprovada', 'finalizada', 'cancelada')),
    CONSTRAINT fk_transacao_obra FOREIGN KEY (id_obra) REFERENCES obra_arte(id_obra),
    CONSTRAINT fk_transacao_comprador FOREIGN KEY (id_comprador) REFERENCES usuario(id_usuario),
    CONSTRAINT fk_transacao_vendedor FOREIGN KEY (id_vendedor) REFERENCES usuario(id_usuario)
);

CREATE TABLE localizacao_entrega (
    id_localizacao SERIAL PRIMARY KEY,
    id_transacao INTEGER NOT NULL,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    endereco_completo TEXT NOT NULL,
    ponto_referencia VARCHAR(200),
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_confirmacao_entrega TIMESTAMP,
    status VARCHAR(20) DEFAULT 'gerada',
    CONSTRAINT check_localizacao_status CHECK (status IN ('gerada', 'confirmada', 'entregue')),
    CONSTRAINT fk_localizacao_transacao FOREIGN KEY (id_transacao) REFERENCES transacao(id_transacao)
);

CREATE TABLE avaliacao (
    id_avaliacao SERIAL PRIMARY KEY,
    id_transacao INTEGER NOT NULL,
    id_avaliador INTEGER NOT NULL,
    id_avaliado INTEGER NOT NULL,
    nota INTEGER NOT NULL,
    comentario TEXT,
    data_avaliacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_avaliacao_nota CHECK (nota BETWEEN 1 AND 5),
    CONSTRAINT fk_avaliacao_transacao FOREIGN KEY (id_transacao) REFERENCES transacao(id_transacao),
    CONSTRAINT fk_avaliacao_avaliador FOREIGN KEY (id_avaliador) REFERENCES usuario(id_usuario),
    CONSTRAINT fk_avaliacao_avaliado FOREIGN KEY (id_avaliado) REFERENCES usuario(id_usuario)
);

create or REPLACE function atualizar_data_venda()
returns trigger as $$
begin
	if new.status = 'vendida' and old.status !='vendida' then
	new.data_venda = CURRENT_TIMESTAMP;
end if;
return new;
end;
$$ language plpgsql;


CREATE TRIGGER trigger_atualizar_venda
BEFORE UPDATE OF status ON obra_arte
FOR EACH ROW
WHEN (NEW.status = 'vendida')
EXECUTE FUNCTION atualizar_data_venda();

CREATE OR REPLACE FUNCTION atualizar_status_obra()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'finalizada' AND OLD.status != 'finalizada' THEN
        UPDATE obra_arte 
        SET status = 'vendida' 
        WHERE id_obra = NEW.id_obra;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_atualizar_status_obra
AFTER UPDATE OF status ON transacao
FOR EACH ROW
WHEN (NEW.status = 'finalizada')
EXECUTE FUNCTION atualizar_status_obra();


CREATE VIEW vw_obras_disponiveis AS
SELECT 
    o.id_obra,
    o.titulo,
    o.descricao,
    o.tecnica,
    o.dimensoes,
    o.preco,
    o.data_cadastro,
    o.visualizacoes,
    u.id_usuario AS id_vendedor,
    u.nome_completo AS nome_vendedor,
    u.cidade,
    u.estado,
    (SELECT url_imagem FROM imagem_obra WHERE id_obra = o.id_obra AND eh_capa = TRUE LIMIT 1) AS imagem_capa
FROM obra_arte o
JOIN usuario u ON o.id_vendedor = u.id_usuario
WHERE o.status = 'disponivel'
ORDER BY o.data_cadastro DESC;

CREATE VIEW vw_transacoes_detalhadas AS
SELECT 
    t.id_transacao,
    t.valor,
    t.status AS status_transacao,
    t.data_transacao,
    t.data_finalizacao,
    t.forma_pagamento,
    o.id_obra,
    o.titulo AS obra_titulo,
    o.preco AS obra_preco_venda,
    c.id_usuario AS comprador_id,
    c.nome_completo AS comprador_nome,
    c.cpf AS comprador_cpf,
    v.id_usuario AS vendedor_id,
    v.nome_completo AS vendedor_nome,
    v.cpf AS vendedor_cpf,
    l.id_localizacao,
    l.latitude,
    l.longitude,
    l.endereco_completo AS endereco_entrega,
    l.ponto_referencia,
    l.status AS status_entrega,
    l.data_criacao AS data_criacao_entrega
FROM transacao t
JOIN obra_arte o ON t.id_obra = o.id_obra
JOIN usuario c ON t.id_comprador = c.id_usuario
JOIN usuario v ON t.id_vendedor = v.id_usuario
LEFT JOIN localizacao_entrega l ON t.id_transacao = l.id_transacao
ORDER BY t.data_transacao DESC;

CREATE VIEW vw_avaliacoes_usuario AS
SELECT 
    u.id_usuario,
    u.nome_completo,
    u.cpf,
    COUNT(a.id_avaliacao) AS total_avaliacoes,
    COALESCE(ROUND(AVG(a.nota), 2), 0) AS media_nota,
    COUNT(CASE WHEN a.nota >= 4 THEN 1 END) AS avaliacoes_positivas,
    COUNT(CASE WHEN a.nota <= 2 THEN 1 END) AS avaliacoes_negativas,
    COUNT(CASE WHEN a.nota = 5 THEN 1 END) AS avaliacoes_5_estrelas
FROM usuario u
LEFT JOIN avaliacao a ON u.id_usuario = a.id_avaliado
GROUP BY u.id_usuario, u.nome_completo, u.cpf
ORDER BY media_nota DESC;


CREATE VIEW vw_estatisticas_vendedor AS
SELECT 
    u.id_usuario,
    u.nome_completo,
    COUNT(o.id_obra) AS total_obras,
    SUM(CASE WHEN o.status = 'disponivel' THEN 1 ELSE 0 END) AS obras_disponiveis,
    SUM(CASE WHEN o.status = 'vendida' THEN 1 ELSE 0 END) AS obras_vendidas,
    COALESCE(SUM(CASE WHEN o.status = 'vendida' THEN o.preco ELSE 0 END), 0) AS total_vendas,
    COALESCE(AVG(o.preco), 0) AS preco_medio_obras
FROM usuario u
LEFT JOIN obra_arte o ON u.id_usuario = o.id_vendedor
GROUP BY u.id_usuario, u.nome_completo
ORDER BY total_vendas DESC;


