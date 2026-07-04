-- Add Anthropic API key to user profile
ALTER TABLE public.profile
ADD COLUMN anthropic_api_key TEXT;
