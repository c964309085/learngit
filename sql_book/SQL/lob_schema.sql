-- This script does the following:
--   1. Creates lob_user
--   2. Creates the database tables
--   3. Populates the database tables with sample data
--   4. Creates the PL/SQL code

-- attempt to drop the user (this will generate an error
-- if the user does not yet exist; do not worry about this
-- error); this statement is included so that you do not have
-- to manually run the DROP before recreating the schema
DROP USER lob_user CASCADE;

-- attempt to drop the sample files directory (this will
-- generate an error if the directory does not yet exist;
-- do not worry about this error);
-- this statement is included so that you do not have
-- to manually run the DROP before recreating the schema
DROP DIRECTORY SAMPLE_FILES_DIR;

-- create lob_user
CREATE USER lob_user IDENTIFIED BY lob_password;

-- create the BFILE directory
CREATE DIRECTORY SAMPLE_FILES_DIR AS 'C:\sample_files';

-- grant read and write permissions on the BFILE directory
GRANT read, write ON DIRECTORY SAMPLE_FILES_DIR TO lob_user;

-- allow the user to connect, create database objects and
-- create directory objects (for the BFILEs)
GRANT connect, resource TO lob_user;

-- give lob_user a quota of 10M on the users tablespace
ALTER USER lob_user QUOTA 10M ON users;

-- connect as lob_user
CONNECT lob_user/lob_password;

-- create the tables
CREATE TABLE clob_content (
  id          INTEGER PRIMARY KEY,
  clob_column CLOB NOT NULL
);

CREATE TABLE blob_content (
  id          INTEGER PRIMARY KEY,
  blob_column BLOB NOT NULL
);

CREATE TABLE bfile_content (
  id           INTEGER PRIMARY KEY,
  bfile_column BFILE NOT NULL
);

CREATE TABLE long_content (
  id          INTEGER PRIMARY KEY,
  long_column LONG NOT NULL
);

CREATE TABLE long_raw_content (
  id              INTEGER PRIMARY KEY,
  long_raw_column LONG RAW NOT NULL
);

-- populate tables with sample data
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

INSERT INTO blob_content (
  id, blob_column
) VALUES (
  1, TO_BLOB('100111010101011111')
);

INSERT INTO blob_content (
  id, blob_column
) VALUES (
  2, TO_BLOB('A0FFB71CF90DE')
);

INSERT INTO bfile_content (
  id, bfile_column
) VALUES (
  1, BFILENAME('SAMPLE_FILES_DIR', 'textContent.txt')
);

INSERT INTO bfile_content (
  id, bfile_column
) VALUES (
  2, BFILENAME('SAMPLE_FILES_DIR', 'binaryContent.doc')
);

INSERT INTO long_content (
  id, long_column
) VALUES (
  1, 'Creeps in this petty pace'
);

INSERT INTO long_content (
  id, long_column
) VALUES (
  2, ' from day to day'
);

INSERT INTO long_raw_content (
  id, long_raw_column
) VALUES (
  1, '100111010101011111'
);

INSERT INTO long_raw_content (
  id, long_raw_column
) VALUES (
  2, 'A0FFB71CF90DE'
);

COMMIT;

-- create the PL/SQL code
CREATE PROCEDURE get_clob_locator(
  p_clob IN OUT CLOB,
  p_id   IN INTEGER
) AS
BEGIN
  -- get the LOB locator and store it in p_clob
  SELECT clob_column
  INTO p_clob
  FROM clob_content
  WHERE id = p_id;
END get_clob_locator;
/

CREATE PROCEDURE get_blob_locator(
  p_blob IN OUT BLOB,
  p_id   IN INTEGER
) AS
BEGIN
  -- get the LOB locator and store it in p_blob
  SELECT blob_column
  INTO p_blob
  FROM blob_content
  WHERE id = p_id;
END get_blob_locator;
/

CREATE PROCEDURE read_clob_example(
  p_id IN INTEGER
) AS
  v_clob CLOB;
  v_offset INTEGER := 1;
  v_amount INTEGER := 50;
  v_char_buffer VARCHAR2(50);
BEGIN
  -- get the LOB locator and store it in v_clob
  get_clob_locator(v_clob, p_id);

  -- read the contents of v_clob into v_char_buffer, starting at
  -- the v_offset position and read a total of v_amount characters
  DBMS_LOB.READ(v_clob, v_amount, v_offset, v_char_buffer);

  -- display the contents of v_char_buffer
  DBMS_OUTPUT.PUT_LINE('v_char_buffer = ' || v_char_buffer);
  DBMS_OUTPUT.PUT_LINE('v_amount = ' || v_amount);
END read_clob_example;
/

CREATE PROCEDURE read_blob_example(
  p_id IN INTEGER
) AS
  v_blob BLOB;
  v_offset INTEGER := 1;
  v_amount INTEGER := 25;
  v_binary_buffer RAW(25);
BEGIN
  -- get the LOB locator and store it in v_blob
  get_blob_locator(v_blob, p_id);

  -- read the contents of v_blob into v_binary_buffer, starting at
  -- the v_offset position and read a total of v_amount bytes
  DBMS_LOB.READ(v_blob, v_amount, v_offset, v_binary_buffer);

  -- display the contents of v_binary_buffer
  DBMS_OUTPUT.PUT_LINE('v_binary_buffer = ' || v_binary_buffer);
  DBMS_OUTPUT.PUT_LINE('v_amount = ' || v_amount);
END read_blob_example;
/

CREATE PROCEDURE write_example(
  p_id IN INTEGER
) AS
  v_clob CLOB;
  v_offset INTEGER := 7;
  v_amount INTEGER := 6;
  v_char_buffer VARCHAR2(10) := 'pretty';
BEGIN
  -- get the LOB locator into v_clob for update (for update
  -- because the LOB is written to using WRITE() later)
  SELECT clob_column
  INTO v_clob
  FROM clob_content
  WHERE id = p_id
  FOR UPDATE;

  -- read and display the contents of the CLOB
  read_clob_example(p_id);

  -- write the characters in v_char_buffer to v_clob, starting 
  -- at the v_offset position and write a total of v_amount characters
  DBMS_LOB.WRITE(v_clob, v_amount, v_offset, v_char_buffer);

  -- read and display the contents of the CLOB
  -- and then rollback the write
  read_clob_example(p_id);
  ROLLBACK;
END write_example;
/

CREATE PROCEDURE append_example AS
  v_src_clob CLOB;
  v_dest_clob CLOB;
BEGIN
  -- get the LOB locator for the CLOB in row #2 of
  -- the clob_content table into v_src_clob
  get_clob_locator(v_src_clob, 2);

  -- get the LOB locator for the CLOB in row #1 of
  -- the clob_content table into v_dest_clob for update
  -- (for update because the CLOB will be added to using
  -- APPEND() later)
  SELECT clob_column
  INTO v_dest_clob
  FROM clob_content
  WHERE id = 1
  FOR UPDATE;

  -- read and display the contents of CLOB #1
  read_clob_example(1);

  -- use APPEND() to copy the contents of v_src_clob to v_dest_clob
  DBMS_LOB.APPEND(v_dest_clob, v_src_clob);

  -- read and display the contents of CLOB #1
  -- and then rollback the change
  read_clob_example(1);
  ROLLBACK;
END append_example;
/

CREATE PROCEDURE compare_example AS
  v_clob1 CLOB;
  v_clob2 CLOB;
  v_return INTEGER;
BEGIN
  -- get the LOB locators
  get_clob_locator(v_clob1, 1);
  get_clob_locator(v_clob2, 2);

  -- compare v_clob1 with v_clob2 (COMPARE() returns 1
  -- because the contents of v_clob1 and v_clob2 are different)
  DBMS_OUTPUT.PUT_LINE('Comparing v_clob1 with v_clob2');
  v_return := DBMS_LOB.COMPARE(v_clob1, v_clob2);
  DBMS_OUTPUT.PUT_LINE('v_return = ' || v_return);

  -- compare v_clob1 with v_clob1 (COMPARE() returns 0
  -- because the contents are the same)
  DBMS_OUTPUT.PUT_LINE('Comparing v_clob1 with v_clob1');
  v_return := DBMS_LOB.COMPARE(v_clob1, v_clob1);
  DBMS_OUTPUT.PUT_LINE('v_return = ' || v_return);
END compare_example;
/

CREATE PROCEDURE copy_example AS
  v_src_clob CLOB;
  v_dest_clob CLOB;
  v_src_offset INTEGER := 1;
  v_dest_offset INTEGER := 7;
  v_amount INTEGER := 5;
BEGIN
  -- get the LOB locator for the CLOB in row #2 of
  -- the clob_content table into v_dest_clob
  get_clob_locator(v_src_clob, 2);

  -- get the LOB locator for the CLOB in row #1 of
  -- the clob_content table into v_dest_clob for update
  -- (for update because the CLOB will be added to using
  -- COPY() later)
  SELECT clob_column
  INTO v_dest_clob
  FROM clob_content
  WHERE id = 1
  FOR UPDATE;

  -- read and display the contents of CLOB #1
  read_clob_example(1);

  -- copy characters to v_dest_clob from v_src_clob using COPY(),
  -- starting at the offsets specified by v_dest_offset and
  -- v_src_offset for a total of v_amount characters
  DBMS_LOB.COPY(
    v_dest_clob, v_src_clob,
    v_amount, v_dest_offset, v_src_offset
  );

  -- read and display the contents of CLOB #1
  -- and then rollback the change
  read_clob_example(1);
  ROLLBACK;
END copy_example;
/

CREATE PROCEDURE temporary_lob_example AS
  v_clob CLOB;
  v_amount INTEGER;
  v_offset INTEGER := 1;
  v_char_buffer VARCHAR2(17) := 'Juliet is the sun';
BEGIN
  -- use CREATETEMPORARY() to create a temporary CLOB named v_clob
  DBMS_LOB.CREATETEMPORARY(v_clob, TRUE);

  -- use WRITE() to write the contents of v_char_buffer to v_clob
  v_amount := LENGTH(v_char_buffer);
  DBMS_LOB.WRITE(v_clob, v_amount, v_offset, v_char_buffer);

  -- use ISTEMPORARY() to check if v_clob is temporary
  IF (DBMS_LOB.ISTEMPORARY(v_clob) = 1) THEN
    DBMS_OUTPUT.PUT_LINE('v_clob is temporary');
  END IF;

  -- use READ() to read the contents of v_clob into v_char_buffer
  DBMS_LOB.READ(
    v_clob, v_amount, v_offset, v_char_buffer
  );
  DBMS_OUTPUT.PUT_LINE('v_char_buffer = ' || v_char_buffer);

  -- use FREETEMPORARY() to free v_clob
  DBMS_LOB.FREETEMPORARY(v_clob);
END temporary_lob_example;
/

CREATE PROCEDURE erase_example AS
  v_clob CLOB;
  v_offset INTEGER := 2;
  v_amount INTEGER := 5;
BEGIN
  -- get the LOB locator for the CLOB in row #1 of
  -- the clob_content table into v_dest_clob for update
  -- (for update because the CLOB will be erased using
  -- ERASE() later)
  SELECT clob_column
  INTO v_clob
  FROM clob_content
  WHERE id = 1
  FOR UPDATE;

  -- read and display the contents of CLOB #1
  read_clob_example(1);

  -- use ERASE() to erase a total of v_amount characters
  -- from v_clob, starting at v_offset
  DBMS_LOB.ERASE(v_clob, v_amount, v_offset);

  -- read and display the contents of CLOB #1
  -- and then rollback the change
  read_clob_example(1);
  ROLLBACK;
END erase_example;
/

CREATE PROCEDURE instr_example AS
  v_clob CLOB;
  v_char_buffer VARCHAR2(50) := 'It is the east and Juliet is the sun';
  v_pattern VARCHAR2(5);
  v_offset INTEGER := 1;
  v_amount INTEGER;
  v_occurrence INTEGER;
  v_return INTEGER;
BEGIN
  -- use CREATETEMPORARY() to create a temporary CLOB named v_clob
  DBMS_LOB.CREATETEMPORARY(v_clob, TRUE);

  -- use WRITE() to write the contents of v_char_buffer to v_clob
  v_amount := LENGTH(v_char_buffer);
  DBMS_LOB.WRITE(v_clob, v_amount, v_offset, v_char_buffer);

  -- use READ() to read the contents of v_clob into v_char_buffer
  DBMS_LOB.READ(v_clob, v_amount, v_offset, v_char_buffer);
  DBMS_OUTPUT.PUT_LINE('v_char_buffer = ' || v_char_buffer);

  -- use INSTR() to search v_clob for the second occurrence of is,
  -- and INSTR() returns 29
  DBMS_OUTPUT.PUT_LINE('Searching for second ''is''');
  v_pattern := 'is';
  v_occurrence := 2;
  v_return := DBMS_LOB.INSTR(v_clob, v_pattern, v_offset, v_occurrence);
  DBMS_OUTPUT.PUT_LINE('v_return = ' || v_return);

  -- use INSTR() to search v_clob for the first occurrence of Moon,
  -- and INSTR() returns 0 because Moon doesn’t appear in v_clob
  DBMS_OUTPUT.PUT_LINE('Searching for ''Moon''');
  v_pattern := 'Moon';
  v_occurrence := 1;
  v_return := DBMS_LOB.INSTR(v_clob, v_pattern, v_offset, v_occurrence);
  DBMS_OUTPUT.PUT_LINE('v_return = ' || v_return);

  -- use FREETEMPORARY() to free v_clob
  DBMS_LOB.FREETEMPORARY(v_clob);
END instr_example;
/

CREATE PROCEDURE copy_file_data_to_clob(
  p_clob_id INTEGER,
  p_directory VARCHAR2,
  p_file_name VARCHAR2
) AS
  v_file UTL_FILE.FILE_TYPE;
  v_chars_read INTEGER;
  v_dest_clob CLOB;
  v_amount INTEGER := 32767;
  v_char_buffer VARCHAR2(32767);
BEGIN
  -- insert an empty CLOB
  INSERT INTO clob_content(
    id, clob_column
  ) VALUES (
    p_clob_id, EMPTY_CLOB()
  );

  -- get the LOB locator of the CLOB
  SELECT clob_column
  INTO v_dest_clob
  FROM clob_content
  WHERE id = p_clob_id
  FOR UPDATE;

  -- open the file for reading of text (up to v_amount characters per line)
  v_file := UTL_FILE.FOPEN(p_directory, p_file_name, 'r', v_amount);

  -- copy the data from the file into v_dest_clob one line at a time
  LOOP
    BEGIN
      -- read a line from the file into v_char_buffer;
      -- GET_LINE() does not copy the newline character into
      -- v_char_buffer
      UTL_FILE.GET_LINE(v_file, v_char_buffer);
      v_chars_read := LENGTH(v_char_buffer);

      -- append the line to v_dest_clob
      DBMS_LOB.WRITEAPPEND(v_dest_clob, v_chars_read, v_char_buffer);

      -- append a newline to v_dest_clob because v_char_buffer;
      -- the ASCII value for newline is 10, so CHR(10) returns newline
      DBMS_LOB.WRITEAPPEND(v_dest_clob, 1, CHR(10));
    EXCEPTION
      -- when there is no more data in the file then exit
      WHEN NO_DATA_FOUND THEN
        EXIT;
    END;
  END LOOP;

  -- close the file
  UTL_FILE.FCLOSE(v_file);

  DBMS_OUTPUT.PUT_LINE('Copy successfully completed.');
END copy_file_data_to_clob;
/

CREATE PROCEDURE copy_file_data_to_blob(
  p_blob_id INTEGER,
  p_directory VARCHAR2,
  p_file_name VARCHAR2
) AS
  v_file UTL_FILE.FILE_TYPE;
  v_bytes_read INTEGER;
  v_dest_blob BLOB;
  v_amount INTEGER := 32767;
  v_binary_buffer RAW(32767);
BEGIN
  -- insert an empty BLOB
  INSERT INTO blob_content(
    id, blob_column
  ) VALUES (
    p_blob_id, EMPTY_BLOB()
  );

  -- get the LOB locator of the BLOB
  SELECT blob_column
  INTO v_dest_blob
  FROM blob_content
  WHERE id = p_blob_id
  FOR UPDATE;

  -- open the file for reading of bytes (up to v_amount bytes at a time)
  v_file := UTL_FILE.FOPEN(p_directory, p_file_name, 'rb', v_amount);

  -- copy the data from the file into v_dest_blob
  LOOP
    BEGIN
      -- read binary data from the file into v_binary_buffer
      UTL_FILE.GET_RAW(v_file, v_binary_buffer, v_amount);
      v_bytes_read := LENGTH(v_binary_buffer);

      -- append v_binary_buffer to v_dest_blob
      DBMS_LOB.WRITEAPPEND(v_dest_blob, v_bytes_read/2,
        v_binary_buffer);
    EXCEPTION
      -- when there is no more data in the file then exit
      WHEN NO_DATA_FOUND THEN
        EXIT;
    END;
  END LOOP;

  -- close the file
  UTL_FILE.FCLOSE(v_file);

  DBMS_OUTPUT.PUT_LINE('Copy successfully completed.');
END copy_file_data_to_blob;
/

CREATE PROCEDURE copy_clob_data_to_file(
  p_clob_id INTEGER,
  p_directory VARCHAR2,
  p_file_name VARCHAR2
) AS
  v_src_clob CLOB;
  v_file UTL_FILE.FILE_TYPE;
  v_offset INTEGER := 1;
  v_amount INTEGER := 32767;
  v_char_buffer VARCHAR2(32767);
BEGIN
  -- get the LOB locator of the CLOB
  SELECT clob_column
  INTO v_src_clob
  FROM clob_content
  WHERE id = p_clob_id;

  -- open the file for writing of text (up to v_amount characters at a time)
  v_file := UTL_FILE.FOPEN(p_directory, p_file_name, 'w', v_amount);

  -- copy the data from v_src_clob to the file
  LOOP
    BEGIN
      -- read characters from v_src_clob into v_char_buffer
      DBMS_LOB.READ(v_src_clob, v_amount, v_offset, v_char_buffer);

      -- copy the characters from v_char_buffer to the file
      UTL_FILE.PUT(v_file, v_char_buffer);

      -- add v_amount to v_offset
      v_offset := v_offset + v_amount;
    EXCEPTION
      -- when there is no more data in the file then exit
      WHEN NO_DATA_FOUND THEN
        EXIT;
    END;
  END LOOP;

  -- flush any remaining data to the file
  UTL_FILE.FFLUSH(v_file);

  -- close the file
  UTL_FILE.FCLOSE(v_file);

  DBMS_OUTPUT.PUT_LINE('Copy successfully completed.');
END copy_clob_data_to_file;
/

CREATE PROCEDURE copy_blob_data_to_file(
  p_blob_id INTEGER,
  p_directory VARCHAR2,
  p_file_name VARCHAR2
) AS
  v_src_blob BLOB;
  v_file UTL_FILE.FILE_TYPE;
  v_offset INTEGER := 1;
  v_amount INTEGER := 32767;
  v_binary_buffer RAW(32767);
BEGIN
  -- get the LOB locator of the BLOB
  SELECT blob_column
  INTO v_src_blob
  FROM blob_content
  WHERE id = p_blob_id;

  -- open the file for writing of bytes (up to v_amount bytes at a time)
  v_file := UTL_FILE.FOPEN(p_directory, p_file_name, 'wb', v_amount);

  -- copy the data from v_src_blob to the file
  LOOP
    BEGIN
      -- read characters from v_src_blob into v_binary_buffer
      DBMS_LOB.READ(v_src_blob, v_amount, v_offset, v_binary_buffer);

      -- copy the binary data from v_binary_buffer to the file
      UTL_FILE.PUT_RAW(v_file, v_binary_buffer);

      -- add v_amount to v_offset
      v_offset := v_offset + v_amount;
    EXCEPTION
      -- when there is no more data in the file then exit
      WHEN NO_DATA_FOUND THEN
        EXIT;
    END;
  END LOOP;

  -- flush any remaining data to the file
  UTL_FILE.FFLUSH(v_file);

  -- close the file
  UTL_FILE.FCLOSE(v_file);

  DBMS_OUTPUT.PUT_LINE('Copy successfully completed.');
END copy_blob_data_to_file;
/

CREATE PROCEDURE copy_bfile_data_to_clob(
  p_bfile_id INTEGER,
  p_clob_id INTEGER
) AS
  v_src_bfile BFILE;
  v_directory VARCHAR2(200);
  v_filename VARCHAR2(200);
  v_length INTEGER;
  v_dest_clob CLOB;
  v_amount INTEGER := DBMS_LOB.LOBMAXSIZE;
  v_dest_offset INTEGER := 1;
  v_src_offset INTEGER := 1;
  v_src_csid INTEGER := DBMS_LOB.DEFAULT_CSID;
  v_lang_context INTEGER := DBMS_LOB.DEFAULT_LANG_CTX;
  v_warning INTEGER;
BEGIN
  -- get the locator of the BFILE
  SELECT bfile_column
  INTO v_src_bfile
  FROM bfile_content
  WHERE id = p_bfile_id;

  -- use FILEEXISTS() to check if the file exists
  -- (FILEEXISTS() returns 1 if the file exists)
  IF (DBMS_LOB.FILEEXISTS(v_src_bfile) = 1) THEN
    -- use OPEN() to open the file
    DBMS_LOB.OPEN(v_src_bfile);

    -- use FILEGETNAME() to get the name of the file and the directory
    DBMS_LOB.FILEGETNAME(v_src_bfile, v_directory, v_filename);
    DBMS_OUTPUT.PUT_LINE('Directory = ' || v_directory);
    DBMS_OUTPUT.PUT_LINE('Filename = ' || v_filename);

    -- insert an empty CLOB
    INSERT INTO clob_content(
      id, clob_column
    ) VALUES (
      p_clob_id, EMPTY_CLOB()
    );

    -- get the LOB locator of the CLOB (for update)
    SELECT clob_column
    INTO v_dest_clob
    FROM clob_content
    WHERE id = p_clob_id
    FOR UPDATE;

    -- use LOADCLOBFROMFILE() to get up to v_amount characters
    -- from v_src_bfile and store them in v_dest_clob, starting
    -- at offset 1 in v_src_bfile and v_dest_clob
    DBMS_LOB.LOADCLOBFROMFILE(
      v_dest_clob, v_src_bfile,
      v_amount, v_dest_offset, v_src_offset,
      v_src_csid, v_lang_context, v_warning
    );

    -- check v_warning for an inconvertible character
    IF (v_warning = DBMS_LOB.WARN_INCONVERTIBLE_CHAR) THEN
      DBMS_OUTPUT.PUT_LINE('Warning! Inconvertible character.');
    END IF;

    -- use CLOSE() to close v_src_bfile
    DBMS_LOB.CLOSE(v_src_bfile);
    DBMS_OUTPUT.PUT_LINE('Copy successfully completed.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('File does not exist');
  END IF;
END copy_bfile_data_to_clob;
/

CREATE PROCEDURE copy_bfile_data_to_blob(
  p_bfile_id INTEGER,
  p_blob_id INTEGER
) AS
  v_src_bfile BFILE;
  v_directory VARCHAR2(200);
  v_filename VARCHAR2(200);
  v_length INTEGER;
  v_dest_blob BLOB;
  v_amount INTEGER := DBMS_LOB.LOBMAXSIZE;
  v_dest_offset INTEGER := 1;
  v_src_offset INTEGER := 1;
BEGIN
  -- get the locator of the BFILE
  SELECT bfile_column
  INTO v_src_bfile
  FROM bfile_content
  WHERE id = p_bfile_id;

  -- use FILEEXISTS() to check if the file exists
  -- (FILEEXISTS() returns 1 if the file exists)
  IF (DBMS_LOB.FILEEXISTS(v_src_bfile) = 1) THEN
    -- use OPEN() to open the file
    DBMS_LOB.OPEN(v_src_bfile);

    -- use FILEGETNAME() to get the name of the file and
    -- the directory
    DBMS_LOB.FILEGETNAME(v_src_bfile, v_directory, v_filename);
    DBMS_OUTPUT.PUT_LINE('Directory = ' || v_directory);
    DBMS_OUTPUT.PUT_LINE('Filename = ' || v_filename);

    -- insert an empty BLOB
    INSERT INTO blob_content(
      id, blob_column
    ) VALUES (
      p_blob_id, EMPTY_BLOB()
    );

    -- get the LOB locator of the BLOB (for update)
    SELECT blob_column
    INTO v_dest_blob
    FROM blob_content
    WHERE id = p_blob_id
    FOR UPDATE;

    -- use LOADBLOBFROMFILE() to get up to v_amount bytes
    -- from v_src_bfile and store them in v_dest_blob, starting
    -- at offset 1 in v_src_bfile and v_dest_blob
    DBMS_LOB.LOADBLOBFROMFILE(
      v_dest_blob, v_src_bfile,
      v_amount, v_dest_offset, v_src_offset
    );

    -- use CLOSE() to close v_src_bfile
    DBMS_LOB.CLOSE(v_src_bfile);
    DBMS_OUTPUT.PUT_LINE('Copy successfully completed.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('File does not exist');
  END IF;
END copy_bfile_data_to_blob;
/
