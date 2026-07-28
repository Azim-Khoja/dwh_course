-- Jadval yaratish
CREATE TABLE dwh_dims.dbo.DIM_EMPLOYEE_HISTORY (
    EMP_SK INT IDENTITY(1,1) PRIMARY KEY,
    EMP_ID INT NOT NULL,
    EMP_NAME NVARCHAR(100) NOT NULL,
    DEPARTMENT NVARCHAR(100) NOT NULL,
    TITLE NVARCHAR(100) NOT NULL,
    VALID_FROM DATE NOT NULL,
    VALID_TO DATE NULL,
    IS_CURRENT BIT NOT NULL
);
GO
USE dwh_dims;

INSERT INTO DIM_EMPLOYEE_HISTORY
(EMP_ID, EMP_NAME, DEPARTMENT, TITLE, VALID_FROM, VALID_TO, IS_CURRENT)
VALUES
-- Employee 101
(101, 'Ali', 'Sales', 'Sales Specialist', '2023-01-01', '2024-03-31', 0),
(101, 'Ali', 'Marketing', 'Marketing Specialist', '2024-04-01', '9999-12-31', 1),

-- Employee 102
(102, 'Vali', 'IT', 'Junior Developer', '2022-06-01', '2023-12-31', 0),
(102, 'Vali', 'IT', 'Middle Developer', '2024-01-01', '2025-05-31', 0),
(102, 'Vali', 'IT', 'Senior Developer', '2025-06-01', '9999-12-31', 1),

-- Employee 103
(103, 'Dilnoza', 'HR', 'HR Specialist', '2023-02-15', '2024-08-31', 0),
(103, 'Dilnoza', 'HR', 'HR Manager', '2024-09-01', '9999-12-31', 1),

-- Employee 104
(104, 'Bekzod', 'Finance', 'Accountant', '2021-09-01', '2023-12-31', 0),
(104, 'Bekzod', 'Finance', 'Senior Accountant', '2024-01-01', '2025-03-31', 0),
(104, 'Bekzod', 'Audit', 'Audit Manager', '2025-04-01', '9999-12-31', 1),

-- Employee 105
(105, 'Malika', 'Operations', 'Coordinator', '2022-05-10', '2023-10-31', 0),
(105, 'Malika', 'Operations', 'Supervisor', '2023-11-01', '2025-01-31', 0),
(105, 'Malika', 'Logistics', 'Supervisor', '2025-02-01', '2026-01-31', 0),
(105, 'Malika', 'Logistics', 'Operations Manager', '2026-02-01', '9999-12-31', 1),

-- Employee 106
(106, 'Jasur', 'Support', 'Support Engineer', '2024-01-15', '9999-12-31', 1);


-- MASHQ 1 — oxirgi holat (ROW_NUMBER)
-- Vazifa: Har xodimning hozirgi bo'lim va lavozimini ROW_NUMBER bilan toping (IS_CURRENT ustunini ishlatMASDAN).

WITH EmployeeHistory AS (
    SELECT EMP_SK, EMP_ID, EMP_NAME, TITLE, VALID_FROM, VALID_TO,
        ROW_NUMBER() OVER (
            PARTITION BY EMP_ID
            ORDER BY VALID_FROM DESC
        ) AS RN
    FROM DIM_EMPLOYEE_HISTORY
)

SELECT EMP_ID, EMP_NAME, TITLE, VALID_FROM, VALID_TO
FROM EmployeeHistory
WHERE RN = 1
ORDER BY EMP_ID;


-- MASHQ 2 — sanity check
-- Vazifa: Mashq 1 natijasini WHERE IS_CURRENT = 1 bilan solishtiring.
-- EXCEPT orqali farq bor-yo'qligini tekshiring. Bo'sh chiqishi kerak.

SELECT * FROM dwh_dims.dbo.DIM_EMPLOYEE_HISTORY;

WITH CurrentEmployees AS (
    SELECT
        EMP_ID, EMP_NAME, DEPARTMENT, TITLE
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY EMP_ID
                   ORDER BY VALID_FROM DESC
               ) AS RN
        FROM DIM_EMPLOYEE_HISTORY
    ) T
    WHERE RN = 1
)

SELECT
    EMP_ID, EMP_NAME, DEPARTMENT, TITLE
FROM CurrentEmployees

EXCEPT

SELECT
    EMP_ID, EMP_NAME, DEPARTMENT, TITLE
FROM DIM_EMPLOYEE_HISTORY
WHERE IS_CURRENT = 1;

-- MASHQ 3 — birinchi holat
-- Vazifa: Har xodim dastlab qaysi bo'limda ishlagan? (birinchi versiya). ORDER BY VALID_FROM ASC.

WITH EmployeeHistory AS (
    SELECT
        EMP_ID, EMP_NAME, DEPARTMENT, TITLE, VALID_FROM, VALID_TO,
    ROW_NUMBER() OVER (
        PARTITION BY EMP_ID
        ORDER BY VALID_FROM ASC    
    ) AS RN
    FROM DIM_EMPLOYEE_HISTORY
)

SELECT EMP_ID, EMP_NAME, DEPARTMENT, TITLE, VALID_FROM, VALID_TO
FROM EmployeeHistory
WHERE RN = 1
ORDER BY EMP_ID


-- MASHQ 4 — point-in-time
-- Vazifa: Ma'lum bir sanada (masalan 1 yil oldin) har xodim qanday lavozimda edi?  BETWEEN VALID_FROM AND VALID_TO naqshi.

SELECT
    EMP_ID, EMP_NAME, DEPARTMENT, TITLE, VALID_FROM, VALID_TO
FROM DIM_EMPLOYEE_HISTORY
WHERE '2025-07-28' BETWEEN VALID_FROM
    AND ISNULL(VALID_TO, '9999-12-31')
ORDER BY EMP_ID;


-- MASHQ 5 — o'zgarishlar soni
-- Vazifa: Har xodim necha marta lavozim yoki bo'lim o'zgartirgan? Eng ko'p o'zgargan xodimni toping.

SELECT
    EMP_ID, EMP_NAME,
    COUNT(*) - 1 AS CHANGE_COUNT
FROM DIM_EMPLOYEE_HISTORY
GROUP BY EMP_ID, EMP_NAME
ORDER BY CHANGE_COUNT DESC;