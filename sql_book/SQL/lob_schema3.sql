-- This script Will only run if you are using Oracle Database 11g

-- This script does the following:
--   1. Creates lob_user3
--   2. Creates the database tables
--   3. Populates the database tables with sample data

-- attempt to drop the user (this will generate an error
-- if the user does not yet exist; do not worry about this
-- error); this statement is included so that you do not have
-- to manually run the DROP before recreating the schema
DROP USER lob_user3 CASCADE;

-- create lob_user3
CREATE USER lob_user3 IDENTIFIED BY lob_password3;

-- allow the user to connect and create database objects
GRANT connect, resource TO lob_user3;

-- give lob_user3 a quota of 10M on the users tablespace
ALTER USER lob_user3 QUOTA 10M ON users;

-- connect as lob_user3
CONNECT lob_user3/lob_password3;

-- create the tables and populate them with sample data
CREATE TABLE clob_content (
  id INTEGER PRIMARY KEY,
  clob_column CLOB ENCRYPT USING 'AES128'
) LOB(clob_column) STORE AS SECUREFILE (
  CACHE
);

INSERT INTO clob_content (
  id, clob_column
) VALUES (
  1, TO_CLOB('Creeps in this petty pace')
);

INSERT INTO clob_content (
  id, clob_column
) VALUES (
  2, TO_CLOB(' from day to day')
);

CREATE TABLE credit_cards (
  card_number NUMBER(16, 0) ENCRYPT,
  first_name VARCHAR2(10),
  last_name VARCHAR2(10),
  expiration DATE
);

INSERT INTO credit_cards (
  card_number, first_name, last_name, expiration
) VALUES (
  1234, 'Jason', 'Bond', '03-FEB-2008'
);

INSERT INTO credit_cards (
  card_number, first_name, last_name, expiration
) VALUES (
  5768, 'Steve', 'Edwards', '07-MAR-2009'
);

COMMIT;
