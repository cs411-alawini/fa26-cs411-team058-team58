



ANALYZE TABLE Lap, Race, Driver;

SELECT 'Q4 BASELINE - EXISTING INDEXES ONLY' AS experiment;

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

CREATE INDEX idx_q4_a ON Lap(raceId, lapTimeMs);

SELECT 'Q4 DESIGN A: Lap(raceId, lapTimeMs)' AS experiment;

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

DROP INDEX idx_q4_a ON Lap;

CREATE INDEX idx_q4_b ON Lap(lapTimeMs, raceId);

SELECT 'Q4 DESIGN B: Lap(lapTimeMs, raceId)' AS experiment;

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

DROP INDEX idx_q4_b ON Lap;

CREATE INDEX idx_q4_c ON Lap(raceId, driverId, lapTimeMs);

SELECT 'Q4 DESIGN C: Lap(raceId, driverId, lapTimeMs)' AS experiment;

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

DROP INDEX idx_q4_c ON Lap;

SELECT 'Q4 EXPERIMENTAL INDEXES REMOVED' AS status;

SELECT 'Q4 Fastest Lap Specialists - TOP 15 RESULTS' AS evidence_label;

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
