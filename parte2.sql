-- 4. A base original do Chinook possui uma coluna Total na tabela Invoice representada de
-- forma redundante com as informações contidas nas colunas UnitPrice e Quantity na
-- tabela InvoiceLine. Podemos identificar nesse caso uma regra semântica onde o valor
-- Total de um Invoice deve ser igual à soma de UnitPrice * Quantity de todos os
-- registros de InvoiceLine relacionados a um Invoice. Implementar uma solução que
-- garanta a integridade dessa regra.

-- PASSO 1: Trigger para impedir atualizações de preço
CREATE OR REPLACE FUNCTION valid_invoice_price_update() RETURNS trigger as $valid_invoice_price_update$
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
$valid_invoice_price_update$ LANGUAGE plpgsql;


-- PASSO 2: Trigger para atualizar total na tabela invoice ao inserir uma nova linha na tabela InvoiceLine
CREATE OR REPLACE FUNCTION update_invoice_price_on_insert_invoice_line() RETURNS trigger as $update_invoice_price_on_insert_invoice_line$
DECLARE old_total numeric(10,2);
DECLARE new_total numeric(10,2);
BEGIN
    old_total := (select sum("UnitPrice" * "Quantity") from "InvoiceLine" where "InvoiceId" = 10);
    new_total := old_total + (NEW."UnitPrice" * NEW."Quantity");

    UPDATE "Invoice" SET "Total" = new_total WHERE "InvoiceId" = NEW."InvoiceId";

    RETURN NEW;
END
$update_invoice_price_on_insert_invoice_line$ LANGUAGE plpgsql;
  
  
-- PASSO 3: Trigger para atualizar total na tabela invoice ao remove uma linha na tabela InvoiceLine
CREATE OR REPLACE FUNCTION update_invoice_price_on_delete_invoice_line() RETURNS trigger as $update_invoice_price_on_delete_invoice_line$
DECLARE old_total numeric(10,2);
DECLARE new_total numeric(10,2);
BEGIN
    old_total := (select sum("UnitPrice" * "Quantity") from "InvoiceLine" where "InvoiceId" = OLD."InvoiceId");
    new_total := old_total - (OLD."UnitPrice" * OLD."Quantity");

    UPDATE "Invoice" SET "Total" = new_total WHERE "InvoiceId" = OLD."InvoiceId";

    RETURN OLD;
END
$update_invoice_price_on_delete_invoice_line$ LANGUAGE plpgsql;


-- PASSO 4: Trigger para atualizar total na tabela invoice ao atualizar uma linha na tabela InvoiceLine
CREATE OR REPLACE FUNCTION update_invoice_price_on_delete_invoice_line() RETURNS trigger as $update_invoice_price_on_delete_invoice_line$
DECLARE old_total numeric(10,2);
DECLARE new_total numeric(10,2);
BEGIN
    old_total := (select sum("UnitPrice" * "Quantity") from "InvoiceLine" where "InvoiceId" = OLD."InvoiceId");
    new_total := old_total - (OLD."UnitPrice" * OLD."Quantity");

    UPDATE "Invoice" SET "Total" = new_total WHERE "InvoiceId" = OLD."InvoiceId";

    RETURN OLD;
END
$update_invoice_price_on_delete_invoice_line$ LANGUAGE plpgsql;


-- PASSO 5: Ligar as procedures à suas tabelas correspondentes 
CREATE TRIGGER valid_invoice_price_update BEFORE UPDATE ON "Invoice"
  FOR EACH ROW EXECUTE PROCEDURE valid_invoice_price_update();

CREATE TRIGGER update_invoice_price_on_insert_invoice_line BEFORE INSERT ON "InvoiceLine"
  FOR EACH ROW EXECUTE PROCEDURE update_invoice_price_on_insert_invoice_line();
  
CREATE TRIGGER update_invoice_price_on_delete_invoice_line BEFORE DELETE ON "InvoiceLine"
  FOR EACH ROW EXECUTE PROCEDURE update_invoice_price_on_delete_invoice_line();

CREATE TRIGGER update_invoice_price_on_update_invoice_line BEFORE UPDATE ON "InvoiceLine"
  FOR EACH ROW EXECUTE PROCEDURE update_invoice_price_on_update_invoice_line();
