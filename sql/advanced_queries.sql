-- Lights Out Trivia (Team 058) - Stage 3 advanced queries
-- Each query feeds the dynamic question generator: its rows give the correct
-- answer, and the runners-up are used as the wrong (distractor) options.

-- Q1. Circuit Kings: the driver(s) with the most wins at each circuit.
--     "Who has won the most Grands Prix at Monaco?"
--     Concepts: multi-relation JOIN + GROUP BY + correlated subquery in HAVING.
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


-- Q2. Poles without wins / wins without poles, per season (2006-2024).
--     "Which driver won a race in 2012 without ever qualifying on pole that year?"
--     Concepts: SET operator (UNION) + JOINs + GROUP BY + NOT EXISTS subqueries.
SELECT r.year, d.forename, d.surname, 'Pole, no win' AS category, COUNT(*) AS cnt
FROM Qualifying q
JOIN Race   r ON r.raceId   = q.raceId
JOIN Driver d ON d.driverId = q.driverId
WHERE q.position = 1
  AND r.year BETWEEN 2006 AND 2024
  AND NOT EXISTS (SELECT 1
                  FROM RaceResult rr
                  JOIN Race r2 ON r2.raceId = rr.raceId
                  WHERE rr.driverId = q.driverId
                    AND r2.year = r.year
                    AND rr.finishPosition = 1)
GROUP BY r.year, d.driverId, d.forename, d.surname
UNION
SELECT r.year, d.forename, d.surname, 'Win, no pole' AS category, COUNT(*) AS cnt
FROM RaceResult rr
JOIN Race   r ON r.raceId   = rr.raceId
JOIN Driver d ON d.driverId = rr.driverId
WHERE rr.finishPosition = 1
  AND r.year BETWEEN 2006 AND 2024
  AND NOT EXISTS (SELECT 1
                  FROM Qualifying q
                  JOIN Race r2 ON r2.raceId = q.raceId
                  WHERE q.driverId = rr.driverId
                    AND r2.year = r.year
                    AND q.position = 1)
GROUP BY r.year, d.driverId, d.forename, d.surname
ORDER BY year DESC, category, cnt DESC
LIMIT 15;


-- Q3. Pit crews faster than their season's average (2011-2024).
--     "Which team had the quickest average pit stop in 2019?"
--     Concepts: JOINs + GROUP BY/HAVING + correlated subquery (season average).
--     Stops over 60 s are red-flag stoppages or repairs and are excluded.
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


-- Q4. Fastest-lap specialists: how often each driver set a race's fastest lap.
--     "Who has set the most fastest laps since 1996?"
--     Concepts: JOINs + GROUP BY + correlated subquery (per-race minimum lap).
SELECT d.forename,
       d.surname,
       COUNT(*)    AS fastestLaps,
       MIN(r.year) AS firstYear,
       MAX(r.year) AS lastYear
FROM Lap l
JOIN Race   r ON r.raceId   = l.raceId
JOIN Driver d ON d.driverId = l.driverId
WHERE l.lapTimeMs = (SELECT MIN(l2.lapTimeMs)
                     FROM Lap l2
                     WHERE l2.raceId = l.raceId)
GROUP BY d.driverId, d.forename, d.surname
ORDER BY fastestLaps DESC, d.surname
LIMIT 15;


-- Q5. Teammate head-to-head: share of races finished ahead of the teammate.
--     Per season, 2010-2024, at least 15 head-to-heads.
--     "Who beat their teammate most consistently in 2023?"
--     Concepts: self-JOIN of RaceResult + JOINs + GROUP BY/HAVING aggregation.
SELECT r.year,
       d.forename,
       d.surname,
       con.name AS constructor,
       COUNT(*) AS headToHeads,
       SUM(CASE WHEN me.positionOrder < mate.positionOrder THEN 1 ELSE 0 END) AS racesAhead,
       ROUND(100.0 * SUM(CASE WHEN me.positionOrder < mate.positionOrder THEN 1 ELSE 0 END)
             / COUNT(*), 1) AS pctAhead
FROM RaceResult me
JOIN RaceResult mate ON mate.raceId        = me.raceId
                    AND mate.constructorId = me.constructorId
                    AND mate.driverId     <> me.driverId
JOIN Race        r   ON r.raceId           = me.raceId
JOIN Driver      d   ON d.driverId         = me.driverId
JOIN Constructor con ON con.constructorId  = me.constructorId
WHERE r.year BETWEEN 2010 AND 2024
GROUP BY r.year, d.driverId, d.forename, d.surname, con.constructorId, con.name
HAVING COUNT(*) >= 15
ORDER BY pctAhead DESC, racesAhead DESC
LIMIT 15;
