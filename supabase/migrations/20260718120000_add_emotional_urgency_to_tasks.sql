-- Emotionales Bedürfnis, den Task zu schließen (1 = niedrig, 3 = hoch).
-- Kriterium für "wo gerade die Energie hinfließen will", unabhängig von Deadline/Priorität.
ALTER TABLE public.tasks
ADD COLUMN emotional_urgency SMALLINT
  CHECK (emotional_urgency IS NULL OR emotional_urgency BETWEEN 1 AND 3);

CREATE INDEX idx_tasks_emotional_urgency
ON public.tasks(emotional_urgency DESC);
