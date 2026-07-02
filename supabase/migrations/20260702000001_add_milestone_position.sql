-- Add position field to milestones for custom ordering
ALTER TABLE public.milestones
ADD COLUMN position INT DEFAULT 0;

-- Create index for position to optimize sorting
CREATE INDEX idx_milestones_position
ON public.milestones(position);
