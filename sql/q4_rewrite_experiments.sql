-- HISTORICAL EXPERIMENT RECORD; DO NOT RUN AGAINST CURRENT PRODUCTION CLOUD SQL.
-- Baselines were measured before the selected final indexes were deployed.
-- Exact reproduction requires an equivalent pre-final-index state or a separate test database.
-- Do not drop the deployed final indexes to recreate these historical experiments.
-- CS 411 Team 058: final Q4 Fastest Lap Specialists indexing configurations.

-- Compare the final Q4 baseline with Designs A, B, and C.

-- The derived table computes one minimum per race; ties are retained.


ANALYZE TABLE Lap, Race, Driver;

SELECT 'R0 REWRITE BASELINE - EXISTING INDEXES ONLY' AS experiment;

EXPLAIN ANALYZE
SELECT d.forename,
       d.surname,
       COUNT(*)    AS fastestLaps,
       MIN(r.year) AS firstYear,
       MAX(r.year) AS lastYear
FROM Lap l
JOIN (
    SELECT raceId, MIN(lapTimeMs) AS bestLapTimeMs
    FROM Lap
    GROUP BY raceId
) best
    ON best.raceId = l.raceId
   AND best.bestLapTimeMs = l.lapTimeMs
JOIN Race r ON r.raceId = l.raceId
JOIN Driver d ON d.driverId = l.driverId
GROUP BY d.driverId, d.forename, d.surname
ORDER BY fastestLaps DESC, d.surname
LIMIT 15;

CREATE INDEX idx_q4_rewrite_a ON Lap(raceId, lapTimeMs);

SELECT 'Q4 REWRITE DESIGN A: Lap(raceId, lapTimeMs)' AS experiment;

EXPLAIN ANALYZE
SELECT d.forename,
       d.surname,
       COUNT(*)    AS fastestLaps,
       MIN(r.year) AS firstYear,
       MAX(r.year) AS lastYear
FROM Lap l
JOIN (
    SELECT raceId, MIN(lapTimeMs) AS bestLapTimeMs
    FROM Lap
    GROUP BY raceId
) best
    ON best.raceId = l.raceId
   AND best.bestLapTimeMs = l.lapTimeMs
JOIN Race r ON r.raceId = l.raceId
JOIN Driver d ON d.driverId = l.driverId
GROUP BY d.driverId, d.forename, d.surname
ORDER BY fastestLaps DESC, d.surname
LIMIT 15;

DROP INDEX idx_q4_rewrite_a ON Lap;

CREATE INDEX idx_q4_rewrite_b ON Lap(lapTimeMs, raceId);

SELECT 'Q4 REWRITE DESIGN B: Lap(lapTimeMs, raceId)' AS experiment;

EXPLAIN ANALYZE
SELECT d.forename,
       d.surname,
       COUNT(*)    AS fastestLaps,
       MIN(r.year) AS firstYear,
       MAX(r.year) AS lastYear
FROM Lap l
JOIN (
    SELECT raceId, MIN(lapTimeMs) AS bestLapTimeMs
    FROM Lap
    GROUP BY raceId
) best
    ON best.raceId = l.raceId
   AND best.bestLapTimeMs = l.lapTimeMs
JOIN Race r ON r.raceId = l.raceId
JOIN Driver d ON d.driverId = l.driverId
GROUP BY d.driverId, d.forename, d.surname
ORDER BY fastestLaps DESC, d.surname
LIMIT 15;

DROP INDEX idx_q4_rewrite_b ON Lap;

CREATE INDEX idx_q4_rewrite_c ON Lap(raceId, driverId, lapTimeMs);

SELECT 'Q4 REWRITE DESIGN C: Lap(raceId, driverId, lapTimeMs)' AS experiment;

EXPLAIN ANALYZE
SELECT d.forename,
       d.surname,
       COUNT(*)    AS fastestLaps,
       MIN(r.year) AS firstYear,
       MAX(r.year) AS lastYear
FROM Lap l
JOIN (
    SELECT raceId, MIN(lapTimeMs) AS bestLapTimeMs
    FROM Lap
    GROUP BY raceId
) best
    ON best.raceId = l.raceId
   AND best.bestLapTimeMs = l.lapTimeMs
JOIN Race r ON r.raceId = l.raceId
JOIN Driver d ON d.driverId = l.driverId
GROUP BY d.driverId, d.forename, d.surname
ORDER BY fastestLaps DESC, d.surname
LIMIT 15;

DROP INDEX idx_q4_rewrite_c ON Lap;

SELECT 'R END - ALL REWRITE EXPERIMENTAL INDEXES REMOVED' AS status;

SELECT 'REWRITTEN Q4 - TOP 15 RESULTS (COMPARE WITH SAVED ORIGINAL Q4)' AS evidence_label;

SELECT d.forename,
       d.surname,
       COUNT(*)    AS fastestLaps,
       MIN(r.year) AS firstYear,
       MAX(r.year) AS lastYear
FROM Lap l
JOIN (
    SELECT raceId, MIN(lapTimeMs) AS bestLapTimeMs
    FROM Lap
    GROUP BY raceId
) best
    ON best.raceId = l.raceId
   AND best.bestLapTimeMs = l.lapTimeMs
JOIN Race r ON r.raceId = l.raceId
JOIN Driver d ON d.driverId = l.driverId
GROUP BY d.driverId, d.forename, d.surname
ORDER BY fastestLaps DESC, d.surname
LIMIT 15;
