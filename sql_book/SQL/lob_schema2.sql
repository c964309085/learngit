-- This script Will only run if you are using Oracle Database 10g
-- or higher

-- This script does the following:
--   1. Creates lob_user2
--   2. Creates the database table and populates them with data
--   3. Creates the PL/SQL code

-- attempt to drop the user (this will generate an error
-- if the user does not yet exist; do not worry about this
-- error); this statement is included so that you do not have
-- to manually run the DROP before recreating the schema
DROP USER lob_user2 CASCADE;

-- create lob_user2
CREATE USER lob_user2 IDENTIFIED BY lob_password2;

-- allow the user to connect and create database objects
GRANT connect, resource TO lob_user2;

-- give lob_user2 a quota of 10M on the users tablespace
ALTER USER lob_user2 QUOTA 10M ON users;

-- connect as lob_user2
CONNECT lob_user2/lob_password2;

-- create the tables and populate with sample data
CREATE TABLE nclob_content (
  id INTEGER PRIMARY KEY,
  nclob_column NCLOB
);

CREATE TABLE clob_content (
  id          INTEGER PRIMARY KEY,
  clob_column CLOB NOT NULL
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

-- create the PL/SQL code
CREATE PROCEDURE nclob_example
AS
  v_clob CLOB := 'It is the east and Juliet is the sun';
  v_nclob NCLOB;
BEGIN
  -- insert v_clob into nclob_column; this implicitly
  -- converts the CLOB v_clob to an NCLOB, storing
  -- the contents of v_clob in the nclob_content table
  INSERT INTO nclob_content (
    id, nclob_column
  ) VALUES (
    1, v_clob
  );

  -- select nclob_column into v_clob; this implicitly
  -- converts the NCLOB stored in nclob_column to a
  -- CLOB, retrieving the contents of nclob_column
  -- into v_clob
  SELECT nclob_column
  INTO v_clob
  FROM nclob_content
  WHERE id = 1;

  -- display the contents of v_clob
  DBMS_OUTPUT.PUT_LINE('v_clob = ' || v_clob);
END nclob_example;
/

-- use :new attribute when using LOBs in a BEFORE UPDATE trigger
CREATE TRIGGER before_clob_content_update
BEFORE UPDATE
ON clob_content
FOR EACH ROW
BEGIN
  DBMS_OUTPUT.PUT_LINE('clob_content changed');
  DBMS_OUTPUT.PUT_LINE(
    'Length = ' || DBMS_LOB.GETLENGTH(:new.clob_column)
  );
END before_clob_content_update;
/
