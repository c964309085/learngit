TTITLE LEFT 'Run date: ' _DATE CENTER 'Run by the ' SQL.USER ' user' RIGHT 'Page: ' FORMAT 999 SQL.PNO SKIP 2

BTITLE CENTER 'Thanks for running the report' RIGHT 'Page: ' FORMAT 999 SQL.PNO

SET ECHO OFF
SET VERIFY OFF
SET PAGESIZE 30
SET LINESIZE 70
CLEAR COLUMNS
COLUMN product_id HEADING ID FORMAT 99
COLUMN name HEADING 'Product Name' FORMAT A20 WORD_WRAPPED
COLUMN description HEADING Description FORMAT A30 WORD_WRAPPED
COLUMN price HEADING Price FORMAT $99.99

SELECT product_id, name, description, price
FROM products;

CLEAR COLUMNS
TTITLE OFF
BTITLE OFF
