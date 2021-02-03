-- This script Will run if you are using Oracle Database 9i or above

-- This script does the following:
--   1. Creates object_user2
--   2. Creates the object types and database tables
--   3. Populates the database tables with sample data
--   4. Creates the PL/SQL code

-- attempt to drop the user (this will generate an error
-- if the user does not yet exist; do not worry about this
-- error); this statement is included so that you do not have
-- to manually run the DROP before recreating the schema
DROP USER object_user2 CASCADE;

-- create object_user2
CREATE USER object_user2 IDENTIFIED BY object_password2;

-- grant the required privileges to the user
GRANT connect, resource TO object_user2;

-- give object_user2 a quota of 10M on the users tablespace
ALTER USER object_user2 QUOTA 10M ON users;

-- connect as object_user2
CONNECT object_user2/object_password2;

-- create the types, tables, and insert sample data
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
  address    t_address,
  MEMBER FUNCTION display_details RETURN VARCHAR2
) NOT FINAL;
/

CREATE TYPE BODY t_person AS
  MEMBER FUNCTION display_details RETURN VARCHAR2 IS
  BEGIN
    RETURN 'id=' || id || ', name=' || first_name || ' ' || last_name;
  END;
END;
/

CREATE TABLE object_customers OF t_person;

INSERT INTO object_customers VALUES (
  t_person(1, 'Jason', 'Bond', '03-APR-1965', '800-555-1212',
    t_address('21 New Street', 'Anytown', 'CA', '12345')
  )
);

CREATE TYPE t_business_person UNDER t_person (
  title   VARCHAR2(20),
  company VARCHAR2(20)
);
/

INSERT INTO object_customers VALUES (
  t_business_person(2, 'Steve', 'Edwards', '03-MAR-1955', '800-555-1212',
    t_address('1 Market Street', 'Anytown', 'VA', '12345'),
    'Manager', 'XYZ Corp'
  )
);

CREATE TABLE object_business_customers OF t_business_person;

INSERT INTO object_business_customers VALUES (
  t_business_person(1, 'John', 'Brown', '01-FEB-1955', '800-555-1211',
    t_address('2 State Street', 'Beantown', 'MA', '12345'),
    'Manager', 'XYZ Corp'
  )
);

CREATE TABLE object_customers_not_subs OF t_person
NOT SUBSTITUTABLE AT ALL LEVELS;

CREATE TYPE t_vehicle AS OBJECT (
  id    INTEGER,
  make  VARCHAR2(15),
  model VARCHAR2(15)
) NOT FINAL NOT INSTANTIABLE;
/

CREATE TABLE vehicles OF t_vehicle;

CREATE TYPE t_car UNDER t_vehicle (
  convertible CHAR(1)
);
/

CREATE TABLE cars OF t_car;

INSERT INTO cars VALUES (
  t_car(1, 'Toyota', 'MR2', 'Y')
);

CREATE TYPE t_motorcycle UNDER t_vehicle (
  sidecar CHAR(1)
);
/

CREATE TABLE motorcycles OF t_motorcycle;

INSERT INTO motorcycles VALUES (
  t_motorcycle(1, 'Harley-Davidson', 'V-Rod', 'N')
);

CREATE TYPE t_person2 AS OBJECT (
  id         INTEGER,
  first_name VARCHAR2(10),
  last_name  VARCHAR2(10),
  dob        DATE,
  phone      VARCHAR2(12),
  CONSTRUCTOR FUNCTION t_person2(
    p_id         INTEGER,
    p_first_name VARCHAR2,
    p_last_name  VARCHAR2
  ) RETURN SELF AS RESULT,
  CONSTRUCTOR FUNCTION t_person2(
    p_id         INTEGER,
    p_first_name VARCHAR2,
    p_last_name  VARCHAR2,
    p_dob        DATE
  ) RETURN SELF AS RESULT
);
/

CREATE TYPE BODY t_person2 AS
  CONSTRUCTOR FUNCTION t_person2(
    p_id         INTEGER,
    p_first_name VARCHAR2,
    p_last_name  VARCHAR2
  ) RETURN SELF AS RESULT IS
  BEGIN
    SELF.id := p_id;
    SELF.first_name := p_first_name;
    SELF.last_name := p_last_name;
    SELF.dob := SYSDATE;
    SELF.phone := '555-1212';
    RETURN;
  END;
  CONSTRUCTOR FUNCTION t_person2(
    p_id         INTEGER,
    p_first_name VARCHAR2,
    p_last_name  VARCHAR2,
    p_dob        DATE
  ) RETURN SELF AS RESULT IS
  BEGIN
    SELF.id := p_id;
    SELF.first_name := p_first_name;
    SELF.last_name := p_last_name;
    SELF.dob := p_dob;
    SELF.phone := '555-1213';
    RETURN;
  END;
END;
/

CREATE TABLE object_customers2 OF t_person2;

INSERT INTO object_customers2 VALUES (
  t_person2(1, 'Jeff', 'Jones')
);

INSERT INTO object_customers2 VALUES (
  t_person2(2, 'Gregory', 'Smith', '03-APR-1965')
);

INSERT INTO object_customers2 VALUES (
  t_person2(3, 'Jeremy', 'Hill', '05-JUN-1975', '555-1214')
);

CREATE TYPE t_person3 AS OBJECT (
  id         INTEGER,
  first_name VARCHAR2(10),
  last_name  VARCHAR2(10),
  MEMBER FUNCTION display_details RETURN VARCHAR2
) NOT FINAL;
/

CREATE TYPE BODY t_person3 AS
  MEMBER FUNCTION display_details RETURN VARCHAR2 IS
  BEGIN
    RETURN 'id=' || id ||
      ', name=' || first_name || ' ' || last_name;
  END;
END;
/

CREATE TABLE object_customers3 OF t_person3;

CREATE TYPE t_business_person3 UNDER t_person3 (
  title   VARCHAR2(20),
  company VARCHAR2(20),
  OVERRIDING MEMBER FUNCTION display_details RETURN VARCHAR2
);
/

CREATE TYPE BODY t_business_person3 AS
  OVERRIDING MEMBER FUNCTION display_details RETURN VARCHAR2 IS
  BEGIN
    RETURN 'id=' || id ||
      ', name=' || first_name || ' ' || last_name ||
      ', title=' || title || ', company=' || company;
  END;
END;
/

CREATE TABLE object_business_customers3 OF t_business_person3;

INSERT INTO object_business_customers3 VALUES (
  t_business_person3(1, 'John', 'Brown', 'Manager', 'XYZ Corp')
);


-- create the PL/SQL code
CREATE PROCEDURE subtypes_and_supertypes AS
  -- create objects
  v_business_person t_business_person :=
    t_business_person(
      1, 'John', 'Brown',
      '01-FEB-1955', '800-555-1211',
      t_address('2 State Street', 'Beantown', 'MA', '12345'),
      'Manager', 'XYZ Corp'
    );
  v_person t_person :=
    t_person(1, 'John', 'Brown', '01-FEB-1955', '800-555-1211',
      t_address('2 State Street', 'Beantown', 'MA', '12345'));
  v_business_person2 t_business_person;
  v_person2 t_person;
BEGIN
  -- assign v_business_person to v_person2
  v_person2 := v_business_person;
  DBMS_OUTPUT.PUT_LINE('v_person2.id = ' || v_person2.id);
  DBMS_OUTPUT.PUT_LINE('v_person2.first_name = ' ||
    v_person2.first_name);
  DBMS_OUTPUT.PUT_LINE('v_person2.last_name = ' ||
    v_person2.last_name);

  -- the following lines will not compile because v_person2
  -- is of type t_person, and t_person does not know about the
  -- additional title and company attributes
  -- DBMS_OUTPUT.PUT_LINE('v_person2.title = ' ||
  --   v_person2.title);
  -- DBMS_OUTPUT.PUT_LINE('v_person2.company = ' ||
  --   v_person2.company);

  -- the following line will not compile because you cannot
  -- directly assign a t_person object to a t_business_person
  -- object
  -- v_business_person2 := v_person;
END subtypes_and_supertypes;
/

CREATE PROCEDURE check_types AS
  -- create objects
  v_business_person t_business_person :=
    t_business_person(
      1, 'John', 'Brown',
      '01-FEB-1955', '800-555-1211',
      t_address('2 State Street', 'Beantown', 'MA', '12345'),
      'Manager', 'XYZ Corp'
    );
  v_person t_person :=
    t_person(1, 'John', 'Brown', '01-FEB-1955', '800-555-1211',
      t_address('2 State Street', 'Beantown', 'MA', '12345'));
BEGIN
  -- check the types of the objects
  IF v_business_person IS OF (t_business_person) THEN
    DBMS_OUTPUT.PUT_LINE('v_business_person is of type ' ||
      't_business_person');
  END IF;
  IF v_person IS OF (t_person) THEN
    DBMS_OUTPUT.PUT_LINE('v_person is of type t_person');
  END IF;
  IF v_business_person IS OF (t_person) THEN
    DBMS_OUTPUT.PUT_LINE('v_business_person is of type t_person');
  END IF;
  IF v_business_person IS OF (t_business_person, t_person) THEN
    DBMS_OUTPUT.PUT_LINE('v_business_person is of ' ||
      'type t_business_person or t_person');
  END IF;
  IF v_business_person IS OF (ONLY t_business_person) THEN
    DBMS_OUTPUT.PUT_LINE('v_business_person is of only ' ||
      'type t_business_person');
  END IF;
  IF v_business_person IS OF (ONLY t_person) THEN
    DBMS_OUTPUT.PUT_LINE('v_business_person is of only ' ||
      'type t_person');
  ELSE
    DBMS_OUTPUT.PUT_LINE('v_business_person is not of only ' ||
      'type t_person');
  END IF;
END check_types;
/

CREATE PROCEDURE treat_example AS
  -- create objects
  v_business_person t_business_person :=
    t_business_person(
      1, 'John', 'Brown',
      '01-FEB-1955', '800-555-1211',
      t_address('2 State Street', 'Beantown', 'MA', '12345'),
      'Manager', 'XYZ Corp'
    );
  v_person t_person :=
    t_person(1, 'John', 'Brown', '01-FEB-1955', '800-555-1211',
      t_address('2 State Street', 'Beantown', 'MA', '12345'));
  v_business_person2 t_business_person;
  v_person2 t_person;
BEGIN
  -- assign v_business_person to v_person2
  v_person2 := v_business_person;
  DBMS_OUTPUT.PUT_LINE('v_person2.id = ' || v_person2.id);
  DBMS_OUTPUT.PUT_LINE('v_person2.first_name = ' ||
    v_person2.first_name);
  DBMS_OUTPUT.PUT_LINE('v_person2.last_name = ' ||
    v_person2.last_name);

  -- the following lines will not compile because v_person2
  -- is of type t_person, and t_person does not know about the
  -- additional title and company attributes
  -- DBMS_OUTPUT.PUT_LINE('v_person2.title = ' ||
  --   v_person2.title);
  -- DBMS_OUTPUT.PUT_LINE('v_person2.company = ' ||
  --   v_person2.company);

  -- use TREAT when assigning v_business_person to v_person2
  DBMS_OUTPUT.PUT_LINE('Using TREAT');
  v_person2 := TREAT(v_business_person AS t_person);
  DBMS_OUTPUT.PUT_LINE('v_person2.id = ' || v_person2.id);
  DBMS_OUTPUT.PUT_LINE('v_person2.first_name = ' ||
    v_person2.first_name);
  DBMS_OUTPUT.PUT_LINE('v_person2.last_name = ' ||
    v_person2.last_name);

  -- the following lines will still not compile because v_person2
  -- is of type t_person, and t_person does not know about the
  -- additional title and company attributes
  -- DBMS_OUTPUT.PUT_LINE('v_person2.title = ' ||
  --   v_person2.title);
  -- DBMS_OUTPUT.PUT_LINE('v_person2.company = ' ||
  --   v_person2.company);

  -- the following lines do compile because TREAT is used
  DBMS_OUTPUT.PUT_LINE('v_person2.title = ' ||
    TREAT(v_person2 AS t_business_person).title);
  DBMS_OUTPUT.PUT_LINE('v_person2.company = ' ||
    TREAT(v_person2 AS t_business_person).company);

  -- the following line will not compile because you cannot
  -- directly assign a t_person object to a t_business_person
  -- object
  -- v_business_person2 := v_person;

  -- the following line throws a runtime error because you cannot
  -- assign a supertype object (v_person) to a subtype object
  -- (v_business_person2)
  -- v_business_person2 := TREAT(v_person AS t_business_person);
END treat_example;
/
