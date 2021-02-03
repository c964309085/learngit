SET ECHO OFF
SET VERIFY OFF

ACCEPT v_product_id NUMBER FORMAT 99 PROMPT 'Product id: '

SELECT product_id, name, price
FROM products
WHERE product_id = &v_product_id;

-- clean up
UNDEFINE v_product_id
