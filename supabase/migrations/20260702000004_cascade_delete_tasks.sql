-- Update milestone_id foreign key to cascade delete tasks when milestone is deleted
ALTER TABLE public.tasks
DROP CONSTRAINT tasks_milestone_id_fkey;

ALTER TABLE public.tasks
ADD CONSTRAINT tasks_milestone_id_fkey
FOREIGN KEY (milestone_id)
REFERENCES public.milestones(id)
ON DELETE CASCADE;
