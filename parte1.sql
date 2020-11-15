
-- 1 Consultar as tabelas de catálogo para listar todos os índices existentes acompanhados
--  das tabelas e colunas indexadas pelo mesmo.
SELECT * FROM pg_indexes WHERE tablename = 'Playlist';


-- INCOMPLETE: 
-- 2 Criar usando a linguagem de programação do SGBD escolhido um procedimento que
-- remova todos os índices de uma tabela informada como parâmetro.
CREATE OR REPLACE FUNCTION remove_indexes_by_table_name (table_name text) RETURNS VOID AS $$
    DECLARE
        ids varchar[] := ARRAY['t1','t2'];
    BEGIN
        FOR index_name IN ids LOOP
            EXECUTE 'DROP INDEX ' || index_name;
        END LOOP;
    END
$$ LANGUAGE plpgsql;
