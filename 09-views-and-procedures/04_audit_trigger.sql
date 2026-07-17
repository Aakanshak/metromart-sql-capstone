/*
Business question: Who changed an order status, when, and from what value to what value?
*/
CREATE TABLE IF NOT EXISTS order_status_audit(
 audit_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,order_row_id bigint NOT NULL,
 order_id bigint NOT NULL,old_status text,new_status text,changed_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 changed_by text NOT NULL DEFAULT current_user
);
CREATE OR REPLACE FUNCTION fn_audit_order_status() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF NEW.status IS DISTINCT FROM OLD.status THEN
  INSERT INTO order_status_audit(order_row_id,order_id,old_status,new_status) VALUES(OLD.order_row_id,OLD.order_id,OLD.status,NEW.status);
 END IF; RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS trg_audit_order_status ON orders;
CREATE TRIGGER trg_audit_order_status AFTER UPDATE OF status ON orders FOR EACH ROW EXECUTE FUNCTION fn_audit_order_status();
/*
So what: IS DISTINCT FROM handles null-safe change detection and creates a durable operational trail for return/cancellation investigations.
*/
