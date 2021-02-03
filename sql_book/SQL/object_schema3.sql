-- This script Will run if you are using Oracle Database 11g or above

-- This script does the following:
--   1. Creates object_user3
--   2. Creates the object types and database tables
--   3. Populates the database tables with sample data
--   4. Creates the PL/SQL code

-- attempt to drop the user (this will generate an error
-- if the user does not yet exist; do not worry about this
-- error); this statement is included so that you do not have
-- to manually run the DROP before recreating the schema
DROP USER object_user3 CASCADE;

-- create object_user3
CREATE USER object_user3 IDENTIFIED BY object_password3;

-- grant the required privileges to the user
GRANT connect, resource TO object_user3;

-- give object_user3 a quota of 10M on the users tablespace
ALTER USER object_user3 QUOTA 10M ON users;

-- connect as object_user3
CONNECT object_user3/object_password3;

-- create the object types, tables, and sample data
CREATE TYPE t_person AS OBJECT (
  id         INTEGER,
  first_name VARCHAR2(10),
  last_name  VARCHAR2(10),
  MEMBER FUNCTION display_details RETURN VARCHAR2
) NOT FINAL;
/

CREATE TYPE BODY t_person AS
  MEMBER FUNCTION display_details RETURN VARCHAR2 IS
  BEGIN
    RETURN 'id=' || id ||
      ', name=' || first_name || ' ' || last_name;
  END;
END;
/

CREATE TYPE t_business_person UNDER t_person (
  title   VARCHAR2(20),
  company VARCHAR2(20),
  OVERRIDING MEMBER FUNCTION display_details RETURN VARCHAR2
);
/

CREATE TYPE BODY t_business_person AS
  OVERRIDING MEMBER FUNCTION display_details RETURN VARCHAR2 IS
  BEGIN
    -- use generalized invocation to call display_details() in t_person
    RETURN (SELF AS t_person).display_details ||
      ', title=' || title || ', company=' || company;
  END;
END;
/

CREATE TABLE object_business_customers OF t_business_person;

INSERT INTO object_business_customers VALUES (
  t_business_person(1, 'John', 'Brown', 'Manager', 'XYZ Corp')
);

COMMIT;
