-- Create comics table
CREATE TABLE public.comics (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  prompt text NOT NULL,
  image_url text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),
  model_used text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT comics_pkey PRIMARY KEY (id),
  CONSTRAINT comics_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);

-- Add credits to profiles if it doesn't exist
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS credits integer NOT NULL DEFAULT 0;

-- Enable RLS
ALTER TABLE public.comics ENABLE ROW LEVEL SECURITY;

-- Policies for comics
CREATE POLICY "Users can view their own comics" 
ON public.comics FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own comics" 
ON public.comics FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Storage bucket for comics (if not exists)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('comics', 'comics', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
CREATE POLICY "Public Access to Comics"
ON storage.objects FOR SELECT
USING ( bucket_id = 'comics' );

CREATE POLICY "Authenticated users can upload comics"
ON storage.objects FOR INSERT
WITH CHECK ( bucket_id = 'comics' AND auth.role() = 'authenticated' );
