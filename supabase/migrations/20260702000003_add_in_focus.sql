-- Add in_focus field to milestones for starring/favoriting
ALTER TABLE public.milestones
ADD COLUMN in_focus BOOLEAN DEFAULT FALSE;

-- Add in_focus field to projects for starring/favoriting
ALTER TABLE public.projects
ADD COLUMN in_focus BOOLEAN DEFAULT FALSE;

-- Create indexes for in_focus to optimize sorting
CREATE INDEX idx_milestones_in_focus
ON public.milestones(in_focus DESC);

CREATE INDEX idx_projects_in_focus
ON public.projects(in_focus DESC);
