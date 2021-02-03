-- This script Will only run if you are using Oracle Database 11g
-- or higher

-- This script contains the PL/SQL Oracle Database 11g examples

CREATE PROCEDURE get_area
AS
  v_width  SIMPLE_INTEGER := 10;
  v_height SIMPLE_INTEGER := 2;
  v_area   SIMPLE_INTEGER := v_width * v_height;
BEGIN
  DBMS_OUTPUT.PUT_LINE('v_area = ' || v_area);
END get_area;
/

CREATE TABLE new_products (
  product_id INTEGER CONSTRAINT new_products_pk PRIMARY KEY,
  name VARCHAR2(30) NOT NULL,
  price NUMBER(5, 2)
);

CREATE SEQUENCE s_product_id;

CREATE PROCEDURE add_new_products
AS
  v_product_id BINARY_INTEGER;
BEGIN
  -- use NEXTVAL to generate the initial sequence number
  v_product_id := s_product_id.NEXTVAL;
  DBMS_OUTPUT.PUT_LINE('v_product_id = ' || v_product_id);

  -- add a row to new_products
  INSERT INTO new_products
  VALUES (v_product_id, 'Plasma Physics book', 49.95);

  DBMS_OUTPUT.PUT_LINE('s_product_id.CURRVAL = ' || s_product_id.CURRVAL);

  -- use NEXTVAL to generate the next sequence number
  v_product_id := s_product_id.NEXTVAL;
  DBMS_OUTPUT.PUT_LINE('v_product_id = ' || v_product_id);

  -- add another row to new_products
  INSERT INTO new_products
  VALUES (v_product_id, 'Quantum Physics book', 69.95);

  DBMS_OUTPUT.PUT_LINE('s_product_id.CURRVAL = ' || s_product_id.CURRVAL);
END add_new_products;
/
