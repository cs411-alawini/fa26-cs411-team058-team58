-- Run ONCE, after checking SHOW INDEX FROM RaceResult;
-- Chosen design: lower estimated cost for Q1 with minimum additional index.
CREATE INDEX idx_rr_finish_position ON RaceResult(finishPosition);
SHOW INDEX FROM RaceResult;
