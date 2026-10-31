-- Final additional indexes selected for Stage 3.
-- Both indexes have already been created and verified on Cloud SQL.
-- Do NOT execute CREATE INDEX again on the populated database.
-- These statements document the selected definitions only:
-- CREATE INDEX idx_rr_finish_position ON RaceResult(finishPosition);
-- CREATE INDEX idx_lap_race_time ON Lap(raceId, lapTimeMs);

-- Read-only verification for both selected indexes:
SHOW INDEX FROM RaceResult WHERE Key_name = 'idx_rr_finish_position';
SHOW INDEX FROM Lap WHERE Key_name = 'idx_lap_race_time';
