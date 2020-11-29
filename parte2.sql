-- 4. A base original do Chinook possui uma coluna Total na tabela Invoice representada de
-- forma redundante com as informações contidas nas colunas UnitPrice e Quantity na
-- tabela InvoiceLine. Podemos identificar nesse caso uma regra semântica onde o valor
-- Total de um Invoice deve ser igual à soma de UnitPrice * Quantity de todos os
-- registros de InvoiceLine relacionados a um Invoice. Implementar uma solução que
-- garanta a integridade dessa regra.

CREATE OR REPLACE FUNCTION valid_invoice_price_update() RETURNS trigger as $check_world_change$
DECLARE expected_value numeric(10,2);
BEGIN
    expected_value := (
        select SUM("UnitPrice" * "Quantity")
        from public."InvoiceLine" where "InvoiceId" = NEW."InvoiceId"
    );

    IF NOT NEW."Total" = expected_value THEN
        RAISE EXCEPTION 'ERROR';
    END IF;

    RETURN NEW;
END
$check_world_change$ LANGUAGE plpgsql;

CREATE TRIGGER valid_invoice_price_update BEFORE UPDATE ON "Invoice"
  FOR EACH ROW EXECUTE PROCEDURE valid_invoice_price_update();
