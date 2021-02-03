-- This script does the following:
--   1. Creates object_user
--   2. Creates the object types and database tables
--   3. Populates the database tables with sample data
--   4. Creates the PL/SQL code

-- attempt to drop the user (this will generate an error
-- if the user does not yet exist; do not worry about this
-- error); this statement is included so that you do not have
-- to manually run the DROP before recreating the schema
DROP USER object_user CASCADE;

-- create object_user
CREATE USER object_user IDENTIFIED BY object_password;

-- grant the required privileges to the user
GRANT connect, resource, create public synonym TO object_user;

-- give object_user a quota of 10M on the users tablespace
ALTER USER object_user QUOTA 10M ON users;

-- connect as object_user
CONNECT object_user/object_password;

-- create the object types, tables, and insert sample data
CREATE TYPE t_address AS OBJECT (
  street VARCHAR2(15),
  city   VARCHAR2(15),
  state  CHAR(2),
  zip    VARCHAR2(5)
);
/

CREATE TYPE t_person AS OBJECT (
  id         INTEGER,
  first_name VARCHAR2(10),
  last_name  VARCHAR2(10),
  dob        DATE,
  phone      VARCHAR2(12),
  address    t_address
);
/

CREATE TABLE object_customers OF t_person;

INSERT INTO object_customers VALUES (
  t_person(1, 'John', 'Brown', '01-FEB-1955', '800-555-1211',
    t_address('2 State Street', 'Beantown', 'MA', '12345')
  )
);

INSERT INTO object_customers (
  id, first_name, last_name, dob, phone,
  address
) VALUES (
  2, 'Cynthia', 'Green', '05-FEB-1968', '800-555-1212',
  t_address('3 Free Street', 'Middle Town', 'CA', '12345')
);

CREATE TYPE t_product AS OBJECT (
  id          INTEGER,
  name        VARCHAR2(10),
  description VARCHAR2(22),
  price       NUMBER(5, 2),
  days_valid  INTEGER,

  -- get_sell_by_date() returns the date by which the
  -- product must be sold
  MEMBER FUNCTION get_sell_by_date RETURN DATE
);
/

CREATE TYPE BODY t_product AS
  -- get_sell_by_date() returns the date by which the
  -- product must be sold
  MEMBER FUNCTION get_sell_by_date RETURN DATE IS
    v_sell_by_date DATE;
  BEGIN
    -- calculate the sell by date by adding the days_valid attribute
    -- to the current date (SYSDATE)
    SELECT days_valid + SYSDATE
    INTO v_sell_by_date
    FROM dual;

    -- return the sell by date 
    RETURN v_sell_by_date;
  END;
END;
/

CREATE TABLE products (
  product           t_product,
  quantity_in_stock INTEGER
);

INSERT INTO products (
  product,
  quantity_in_stock
) VALUES (
  t_product(1, 'pasta', '20 oz bag of pasta', 3.95, 10),
  50
);

INSERT INTO products (
  product,
  quantity_in_stock
) VALUES (
  t_product(2, 'sardines', '12 oz box of sardines', 2.99, 5),
  25
);

CREATE TABLE object_products OF t_product;

INSERT INTO object_products VALUES (
  t_product(1, 'pasta', '20 oz bag of pasta', 3.95, 10)
);

INSERT INTO object_products (
  id, name, description, price, days_valid
) VALUES (
  2, 'sardines', '12 oz box of sardines', 2.99, 5
);

CREATE TABLE purchases (
  id           INTEGER PRIMARY KEY,
  customer_ref REF t_person  SCOPE IS object_customers,
  product_ref  REF t_product SCOPE IS object_products
);

INSERT INTO purchases (
  id,
  customer_ref,
  product_ref
) VALUES (
  1,
  (SELECT REF(oc) FROM object_customers oc WHERE oc.id = 1),
  (SELECT REF(op) FROM object_products  op WHERE op.id = 1)
);

CREATE TYPE t_person2 AS OBJECT (
  id         INTEGER,
  first_name VARCHAR2(10),
  last_name  VARCHAR2(10),
  dob        DATE,
  phone      VARCHAR2(12),
  address    t_address,

  -- declare the get_string() map function,
  -- which returns a VARCHAR2 string
  MAP MEMBER FUNCTION get_string RETURN VARCHAR2
);
/

CREATE TYPE BODY t_person2 AS
  -- define the get_string() map function
  MAP MEMBER FUNCTION get_string RETURN VARCHAR2 IS
  BEGIN
    -- return a concatenated string containing the
    -- last_name and first_name attributes
    RETURN last_name || ' ' || first_name;
  END get_string;
END;
/

CREATE TABLE object_customers2 OF t_person2;

INSERT INTO object_customers2 VALUES (
  t_person2(1, 'John', 'Brown', '01-FEB-1955', '800-555-1211',
    t_address('2 State Street', 'Beantown', 'MA', '12345')
  )
);

INSERT INTO object_customers2 VALUES (
  t_person2(2, 'Cynthia', 'Green', '05-FEB-1968', '800-555-1212',
    t_address('3 Free Street', 'Middle Town', 'CA', '12345')
  )
);

-- create the PL/SQL code
CREATE PACKAGE product_package AS
  TYPE t_ref_cursor IS REF CURSOR;
  FUNCTION get_products RETURN t_ref_cursor;
  PROCEDURE display_product(
    p_id IN object_products.id%TYPE
  );
  PROCEDURE insert_product(
    p_id          IN object_products.id%TYPE,
    p_name        IN object_products.name%TYPE,
    p_description IN object_products.description%TYPE,
    p_price       IN object_products.price%TYPE,
    p_days_valid  IN object_products.days_valid%TYPE
  );
  PROCEDURE update_product_price(
    p_id     IN object_products.id%TYPE,
    p_factor IN NUMBER
  );
  FUNCTION get_product(
    p_id IN object_products.id%TYPE
  ) RETURN t_product;
  PROCEDURE update_product(
    p_product t_product
  );
  FUNCTION get_product_ref(
    p_id IN object_products.id%TYPE
  ) RETURN REF t_product;
  PROCEDURE delete_product(
    p_id IN object_products.id%TYPE
  );
END product_package;
/

CREATE PACKAGE BODY product_package AS
  FUNCTION get_products
  RETURN t_ref_cursor IS
    -- declare a t_ref_cursor object 
    v_products_ref_cursor t_ref_cursor;
  BEGIN
    -- get the REF CURSOR
    OPEN v_products_ref_cursor FOR
      SELECT VALUE(op)
      FROM object_products op
      ORDER BY op.id;

    -- return the REF CURSOR
    RETURN v_products_ref_cursor;
  END get_products;

  PROCEDURE display_product(
    p_id IN object_products.id%TYPE
  ) AS
    -- declare a t_product object named v_product
    v_product t_product;
  BEGIN
    -- attempt to get the product and store it in v_product
    SELECT VALUE(op)
    INTO v_product
    FROM object_products op
    WHERE id = p_id;

    -- display the attributes of v_product
    DBMS_OUTPUT.PUT_LINE('v_product.id=' ||
      v_product.id);
    DBMS_OUTPUT.PUT_LINE('v_product.name=' ||
      v_product.name);
    DBMS_OUTPUT.PUT_LINE('v_product.description=' ||
      v_product.description);
    DBMS_OUTPUT.PUT_LINE('v_product.price=' ||
      v_product.price);
    DBMS_OUTPUT.PUT_LINE('v_product.days_valid=' ||
      v_product.days_valid);

    -- call v_product.get_sell_by_date() and display the date
    DBMS_OUTPUT.PUT_LINE('Sell by date=' ||
      v_product.get_sell_by_date());
  END display_product;

  PROCEDURE insert_product(
    p_id          IN object_products.id%TYPE,
    p_name        IN object_products.name%TYPE,
    p_description IN object_products.description%TYPE,
    p_price       IN object_products.price%TYPE,
    p_days_valid  IN object_products.days_valid%TYPE
  ) AS
    -- create a t_product object named v_product
    v_product t_product :=
      t_product(
        p_id, p_name, p_description, p_price, p_days_valid
      );
  BEGIN
    -- add v_product to the object_products table
    INSERT INTO object_products VALUES (v_product);
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
  END insert_product;

  PROCEDURE update_product_price(
    p_id     IN object_products.id%TYPE,
    p_factor IN NUMBER
  ) AS
    -- declare a t_product object named v_product
    v_product t_product;
  BEGIN
    -- attempt to select the product for update and
    -- store the product in v_product
    SELECT VALUE(op)
    INTO v_product
    FROM object_products op
    WHERE id = p_id
    FOR UPDATE;

    -- display the current price of v_product
    DBMS_OUTPUT.PUT_LINE('v_product.price=' ||
      v_product.price);

    -- multiply v_product.price by p_factor
    v_product.price := v_product.price * p_factor;
    DBMS_OUTPUT.PUT_LINE('New v_product.price=' ||
      v_product.price);

    -- update the product in the object_products table
    UPDATE object_products op
    SET op = v_product
    WHERE id = p_id;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
  END update_product_price;

  FUNCTION get_product(
    p_id IN object_products.id%TYPE
  )
  RETURN t_product IS
    -- declare a t_product object named v_product
    v_product t_product;
  BEGIN
    -- get the product and store it in v_product
    SELECT VALUE(op)
    INTO v_product
    FROM object_products op
    WHERE op.id = p_id;

    -- return v_product
    RETURN v_product;
  END get_product;

  PROCEDURE update_product(
    p_product IN t_product
  ) AS
  BEGIN
    -- update the product in the object_products table
    UPDATE object_products op
    SET op = p_product
    WHERE id = p_product.id;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
  END update_product;

  FUNCTION get_product_ref(
    p_id IN object_products.id%TYPE
  )
  RETURN REF t_product IS
    -- declare a reference to a t_product
    v_product_ref REF t_product;
  BEGIN
    -- get the REF for the product and
    -- store it in v_product_ref
    SELECT REF(op)
    INTO v_product_ref
    FROM object_products op
    WHERE op.id = p_id;

    -- return v_product_ref
    RETURN v_product_ref;
  END get_product_ref;

  PROCEDURE delete_product(
    p_id IN object_products.id%TYPE
  ) AS
  BEGIN
    -- delete the product
    DELETE FROM object_products op
    WHERE op.id = p_id;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
  END delete_product;
END product_package;
/

CREATE PROCEDURE product_lifecycle AS
  -- declare object
  v_product t_product;
BEGIN
  -- insert a new product
  product_package.insert_product(4, 'beef',
   '25 lb pack of beef', 32, 10);

  -- display the product
  product_package.display_product(4);

  -- get the new product and store it in v_product
  SELECT product_package.get_product(4)
  INTO v_product
  FROM dual;

  -- change some attributes of v_product
  v_product.description := '20 lb pack of beef';
  v_product.price := 36;
  v_product.days_valid := 8;

  -- update the product
  product_package.update_product(v_product);

  -- display the product
  product_package.display_product(4);

  -- delete the product
  product_package.delete_product(4);
END product_lifecycle;
/

CREATE PROCEDURE product_lifecycle2 AS
  -- declare object
  v_product t_product;

  -- declare object reference
  v_product_ref REF t_product;
BEGIN
  -- insert a new product
  product_package.insert_product(4, 'beef',
   '25 lb pack of beef', 32, 10);

  -- display the product
  product_package.display_product(4);

  -- get the new product reference and store it in v_product_ref
  SELECT product_package.get_product_ref(4)
  INTO v_product_ref
  FROM dual;

  -- dereference v_product_ref using the following query
  SELECT DEREF(v_product_ref)
  INTO v_product
  FROM dual;

  -- change some attributes of v_product
  v_product.description := '20 lb pack of beef';
  v_product.price := 36;
  v_product.days_valid := 8;

  -- update the product
  product_package.update_product(v_product);

  -- display the product
  product_package.display_product(4);

  -- delete the product
  product_package.delete_product(4);
END product_lifecycle2;
/
