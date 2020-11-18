
-- 1 Consultar as tabelas de catálogo para listar todos os índices existentes acompanhados
--  das tabelas e colunas indexadas pelo mesmo.
SELECT * FROM pg_catalog.pg_indexes WHERE tablename = 'MediaType';


-- INCOMPLETE: Ainda é necessário lidar com uma excessão caso não seja possível deletar o index
-- 2 Criar usando a linguagem de programação do SGBD escolhido um procedimento que
-- remova todos os índices de uma tabela informada como parâmetro.
CREATE OR REPLACE FUNCTION remove_indexes_by_table_name (table_name text) RETURNS VOID AS $$
    DECLARE
        r text;
    BEGIN
        FOR r IN
            SELECT indexname FROM pg_indexes WHERE tablename = table_name
        LOOP
            EXECUTE 'ALTER TABLE "' || table_name || '" DROP CONSTRAINT "' || r || '" CASCADE';
        END LOOP;
    END
$$ LANGUAGE plpgsql;
