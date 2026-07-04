-- Create decisions table
CREATE TABLE public.decisions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  method TEXT NOT NULL,
  topic TEXT NOT NULL,
  result TEXT NOT NULL,
  details JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.decisions ENABLE ROW LEVEL SECURITY;

-- Create policy: users can read/write their own decisions
CREATE POLICY "Users can manage their own decisions"
  ON public.decisions
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create index for faster queries
CREATE INDEX decisions_user_id_created_at_idx
  ON public.decisions(user_id, created_at DESC);
