-- Add parent_milestone_id to milestones table (for hierarchical milestones)
ALTER TABLE public.milestones
ADD COLUMN parent_milestone_id UUID REFERENCES public.milestones(id) ON DELETE SET NULL;

-- Add milestone_id to tasks table (for task-milestone association)
ALTER TABLE public.tasks
ADD COLUMN milestone_id UUID REFERENCES public.milestones(id) ON DELETE SET NULL;

-- Create index for parent_milestone_id for better query performance
CREATE INDEX idx_milestones_parent_milestone_id
ON public.milestones(parent_milestone_id);

-- Create index for milestone_id in tasks
CREATE INDEX idx_tasks_milestone_id
ON public.tasks(milestone_id);
