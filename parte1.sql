
-- 1 Consultar as tabelas de catálogo para listar todos os índices existentes acompanhados
--  das tabelas e colunas indexadas pelo mesmo.
SELECT tablename, indexname, indexdef FROM pg_indexes;


-- 2 Criar usando a linguagem de programação do SGBD escolhido um procedimento que
-- remova todos os índices de uma tabela informada como parâmetro.
CREATE OR REPLACE FUNCTION remove_indexes_by_table_name (table_name text) RETURNS INTEGER AS $$
    DECLARE
        r text;
    BEGIN
        FOR r IN
            SELECT indexname FROM pg_indexes WHERE tablename = table_name
        LOOP
            EXECUTE 'DROP INDEX IF EXISTS ' || r;
        END LOOP;
        RETURN 1;
    END
$$ LANGUAGE plpgsql;
