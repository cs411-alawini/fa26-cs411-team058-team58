USE lights_out_trivia;

SELECT 'Q1 Circuit Kings - TOP 15 RESULTS' AS evidence_label;
SELECT c.name    AS circuit,
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

SELECT 'Q3 Pit Stop Performance - TOP 15 RESULTS' AS evidence_label;
SELECT r.year,
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

SELECT 'Q4 Fastest Lap Specialists - TOP 15 RESULTS' AS evidence_label;
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
