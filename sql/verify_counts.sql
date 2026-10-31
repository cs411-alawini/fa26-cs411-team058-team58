-- Check MySQL version and verify the 12 imported tables.
SELECT VERSION() AS mysql_version;
SELECT @@local_infile AS local_infile_enabled;
SELECT 'Season' AS table_name, COUNT(*) AS row_count FROM `Season`;
SELECT 'Location' AS table_name, COUNT(*) AS row_count FROM `Location`;
SELECT 'Circuit' AS table_name, COUNT(*) AS row_count FROM `Circuit`;
SELECT 'Driver' AS table_name, COUNT(*) AS row_count FROM `Driver`;
SELECT 'Constructor' AS table_name, COUNT(*) AS row_count FROM `Constructor`;
SELECT 'Race' AS table_name, COUNT(*) AS row_count FROM `Race`;
SELECT 'Qualifying' AS table_name, COUNT(*) AS row_count FROM `Qualifying`;
SELECT 'DriverStanding' AS table_name, COUNT(*) AS row_count FROM `DriverStanding`;
SELECT 'ConstructorStanding' AS table_name, COUNT(*) AS row_count FROM `ConstructorStanding`;
SELECT 'RaceResult' AS table_name, COUNT(*) AS row_count FROM `RaceResult`;
SELECT 'Lap' AS table_name, COUNT(*) AS row_count FROM `Lap`;
SELECT 'PitStop' AS table_name, COUNT(*) AS row_count FROM `PitStop`;
