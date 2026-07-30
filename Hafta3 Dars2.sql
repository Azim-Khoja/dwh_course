-- MASHQ 1 — jadvallarni qurish

-- ====================
-- Database yaratish
IF DB_ID('dwh_training') IS NULL
BEGIN
    CREATE DATABASE dwh_training;
END
GO

USE dwh_training;
GO


-- ====================
-- Eski Table-lar mavjud bo'lsa o'chirish
IF OBJECT_ID('dbo.FACT_LOAN','U') IS NOT NULL DROP TABLE dbo.FACT_LOAN;

IF OBJECT_ID('dbo.DIM_CLIENT','U') IS NOT NULL DROP TABLE dbo.DIM_CLIENT;
IF OBJECT_ID('dbo.DIM_BRANCH','U') IS NOT NULL DROP TABLE dbo.DIM_BRANCH;
IF OBJECT_ID('dbo.DIM_PRODUCT','U') IS NOT NULL DROP TABLE dbo.DIM_PRODUCT;
IF OBJECT_ID('dbo.DIM_DATE','U') IS NOT NULL DROP TABLE dbo.DIM_DATE;
GO


-- ====================
-- DIM_CLIENT table yaratish

CREATE TABLE dbo.DIM_CLIENT
(
    CLIENT_SK BIGINT IDENTITY(1,1) PRIMARY KEY,
    CLIENT_ID VARCHAR(20) NOT NULL,
    CLIENT_NAME VARCHAR(100) NOT NULL,
    BRANCH_ID INT NOT NULL,
    RISK_CLASS VARCHAR(20) NOT NULL,
    VALID_FROM DATE NOT NULL,
    VALID_TO DATE NOT NULL DEFAULT '9999-12-31',
    IS_CURRENT BIT NOT NULL DEFAULT 1
);

-- ====================
-- DIM_BRANCH table yaratish
CREATE TABLE dbo.DIM_BRANCH
(
    BRANCH_SK BIGINT IDENTITY(1,1) PRIMARY KEY,
    BRANCH_ID INT NOT NULL,
    BRANCH_NAME VARCHAR(100) NOT NULL,
    REGION VARCHAR(50) NOT NULL,
    VALID_FROM DATE NOT NULL,
    VALID_TO DATE NOT NULL DEFAULT '9999-12-31',
    IS_CURRENT BIT NOT NULL DEFAULT 1
);


-- ====================
-- DIM_PRODUCT table yaratish
CREATE TABLE dbo.DIM_PRODUCT
(
    PRODUCT_SK BIGINT IDENTITY(1,1) PRIMARY KEY,
    PRODUCT_ID VARCHAR(20) NOT NULL,
    PRODUCT_NAME VARCHAR(100) NOT NULL
);

-- ====================
-- DIM_DATE table yaratish
CREATE TABLE dbo.DIM_DATE
(
    DATE_KEY DATE PRIMARY KEY,
    MONTH_NAME VARCHAR(15),
    QUARTER TINYINT,
    YEAR_NUMBER SMALLINT
);
GO


-- ====================
-- DIM_CLIENT ma'lumotlari
SET IDENTITY_INSERT dbo.DIM_CLIENT ON;


INSERT INTO dbo.DIM_CLIENT
(CLIENT_SK,CLIENT_ID,CLIENT_NAME,BRANCH_ID,RISK_CLASS,VALID_FROM,VALID_TO,IS_CURRENT)
VALUES
(1,'CL001','Jamshid',201,'Substandart','2026-01-01','9999-12-31',1),
(2,'CL002','Madina',202,'Standart','2026-01-10','9999-12-31',1),
(3,'CL003','Aziz',203,'Standart','2026-01-15','9999-12-31',1),
(4,'CL004','Nigora',201,'Substandart','2026-02-01','9999-12-31',1),
(5,'CL005','Sardor',204,'Standart','2026-02-15','9999-12-31',1);

SET IDENTITY_INSERT dbo.DIM_CLIENT OFF;


-- ====================
-- DIM_BRANCH ma'lumotlari
SET IDENTITY_INSERT dbo.DIM_BRANCH ON;

INSERT INTO dbo.DIM_BRANCH
(BRANCH_SK,BRANCH_ID,BRANCH_NAME,REGION,VALID_FROM,VALID_TO,IS_CURRENT)
VALUES
(1,201,'Chilonzor Branch','Toshkent','2025-01-01','9999-12-31',1),
(2,202,'Yunusobod Branch','Toshkent','2025-01-01','9999-12-31',1),
(3,203,'Urganch Branch','Xorazm','2025-01-01','9999-12-31',1),
(4,204,'Qarshi Branch','Qashqadaryo','2025-01-01','9999-12-31',1);

SET IDENTITY_INSERT dbo.DIM_BRANCH OFF;


-- ====================
-- DIM_PRODUCT ma'lumotlari
SET IDENTITY_INSERT dbo.DIM_PRODUCT ON;

INSERT INTO dbo.DIM_PRODUCT
(PRODUCT_SK,PRODUCT_ID,PRODUCT_NAME)
VALUES
(1,'PR01','Consumer Loan'),
(2,'PR02','Mortgage'),
(3,'PR03','Auto Loan'),
(4,'PR04','Business Loan');

SET IDENTITY_INSERT dbo.DIM_PRODUCT OFF;


-- ====================
-- DIM_DATE ma'lumotlari
INSERT INTO dbo.DIM_DATE
(DATE_KEY,MONTH_NAME,QUARTER,YEAR_NUMBER)
VALUES
('2026-01-31','January',1,2026),
('2026-02-28','February',1,2026),
('2026-03-31','March',1,2026),
('2026-04-30','April',2,2026);


-- ====================
-- FACT_LOAN table yaratish
CREATE TABLE dbo.FACT_LOAN
(
    LOAN_SK BIGINT IDENTITY(1,1) PRIMARY KEY,

    CLIENT_SK BIGINT NOT NULL,
    BRANCH_SK BIGINT NOT NULL,
    PRODUCT_SK BIGINT NOT NULL,
    DATE_KEY DATE NOT NULL,

    LOAN_AMOUNT DECIMAL(18,2) NOT NULL,

    CONSTRAINT FK_CLIENT
        FOREIGN KEY (CLIENT_SK)
        REFERENCES dbo.DIM_CLIENT(CLIENT_SK),

    CONSTRAINT FK_BRANCH
        FOREIGN KEY (BRANCH_SK)
        REFERENCES dbo.DIM_BRANCH(BRANCH_SK),

    CONSTRAINT FK_PRODUCT
        FOREIGN KEY (PRODUCT_SK)
        REFERENCES dbo.DIM_PRODUCT(PRODUCT_SK),

    CONSTRAINT FK_DATE
        FOREIGN KEY (DATE_KEY)
        REFERENCES dbo.DIM_DATE(DATE_KEY)
);


-- ====================
-- FACT_LOAN ma'lumotlari
INSERT INTO dbo.FACT_LOAN
(CLIENT_SK,BRANCH_SK,PRODUCT_SK,DATE_KEY,LOAN_AMOUNT)
VALUES
(1,1,1,'2026-01-31',45000000),
(2,2,2,'2026-01-31',280000000),
(3,3,4,'2026-02-28',120000000),
(4,1,3,'2026-03-31',85000000),
(5,4,2,'2026-04-30',350000000);


-- ====================
INSERT INTO dbo.FACT_LOAN (
    CLIENT_SK,
    BRANCH_SK,
    PRODUCT_SK,
    DATE_KEY,
    LOAN_AMOUNT)

VALUES (100,
    1,
    1,
    '2026-01-31',
    5000000);


SELECT * FROM DIM_CLIENT;



-- MASHQ 2 — SK join (point-in-time)
SELECT
    f.LOAN_SK,
    c.CLIENT_NAME,
    b.BRANCH_NAME,
    b.REGION,
    f.LOAN_AMOUNT
FROM dbo.FACT_LOAN AS f
JOIN dbo.DIM_CLIENT AS c
    ON f.CLIENT_SK = c.CLIENT_SK
JOIN dbo.DIM_BRANCH AS b
    ON f.BRANCH_SK = b.BRANCH_SK
ORDER BY f.LOAN_SK;

-- Ikkinchi kreditni qo'shish

INSERT INTO dbo.FACT_LOAN
    (CLIENT_SK,
    BRANCH_SK,
    PRODUCT_SK,
    DATE_KEY,
    LOAN_AMOUNT)
VALUES
(1,
2,
4,
'2026-04-30',
65000000);

-- Jamshidni ikki kreditini ko'rish
SELECT
    f.LOAN_SK,
    c.CLIENT_NAME,
    b.BRANCH_NAME,
    b.REGION,
    f.LOAN_AMOUNT
FROM dbo.FACT_LOAN AS f
JOIN dbo.DIM_CLIENT AS c
    ON f.CLIENT_SK = c.CLIENT_SK
JOIN dbo.DIM_BRANCH AS b
    ON f.BRANCH_SK = b.BRANCH_SK
WHERE c.CLIENT_NAME = 'Jamshid'
ORDER BY f.LOAN_SK;

-- MASHQ 3 — star schema agregatsiya

-- Region va oy bo'yicha jami kredit summasi
SELECT
    b.REGION,
    d.MONTH_NAME,
    SUM(f.LOAN_AMOUNT) AS TOTAL_LOAN_AMOUNT
FROM dbo.FACT_LOAN AS f
JOIN dbo.DIM_BRANCH AS b
    ON f.BRANCH_SK = b.BRANCH_SK
JOIN dbo.DIM_DATE AS d
    ON f.DATE_KEY = d.DATE_KEY
GROUP BY
    b.REGION,
    d.MONTH_NAME
ORDER BY
    b.REGION,
    d.MONTH_NAME;

-- matritsa ko'rinishida yoki guruhlangan
SELECT
    b.REGION,
    SUM(CASE WHEN d.MONTH_NAME='January' THEN f.LOAN_AMOUNT ELSE 0 END) AS January,
    SUM(CASE WHEN d.MONTH_NAME='February' THEN f.LOAN_AMOUNT ELSE 0 END) AS February,
    SUM(CASE WHEN d.MONTH_NAME='March' THEN f.LOAN_AMOUNT ELSE 0 END) AS March,
    SUM(CASE WHEN d.MONTH_NAME='April' THEN f.LOAN_AMOUNT ELSE 0 END) AS April
FROM dbo.FACT_LOAN AS f
JOIN dbo.DIM_BRANCH AS b
    ON f.BRANCH_SK = b.BRANCH_SK
JOIN dbo.DIM_DATE AS d
    ON f.DATE_KEY = d.DATE_KEY
GROUP BY
    b.REGION
ORDER BY
    b.REGION;


-- Eng katta region-oy kombinatsiyasini toping
SELECT TOP (1)
    b.REGION,
    d.MONTH_NAME,
    SUM(f.LOAN_AMOUNT) AS TOTAL_LOAN_AMOUNT
FROM dbo.FACT_LOAN AS f
JOIN dbo.DIM_BRANCH AS b
    ON f.BRANCH_SK = b.BRANCH_SK
JOIN dbo.DIM_DATE AS d
    ON f.DATE_KEY = d.DATE_KEY
GROUP BY
    b.REGION,
    d.MONTH_NAME
ORDER BY
    TOTAL_LOAN_AMOUNT DESC;

SELECT * FROM dbo.DIM_CLIENT;

-- MASHQ 4 — SCD2 yangi versiya (MERGE'siz)
-- Vazifa: Yangi o'zgarish qo'shing: Aziz (CL003) Jizzaxga (205) ko'chdi, sana 2026-05-01. UPDATE + INSERT bilan eski versiyani
-- yoping, yangisini qo'shing. Natijada Aziz 3 versiyali bo'lishini tekshiring

SET IDENTITY_INSERT dbo.DIM_BRANCH ON;
INSERT INTO dbo.DIM_BRANCH
    (BRANCH_SK,
    BRANCH_ID,
    BRANCH_NAME,
    REGION,
    VALID_FROM,
    VALID_TO,
    IS_CURRENT)
VALUES
    (5,
    205,
    'Jizzax Branch',
    'Jizzax',
    '2026-05-01',
    '9999-12-31',
    1);
SET IDENTITY_INSERT dbo.DIM_BRANCH OFF;

-- Eski yozuvni yopish
UPDATE dbo.DIM_CLIENT
SET
    VALID_TO = '2026-04-30',
    IS_CURRENT = 0
WHERE CLIENT_ID = 'CL003'
  AND IS_CURRENT = 1;

SELECT * FROM dbo.DIM_CLIENT;

-- Yangi yozuv qo'shish
INSERT INTO dbo.DIM_CLIENT
    (CLIENT_ID,
    CLIENT_NAME,
    BRANCH_ID,
    RISK_CLASS,
    VALID_FROM,
    VALID_TO,
    IS_CURRENT)
VALUES
    ('CL003',
    'Aziz',
    205,
    'Standart',
    '2026-05-01',
    '9999-12-31',
    1);

-- Tekshirish
SELECT * FROM dbo.DIM_CLIENT
WHERE CLIENT_ID = 'CL003';


-- MASHQ 5 — star join vs complex join
-- Vazifa: Bitta so'rovni ikki xil yozing: (a) SK bilan (oddiy), (b) CLIENT_ID + sana oralig'i bilan (complex). Natija bir xil ekanini tasdiqlang.
-- Qaysi biri o'qishga oson?

-- STAR JOIN — SK bilan
SELECT
    f.LOAN_SK,
    c.CLIENT_NAME,
    c.BRANCH_ID,
    f.LOAN_AMOUNT
FROM dbo.FACT_LOAN AS f
INNER JOIN dbo.DIM_CLIENT AS c
    ON f.CLIENT_SK = c.CLIENT_SK
ORDER BY f.LOAN_SK;

-- COMPLEX JOIN — CLIENT_ID + sana oralig'i
WITH FACT_WITH_BK AS
    (SELECT
        f.LOAN_SK,
        f.LOAN_AMOUNT,
        f.DATE_KEY AS LOAN_DATE,
        c.CLIENT_ID
    FROM dbo.FACT_LOAN AS f
    INNER JOIN dbo.DIM_CLIENT AS c
        ON f.CLIENT_SK = c.CLIENT_SK)

SELECT
    fb.LOAN_SK,
    c.CLIENT_NAME,
    c.BRANCH_ID,
    fb.LOAN_AMOUNT
FROM FACT_WITH_BK AS fb
INNER JOIN dbo.DIM_CLIENT AS c
    ON fb.CLIENT_ID = c.CLIENT_ID
   AND fb.LOAN_DATE BETWEEN c.VALID_FROM AND c.VALID_TO
ORDER BY fb.LOAN_SK;


-- BONUS — sanity check
-- O'tgan darsdagi sanity check'ni bu jadvalga qo'llang: har mijozda aynan bitta IS_CURRENT=1 qator bormi? 
-- MASHQ 4 dan keyin ham buzilmaganini tekshiring

SELECT
    CLIENT_ID,
    COUNT(*) AS CURRENT_ROWS
FROM dbo.DIM_CLIENT
WHERE IS_CURRENT = 1
GROUP BY CLIENT_ID
HAVING COUNT(*) <> 1;
