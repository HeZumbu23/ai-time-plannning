-- Add position field to projects for custom ordering
ALTER TABLE public.projects
ADD COLUMN position INT DEFAULT 0;

-- Create index for position to optimize sorting
CREATE INDEX idx_projects_position
ON public.projects(position);
