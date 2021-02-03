-- This script does the following:
--   1. Creates collection_user
--   2. Creates the collection types and database tables
--   3. Populates the database tables with sample data
--   4. Creates the PL/SQL code

-- attempt to drop the user (this will generate an error
-- if the user does not yet exist; do not worry about this
-- error); this statement is included so that you do not have
-- to manually run the DROP before recreating the schema
DROP USER collection_user CASCADE;

-- create collection_user
CREATE USER collection_user IDENTIFIED BY collection_password;

-- allow collection_user to connect and create database objects
GRANT connect, resource TO collection_user;

-- give collection_user a quota of 10M on the users tablespace
ALTER USER collection_user QUOTA 10M ON users;

-- connect as collection_user
CONNECT collection_user/collection_password;

-- create the types, tables, and insert sample data
CREATE TYPE t_varray_address AS VARRAY(3) OF VARCHAR2(50);
/

CREATE TABLE customers_with_varray (
  id         INTEGER PRIMARY KEY,
  first_name VARCHAR2(10),
  last_name  VARCHAR2(10),
  addresses  t_varray_address
);

INSERT INTO customers_with_varray VALUES (
  1, 'Steve', 'Brown',
  t_varray_address(
    '2 State Street, Beantown, MA, 12345',
    '4 Hill Street, Lost Town, CA, 54321'
  )
);

INSERT INTO customers_with_varray VALUES (
  2, 'John', 'Smith',
  t_varray_address(
    '1 High Street, Newtown, CA, 12347',
    '3 New Street, Anytown, MI, 54323',
    '7 Market Street, Main Town, MA, 54323'
  )
);

CREATE TYPE t_address AS OBJECT (
  street VARCHAR2(15),
  city   VARCHAR2(15),
  state  CHAR(2),
  zip    VARCHAR2(5)
);
/

CREATE TYPE t_nested_table_address AS TABLE OF t_address;
/

CREATE TABLE customers_with_nested_table (
  id         INTEGER PRIMARY KEY,
  first_name VARCHAR2(10),
  last_name  VARCHAR2(10),
  addresses  t_nested_table_address
)
NESTED TABLE
  addresses
STORE AS
  nested_addresses;

INSERT INTO customers_with_nested_table VALUES (
  1, 'Steve', 'Brown',
  t_nested_table_address(
    t_address('2 State Street', 'Beantown', 'MA', '12345'),
    t_address('4 Hill Street', 'Lost Town', 'CA', '54321')
  )
);

INSERT INTO customers_with_nested_table VALUES (
  2, 'John', 'Smith',
  t_nested_table_address(
    t_address('1 High Street', 'Newtown', 'CA', '12347'),
    t_address('3 New Street', 'Anytown', 'MI', '54323'),
    t_address('7 Market Street', 'Main Town', 'MA', '54323')
  )
);

CREATE TYPE t_address2 AS OBJECT (
  street VARCHAR2(15),
  city   VARCHAR2(15),
  state  CHAR(2),
  zip    VARCHAR2(5),

  -- declare the get_string() map function,
  -- which returns a VARCHAR2 string
  MAP MEMBER FUNCTION get_string RETURN VARCHAR2
);
/

CREATE TYPE BODY t_address2 AS
  -- define the get_string() map function
  MAP MEMBER FUNCTION get_string RETURN VARCHAR2 IS
  BEGIN
    -- return a concatenated string containing the
    -- zip, state, city, and street attributes 
    RETURN zip || ' ' || state || ' ' || city || ' ' || street;
  END get_string;
END;
/

CREATE TYPE t_nested_table_address2 AS TABLE OF t_address2;
/

CREATE TABLE customers_with_nested_table2 (
  id         INTEGER PRIMARY KEY,
  first_name VARCHAR2(10),
  last_name  VARCHAR2(10),
  addresses  t_nested_table_address2
)
NESTED TABLE
  addresses
STORE AS
  nested_addresses2;

INSERT INTO customers_with_nested_table2 VALUES (
  1, 'Steve', 'Brown',
  t_nested_table_address2(
    t_address2('2 State Street', 'Beantown', 'MA', '12345'),
    t_address2('4 Hill Street', 'Lost Town', 'CA', '54321')
  )
);

CREATE TYPE t_varray_address2 AS VARRAY(3) OF t_address;
/

CREATE TABLE customers_with_varray2 (
  id         INTEGER PRIMARY KEY,
  first_name VARCHAR2(10),
  last_name  VARCHAR2(10),
  addresses  t_varray_address2
);

INSERT INTO customers_with_varray2 VALUES (
  1, 'Jason', 'Bond',
  t_varray_address2(
    t_address('9 Newton Drive', 'Sometown', 'WY', '22123'),
    t_address('6 Spring Street', 'New City', 'CA', '77712')
  )
);


-- create the PL/SQL code
CREATE PACKAGE varray_package AS
  TYPE t_ref_cursor IS REF CURSOR;
  FUNCTION get_customers RETURN t_ref_cursor;
  PROCEDURE insert_customer(
    p_id         IN customers_with_varray.id%TYPE,
    p_first_name IN customers_with_varray.first_name%TYPE,
    p_last_name  IN customers_with_varray.last_name%TYPE,
    p_addresses  IN customers_with_varray.addresses%TYPE
  );
END varray_package;
/

CREATE PACKAGE BODY varray_package AS
  -- get_customers() function returns a REF CURSOR
  -- that points to the rows in customers_with_varray
  FUNCTION get_customers
  RETURN t_ref_cursor IS
    --declare the REF CURSOR object
    v_customers_ref_cursor t_ref_cursor;
  BEGIN
    -- get the REF CURSOR
    OPEN v_customers_ref_cursor FOR
      SELECT *
      FROM customers_with_varray;
    -- return the REF CURSOR
    RETURN v_customers_ref_cursor;
  END get_customers;

  -- insert_customer() procedure adds a row to
  -- customers_with_varray
  PROCEDURE insert_customer(
    p_id         IN customers_with_varray.id%TYPE,
    p_first_name IN customers_with_varray.first_name%TYPE,
    p_last_name  IN customers_with_varray.last_name%TYPE,
    p_addresses  IN customers_with_varray.addresses%TYPE
  ) IS
  BEGIN
    INSERT INTO customers_with_varray
    VALUES (p_id, p_first_name, p_last_name, p_addresses);
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
  END insert_customer;
END varray_package;
/

CREATE PACKAGE nested_table_package AS
  TYPE t_ref_cursor IS REF CURSOR;
  FUNCTION get_customers RETURN t_ref_cursor;
  PROCEDURE insert_customer(
    p_id         IN customers_with_nested_table.id%TYPE,
    p_first_name IN customers_with_nested_table.first_name%TYPE,
    p_last_name  IN customers_with_nested_table.last_name%TYPE,
    p_addresses  IN customers_with_nested_table.addresses%TYPE
  );
END nested_table_package;
/

CREATE PACKAGE BODY nested_table_package AS
  -- get_customers() function returns a REF CURSOR
  -- that points to the rows in customers_with_nested_table
  FUNCTION get_customers
  RETURN t_ref_cursor IS
    -- declare the REF CURSOR object
    v_customers_ref_cursor t_ref_cursor;
  BEGIN
    -- get the REF CURSOR
    OPEN v_customers_ref_cursor FOR
      SELECT *
      FROM customers_with_nested_table;
    -- return the REF CURSOR
    RETURN v_customers_ref_cursor;
  END get_customers;

  -- insert_customer() procedure adds a row to
  -- customers_with_nested_table
  PROCEDURE insert_customer(
    p_id         IN customers_with_nested_table.id%TYPE,
    p_first_name IN customers_with_nested_table.first_name%TYPE,
    p_last_name  IN customers_with_nested_table.last_name%TYPE,
    p_addresses  IN customers_with_nested_table.addresses%TYPE
  ) IS
  BEGIN
    INSERT INTO customers_with_nested_table
    VALUES (p_id, p_first_name, p_last_name, p_addresses);
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
  END insert_customer;
END nested_table_package;
/

CREATE PACKAGE collection_method_examples AS
  FUNCTION get_addresses(
    p_id customers_with_nested_table.id%TYPE
  ) RETURN t_nested_table_address;
  PROCEDURE display_addresses(
    p_addresses t_nested_table_address
  );
  PROCEDURE delete_address(
    p_address_num INTEGER
  );
  PROCEDURE exist_addresses;
  PROCEDURE extend_addresses;
  PROCEDURE first_address;
  PROCEDURE last_address;
  PROCEDURE next_address;
  PROCEDURE prior_address;
  PROCEDURE trim_addresses;
END collection_method_examples;
/

CREATE PACKAGE BODY collection_method_examples AS
  -- get_addresses() function returns the nested table of
  -- addresses from customers_with_nested_table for a customer
  -- whose ID is specified by p_id
  FUNCTION get_addresses(
    p_id customers_with_nested_table.id%TYPE
  ) RETURN t_nested_table_address IS
    -- declare object named v_addresses to store the
    -- nested table of addresses
    v_addresses t_nested_table_address;
  BEGIN
    -- retrieve the nested table of addresses into v_addresses
    SELECT addresses
    INTO v_addresses
    FROM customers_with_nested_table
    WHERE id = p_id;

    -- display the number of addresses using v_addresses.COUNT
    DBMS_OUTPUT.PUT_LINE(
      'Number of addresses = '|| v_addresses.COUNT
    );

    -- return v_addresses
    RETURN v_addresses;
  END get_addresses;

  -- display_addresses() procedure displays the addresses
  -- in the parameter p_addresses, which contains a nested
  -- table of addresses
  PROCEDURE display_addresses(
    p_addresses t_nested_table_address
  ) IS
    v_count INTEGER;
  BEGIN
    -- display the number of addresses in p_addresses
    DBMS_OUTPUT.PUT_LINE(
      'Current number of addresses = '|| p_addresses.COUNT
    );

    -- display the addresses in p_addresses using a loop
    FOR v_count IN 1..p_addresses.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE('Address #' || v_count || ':');
      DBMS_OUTPUT.PUT(p_addresses(v_count).street || ', ');
      DBMS_OUTPUT.PUT(p_addresses(v_count).city || ', ');
      DBMS_OUTPUT.PUT(p_addresses(v_count).state || ', ');
      DBMS_OUTPUT.PUT_LINE(p_addresses(v_count).zip);
    END LOOP;
  END display_addresses;

  -- delete_address() procedure gets the addresses for
  -- customer #1 from customers_with_nested_table and
  -- then deletes the address whose index is specified by
  -- the p_address_num parameter
  PROCEDURE delete_address(
    p_address_num INTEGER
  ) IS
    v_addresses t_nested_table_address;
  BEGIN
    v_addresses := get_addresses(1);
    display_addresses(v_addresses);
    DBMS_OUTPUT.PUT_LINE('Deleting address #' || p_address_num);

    -- delete the address specified by p_address_num
    v_addresses.DELETE(p_address_num);

    display_addresses(v_addresses);
  END delete_address;

  -- exist_addresses() procedure gets the addresses for
  -- customer #1 from customers_with_nested_table into
  -- v_addresses, uses DELETE to remove address #1,
  -- and then uses EXISTS to check whether address #1 and #2 exist
  -- (#1 does not exist because it has been deleted, #2 does exist)
  PROCEDURE exist_addresses IS
    v_addresses t_nested_table_address;
  BEGIN
    v_addresses := get_addresses(1);
    DBMS_OUTPUT.PUT_LINE('Deleting address #1');
    v_addresses.DELETE(1);

    -- use EXISTS to check if the addresses exist
    IF v_addresses.EXISTS(1) THEN
      DBMS_OUTPUT.PUT_LINE('Address #1 does exist');
    ELSE
      DBMS_OUTPUT.PUT_LINE('Address #1 does not exist');
    END IF;
    IF v_addresses.EXISTS(2) THEN
      DBMS_OUTPUT.PUT_LINE('Address #2 does exist');
    END IF;
  END exist_addresses;

  -- extend_addresses() procedure gets the addresses for
  -- customer #1 from customers_with_nested_table into
  -- v_addresses and then uses EXTEND to copy address #1
  -- twice to the end of v_addresses
  PROCEDURE extend_addresses IS
    v_addresses t_nested_table_address;
  BEGIN
    v_addresses := get_addresses(1);
    display_addresses(v_addresses);
    DBMS_OUTPUT.PUT_LINE('Extending addresses');

    -- copy address #1 twice to the end of v_addresses
    v_addresses.EXTEND(2, 1);

    display_addresses(v_addresses);
  END extend_addresses;

  -- first_address() procedure gets the addresses for
  -- customer #1 from customers_with_nested_table into
  -- v_addresses and then uses FIRST to display the index
  -- of the first address in v_addresses; the procedure then
  -- deletes address #1 using DELETE and displays the
  -- new FIRST address index
  PROCEDURE first_address IS
    v_addresses t_nested_table_address;
  BEGIN
    v_addresses := get_addresses(1);

    -- display the FIRST address
    DBMS_OUTPUT.PUT_LINE('First address = ' || v_addresses.FIRST);
    DBMS_OUTPUT.PUT_LINE('Deleting address #1');
    v_addresses.DELETE(1);

    -- display the FIRST address again
    DBMS_OUTPUT.PUT_LINE('First address = ' || v_addresses.FIRST);
  END first_address;

  -- last_address() procedure gets the addresses for
  -- customer #1 from customers_with_nested_table into
  -- v_addresses and then uses LAST to display the index
  -- of the last address in v_addresses; the procedure then
  -- deletes address #2 using DELETE and displays the
  -- new LAST address index
  PROCEDURE last_address IS
    v_addresses t_nested_table_address;
  BEGIN
    v_addresses := get_addresses(1);

    -- display the LAST address
    DBMS_OUTPUT.PUT_LINE('Last address = ' || v_addresses.LAST);
    DBMS_OUTPUT.PUT_LINE('Deleting address #2');
    v_addresses.DELETE(2);

    -- display the LAST address again
    DBMS_OUTPUT.PUT_LINE('Last address = ' || v_addresses.LAST);
  END last_address;

  -- next_address() procedure gets the addresses for
  -- customer #1 from customers_with_nested_table into
  -- v_addresses and then uses NEXT(1) to get the index
  -- of the address after address #1 in v_addresses; the
  -- procedure then uses NEXT(2) to attempt to get the
  -- index of the address after address #2 (there isn't one,
  -- so null is returned)
  PROCEDURE next_address IS
    v_addresses t_nested_table_address;
  BEGIN
    v_addresses := get_addresses(1);

    -- use NEXT(1) to get the index of the address
    -- after address #1
    DBMS_OUTPUT.PUT_LINE(
      'v_addresses.NEXT(1) = ' || v_addresses.NEXT(1)
    );

    -- use NEXT(2) to attempt to get the index of
    -- the address after address #2 (there isn't one,
    -- so null is returned)
    DBMS_OUTPUT.PUT_LINE(
      'v_addresses.NEXT(2) = ' || v_addresses.NEXT(2)
    );
  END next_address;

  -- prior_address() procedure gets the addresses for
  -- customer #1 from customers_with_nested_table into
  -- v_addresses and then uses PRIOR(2) to display the index
  -- of the address before address #2 in v_addresses; the
  -- procedure then uses PRIOR(1) to attempt to display the
  -- index of address before address #1 (there isn't one, so null
  -- is returned)
  PROCEDURE prior_address IS
    v_addresses t_nested_table_address;
  BEGIN
    v_addresses := get_addresses(1);

    -- use PRIOR(2) to get the index of the address
    -- before address #2
    DBMS_OUTPUT.PUT_LINE(
      'v_addresses.PRIOR(2) = ' || v_addresses.PRIOR(2)
    );

    -- use PRIOR(1) to attempt to get the index of
    -- the address before address #1 (there isn't one,
    -- so null is returned)
    DBMS_OUTPUT.PUT_LINE(
      'v_addresses.PRIOR(1) = ' || v_addresses.PRIOR(1)
    );
  END prior_address;

  -- trim_addresses() procedure gets the addresses
  -- of customer #1, then copies address #1 to the end of
  -- v_addresses three times using EXTEND(3, 1), and finally
  -- removes two addresses from the end of v_addresses using
  -- TRIM(2)
  PROCEDURE trim_addresses IS
    v_addresses t_nested_table_address;
  BEGIN
    v_addresses := get_addresses(1);
    display_addresses(v_addresses);
    DBMS_OUTPUT.PUT_LINE('Extending addresses');
    v_addresses.EXTEND(3, 1);
    display_addresses(v_addresses);
    DBMS_OUTPUT.PUT_LINE('Trimming 2 addresses from end');

    -- remove 2 addresses from the end of v_addresses
    -- using TRIM(2)
    v_addresses.TRIM(2);

    display_addresses(v_addresses);
  END trim_addresses;
END collection_method_examples;
/

COMMIT;
