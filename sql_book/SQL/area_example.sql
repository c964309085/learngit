SET SERVEROUTPUT ON

DECLARE
  v_width  INTEGER;
  v_height INTEGER := 2;
  v_area   INTEGER := 6;
BEGIN
  -- set the width equal to the area divided by the height
  v_width := v_area / v_height;
  DBMS_OUTPUT.PUT_LINE('v_width = ' || v_width);
EXCEPTION
  WHEN ZERO_DIVIDE THEN
    DBMS_OUTPUT.PUT_LINE('Division by zero');
END;
/
