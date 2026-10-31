-- CS 411 Team 058: Q4 ORIGINAL query optimizer diagnostics.

-- EXPLAIN FORMAT=TREE only: the original expensive query is NOT executed.

-- Run separately from the rewritten query experiments.

-- Starting assumption: idx_s3_q4_* indexes were removed by original experiment script.

SELECT 'D1 ORIGINAL: no new Lap index' AS experiment;

EXPLAIN FORMAT=TREE
SELECT d.forename,
       d.surname,
       COUNT(*)    AS fastestLaps,
       MIN(r.year) AS firstYear,
       MAX(r.year) AS lastYear
FROM Lap l
JOIN Race r ON r.raceId = l.raceId
JOIN Driver d ON d.driverId = l.driverId
WHERE l.lapTimeMs = (
    SELECT MIN(l2.lapTimeMs)
    FROM Lap l2
    WHERE l2.raceId = l.raceId
)
GROUP BY d.driverId, d.forename, d.surname
ORDER BY fastestLaps DESC, d.surname
LIMIT 15;

CREATE INDEX idx_q4_probe ON Lap(raceId, lapTimeMs);

SELECT 'D2 ORIGINAL: composite index available, no hint' AS experiment;

EXPLAIN FORMAT=TREE
SELECT d.forename,
       d.surname,
       COUNT(*)    AS fastestLaps,
       MIN(r.year) AS firstYear,
       MAX(r.year) AS lastYear
FROM Lap l
JOIN Race r ON r.raceId = l.raceId
JOIN Driver d ON d.driverId = l.driverId
WHERE l.lapTimeMs = (
    SELECT MIN(l2.lapTimeMs)
    FROM Lap l2
    WHERE l2.raceId = l.raceId
)
GROUP BY d.driverId, d.forename, d.surname
ORDER BY fastestLaps DESC, d.surname
LIMIT 15;

SELECT 'D3 ORIGINAL: force composite index in correlated subquery' AS experiment;

EXPLAIN FORMAT=TREE
SELECT d.forename,
       d.surname,
       COUNT(*)    AS fastestLaps,
       MIN(r.year) AS firstYear,
       MAX(r.year) AS lastYear
FROM Lap l
JOIN Race r ON r.raceId = l.raceId
JOIN Driver d ON d.driverId = l.driverId
WHERE l.lapTimeMs = (
    SELECT MIN(l2.lapTimeMs)
    FROM Lap l2 FORCE INDEX (idx_q4_probe)
    WHERE l2.raceId = l.raceId
)
GROUP BY d.driverId, d.forename, d.surname
ORDER BY fastestLaps DESC, d.surname
LIMIT 15;

DROP INDEX idx_q4_probe ON Lap;

SELECT 'DIAGNOSTICS END: idx_q4_probe removed' AS status;
