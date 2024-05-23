CREATE DATABASE db_estoque;
USE db_estoque;

CREATE TABLE categorias_produtos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100)
);

CREATE TABLE produtos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    categoria_id INT,
    nome VARCHAR(100),
    quantidade INT,
    preco DECIMAL(10, 2),
    FOREIGN KEY (categoria_id) REFERENCES categorias_produtos(id)
);


CREATE TABLE clientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100),
    cpf varchar(15),
    email VARCHAR(100),
    telefone VARCHAR(20)
);

CREATE TABLE vendas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT,
    produto_id INT,
    quantidade INT,
    data_venda TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id),
    FOREIGN KEY (produto_id) REFERENCES produtos(id)
);

-- Mostra todo o estoque
CREATE VIEW estoque AS
SELECT p.id, p.nome AS nome_produto, p.quantidade, p.categoria_id, cp.nome AS nome_categoria, p.preco
FROM produtos p
JOIN categorias_produtos cp ON p.categoria_id = cp.id;


CREATE VIEW total_vendas_produto AS
SELECT p.id AS produto_id,
       p.nome AS produto,
       cp.nome AS categoria,
       SUM(v.quantidade) AS total_vendido
FROM vendas v
JOIN produtos p ON v.produto_id = p.id
JOIN categorias_produtos cp ON p.categoria_id = cp.id
GROUP BY p.id, p.nome, cp.nome;



CREATE VIEW exibir_clientes as
select id, nome, cpf,email, telefone 
from clientes;


CREATE VIEW qtd_compras_cliente AS
SELECT c.nome AS nome_cliente, COUNT(v.id) AS quantidade_de_compras
FROM clientes c
LEFT JOIN vendas v ON c.id = v.id_cliente
GROUP BY c.nome;


CREATE VIEW vendasGeral_produtos AS
SELECT v.id AS venda_id, 
       v.id_cliente, 
       c.nome AS nome_cliente, 
       v.produto_id, 
       p.nome AS nome_produto, 
       v.quantidade, 
       (p.preco * v.quantidade) AS total
FROM vendas v
JOIN produtos p ON v.produto_id = p.id
JOIN clientes c ON v.id_cliente = c.id;



-- Registra venda do produto e quem comprou
DELIMITER //
CREATE PROCEDURE adicionar_venda(
  IN id_cliente INT,
    IN produto_id INT,
    IN quantidade INT
)
BEGIN
    INSERT INTO vendas (id_cliente, produto_id, quantidade) VALUES (id_cliente, produto_id, quantidade);
END //
DELIMITER ;

-- Adiciona uma nova categoria que vai ser combinada com o produto, sendo obrigatório sua criação
DELIMITER //
CREATE PROCEDURE adicionar_categoria(
    IN nome_categoria VARCHAR(100)
)
BEGIN
    INSERT INTO categorias_produtos (nome) VALUES (nome_categoria);
END //
DELIMITER ;

-- Cadastra um novo cliente
DELIMITER //
CREATE PROCEDURE adicionar_cliente(
    IN nome_cliente VARCHAR(100),
    IN cpf_cliente VARCHAR(15),
    IN email_cliente VARCHAR(100),
    IN telefone_cliente VARCHAR(20)
)
BEGIN
    INSERT INTO clientes (nome, cpf, email, telefone) VALUES (nome_cliente, cpf_cliente, email_cliente, telefone_cliente);
END //
DELIMITER ;

-- Cria um novo produto na tabela produto
DELIMITER //
CREATE PROCEDURE adicionar_produto(
    IN categoria_id INT,
    IN nome_produto VARCHAR(100),
    IN quantidade INT,
    IN preco DECIMAL(10, 2)
)
BEGIN
    INSERT INTO produtos (categoria_id, nome, quantidade, preco) VALUES (categoria_id, nome_produto, quantidade, preco);
END //
DELIMITER ;


-- Altera a quantidade de produtos no estoque e altera o seu valor
DELIMITER //

CREATE PROCEDURE alterar_produto_estoque_valor(
    IN produto_id INT,
    IN nova_quantidade INT,
    IN novo_preco DECIMAL(10, 2)
)
BEGIN
    -- Atualiza a quantidade no estoque
    UPDATE produtos SET quantidade = nova_quantidade WHERE id = produto_id;
    
    -- Atualiza o preço do produto
    UPDATE produtos SET preco = novo_preco WHERE id = produto_id;
END //

DELIMITER ;

-- Deleta todos os produtos com o ID enviado
DELIMITER //
CREATE PROCEDURE deletar_produto(
    IN produto_id_parametro INT
)
BEGIN
	-- Desabilita o modo de atualização segura, importante, se não não conseguimos fazer esse delete
	SET SQL_SAFE_UPDATES = 0; 

    DELETE FROM vendas WHERE produto_id = produto_id_parametro;
    DELETE FROM produtos WHERE id = produto_id_parametro;
    
    -- Habilita o modo de atualização segura
    SET SQL_SAFE_UPDATES = 1;
END //
DELIMITER ;


-- Só possivel deletar se a categoria não estiver sendo usada, então primeiro delete todos os produtos de tal categoria
DELIMITER // 
CREATE PROCEDURE deletar_categoria(
    IN categoria_id INT
)
BEGIN
    DELETE FROM categorias_produtos where id = categoria_id;
END //
DELIMITER ;


-- Trigger para atualizar o estoque após uma venda
DELIMITER //

CREATE TRIGGER atualizar_estoque_after_insert
AFTER INSERT ON vendas
FOR EACH ROW
BEGIN
    DECLARE novo_estoque INT;
    DECLARE produto_id INT;
    DECLARE quantidade_vendida INT;
    
    -- Obter o ID do produto e a quantidade vendida
    SELECT NEW.produto_id, NEW.quantidade INTO produto_id, quantidade_vendida;
    
    -- Atualizar o estoque
    SELECT quantidade INTO novo_estoque FROM produtos WHERE id = produto_id;
    SET novo_estoque = novo_estoque - quantidade_vendida;
    UPDATE produtos SET quantidade = novo_estoque WHERE id = produto_id;
END //

DELIMITER ;

-- Chamada das Procedures
CALL adicionar_categoria('Eletrodomésticos');
CALL adicionar_cliente('Ana', '123.456.789-00', 'ana@teste.com', '51997882342');
CALL adicionar_produto(1, 'Geladeira', 5, 1999.99);
CALL adicionar_venda(1, 1, 1);


CALL adicionar_categoria('Móveis');
CALL adicionar_cliente('Pedro', '987.654.321-00', 'pedro@teste.com', '81991825137');
CALL adicionar_produto(2, 'Sofá', 3, 899.99);
CALL adicionar_venda(2, 2, 1);

CALL adicionar_categoria('Informática');
CALL adicionar_produto(2, 'Notebook', 3, 899.99);
CALL adicionar_cliente('Maria', '889.343.221-08', 'Maria@teste.com', '11995478459');
CALL adicionar_produto(3, 'Sofá', 8, 2849.99);
CALL adicionar_venda(3,3,3);


-- CALL deletar_produto(1);
-- CALL deletar_categoria(1);


CALL alterar_produto_estoque_valor(1, 10, 2199.99);
CALL adicionar_venda(2, 1, 8);

SELECT * FROM estoque;
SELECT * FROM exibir_clientes;
SELECT * FROM qtd_compras_cliente;
SELECT * FROM total_vendas_produto;
SELECT * FROM vendasgeral_produtos;

