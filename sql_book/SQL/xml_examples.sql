-- This script creates two PL/SQL procedures, run this script as the store user

CREATE PROCEDURE write_xml_data_to_file(
  p_directory VARCHAR2,
  p_file_name VARCHAR2
) AS
  v_file UTL_FILE.FILE_TYPE;
  v_amount INTEGER := 32767;
  v_xml_data XMLType;
  v_char_buffer VARCHAR2(32767);
BEGIN
  -- open the file for writing of text (up to v_amount
  -- characters at a time)
  v_file := UTL_FILE.FOPEN(p_directory, p_file_name, 'w', v_amount);

  -- write the starting line to v_file
  UTL_FILE.PUT_LINE(v_file, '<?xml version="1.0"?>');

  -- retrieve the customers and store them in v_xml_data
  SELECT
    EXTRACT(
      XMLELEMENT(
        "customer_list",
        XMLAGG(
          XMLELEMENT("customer", first_name || ' ' || last_name)
          ORDER BY last_name
        )
      ),
      '/customer_list'
    )
  AS xml_customers
  INTO v_xml_data
  FROM customers;

  -- get the string value from v_xml_data and store it in v_char_buffer
  v_char_buffer := v_xml_data.GETSTRINGVAL();

  -- copy the characters from v_char_buffer to the file
  UTL_FILE.PUT(v_file, v_char_buffer);

  -- flush any remaining data to the file
  UTL_FILE.FFLUSH(v_file);

  -- close the file
  UTL_FILE.FCLOSE(v_file);
END write_xml_data_to_file;
/

CREATE PROCEDURE create_xml_resources AS
  v_result BOOLEAN;

  -- create string containing XML for products
  v_products VARCHAR2(300):=
    '<?xml version="1.0"?>' ||
    '<products>' ||
      '<product product_id="1" product_type_id="1" name="Modern Science"'
       || ' price="19.95"/>' ||
      '<product product_id="2" product_type_id="1" name="Chemistry"' ||
      ' price="30"/>' ||
      '<product product_id="3" product_type_id="2" name="Supernova"' ||
      ' price="25.99"/>' ||
    '</products>';

  -- create string containing XML for product types
  v_product_types VARCHAR2(300):=
    '<?xml version="1.0"?>' ||
    '<product_types>' ||
      '<product_type product_type_id="1" name="Book"/>' ||
      '<product_type product_type_id="2" name="Video"/>' ||
    '</product_types>';
BEGIN
  -- create resource for products
  v_result := DBMS_XDB.CREATERESOURCE('/public/products.xml',
    v_products);

  -- create resource for product types
  v_result := DBMS_XDB.CREATERESOURCE('/public/product_types.xml',
    v_product_types);
END create_xml_resources;
/
