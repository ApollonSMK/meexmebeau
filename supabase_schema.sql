-- ============================================
-- ME Skin AI — Supabase Database Schema
-- ============================================
-- Run this SQL in your Supabase SQL Editor
-- Dashboard: https://supabase.com/dashboard
-- ============================================

-- 1. Products table
CREATE TABLE IF NOT EXISTS products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  price DECIMAL(10,2),
  image_url TEXT,
  skin_concerns TEXT[] DEFAULT '{}',
  skin_types TEXT[] DEFAULT '{}',
  ingredients TEXT,
  brand TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Analyses table
CREATE TABLE IF NOT EXISTS analyses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  rapport_raw TEXT,
  rapport_source TEXT DEFAULT 'M7',
  skin_type TEXT,
  ai_analysis JSONB,
  skin_scores JSONB,
  recommended_product_ids UUID[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Admin users table
CREATE TABLE IF NOT EXISTS admin_users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  role TEXT DEFAULT 'admin',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- Row Level Security (RLS)
-- ============================================

ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Products: anyone can read active products
CREATE POLICY "Products are viewable by everyone"
  ON products FOR SELECT
  USING (true);

-- Products: only authenticated admins can insert
CREATE POLICY "Admins can insert products"
  ON products FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() IN (SELECT id FROM admin_users)
  );

-- Products: only authenticated admins can update
CREATE POLICY "Admins can update products"
  ON products FOR UPDATE
  TO authenticated
  USING (
    auth.uid() IN (SELECT id FROM admin_users)
  );

-- Products: only authenticated admins can delete
CREATE POLICY "Admins can delete products"
  ON products FOR DELETE
  TO authenticated
  USING (
    auth.uid() IN (SELECT id FROM admin_users)
  );

-- Analyses: anyone can insert (for anonymous usage)
CREATE POLICY "Anyone can insert analyses"
  ON analyses FOR INSERT
  WITH CHECK (true);

-- Analyses: anyone can read
CREATE POLICY "Analyses are viewable by everyone"
  ON analyses FOR SELECT
  USING (true);

-- Admin users: only admins can read
CREATE POLICY "Admins can view admin_users"
  ON admin_users FOR SELECT
  TO authenticated
  USING (
    auth.uid() IN (SELECT id FROM admin_users)
  );

-- ============================================
-- Indexes for performance
-- ============================================
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active);
CREATE INDEX IF NOT EXISTS idx_analyses_created ON analyses(created_at DESC);

-- ============================================
-- Sample products (optional - for testing)
-- ============================================
INSERT INTO products (name, description, category, price, brand, skin_concerns, skin_types, ingredients) VALUES
  ('Hydra Boost Sérum', 'Sérum intensivo de ácido hialurónico para hidratação profunda e duradoura. Textura leve e absorção rápida.', 'Sérum', 45.90, 'SkinLab', ARRAY['Desidratação', 'Rugas'], ARRAY['Seca', 'Normal', 'Mista'], 'Ácido Hialurónico, Vitamina B5, Aloe Vera'),
  ('Vitamin C Glow Sérum', 'Sérum antioxidante com Vitamina C 15% para luminosidade e proteção contra radicais livres.', 'Sérum', 52.00, 'SkinLab', ARRAY['Manchas', 'Textura Irregular'], ARRAY['Normal', 'Mista', 'Oleosa'], 'Vitamina C 15%, Vitamina E, Ácido Ferúlico'),
  ('Pore Refiner Tónico', 'Tónico adstringente com niacinamida para redução visível dos poros e controlo de oleosidade.', 'Tónico', 28.50, 'DermaClean', ARRAY['Poros Dilatados', 'Oleosidade'], ARRAY['Oleosa', 'Mista'], 'Niacinamida 10%, Zinco, Ácido Salicílico'),
  ('Anti-Aging Night Cream', 'Creme noturno reparador com retinol e peptídeos para combate a rugas e linhas finas.', 'Hidratante', 68.00, 'SkinLab', ARRAY['Rugas', 'Flacidez'], ARRAY['Normal', 'Seca', 'Mista'], 'Retinol 0.5%, Peptídeos, Manteiga de Karité'),
  ('Gentle Foam Cleanser', 'Espuma de limpeza suave para todos os tipos de pele. Remove impurezas sem ressecar.', 'Limpeza', 22.90, 'DermaClean', ARRAY['Acne', 'Oleosidade'], ARRAY['Normal', 'Oleosa', 'Mista', 'Sensível'], 'Extrato de Camomila, Glicerina, Ácido Láctico'),
  ('SPF 50+ Daily Shield', 'Protetor solar facial de uso diário com textura invisível e proteção UVA/UVB.', 'Protetor Solar', 35.00, 'SunGuard', ARRAY['Manchas', 'Rugas'], ARRAY['Normal', 'Oleosa', 'Mista', 'Seca', 'Sensível'], 'Óxido de Zinco, Vitamina E, Niacinamida'),
  ('Retexturizing Peel', 'Esfoliante químico com AHA e BHA para renovação celular e textura uniforme.', 'Esfoliante', 38.50, 'SkinLab', ARRAY['Textura Irregular', 'Acne', 'Manchas'], ARRAY['Normal', 'Oleosa', 'Mista'], 'Ácido Glicólico 8%, Ácido Salicílico 2%'),
  ('Eye Repair Complex', 'Complexo anti-olheiras e anti-rugas para o contorno dos olhos com cafeína e vitamina K.', 'Contorno de Olhos', 42.00, 'DermaClean', ARRAY['Olheiras', 'Rugas'], ARRAY['Normal', 'Seca', 'Mista', 'Sensível'], 'Cafeína, Vitamina K, Peptídeos de Colágeno');
