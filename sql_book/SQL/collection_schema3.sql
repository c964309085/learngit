-- This script Will only run if you are using Oracle Database 10g
-- or higher

-- This script does the following:
--   1. Creates collection_user3
--   2. Creates the collection types and database tables
--   3. Populates the database tables with sample data
--   4. Creates the PL/SQL code

-- attempt to drop the user (this will generate an error
-- if the user does not yet exist; do not worry about this
-- error); this statement is included so that you do not have
-- to manually run the DROP before recreating the schema
DROP USER collection_user3 CASCADE;

-- create collection_user3
CREATE USER collection_user3 IDENTIFIED BY collection_password3;

-- allow collection_user3 to connect and create database objects
GRANT connect, resource TO collection_user3;

-- give collection_user3 a quota of 10M on the users tablespace
ALTER USER collection_user3 QUOTA 10M ON users;

-- connect as collection_user3
CONNECT collection_user3/collection_password3;

-- create the types, tables, and insert sample data
CREATE TYPE t_varray_address AS VARRAY(3) OF VARCHAR2(50);
/

CREATE TYPE t_address AS OBJECT (
  street VARCHAR2(15),
  city   VARCHAR2(15),
  state  CHAR(2),
  zip    VARCHAR2(5)
);
/

CREATE TYPE t_nested_table_address AS TABLE OF t_address;
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

COMMIT;

CREATE TYPE t_table AS TABLE OF VARCHAR2(10);
/

-- varray in temporary table example
CREATE GLOBAL TEMPORARY TABLE cust_with_varray_temp_table (
  id         INTEGER PRIMARY KEY,
  first_name VARCHAR2(10),
  last_name  VARCHAR2(10),
  addresses  t_varray_address
);

-- using a different tablespace for a nested table's storage table example
-- (assumes you have a tablespace named users, so you'll need to edit
-- the TABLESPACE clause and uncomment the example)
/*
CREATE TABLE cust_with_nested_table (
  id         INTEGER PRIMARY KEY,
  first_name VARCHAR2(10),
  last_name  VARCHAR2(10),
  addresses  t_nested_table_address
)
NESTED TABLE
  addresses
STORE AS
  nested_addresses2 TABLESPACE users;
*/

-- associative array example
CREATE PROCEDURE customers_associative_array AS
  -- define an associative array type named t_assoc_array;
  -- the value stored in each array element is a NUMBER,
  -- and the index key to access each element is a VARCHAR2
  TYPE t_assoc_array IS TABLE OF NUMBER INDEX BY VARCHAR2(15);

  -- declare an object named v_customer_array of type t_assoc_array;
  -- v_customer_array will be used to store the ages of customers
  v_customer_array t_assoc_array;
BEGIN
  -- assign the values to v_customer_array; the VARCHAR2 key is the
  -- customer name and the NUMBER value is the age of the customer
  v_customer_array('Jason') := 32;
  v_customer_array('Steve') := 28;
  v_customer_array('Fred') := 43;
  v_customer_array('Cynthia') := 27;

  -- display the values stored in v_customer_array
  DBMS_OUTPUT.PUT_LINE(
    'v_customer_array[''Jason''] = ' || v_customer_array('Jason')
  );
  DBMS_OUTPUT.PUT_LINE(
    'v_customer_array[''Steve''] = ' || v_customer_array('Steve')
  );
  DBMS_OUTPUT.PUT_LINE(
    'v_customer_array[''Fred''] = ' || v_customer_array('Fred')
  );
  DBMS_OUTPUT.PUT_LINE(
    'v_customer_array[''Cynthia''] = ' || v_customer_array('Cynthia')
  );
END customers_associative_array;
/

-- equal/not equal example
CREATE PROCEDURE equal_example AS
  -- declare a type named t_nested_table
  TYPE t_nested_table IS TABLE OF VARCHAR2(10);

  -- create t_nested_table objects named v_customer_nested_table1,
  -- v_customer_nested_table2, and v_customer_nested_table3;
  -- these objects are used to store the names of customers
  v_customer_nested_table1 t_nested_table :=
    t_nested_table('Fred', 'George', 'Susan');
  v_customer_nested_table2 t_nested_table :=
    t_nested_table('Fred', 'George', 'Susan');
  v_customer_nested_table3 t_nested_table :=
    t_nested_table('John', 'George', 'Susan');

  v_result BOOLEAN;
BEGIN
  -- use = operator to compare v_customer_nested_table1 with
  -- v_customer_nested_table2 (they contain the same names, so
  -- v_result is set to true)
  v_result := v_customer_nested_table1 = v_customer_nested_table2;
  IF v_result THEN
    DBMS_OUTPUT.PUT_LINE(
      'v_customer_nested_table1 equal to v_customer_nested_table2'
    );
  END IF;

  -- use <> operator to compare v_customer_nested_table1 with
  -- v_customer_nested_table3 (they are not equal because the first
  -- names, 'Fred' and 'John', are different and v_result is set
  -- to true)
  v_result := v_customer_nested_table1 <> v_customer_nested_table3;
  IF v_result THEN
    DBMS_OUTPUT.PUT_LINE(
      'v_customer_nested_table1 not equal to v_customer_nested_table3'
    );
  END IF;
END equal_example;
/

-- IN/NOT IN example
CREATE PROCEDURE in_example AS
  TYPE t_nested_table IS TABLE OF VARCHAR2(10);
  v_customer_nested_table1 t_nested_table :=
    t_nested_table('Fred', 'George', 'Susan');
  v_customer_nested_table2 t_nested_table :=
    t_nested_table('John', 'George', 'Susan');
  v_customer_nested_table3 t_nested_table :=
    t_nested_table('Fred', 'George', 'Susan');
  v_result BOOLEAN;
BEGIN
  -- use IN operator to check if elements of v_customer_nested_table3
  -- are in v_customer_nested_table1 (they are, so v_result is
  -- set to true)
  v_result := v_customer_nested_table3 IN
    (v_customer_nested_table1);
  IF v_result THEN
    DBMS_OUTPUT.PUT_LINE(
      'v_customer_nested_table3 in v_customer_nested_table1'
    );
  END IF;

  -- use NOT IN operator to check if the elements of
  -- v_customer_nested_table3 are not in v_customer_nested_table2
  -- (they are not, so v_result is set to true)
  v_result := v_customer_nested_table3 NOT IN
    (v_customer_nested_table2);
  IF v_result THEN
    DBMS_OUTPUT.PUT_LINE(
      'v_customer_nested_table3 not in v_customer_nested_table2'
    );
  END IF;
END in_example;
/

-- SUBMULTISET example
CREATE PROCEDURE submultiset_example AS
  TYPE t_nested_table IS TABLE OF VARCHAR2(10);
  v_customer_nested_table1 t_nested_table :=
    t_nested_table('Fred', 'George', 'Susan');
  v_customer_nested_table2 t_nested_table :=
    t_nested_table('George', 'Fred', 'Susan', 'John', 'Steve');
  v_result BOOLEAN;
BEGIN
  -- use SUBMULTISET operator to check if elements of
  -- v_customer_nested_table1 are a subset of v_customer_nested_table2
  -- (they are, so v_result is set to true)
  v_result :=
    v_customer_nested_table1 SUBMULTISET OF v_customer_nested_table2;
  IF v_result THEN
    DBMS_OUTPUT.PUT_LINE(
      'v_customer_nested_table1 subset of v_customer_nested_table2'
    );
  END IF;
END submultiset_example;
/

-- MULTISET example
CREATE PROCEDURE multiset_example AS
  TYPE t_nested_table IS TABLE OF VARCHAR2(10);
  v_customer_nested_table1 t_nested_table :=
    t_nested_table('Fred', 'George', 'Susan');
  v_customer_nested_table2 t_nested_table :=
    t_nested_table('George', 'Steve', 'Rob');
  v_customer_nested_table3 t_nested_table;
  v_count INTEGER;
BEGIN
  -- use MULTISET UNION (returns a nested table whose elements
  -- are set to the sum of the two supplied nested tables)
  v_customer_nested_table3 :=
    v_customer_nested_table1 MULTISET UNION
      v_customer_nested_table2;
  DBMS_OUTPUT.PUT('UNION: ');
  FOR v_count IN 1..v_customer_nested_table3.COUNT LOOP
    DBMS_OUTPUT.PUT(v_customer_nested_table3(v_count) || ' ');
  END LOOP;
  DBMS_OUTPUT.PUT_LINE(' ');

  -- use MULTISET UNION DISTINCT (DISTINCT indicates that only
  -- the non-duplicate elements of the two supplied nested tables
  -- are set in the returned nested table)
  v_customer_nested_table3 :=
    v_customer_nested_table1 MULTISET UNION DISTINCT
      v_customer_nested_table2;
  DBMS_OUTPUT.PUT('UNION DISTINCT: ');
  FOR v_count IN 1..v_customer_nested_table3.COUNT LOOP
    DBMS_OUTPUT.PUT(v_customer_nested_table3(v_count) || ' ');
  END LOOP;
  DBMS_OUTPUT.PUT_LINE(' ');

  -- use MULTISET INTERSECT (returns a nested table whose elements
  -- are set to the elements that are common to the two supplied
  -- nested tables)
  v_customer_nested_table3 :=
    v_customer_nested_table1 MULTISET INTERSECT
      v_customer_nested_table2;
  DBMS_OUTPUT.PUT('INTERSECT: ');
  FOR v_count IN 1..v_customer_nested_table3.COUNT LOOP
    DBMS_OUTPUT.PUT(v_customer_nested_table3(v_count) || ' ');
  END LOOP;
  DBMS_OUTPUT.PUT_LINE(' ');

  -- use MULTISET EXCEPT (returns a nested table whose
  -- elements are in the first nested table but not in
  -- the second)
  v_customer_nested_table3 :=
    v_customer_nested_table1 MULTISET EXCEPT
      v_customer_nested_table2;
  DBMS_OUTPUT.PUT_LINE('EXCEPT: ');
  FOR v_count IN 1..v_customer_nested_table3.COUNT LOOP
    DBMS_OUTPUT.PUT(v_customer_nested_table3(v_count) || ' ');
  END LOOP;
END multiset_example;
/

-- CARDINALITY example
CREATE PROCEDURE cardinality_example AS
  TYPE t_nested_table IS TABLE OF VARCHAR2(10);
  v_customer_nested_table1 t_nested_table :=
    t_nested_table('Fred', 'George', 'Susan');
  v_cardinality INTEGER;
BEGIN
  -- call CARDINALITY() to get the number of elements in
  -- v_customer_nested_table1
  v_cardinality := CARDINALITY(v_customer_nested_table1);
  DBMS_OUTPUT.PUT_LINE('v_cardinality = ' || v_cardinality);
END cardinality_example;
/

-- MEMBER OF example
CREATE PROCEDURE member_of_example AS
  TYPE t_nested_table IS TABLE OF VARCHAR2(10);
  v_customer_nested_table1 t_nested_table :=
    t_nested_table('Fred', 'George', 'Susan');
  v_result BOOLEAN;
BEGIN
  -- use MEMBER OF to check if 'George' is in
  -- v_customer_nested_table1 (he is, so v_result is set
  -- to true)
  v_result := 'George' MEMBER OF v_customer_nested_table1;
  IF v_result THEN
    DBMS_OUTPUT.PUT_LINE('''George'' is a member');
  END IF;
END member_of_example;
/

-- SET example
CREATE PROCEDURE set_example AS
  TYPE t_nested_table IS TABLE OF VARCHAR2(10);
  v_customer_nested_table1 t_nested_table :=
    t_nested_table('Fred', 'George', 'Susan', 'George');
  v_customer_nested_table2 t_nested_table;
  v_count INTEGER;
BEGIN
  -- call SET() to convert a nested table into a set,
  -- remove duplicate elements from the set, and get the set
  -- as a nested table
  v_customer_nested_table2 := SET(v_customer_nested_table1);
  DBMS_OUTPUT.PUT('v_customer_nested_table2: ');
  FOR v_count IN 1..v_customer_nested_table2.COUNT LOOP
    DBMS_OUTPUT.PUT(v_customer_nested_table2(v_count) || ' ');
  END LOOP;
  DBMS_OUTPUT.PUT_LINE(' ');
END set_example;
/

-- IS A SET example
CREATE PROCEDURE is_a_set_example AS
  TYPE t_nested_table IS TABLE OF VARCHAR2(10);
  v_customer_nested_table1 t_nested_table :=
    t_nested_table('Fred', 'George', 'Susan', 'George');
  v_result BOOLEAN;
BEGIN
  -- use IS A SET operator to check if the elements in
  -- v_customer_nested_table1 are distinct (they are not, so
  -- v_result is set to false)
  v_result := v_customer_nested_table1 IS A SET;
  IF v_result THEN
    DBMS_OUTPUT.PUT_LINE('Elements are all unique');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Elements contain duplicates');
  END IF;
END is_a_set_example;
/

-- IS EMPTY example
CREATE PROCEDURE is_empty_example AS
  TYPE t_nested_table IS TABLE OF VARCHAR2(10);
  v_customer_nested_table1 t_nested_table :=
    t_nested_table('Fred', 'George', 'Susan');
  v_result BOOLEAN;
BEGIN
  -- use IS EMPTY operator to check if
  -- v_customer_nested_table1 is empty (it is not, so
  -- v_result is set to false)
  v_result := v_customer_nested_table1 IS EMPTY;
  IF v_result THEN
    DBMS_OUTPUT.PUT_LINE('Nested table is empty');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Nested table contains elements');
  END IF;
END is_empty_example;
/

COMMIT;
