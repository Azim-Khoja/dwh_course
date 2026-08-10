USE LearningSQL;


CREATE TABLE Peoples(
    ID INT PRIMARY KEY,
    FullName VARCHAR(50),
    GroupName VARCHAR(5),
    Score DECIMAL(10,2)
)

INSERT INTO Peoples VALUES
    (1, 'Abdulla', 'A', 95),
    (2, 'Nigora', 'B', 80),
    (3, 'Jasur', 'B', 90),
    (4, 'Dilshod', 'B', 80),
    (5, 'Akrom', 'A', 85),
    (6, 'Kamola', 'A', 85)

-- ==========================================================
-- BROUP BY                                                 |
SELECT GroupName, AVG(Score) AS Avg_score --                |
FROM Peoples --                                             |
GROUP BY GroupName --                                       |
--                                                          |
-- ==========================================================
--                                                          |
-- Window Function   OVER(PARTITION BY ColumnName)          |
SELECT FullName, --                                         |
    GroupName, --                                           |
    Score, --                                               |
    SUM(Score) OVER(PARTITION BY GroupName) AS Group_AVG -- |
FROM Peoples --                                             |
--                                                          |
-- ==========================================================



-- OVER(ORDER BY) AMALIYOTDA QO'LLANILISHI
DROP TABLE IF EXISTS dbo.LOAN_PORTFOLIO;
GO
CREATE TABLE dbo.LOAN_PORTFOLIO(
    Contract_id VARCHAR(10),
    Branch VARCHAR(10),
    Report_date DATE,
    Amount DECIMAL(12,2)
);
GO
INSERT INTO dbo.LOAN_PORTFOLIO
    (Contract_id, Branch, Report_date, Amount)
VALUES
    ('C001', 'Toshkent', '2026-01-31', 100000000),
    ('C001', 'Toshkent', '2026-02-28', 120000000),
    ('C001', 'Toshkent', '2026-02-28', 115000000),

    ('C002', 'Toshkent', '2026-01-31', 200000000),
    ('C002', 'Toshkent', '2026-02-28', 210000000),

    ('C003', 'Samarqand', '2026-01-31', 150000000),
    ('C003', 'Samarqand', '2026-02-28', 160000000),

    ('C004', 'Samarqand', '2026-01-31', 300000000)

-- OVER(ORDER BY ...) nima qiladi?
-- kreditlarni eng kattasidan kichigiga saralaymiz (raqamlaymiz)
SELECT
    ROW_NUMBER() OVER(
        ORDER BY Amount DESC
    ) AS rn,
    Contract_id, Branch, Amount
FROM dbo.LOAN_PORTFOLIO;


-- 
-- PARTITION BY bilan alohida reyting
SELECT 
    Contract_id,
    Branch,
    Amount,
    ROW_NUMBER() OVER(
        PARTITION BY Branch
        ORDER BY Amount DESC
    ) AS Branch_Rank
FROM dbo.LOAN_PORTFOLIO


-- Har oyl
WITH CTE AS (
    SELECT
        Contract_id,
        Report_date,
        Amount,
        ROW_NUMBER() OVER(
            PARTITION BY Contract_id
            ORDER BY Report_date DESC
        ) AS rn
    FROM dbo.LOAN_PORTFOLIO
)
SELECT * FROM CTE
WHERE rn = 1
ORDER BY Contract_id;

-- ROW_NUMBER(), RANK() va DENSE_RANK() </> bir xil natijalarni ko'rsatish uchun yangi ma'lumotlar qo'shamiz
INSERT INTO dbo.LOAN_PORTFOLIO
VALUES ('C005','Toshkent','2026-02-28',210000000);

INSERT INTO dbo.LOAN_PORTFOLIO
VALUES ('C006','Samarqand','2026-01-31',115000000);

-- Reyting: ROW_NUMBER(), RANK(), DENSE_RANK()
SELECT 
    Contract_id,
    Amount,
    ROW_NUMBER() OVER(ORDER BY Amount DESC) AS row_num,
    RANK() OVER(ORDER BY Amount DESC) AS rank_num,
    DENSE_RANK() OVER(ORDER BY Amount DESC) AS dense_rank_num
    
FROM dbo.LOAN_PORTFOLIO
ORDER BY Amount DESC;



SELECT * FROM (
    SELECT *,
        DENSE_RANK() OVER(
            PARTITION BY Report_date
            ORDER BY Amount DESC
        ) AS rn
    From dbo.LOAN_PORTFOLIO) AS T
    -- WHERE T.rn <= 5


-- LAG() Oldingi qatorni ko'rsatadi
SELECT
    Contract_id,
    Report_date,
    Amount,
    LAG(Amount) OVER(
        ORDER BY Amount
    ) AS prev_amount
FROM dbo.LOAN_PORTFOLIO;

-- LAG() bilan Har oyning o'tgan oyga nisbatan o'zgarishini farqini ko'rish
SELECT
    Contract_id,
    Report_date,
    Amount,
    LAG(Amount) OVER(
        PARTITION BY Contract_id
        ORDER BY Report_date
    ) AS prev_amount,
    Amount - LAG(Amount) OVER(
        PARTITION BY Contract_id
        ORDER BY Report_date
    ) AS Delta
FROM dbo.LOAN_PORTFOLIO
WHERE Contract_id = 'C001'
ORDER BY Report_date;


-- LEAD() Keyingi qatorni ko'rsatadi
SELECT 
    Contract_id,
    Report_date,
    Amount,
    LEAD(Amount) OVER(
        -- PARTITION BY Contract_id
        ORDER BY Report_date
    ) AS Next_amount
FROM dbo.LOAN_PORTFOLIO
-- WHERE Contract_id = 'C001'

-- Running Total (Yig'ilib boruvchi summma)
SELECT
    Report_date,
    Amount,
    SUM(Amount) OVER(
        PARTITION BY Branch
        ORDER BY Report_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS Running_Total
FROM dbo.LOAN_PORTFOLIO
WHERE Branch = 'Toshkent'
ORDER BY Report_date, Amount;

-- Moving Average (sirg'aluvchi o'rtacha)
SELECT
    Contract_id,
    Report_date,
    Amount,
    AVG(Amount) OVER(
        PARTITION BY Contract_id
        ORDER BY Report_date
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS Moving_Avg
FROM dbo.LOAN_PORTFOLIO
WHERE Contract_id = 'C001'
ORDER BY Report_date;

-- Filial bo'yicha eng katta kreditlarni topish
WITH ranked AS (
    SELECT
        Contract_id,
        Branch,
        Report_date,
        Amount,
        ROW_NUMBER() OVER(
            PARTITION BY Branch
            ORDER BY Amount DESC
        ) AS rn
    FROM dbo.LOAN_PORTFOLIO
)
SELECT *
FROM ranked
WHERE rn <= 1
ORDER BY Branch, rn;

/*
    1. ROW_NUMBER() - har bir qatorni tartib raqami bilan belgilaydi.
    2. RANK() - bir xil qiymatga ega bo'lgan qatorlar uchun bir xil reyting beradi, keyingi qatorlar esa o'tkazib yuboriladi.
    3. DENSE_RANK() - bir xil qiymatga ega bo'lgan qatorlar uchun bir xil reyting beradi, keyingi qatorlar esa o'tkazib yuborilmaydi.
    4. LAG() - joriy qatorning oldingi qatoridagi qiymatni qaytaradi.
    5. LEAD() - joriy qatorning keyingi qatoridagi qiymatni qaytaradi.
    6. SUM() OVER() - yig'ilib boruvchi summani hisoblaydi.
    7. AVG() OVER() - sirg'aluvchi o'rtacha qiymatni hisoblaydi.
*/

-- Uyga vazifa (o‘zingiz ishlang)

-- Har filial bo‘yicha eng kichik kredit
WITH ranked AS (
    SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY Branch
        ORDER BY AMOUNT ASC
    ) AS RN
FROM dbo.LOAN_PORTFOLIO
)
SELECT *
FROM ranked
WHERE RN <= 1
ORDER BY Branch, RN;

-- Har shartnoma bo‘yicha oylik foiz o‘sishi: (AMOUNT - prev_amount) / prev_amount * 100
SELECT
    Contract_id,
    Report_date,
    Amount,
    LAG(Amount) OVER(
        PARTITION BY Contract_id
        ORDER BY Report_date
    ) AS prev_amount,
    Amount - LAG(Amount) OVER(
        PARTITION BY Contract_id
        ORDER BY Report_date
    ) AS Delta,
    CASE
        WHEN LAG(Amount) OVER(
            PARTITION BY Contract_id
            ORDER BY Report_date
        ) IS NULL THEN NULL
        ELSE (Amount - LAG(Amount) OVER(
            PARTITION BY Contract_id
            ORDER BY Report_date
        )) / LAG(Amount) OVER(
            PARTITION BY Contract_id
            ORDER BY Report_date
        ) * 100
    END AS Percent_Change
FROM dbo.LOAN_PORTFOLIO
WHERE 
    Contract_id = 'C001' OR 
    Contract_id = 'C002'
ORDER BY Contract_id, Report_date

-- Har filial portfelining running total
SELECT 
    Branch,
    Report_date,
    Amount,
    SUM(Amount) OVER(
        PARTITION BY Branch
        ORDER BY Report_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS Running_Total
FROM dbo.LOAN_PORTFOLIO
ORDER BY Branch, Report_date;

-- Har shartnoma uchun oxirgi 3 oy o‘rtachasi.
SELECT
    Branch,
    Contract_id,
    Report_date,
    Amount,
    AVG(Amount) OVER(
        PARTITION BY Branch
        ORDER BY Report_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS Running_Total
FROM dbo.LOAN_PORTFOLIO
ORDER BY Branch, Contract_id, Report_date;

-- Har filial bo‘yicha Top 1 kredit
WITH ranked AS (
    SELECT Branch,
        Report_date,
        Amount,
    ROW_NUMBER() OVER(
        PARTITION BY Branch
        ORDER BY AMOUNT DESC
    ) AS RN
FROM dbo.LOAN_PORTFOLIO
)
SELECT *
FROM ranked
WHERE RN <= 1
GROUP BY BRANCH, RN, Report_date, Amount
ORDER BY Branch, RN;





