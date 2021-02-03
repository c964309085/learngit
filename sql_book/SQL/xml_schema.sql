-- This script does the following:
--   1. Creates xml_user
--   2. Creates the database table
--   3. Populates the database table with sample data
--   4. Creates the PL/SQL code

-- attempt to drop the user (this will generate an error
-- if the user does not yet exist; do not worry about this
-- error); this statement is included so that you do not have
-- to manually run the DROP before recreating the schema
DROP USER xml_user CASCADE;

-- create xml_user
CREATE USER xml_user IDENTIFIED BY xml_password;

-- allow the user to connect, create database objects and
-- create directory objects (for the BFILEs)
GRANT connect, resource, create any directory TO xml_user;

-- give xml_user a quota of 10M on the users tablespace
ALTER USER xml_user QUOTA 10M ON users;

-- connect as xml_user
CONNECT xml_user/xml_password;

-- create the types
CREATE TYPE t_product AS OBJECT (
  product_id INTEGER,
  name VARCHAR2(15),
  quantity INTEGER
);
/

CREATE TYPE t_nested_table_product AS TABLE OF t_product;
/

-- create the table
CREATE TABLE purchase_order (
  purchase_order_id INTEGER CONSTRAINT purchase_order_pk PRIMARY KEY,
  customer_order_id INTEGER,
  order_date DATE,
  customer_name VARCHAR2(25),
  street VARCHAR2(15),
  city VARCHAR2(15),
  state VARCHAR2(2),
  zip VARCHAR2(5),
  phone_number VARCHAR2(12),
  products t_nested_table_product,
  xml_purchase_order XMLType
)
NESTED TABLE products
STORE AS nested_products;

-- create the directory (you may need to modify this line)
CREATE OR REPLACE DIRECTORY XML_FILES_DIR AS 'C:\xml_files';

-- add a row to the table
INSERT INTO purchase_order (
  purchase_order_id,
  xml_purchase_order
) VALUES (
  1,
  XMLType(
    BFILENAME('XML_FILES_DIR', 'purchase_order.xml'),
    NLS_CHARSET_ID('AL32UTF8')
  )
);

-- commit the transaction
COMMIT;

-- create the PL/SQL code
CREATE PROCEDURE update_purchase_order(
  p_purchase_order_id IN purchase_order.purchase_order_id%TYPE
) AS
  v_count INTEGER := 1;

  -- declare a nested table to store products
  v_nested_table_products t_nested_table_product :=
    t_nested_table_product();

  -- declare a type to represent a product record
  TYPE t_product_record IS RECORD (
    product_id INTEGER,
    name VARCHAR2(15),
    quantity INTEGER
  );

  -- declare a REF CURSOR type to point to product records
  TYPE t_product_cursor IS REF CURSOR RETURN t_product_record;

  -- declare a cursor
  v_product_cursor t_product_cursor;

  -- declare a variable to store a product record
  v_product t_product_record;
BEGIN
  -- open v_product_cursor to read the product_id, name, and quantity for
  -- each product stored in the XML of the xml_purchase_order column
  -- in the purchase_order table
  OPEN v_product_cursor FOR
  SELECT
    EXTRACTVALUE(product.COLUMN_VALUE, '/product/product_id')
      AS product_id,
    EXTRACTVALUE(product.COLUMN_VALUE, '/product/name') AS name,
    EXTRACTVALUE(product.COLUMN_VALUE, '/product/quantity') AS quantity
  FROM TABLE(
    SELECT
      XMLSEQUENCE(EXTRACT(xml_purchase_order, '/purchase_order//product'))
    FROM purchase_order
    WHERE purchase_order_id = p_purchase_order_id
  ) product;

  -- loop over the contents of v_product_cursor
  LOOP
    -- fetch the product records from v_product_cursor and exit when there
    -- are no more records found
    FETCH v_product_cursor INTO v_product;
    EXIT WHEN v_product_cursor%NOTFOUND;

    -- extend v_nested_table_products so that a product can be stored in it
    v_nested_table_products.EXTEND;

    -- create a new product and store it in v_nested_table_products
    v_nested_table_products(v_count) :=
      t_product(v_product.product_id, v_product.name, v_product.quantity);

    -- display the new product stored in v_nested_table_products
    DBMS_OUTPUT.PUT_LINE('product_id = ' ||
      v_nested_table_products(v_count).product_id);
    DBMS_OUTPUT.PUT_LINE('name = ' ||
      v_nested_table_products(v_count).name);
    DBMS_OUTPUT.PUT_LINE('quantity = ' ||
      v_nested_table_products(v_count).quantity);

    -- increment v_count ready for the next iteration of the loop
    v_count := v_count + 1;
  END LOOP;

  -- close v_product_cursor
  CLOSE v_product_cursor;

  -- update the purchase_order table using the values extracted from the
  -- XML stored in the xml_purchase_order column (the products nested
  -- table is set to v_nested_table_products already populated by the
  -- previous loop)
  UPDATE purchase_order
  SET
    customer_order_id =
      EXTRACTVALUE(xml_purchase_order,
        '/purchase_order/customer_order_id'),
    order_date =
      TO_DATE(EXTRACTVALUE(xml_purchase_order,
        '/purchase_order/order_date'), 'YYYY-MM-DD'),
    customer_name =
      EXTRACTVALUE(xml_purchase_order, '/purchase_order/customer_name'),
    street =
      EXTRACTVALUE(xml_purchase_order, '/purchase_order/street'),
    city =
      EXTRACTVALUE(xml_purchase_order, '/purchase_order/city'),
    state =
      EXTRACTVALUE(xml_purchase_order, '/purchase_order/state'),
    zip =
      EXTRACTVALUE(xml_purchase_order, '/purchase_order/zip'),
    phone_number =
      EXTRACTVALUE(xml_purchase_order, '/purchase_order/phone_number'),
    products = v_nested_table_products
  WHERE purchase_order_id = p_purchase_order_id;

  -- commit the transaction
  COMMIT;
END update_purchase_order;
/
