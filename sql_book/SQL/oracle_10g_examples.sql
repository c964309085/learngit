-- This script Will only run if you are using Oracle Database 10g
-- or higher

-- This script does the following:
--   Connects as the store user and creates items for the
--   Oracle Database 10g examples

CONNECT store/store_password;

-- BINARY_FLOAT and BINARY_DOUBLE example
CREATE TABLE binary_test (
  bin_float BINARY_FLOAT,
  bin_double BINARY_DOUBLE
);

INSERT INTO binary_test (
  bin_float, bin_double
) VALUES (
  39.5f, 15.7d
);

INSERT INTO binary_test (
  bin_float, bin_double
) VALUES (
  BINARY_FLOAT_INFINITY, BINARY_DOUBLE_INFINITY
);

-- commit the transaction
COMMIT;
