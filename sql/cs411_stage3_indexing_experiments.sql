-- Team 058 Stage 3: THREE-query indexing experiments (Q1, Q3, Q4)
-- Run only against MySQL 8.4 lights_out_trivia, after importing and verifying data.
-- Records 12 EXPLAIN ANALYZE plans: baseline + three nondefault designs per query.
-- Each design is tested ALONE, then removed before the next design.
-- This script does NOT modify any row data and does not drop any existing index.
-- If an error occurs, stop and check SHOW INDEX before restarting.
USE lights_out_trivia;
SELECT 'SERVER AND ORIGINAL INDEXES' AS phase, VERSION() AS mysql_version;
SHOW INDEX FROM RaceResult;
SHOW INDEX FROM PitStop;
SHOW INDEX FROM Lap;
ANALYZE TABLE RaceResult, Race, Circuit, Driver, PitStop, Constructor, Lap;

-- ============ QUERY 1: BASELINE ============
SELECT 'Q1 BASELINE' AS experiment;
EXPLAIN ANALYZE SELECT c.name    AS circuit,
       d.forename,
       d.surname,
       COUNT(*)  AS wins
FROM RaceResult rr
JOIN Race    r ON r.raceId    = rr.raceId
JOIN Circuit c ON c.circuitId = r.circuitId
JOIN Driver  d ON d.driverId  = rr.driverId
WHERE rr.finishPosition = 1
GROUP BY c.circuitId, c.name, d.driverId, d.forename, d.surname
HAVING COUNT(*) = (SELECT COUNT(*)
                   FROM RaceResult rr2
                   JOIN Race r2 ON r2.raceId = rr2.raceId
                   WHERE rr2.finishPosition = 1
                     AND r2.circuitId = c.circuitId
                   GROUP BY rr2.driverId
                   ORDER BY COUNT(*) DESC
                   LIMIT 1)
ORDER BY wins DESC, circuit
LIMIT 15;

-- ------------ QUERY 1: INDEX A (Index winning position) ------------
CREATE INDEX idx_s3_q1_a ON RaceResult(finishPosition);
SELECT 'Q1 DESIGN A: idx_s3_q1_a ON RaceResult(finishPosition)' AS experiment;
EXPLAIN ANALYZE SELECT c.name    AS circuit,
       d.forename,
       d.surname,
       COUNT(*)  AS wins
FROM RaceResult rr
JOIN Race    r ON r.raceId    = rr.raceId
JOIN Circuit c ON c.circuitId = r.circuitId
JOIN Driver  d ON d.driverId  = rr.driverId
WHERE rr.finishPosition = 1
GROUP BY c.circuitId, c.name, d.driverId, d.forename, d.surname
HAVING COUNT(*) = (SELECT COUNT(*)
                   FROM RaceResult rr2
                   JOIN Race r2 ON r2.raceId = rr2.raceId
                   WHERE rr2.finishPosition = 1
                     AND r2.circuitId = c.circuitId
                   GROUP BY rr2.driverId
                   ORDER BY COUNT(*) DESC
                   LIMIT 1)
ORDER BY wins DESC, circuit
LIMIT 15;
DROP INDEX idx_s3_q1_a ON RaceResult;

-- ------------ QUERY 1: INDEX B (Add race join field) ------------
CREATE INDEX idx_s3_q1_b ON RaceResult(finishPosition, raceId);
SELECT 'Q1 DESIGN B: idx_s3_q1_b ON RaceResult(finishPosition, raceId)' AS experiment;
EXPLAIN ANALYZE SELECT c.name    AS circuit,
       d.forename,
       d.surname,
       COUNT(*)  AS wins
FROM RaceResult rr
JOIN Race    r ON r.raceId    = rr.raceId
JOIN Circuit c ON c.circuitId = r.circuitId
JOIN Driver  d ON d.driverId  = rr.driverId
WHERE rr.finishPosition = 1
GROUP BY c.circuitId, c.name, d.driverId, d.forename, d.surname
HAVING COUNT(*) = (SELECT COUNT(*)
                   FROM RaceResult rr2
                   JOIN Race r2 ON r2.raceId = rr2.raceId
                   WHERE rr2.finishPosition = 1
                     AND r2.circuitId = c.circuitId
                   GROUP BY rr2.driverId
                   ORDER BY COUNT(*) DESC
                   LIMIT 1)
ORDER BY wins DESC, circuit
LIMIT 15;
DROP INDEX idx_s3_q1_b ON RaceResult;

-- ------------ QUERY 1: INDEX C (Compare alternative composite key order) ------------
CREATE INDEX idx_s3_q1_c ON RaceResult(finishPosition, driverId, raceId);
SELECT 'Q1 DESIGN C: idx_s3_q1_c ON RaceResult(finishPosition, driverId, raceId)' AS experiment;
EXPLAIN ANALYZE SELECT c.name    AS circuit,
       d.forename,
       d.surname,
       COUNT(*)  AS wins
FROM RaceResult rr
JOIN Race    r ON r.raceId    = rr.raceId
JOIN Circuit c ON c.circuitId = r.circuitId
JOIN Driver  d ON d.driverId  = rr.driverId
WHERE rr.finishPosition = 1
GROUP BY c.circuitId, c.name, d.driverId, d.forename, d.surname
HAVING COUNT(*) = (SELECT COUNT(*)
                   FROM RaceResult rr2
                   JOIN Race r2 ON r2.raceId = rr2.raceId
                   WHERE rr2.finishPosition = 1
                     AND r2.circuitId = c.circuitId
                   GROUP BY rr2.driverId
                   ORDER BY COUNT(*) DESC
                   LIMIT 1)
ORDER BY wins DESC, circuit
LIMIT 15;
DROP INDEX idx_s3_q1_c ON RaceResult;

-- ============ QUERY 3: BASELINE ============
SELECT 'Q3 BASELINE' AS experiment;
EXPLAIN ANALYZE SELECT r.year,
       con.name                        AS constructor,
       COUNT(*)                        AS stops,
       ROUND(AVG(ps.durationMs) / 1000, 3) AS avgStopSec
FROM PitStop ps
JOIN RaceResult  rr  ON rr.raceId = ps.raceId AND rr.driverId = ps.driverId
JOIN Race        r   ON r.raceId  = ps.raceId
JOIN Constructor con ON con.constructorId = rr.constructorId
WHERE ps.durationMs < 60000
GROUP BY r.year, con.constructorId, con.name
HAVING COUNT(*) >= 20
   AND AVG(ps.durationMs) < (SELECT AVG(ps2.durationMs)
                             FROM PitStop ps2
                             JOIN Race r2 ON r2.raceId = ps2.raceId
                             WHERE r2.year = r.year
                               AND ps2.durationMs < 60000)
ORDER BY r.year DESC, avgStopSec
LIMIT 15;

-- ------------ QUERY 3: INDEX A (Filter stop duration) ------------
CREATE INDEX idx_s3_q3_a ON PitStop(durationMs);
SELECT 'Q3 DESIGN A: idx_s3_q3_a ON PitStop(durationMs)' AS experiment;
EXPLAIN ANALYZE SELECT r.year,
       con.name                        AS constructor,
       COUNT(*)                        AS stops,
       ROUND(AVG(ps.durationMs) / 1000, 3) AS avgStopSec
FROM PitStop ps
JOIN RaceResult  rr  ON rr.raceId = ps.raceId AND rr.driverId = ps.driverId
JOIN Race        r   ON r.raceId  = ps.raceId
JOIN Constructor con ON con.constructorId = rr.constructorId
WHERE ps.durationMs < 60000
GROUP BY r.year, con.constructorId, con.name
HAVING COUNT(*) >= 20
   AND AVG(ps.durationMs) < (SELECT AVG(ps2.durationMs)
                             FROM PitStop ps2
                             JOIN Race r2 ON r2.raceId = ps2.raceId
                             WHERE r2.year = r.year
                               AND ps2.durationMs < 60000)
ORDER BY r.year DESC, avgStopSec
LIMIT 15;
DROP INDEX idx_s3_q3_a ON PitStop;

-- ------------ QUERY 3: INDEX B (Filter first, race join second) ------------
CREATE INDEX idx_s3_q3_b ON PitStop(durationMs, raceId);
SELECT 'Q3 DESIGN B: idx_s3_q3_b ON PitStop(durationMs, raceId)' AS experiment;
EXPLAIN ANALYZE SELECT r.year,
       con.name                        AS constructor,
       COUNT(*)                        AS stops,
       ROUND(AVG(ps.durationMs) / 1000, 3) AS avgStopSec
FROM PitStop ps
JOIN RaceResult  rr  ON rr.raceId = ps.raceId AND rr.driverId = ps.driverId
JOIN Race        r   ON r.raceId  = ps.raceId
JOIN Constructor con ON con.constructorId = rr.constructorId
WHERE ps.durationMs < 60000
GROUP BY r.year, con.constructorId, con.name
HAVING COUNT(*) >= 20
   AND AVG(ps.durationMs) < (SELECT AVG(ps2.durationMs)
                             FROM PitStop ps2
                             JOIN Race r2 ON r2.raceId = ps2.raceId
                             WHERE r2.year = r.year
                               AND ps2.durationMs < 60000)
ORDER BY r.year DESC, avgStopSec
LIMIT 15;
DROP INDEX idx_s3_q3_b ON PitStop;

-- ------------ QUERY 3: INDEX C (Race join first, duration filter second) ------------
CREATE INDEX idx_s3_q3_c ON PitStop(raceId, durationMs);
SELECT 'Q3 DESIGN C: idx_s3_q3_c ON PitStop(raceId, durationMs)' AS experiment;
EXPLAIN ANALYZE SELECT r.year,
       con.name                        AS constructor,
       COUNT(*)                        AS stops,
       ROUND(AVG(ps.durationMs) / 1000, 3) AS avgStopSec
FROM PitStop ps
JOIN RaceResult  rr  ON rr.raceId = ps.raceId AND rr.driverId = ps.driverId
JOIN Race        r   ON r.raceId  = ps.raceId
JOIN Constructor con ON con.constructorId = rr.constructorId
WHERE ps.durationMs < 60000
GROUP BY r.year, con.constructorId, con.name
HAVING COUNT(*) >= 20
   AND AVG(ps.durationMs) < (SELECT AVG(ps2.durationMs)
                             FROM PitStop ps2
                             JOIN Race r2 ON r2.raceId = ps2.raceId
                             WHERE r2.year = r.year
                               AND ps2.durationMs < 60000)
ORDER BY r.year DESC, avgStopSec
LIMIT 15;
DROP INDEX idx_s3_q3_c ON PitStop;

-- ============ QUERY 4: REWRITTEN Q4 BASELINE ============
-- One per-race minimum is materialized, then matched back to Lap. Ties are retained.
SELECT 'Q4 REWRITE BASELINE' AS experiment;
EXPLAIN ANALYZE
SELECT d.forename,
       d.surname,
       COUNT(*) AS fastestLaps,
       MIN(r.year) AS firstYear,
       MAX(r.year) AS lastYear
FROM Lap l
JOIN (
    SELECT raceId, MIN(lapTimeMs) AS bestLapTimeMs
    FROM Lap
    GROUP BY raceId
) best ON best.raceId = l.raceId
      AND best.bestLapTimeMs = l.lapTimeMs
JOIN Race r ON r.raceId = l.raceId
JOIN Driver d ON d.driverId = l.driverId
GROUP BY d.driverId, d.forename, d.surname
ORDER BY fastestLaps DESC, d.surname
LIMIT 15;

-- ------------ QUERY 4: REWRITE DESIGN A ------------
CREATE INDEX idx_q4_rewrite_a ON Lap(raceId, lapTimeMs);
SELECT 'Q4 REWRITE DESIGN A: Lap(raceId, lapTimeMs)' AS experiment;
EXPLAIN ANALYZE
SELECT d.forename,
       d.surname,
       COUNT(*) AS fastestLaps,
       MIN(r.year) AS firstYear,
       MAX(r.year) AS lastYear
FROM Lap l
JOIN (
    SELECT raceId, MIN(lapTimeMs) AS bestLapTimeMs
    FROM Lap
    GROUP BY raceId
) best ON best.raceId = l.raceId
      AND best.bestLapTimeMs = l.lapTimeMs
JOIN Race r ON r.raceId = l.raceId
JOIN Driver d ON d.driverId = l.driverId
GROUP BY d.driverId, d.forename, d.surname
ORDER BY fastestLaps DESC, d.surname
LIMIT 15;

DROP INDEX idx_q4_rewrite_a ON Lap;

-- ------------ QUERY 4: REWRITE DESIGN B ------------
CREATE INDEX idx_q4_rewrite_b ON Lap(lapTimeMs, raceId);
SELECT 'Q4 REWRITE DESIGN B: Lap(lapTimeMs, raceId)' AS experiment;
EXPLAIN ANALYZE
SELECT d.forename,
       d.surname,
       COUNT(*) AS fastestLaps,
       MIN(r.year) AS firstYear,
       MAX(r.year) AS lastYear
FROM Lap l
JOIN (
    SELECT raceId, MIN(lapTimeMs) AS bestLapTimeMs
    FROM Lap
    GROUP BY raceId
) best ON best.raceId = l.raceId
      AND best.bestLapTimeMs = l.lapTimeMs
JOIN Race r ON r.raceId = l.raceId
JOIN Driver d ON d.driverId = l.driverId
GROUP BY d.driverId, d.forename, d.surname
ORDER BY fastestLaps DESC, d.surname
LIMIT 15;

DROP INDEX idx_q4_rewrite_b ON Lap;

-- ------------ QUERY 4: REWRITE DESIGN C ------------
CREATE INDEX idx_q4_rewrite_c ON Lap(raceId, driverId, lapTimeMs);
SELECT 'Q4 REWRITE DESIGN C: Lap(raceId, driverId, lapTimeMs)' AS experiment;
EXPLAIN ANALYZE
SELECT d.forename,
       d.surname,
       COUNT(*) AS fastestLaps,
       MIN(r.year) AS firstYear,
       MAX(r.year) AS lastYear
FROM Lap l
JOIN (
    SELECT raceId, MIN(lapTimeMs) AS bestLapTimeMs
    FROM Lap
    GROUP BY raceId
) best ON best.raceId = l.raceId
      AND best.bestLapTimeMs = l.lapTimeMs
JOIN Race r ON r.raceId = l.raceId
JOIN Driver d ON d.driverId = l.driverId
GROUP BY d.driverId, d.forename, d.surname
ORDER BY fastestLaps DESC, d.surname
LIMIT 15;

DROP INDEX idx_q4_rewrite_c ON Lap;

SELECT 'END: all experimental indexes removed' AS result;
