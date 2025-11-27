-- Fix products table to ensure all necessary columns exist
-- Run this migration if products aren't showing up in the shop

-- Ensure created_at and updated_at have defaults
ALTER TABLE products 
  ALTER COLUMN created_at SET DEFAULT now(),
  ALTER COLUMN updated_at SET DEFAULT now();

-- Ensure is_active defaults to true
ALTER TABLE products 
  ALTER COLUMN is_active SET DEFAULT true;

-- Ensure is_exclusive defaults to false  
ALTER TABLE products 
  ALTER COLUMN is_exclusive SET DEFAULT false;

-- Add shipping_option if it doesn't exist (with default)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' AND column_name = 'shipping_option'
  ) THEN
    ALTER TABLE products 
      ADD COLUMN shipping_option text NOT NULL DEFAULT 'stand_pickup' 
      CHECK (shipping_option IN ('stand_pickup', 'home_delivery', 'both'));
  END IF;
END $$;

-- Create updated_at trigger for products if it doesn't exist
CREATE OR REPLACE FUNCTION update_products_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_products_updated_at_trigger ON products;

CREATE TRIGGER update_products_updated_at_trigger
  BEFORE UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION update_products_updated_at();

-- Add index for active products query (performance optimization)
CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active, created_at DESC);

-- Grant permissions for products table
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Allow everyone to read active products
DROP POLICY IF EXISTS "Allow public read access to active products" ON products;
CREATE POLICY "Allow public read access to active products"
  ON products FOR SELECT
  USING (is_active = true);

-- Allow authenticated users to read all products
DROP POLICY IF EXISTS "Allow authenticated users to read all products" ON products;
CREATE POLICY "Allow authenticated users to read all products"
  ON products FOR SELECT
  TO authenticated
  USING (true);

-- Allow admin users to insert/update/delete products
DROP POLICY IF EXISTS "Allow admin users to manage products" ON products;
CREATE POLICY "Allow admin users to manage products"
  ON products FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Display confirmation
DO $$
BEGIN
  RAISE NOTICE '✅ Products table migration completed successfully';
END $$;
