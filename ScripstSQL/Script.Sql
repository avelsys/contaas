CREATE database contas;

CREATE TABLE empresas (
    id_empresa SERIAL primary key,
    razao_social VARCHAR(200) NOT NULL,
    nome_fantasia VARCHAR(150),
    cnpj_cpf VARCHAR(18) UNIQUE,
    inscricao_estadual VARCHAR(20),
    endereco VARCHAR(200),
    numero VARCHAR(10),
    complemento VARCHAR(50),
    bairro VARCHAR(100),
    cidade VARCHAR(100),
    estado VARCHAR(2),
    cep VARCHAR(10),
    telefone VARCHAR(20),
    email VARCHAR(100),
    ativo BOOLEAN DEFAULT TRUE,
    data_cadastro TIMESTAMP default current_TIMESTAMP,
    data_atualizacao TIMESTAMP default current_TIMESTAMP
    );

create unique index idx_cnpj on empresas (cnpj_cpf);
create index idx_ativo_empresa on empresas (ativo);

CREATE TABLE fornecedores (
    id_fornecedor SERIAL PRIMARY KEY,
    id_empresa INT NOT NULL,
    tipo_pessoa VARCHAR(10) NOT NULL CHECK (tipo_pessoa IN ('FISICA', 'JURIDICA')),
    razao_social VARCHAR(200) NOT NULL,
    nome_fantasia VARCHAR(150),
    cpf_cnpj VARCHAR(18) NOT NULL,
    rg_inscricao_estadual VARCHAR(20),
    endereco VARCHAR(200),
    numero VARCHAR(10),
    complemento VARCHAR(50),
    bairro VARCHAR(100),
    cidade VARCHAR(100),
    estado VARCHAR(2),
    cep VARCHAR(10),
    telefone VARCHAR(20),
    celular VARCHAR(20),
    email VARCHAR(100),
    observacoes TEXT,
    ativo BOOLEAN DEFAULT TRUE,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_empresa FOREIGN KEY (id_empresa) REFERENCES empresas(id_empresa)
);

CREATE INDEX idx_empresa_fornecedor ON fornecedores (id_empresa);
CREATE INDEX idx_cpf_cnpj ON fornecedores (cpf_cnpj);
CREATE INDEX idx_razao_social ON fornecedores (razao_social);
CREATE INDEX idx_ativo_fornecedor ON fornecedores (ativo);

CREATE TYPE tipo_pessoa_enum AS ENUM ('FISICA', 'JURIDICA');

CREATE TABLE clientes (
    id_cliente SERIAL PRIMARY KEY,
    id_empresa INT NOT NULL REFERENCES empresas(id_empresa),
    tipo_pessoa tipo_pessoa_enum NOT NULL,
    razao_social VARCHAR(200) NOT NULL,
    nome_fantasia VARCHAR(150),
    cpf_cnpj VARCHAR(18) NOT NULL,
    rg_inscricao_estadual VARCHAR(20),
    endereco VARCHAR(200),
    numero VARCHAR(10),
    complemento VARCHAR(50),
    bairro VARCHAR(100),
    cidade VARCHAR(100),
    estado VARCHAR(2),
    cep VARCHAR(10),
    telefone VARCHAR(20),
    celular VARCHAR(20),
    email VARCHAR(100),
    limite_credito DECIMAL(15, 2) DEFAULT 0.00,
    observacoes TEXT,
    ativo BOOLEAN DEFAULT TRUE,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TYPE categoria_tipo_enum AS ENUM ('DESPESA', 'RECEITA');

CREATE TABLE categorias (
    id_categoria SERIAL PRIMARY KEY,
    id_empresa INT NOT NULL REFERENCES empresas(id_empresa),
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    tipo categoria_tipo_enum NOT NULL,
    ativo BOOLEAN DEFAULT TRUE,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

CREATE INDEX idx_empresa_categoria ON categorias (id_empresa);
CREATE INDEX idx_tipo ON categorias (tipo);
CREATE INDEX idx_ativo_categoria ON categorias (ativo);

CREATE TABLE centros_custo (
    id_centro_custo SERIAL PRIMARY KEY,
    id_empresa INT NOT NULL REFERENCES empresas(id_empresa),
    codigo VARCHAR(20) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN DEFAULT TRUE,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_empresa_centro ON centros_custo (id_empresa);
CREATE INDEX idx_codigo ON centros_custo (codigo);
CREATE INDEX idx_ativo_centro ON centros_custo (ativo);

CREATE TYPE tipo_pagamento_enum AS ENUM (
  'dinheiro', 
  'cheque',
  'CARTAO_CREDITO', 
  'CARTAO_DEBITO', 
  'TRANSFERENCIA', 
  'BOLETO', 
  'PIX'
);

CREATE TABLE formas_pagamento (
    id_forma_pagamento SERIAL PRIMARY KEY,
    id_empresa INT NOT NULL REFERENCES empresas(id_empresa),
    nome VARCHAR(50) NOT NULL,
    descricao VARCHAR(200),
    tipo tipo_pagamento_enum NOT NULL,
    prazo_compensacao INT DEFAULT 0,
    taxa_percentual DECIMAL(5,2) DEFAULT 0.00,
    taxa_fixa DECIMAL(10,2) DEFAULT 0.00,
    ativo BOOLEAN DEFAULT TRUE,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_empresa_forma ON formas_pagamento (id_empresa);
CREATE INDEX idx_tipo ON formas_pagamento (tipo);
CREATE INDEX idx_ativo ON formas_pagamento (ativo);

CREATE TYPE tipo_conta_enum AS ENUM ('CORRENTE', 'POUPANCA', 'APLICACAO');

CREATE TABLE contas_bancarias (
    id_conta_bancaria SERIAL PRIMARY KEY,
    id_empresa INT NOT NULL REFERENCES empresas(id_empresa),
    banco VARCHAR(100) NOT NULL,
    agencia VARCHAR(10) NOT NULL,
    conta VARCHAR(20) NOT NULL,
    digito VARCHAR(2),
    tipo_conta tipo_conta_enum NOT NULL,
    saldo_inicial DECIMAL(15,2) DEFAULT 0.00,
    saldo_atual DECIMAL(15,2) DEFAULT 0.00,
    limite_credito DECIMAL(15,2) DEFAULT 0.00,
    ativo BOOLEAN DEFAULT TRUE,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE INDEX idx_empresa_conta ON contas_bancarias (id_empresa);
CREATE INDEX idx_banco_agencia_conta ON contas_bancarias (banco, agencia, conta);
CREATE INDEX idx_ativo_conta ON contas_bancarias (ativo);

CREATE TYPE status_conta_enum AS ENUM ('PENDENTE', 'PAGO', 'VENCIDO', 'CANCELADO');

CREATE TABLE contas_pagar (
    id_conta_pagar SERIAL PRIMARY KEY,
    id_empresa INT NOT NULL REFERENCES empresas(id_empresa),
    id_fornecedor INT NOT NULL REFERENCES fornecedores(id_fornecedor),
    id_categoria INT NOT NULL REFERENCES categorias(id_categoria),
    id_centro_custo INT REFERENCES centros_custo(id_centro_custo),
    numero_documento VARCHAR(50),
    descricao VARCHAR(200) NOT NULL,
    valor_original DECIMAL(15,2) NOT NULL,
    valor_desconto DECIMAL(15,2) DEFAULT 0.00,
    valor_acrescimo DECIMAL(15,2) DEFAULT 0.00,
    valor_final DECIMAL(15,2) NOT NULL,
    valor_pago DECIMAL(15,2) DEFAULT 0.00,
    data_emissao DATE NOT NULL,
    data_vencimento DATE NOT NULL,
    data_pagamento DATE,
    status status_conta_enum DEFAULT 'PENDENTE',
    observacoes TEXT,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE INDEX idx_empresa_pagar ON contas_pagar (id_empresa);
CREATE INDEX idx_fornecedor ON contas_pagar (id_fornecedor);
CREATE INDEX idx_data_vencimento ON contas_pagar (data_vencimento);
CREATE INDEX idx_status ON contas_pagar (status);
CREATE INDEX idx_numero_documento ON contas_pagar (numero_documento);


CREATE TYPE status_receber_enum AS ENUM ('PENDENTE', 'RECEBIDO', 'VENCIDO', 'CANCELADO');

CREATE TABLE contas_receber (
    id_conta_receber SERIAL PRIMARY KEY,
    id_empresa INT NOT NULL REFERENCES empresas(id_empresa),
    id_cliente INT NOT NULL REFERENCES clientes(id_cliente),
    id_categoria INT NOT NULL REFERENCES categorias(id_categoria),
    id_centro_custo INT REFERENCES centros_custo(id_centro_custo),
    numero_documento VARCHAR(50),
    descricao VARCHAR(200) NOT NULL,
    valor_original DECIMAL(15,2) NOT NULL,
    valor_desconto DECIMAL(15,2) DEFAULT 0.00,
    valor_acrescimo DECIMAL(15,2) DEFAULT 0.00,
    valor_final DECIMAL(15,2) NOT NULL,
    valor_recebido DECIMAL(15,2) DEFAULT 0.00,
    data_emissao DATE NOT NULL,
    data_vencimento DATE NOT NULL,
    data_recebimento DATE,
    status status_receber_enum DEFAULT 'PENDENTE',
    observacoes TEXT,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE INDEX idx_empresa_receber ON contas_receber (id_empresa);
CREATE INDEX idx_cliente ON contas_receber (id_cliente);
CREATE INDEX idx_data_vencimento ON contas_receber (data_vencimento);
CREATE INDEX idx_status ON contas_receber (status);
CREATE INDEX idx_numero_documento_receber ON contas_receber (numero_documento);


CREATE TABLE pagamentos (
    id_pagamento SERIAL PRIMARY KEY,
    id_conta_pagar INT NOT NULL REFERENCES contas_pagar(id_conta_pagar),
    id_conta_bancaria INT REFERENCES contas_bancarias(id_conta_bancaria),
    id_forma_pagamento INT NOT NULL REFERENCES formas_pagamento(id_forma_pagamento),
    numero_pagamento VARCHAR(50),
    valor_pago DECIMAL(15,2) NOT NULL,
    valor_desconto DECIMAL(15,2) DEFAULT 0.00,
    valor_acrescimo DECIMAL(15,2) DEFAULT 0.00,
    data_pagamento DATE NOT NULL,
    observacoes TEXT,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_conta_pagar_pagamentos ON pagamentos (id_conta_pagar);
CREATE INDEX idx_conta_bancaria_pagamentos ON pagamentos (id_conta_bancaria);
CREATE INDEX idx_forma_pagamento_pagamentos ON pagamentos (id_forma_pagamento);
CREATE INDEX idx_data_pagamento ON pagamentos (data_pagamento);

CREATE INDEX idx_conta_pagar ON pagamentos (id_conta_pagar);
CREATE INDEX idx_data_pagamento ON pagamentos (data_pagamento);
CREATE INDEX idx_numero_pagamento ON pagamentos (numero_pagamento);

CREATE TABLE recebimentos (
    id_recebimento SERIAL PRIMARY KEY,
    id_conta_receber INT NOT NULL REFERENCES contas_receber(id_conta_receber),
    id_conta_bancaria INT REFERENCES contas_bancarias(id_conta_bancaria),
    id_forma_pagamento INT NOT NULL REFERENCES formas_pagamento(id_forma_pagamento),
    numero_recebimento VARCHAR(50),
    valor_recebido DECIMAL(15,2) NOT NULL,
    valor_desconto DECIMAL(15,2) DEFAULT 0.00,
    valor_acrescimo DECIMAL(15,2) DEFAULT 0.00,
    data_recebimento DATE NOT NULL,
    observacoes TEXT,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_conta_receber ON recebimentos (id_conta_receber);
CREATE INDEX idx_data_recebimento ON recebimentos (data_recebimento);
CREATE INDEX idx_numero_recebimento ON recebimentos (numero_recebimento);

CREATE TYPE perfil_enum AS ENUM ('ADMIN', 'OPERADOR', 'CONSULTA');

CREATE TABLE usuarios (
    id_usuario SERIAL PRIMARY KEY,
    id_empresa INT NOT NULL REFERENCES empresas(id_empresa),
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    senha VARCHAR(255) NOT NULL,
    perfil perfil_enum NOT NULL,
    ativo BOOLEAN DEFAULT TRUE,
    ultimo_acesso TIMESTAMP NULL,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_empresa_usuario ON usuarios (id_empresa);
CREATE INDEX idx_ativo_usuarios ON usuarios (ativo);

CREATE TYPE operacao_enum AS ENUM ('INSERT', 'UPDATE', 'DELETE');


CREATE TABLE log_operacoes (
    id_log SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL REFERENCES usuarios(id_usuario),
    id_empresa INT NOT NULL REFERENCES empresas(id_empresa),
    tabela VARCHAR(50) NOT NULL,
    registro_id INT NOT NULL,
    operacao operacao_enum NOT NULL,
    valores_anteriores JSON,
    valores_novos JSON,
    ip_usuario VARCHAR(45),
    data_operacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tabela_registro ON log_operacoes (tabela, registro_id);
CREATE INDEX idx_data_operacao ON log_operacoes (data_operacao);
CREATE INDEX idx_usuario ON log_operacoes (id_usuario);

create or replace function atualizar_saldo_conta() returns trigger as $$
BEGIN
  UPDATE contas_bancarias cb
  SET saldo_atual = (
    SELECT COALESCE(SUM(r.valor_recebido), 0)
    FROM recebimentos r
    WHERE r.id_conta_bancaria = cb.id_conta_bancaria
  )
  WHERE cb.id_conta_bancaria = NEW.id_conta_bancaria;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE INDEX idx_contas_pagar_empresa_status_vencimento 
ON contas_pagar (id_empresa, status, data_vencimento);

CREATE INDEX idx_contas_receber_empresa_status_vencimento 
ON contas_receber (id_empresa, status, data_vencimento);

CREATE INDEX idx_pagamentos_data_pagamento_conta_bancaria 
ON pagamentos (data_pagamento, id_conta_bancaria);

CREATE INDEX idx_recebimentos_data_recebimento_conta_bancaria 
ON recebimentos (data_recebimento, id_conta_bancaria);


















 
