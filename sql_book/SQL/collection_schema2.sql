-- This script Will only run if you are using Oracle Database 9i or higher

-- This script does the following:
--   1. Creates collection_user2
--   2. Creates the collection types and database tables
--   3. Populates the database tables with sample data

-- attempt to drop the user (this will generate an error
-- if the user does not yet exist; do not worry about this
-- error); this statement is included so that you do not have
-- to manually run the DROP before recreating the schema
DROP USER collection_user2 CASCADE;

-- create collection_user2
CREATE USER collection_user2 IDENTIFIED BY collection_password2;

-- allow collection_user2 to connect and create database objects
GRANT connect, resource TO collection_user2;

-- give collection_user2 a quota of 10M on the users tablespace
ALTER USER collection_user2 QUOTA 10M ON users;

-- connect as collection_user2
CONNECT collection_user2/collection_password2;

-- create the types, tables, and insert sample data
CREATE TYPE t_varray_phone AS VARRAY(3) OF VARCHAR2(14);
/

CREATE TYPE t_address AS OBJECT (
  street        VARCHAR2(15),
  city          VARCHAR2(15),
  state         CHAR(2),
  zip           VARCHAR2(5),
  phone_numbers t_varray_phone
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
    t_address('2 State Street', 'Beantown', 'MA', '12345',
      t_varray_phone(
        '(800)-555-1211',
        '(800)-555-1212',
        '(800)-555-1213'
      )
    ),
    t_address('4 Hill Street', 'Lost Town', 'CA', '54321',
      t_varray_phone(
        '(800)-555-1211',
        '(800)-555-1212'
      )
    )
  )
);

COMMIT;
