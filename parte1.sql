
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


-- 4 Criar usando a linguagem de programação do SGBD escolhido um script que construa
-- de forma dinâmica a partir do catálogo os comandos create table das tabelas
-- existentes no esquema exemplo considerando pelo menos as informações sobre
-- colunas (nome, tipo e obrigatoriedade) e chaves primárias e estrangeiras.
CREATE OR REPLACE FUNCTION get_tables_statements_by_table_name() RETURNS text array AS
$get_tables_statements_by_table_name$
DECLARE
    ddl text;
    cl  record;
    table_sample text;
    result       text ARRAY;
BEGIN
    FOR table_sample IN
        select table_name FROM information_schema.tables WHERE table_schema = 'public'
    LOOP
        FOR cl IN
            select b.nspname                                       as schema_name,
                   b.relname                                       as table_name,
                   a.attname                                       as column_name,
                   pg_catalog.format_type(a.atttypid, a.atttypmod) as column_type,

                   CASE
                       WHEN
                           (select substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128)
                            FROM pg_catalog.pg_attrdef d
                            WHERE d.adrelid = a.attrelid
                              AND d.adnum = a.attnum
                              AND a.atthasdef) IS NOT NULL THEN
                               'DEFAULT ' || (select substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128)
                                              from pg_catalog.pg_attrdef d
                                              WHERE d.adrelid = a.attrelid
                                                AND d.adnum = a.attnum
                                                AND a.atthasdef)
                       ELSE ''
                       END                                         as column_default_value,
                   CASE
                       WHEN a.attnotnull = true THEN
                           'NOT NULL'
                       ELSE
                           'NULL'
                       END                                         as column_not_null,
                   a.attnum                                        as attnum,
                   e.max_attnum                                    as max_attnum
            from pg_catalog.pg_attribute a
                     inner join
                 (select c.oid,
                         n.nspname,
                         c.relname
                  from pg_catalog.pg_class c
                           LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
                  WHERE c.relname ~ ('^(' || table_sample || ')$')
                    AND pg_catalog.pg_table_is_visible(c.oid)
                  ORDER BY 2, 3) b
                 ON a.attrelid = b.oid
                     inner join
                 (select a.attrelid, max(a.attnum) as max_attnum
                  from pg_catalog.pg_attribute a
                  WHERE a.attnum > 0
                    AND NOT a.attisdropped
                  GROUP BY a.attrelid) e ON a.attrelid = e.attrelid
            WHERE a.attnum > 0
              AND NOT a.attisdropped
            ORDER BY a.attnum
            LOOP
                IF cl.attnum = 1 THEN
                    ddl := 'CREATE TABLE ' || cl.schema_name || '.' || cl.table_name || ' (';
                ELSE
                    ddl := ddl || ',';
                END IF;

                IF cl.attnum <= cl.max_attnum THEN
                    ddl := ddl || chr(10) || '    ' || cl.column_name || ' ' || cl.column_type || ' ' ||
                           cl.column_default_value || ' ' || cl.column_not_null;
                END IF;
            END LOOP;
        ddl := ddl || ');';
        result = array_append(result, ddl);
    END LOOP;
    RETURN result;
END;

$get_tables_statements_by_table_name$ LANGUAGE plpgsql SECURITY INVOKER;

select unnest(get_tables_statements_by_table_name());
