

CREATE TABLE Season (
    year    INT PRIMARY KEY,
    wikiUrl VARCHAR(2048)
);

CREATE TABLE Location (
    location VARCHAR(100) PRIMARY KEY,
    country  VARCHAR(100)
);

CREATE TABLE Circuit (
    circuitId  INT PRIMARY KEY,
    circuitRef VARCHAR(100) NOT NULL UNIQUE,
    name       VARCHAR(255),
    location   VARCHAR(100),
    latitude   DECIMAL(10,7),
    longitude  DECIMAL(10,7),
    altitudeM  INT,
    wikiUrl    VARCHAR(2048),
    FOREIGN KEY (location) REFERENCES Location(location)
);

CREATE TABLE Driver (
    driverId        INT PRIMARY KEY,
    driverRef       VARCHAR(100) NOT NULL UNIQUE,
    code            VARCHAR(3),
    permanentNumber INT,
    forename        VARCHAR(100),
    surname         VARCHAR(100),
    dateOfBirth     DATE,
    nationality     VARCHAR(100),
    wikiUrl         VARCHAR(2048)
);

CREATE TABLE Constructor (
    constructorId  INT PRIMARY KEY,
    constructorRef VARCHAR(100) NOT NULL UNIQUE,
    name           VARCHAR(255),
    nationality    VARCHAR(100),
    wikiUrl        VARCHAR(2048)
);

CREATE TABLE Race (
    raceId    INT PRIMARY KEY,
    year      INT NOT NULL,
    circuitId INT NOT NULL,
    round     INT NOT NULL,
    name      VARCHAR(255),
    raceDate  DATE,
    raceTime  TIME,
    wikiUrl   VARCHAR(2048),
    UNIQUE (year, round),
    FOREIGN KEY (year)      REFERENCES Season(year),
    FOREIGN KEY (circuitId) REFERENCES Circuit(circuitId)
);

CREATE TABLE Qualifying (
    raceId   INT,
    driverId INT,
    position INT,
    q1TimeMs INT,
    q2TimeMs INT,
    q3TimeMs INT,
    PRIMARY KEY (raceId, driverId),
    FOREIGN KEY (raceId)   REFERENCES Race(raceId),
    FOREIGN KEY (driverId) REFERENCES Driver(driverId)
);

CREATE TABLE DriverStanding (
    year     INT,
    driverId INT,
    position INT,
    points   DECIMAL(10,2),
    PRIMARY KEY (year, driverId),
    FOREIGN KEY (year)     REFERENCES Season(year),
    FOREIGN KEY (driverId) REFERENCES Driver(driverId)
);

CREATE TABLE ConstructorStanding (
    year          INT,
    constructorId INT,
    position      INT,
    points        DECIMAL(10,2),
    PRIMARY KEY (year, constructorId),
    FOREIGN KEY (year)          REFERENCES Season(year),
    FOREIGN KEY (constructorId) REFERENCES Constructor(constructorId)
);

CREATE TABLE RaceResult (
    raceId         INT,
    driverId       INT,
    constructorId  INT NOT NULL,
    carNumber      INT,
    gridPosition   INT,
    finishPosition INT,
    positionOrder  INT,
    points         DECIMAL(10,2),
    lapsCompleted  INT,
    raceTimeMs     INT,
    status         VARCHAR(100),
    PRIMARY KEY (raceId, driverId),
    FOREIGN KEY (raceId)        REFERENCES Race(raceId),
    FOREIGN KEY (driverId)      REFERENCES Driver(driverId),
    FOREIGN KEY (constructorId) REFERENCES Constructor(constructorId)
);

CREATE TABLE Lap (
    raceId       INT,
    driverId     INT,
    lapNumber    INT,
    position     INT,
    lapTimeMs    INT,
    sector1Ms    INT,
    sector2Ms    INT,
    sector3Ms    INT,
    tyreCompound VARCHAR(30),
    tyreLifeLaps INT,
    trackStatus  VARCHAR(20),
    speedTrapKph DECIMAL(7,3),
    PRIMARY KEY (raceId, driverId, lapNumber),
    FOREIGN KEY (raceId, driverId) REFERENCES RaceResult(raceId, driverId)
);

CREATE TABLE PitStop (
    raceId     INT,
    driverId   INT,
    lapNumber  INT,
    durationMs INT,
    timeOfDay  TIME,
    PRIMARY KEY (raceId, driverId, lapNumber),
    FOREIGN KEY (raceId, driverId, lapNumber) REFERENCES Lap(raceId, driverId, lapNumber)
);

CREATE TABLE TelemetrySample (
    raceId      INT,
    driverId    INT,
    lapNumber   INT,
    offsetMs    INT,
    speedKph    DECIMAL(7,3),
    rpm         INT,
    gear        INT,
    throttlePct DECIMAL(5,2),
    brakeOn     BOOLEAN,
    drsState    INT,
    posX        DECIMAL(12,3),
    posY        DECIMAL(12,3),
    PRIMARY KEY (raceId, driverId, lapNumber, offsetMs),
    FOREIGN KEY (raceId, driverId, lapNumber) REFERENCES Lap(raceId, driverId, lapNumber)
);


CREATE TABLE User (
    userId       INT PRIMARY KEY,
    username     VARCHAR(50)  NOT NULL UNIQUE,
    email        VARCHAR(254) NOT NULL UNIQUE,
    passwordHash VARCHAR(255) NOT NULL,
    country      VARCHAR(100),
    isAdmin      BOOLEAN NOT NULL DEFAULT FALSE,
    createdAt    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Question (
    questionId  INT PRIMARY KEY,
    authorId    INT,
    raceId      INT,
    driverId    INT,
    lapNumber   INT,
    text        TEXT NOT NULL,
    format      VARCHAR(30),
    category    VARCHAR(100),
    difficulty  VARCHAR(20),
    explanation TEXT,
    visibility  VARCHAR(20),
    sourceKey   VARCHAR(255) UNIQUE,
    createdAt   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (authorId) REFERENCES User(userId),
    FOREIGN KEY (raceId, driverId, lapNumber) REFERENCES Lap(raceId, driverId, lapNumber)
);

CREATE TABLE Quiz (
    quizId        INT PRIMARY KEY,
    ownerId       INT,
    driverId      INT,
    constructorId INT,
    title         VARCHAR(255) NOT NULL,
    description   TEXT,
    quizType      VARCHAR(30),
    visibility    VARCHAR(20),
    category      VARCHAR(100),
    eraStartYear  INT,
    eraEndYear    INT,
    createdAt     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ownerId)       REFERENCES User(userId),
    FOREIGN KEY (driverId)      REFERENCES Driver(driverId),
    FOREIGN KEY (constructorId) REFERENCES Constructor(constructorId)
);

CREATE TABLE QuizQuestion (
    quizId     INT,
    questionId INT,
    position   INT,
    PRIMARY KEY (quizId, questionId),
    FOREIGN KEY (quizId)     REFERENCES Quiz(quizId),
    FOREIGN KEY (questionId) REFERENCES Question(questionId)
);

CREATE TABLE AnswerOption (
    questionId INT,
    label      VARCHAR(10),
    text       TEXT NOT NULL,
    isCorrect  BOOLEAN NOT NULL,
    PRIMARY KEY (questionId, label),
    FOREIGN KEY (questionId) REFERENCES Question(questionId)
);

CREATE TABLE QuizAttempt (
    attemptId   INT PRIMARY KEY,
    quizId      INT NOT NULL,
    userId      INT NOT NULL,
    startedAt   TIMESTAMP NULL,
    completedAt TIMESTAMP NULL,
    FOREIGN KEY (quizId) REFERENCES Quiz(quizId),
    FOREIGN KEY (userId) REFERENCES User(userId)
);

CREATE TABLE AttemptAnswer (
    attemptId     INT,
    questionId    INT,
    selectedLabel VARCHAR(10),
    timeTakenMs   INT,
    PRIMARY KEY (attemptId, questionId),
    FOREIGN KEY (attemptId) REFERENCES QuizAttempt(attemptId),
    FOREIGN KEY (questionId) REFERENCES Question(questionId),
    FOREIGN KEY (questionId, selectedLabel) REFERENCES AnswerOption(questionId, label)
);

CREATE TABLE Favorite (
    userId     INT,
    questionId INT,
    savedAt    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (userId, questionId),
    FOREIGN KEY (userId)     REFERENCES User(userId),
    FOREIGN KEY (questionId) REFERENCES Question(questionId)
);
