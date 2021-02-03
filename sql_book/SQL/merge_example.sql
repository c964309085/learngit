MERGE INTO products p
USING product_changes pc ON (
  p.product_id = pc.product_id 
)
WHEN MATCHED THEN
  UPDATE
  SET
    p.product_type_id = pc.product_type_id,
    p.name = pc.name,
    p.description = pc.description,
    p.price = pc.price
WHEN NOT MATCHED THEN
  INSERT (
    p.product_id, p.product_type_id, p.name,
    p.description, p.price
  ) VALUES (
    pc.product_id, pc.product_type_id, pc.name,
    pc.description, pc.price
  );
