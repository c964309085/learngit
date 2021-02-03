-- This script shows the use of unconstrained cursors

SET SERVEROUTPUT ON

DECLARE
  -- declare a REF CURSOR type named t_cursor (this has no return
  -- type and can therefore run any query)
  TYPE t_cursor IS REF CURSOR;

  -- declare a t_cursor object named v_cursor
  v_cursor t_cursor;

  -- declare an object to store columns from the products table
  -- named v_product (of type products%ROWTYPE)
  v_product products%ROWTYPE;

  -- declare an object to store columns from the customers table
  -- named v_customer (of type customers%ROWTYPE)
  v_customer customers%ROWTYPE;
BEGIN
  -- assign a query to v_cursor and open it using OPEN-FOR
  OPEN v_cursor FOR
  SELECT * FROM products WHERE product_id < 5;

  -- use a loop to fetch the rows from v_cursor into v_product
  LOOP
    FETCH v_cursor INTO v_product;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(
      'product_id = ' || v_product.product_id ||
      ', name = ' || v_product.name ||
      ', price = ' || v_product.price
    );
  END LOOP;

  -- assign a new query to v_cursor and open it using OPEN-FOR
  OPEN v_cursor FOR
  SELECT * FROM customers WHERE customer_id < 3;

  -- use a loop to fetch the rows from v_cursor into v_product
  LOOP
    FETCH v_cursor INTO v_customer;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(
      'customer_id = ' || v_customer.customer_id ||
      ', first_name = ' || v_customer.first_name ||
      ', last_name = ' || v_customer.last_name
    );
  END LOOP;

  -- close v_cursor
  CLOSE v_cursor;
END;
/
