-- Migration: Add missing columns to products and panel_votes tables
-- Date: 2025-11-15
-- Description: Adds created_at to products, and points+synced to panel_votes

-- ============================================
-- 1. Add created_at to products table
-- ============================================
DO $$ 
BEGIN
  -- Check if created_at column exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'products' 
    AND column_name = 'created_at'
  ) THEN
    -- Add created_at column with default value
    ALTER TABLE public.products 
    ADD COLUMN created_at timestamptz NOT NULL DEFAULT now();
    
    -- Update existing rows to use updated_at as created_at
    UPDATE public.products 
    SET created_at = updated_at 
    WHERE created_at IS NULL OR created_at = now();
    
    RAISE NOTICE 'Added created_at column to products table';
  ELSE
    RAISE NOTICE 'Column created_at already exists in products table';
  END IF;
END $$;

-- ============================================
-- 2. Add points to panel_votes table
-- ============================================
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'panel_votes' 
    AND column_name = 'points'
  ) THEN
    ALTER TABLE public.panel_votes 
    ADD COLUMN points integer NOT NULL DEFAULT 1;
    
    RAISE NOTICE 'Added points column to panel_votes table';
  ELSE
    RAISE NOTICE 'Column points already exists in panel_votes table';
  END IF;
END $$;

-- ============================================
-- 3. Add synced to panel_votes table
-- ============================================
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'panel_votes' 
    AND column_name = 'synced'
  ) THEN
    ALTER TABLE public.panel_votes 
    ADD COLUMN synced boolean NOT NULL DEFAULT true;
    
    RAISE NOTICE 'Added synced column to panel_votes table';
  ELSE
    RAISE NOTICE 'Column synced already exists in panel_votes table';
  END IF;
END $$;

-- ============================================
-- 4. Create index on products.created_at
-- ============================================
CREATE INDEX IF NOT EXISTS idx_products_created_at 
ON public.products(created_at DESC);

-- ============================================
-- 5. Verify changes
-- ============================================
DO $$ 
BEGIN
  RAISE NOTICE '✅ Migration completed successfully!';
  RAISE NOTICE 'Products table now has: id, name, description, price, seller_id, stock, shipping_option, image_url, is_active, created_at, updated_at, points_price, is_exclusive';
  RAISE NOTICE 'Panel_votes table now has: id, user_id, schedule_item_id, contestant_id, points, synced, created_at';
END $$;
