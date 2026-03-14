
--         Database: Company HR System
--         Run this in SQL Server Management Studio (SSMS)


---SETUP: Create & select the database

-- Create a fresh database (skip if already exists)
---SYS.DATABASE=This is a system table that SQL Server maintains automatically.
--It stores information about every database on your server. Think of sys.databases like a 
--registry — before creating anything, you check the registry first to avoid collisions.
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'CompanyHR')
    CREATE DATABASE CompanyHR;
GO

-- Always run this first so every query below runs inside CompanyHR
USE CompanyHR;
GO


-- SECTION 1 — CREATE TABLES
-- Concepts: PRIMARY KEY, FOREIGN KEY, NOT NULL, DEFAULT,
--           UNIQUE, CHECK, IDENTITY, self-referencing FK

-- Drop tables in reverse order (child before parent)
-- so we can re-run this script cleanly
IF OBJECT_ID('projects',    'U') IS NOT NULL DROP TABLE projects;
IF OBJECT_ID('salaries',    'U') IS NOT NULL DROP TABLE salaries;
IF OBJECT_ID('employees',   'U') IS NOT NULL DROP TABLE employees;
IF OBJECT_ID('departments', 'U') IS NOT NULL DROP TABLE departments;
GO

-- ── DEPARTMENTS ──────────────────────────────────────────────
-- No foreign keys here, so we create this table FIRST
CREATE TABLE departments (
    dept_id    INT           PRIMARY KEY IDENTITY(1,1), -- auto-increment PK
    dept_name  VARCHAR(100)  NOT NULL UNIQUE,            -- must exist, no duplicates
    location   VARCHAR(100),                             -- optional
    budget     DECIMAL(15,2) DEFAULT 0                   -- defaults to 0 if not provided
);

-- ── EMPLOYEES ────────────────────────────────────────────────
-- References departments (so departments must exist first)
-- Also has a SELF-REFERENCING FK: manager_id points back to emp_id
CREATE TABLE employees (
    emp_id      INT           PRIMARY KEY IDENTITY(1,1),
    name        VARCHAR(100)  NOT NULL,
    dept_id     INT           REFERENCES departments(dept_id),  -- FK to departments
    hire_date   DATE          DEFAULT GETDATE(),                -- defaults to today
    manager_id  INT           REFERENCES employees(emp_id)      -- FK to ITSELF (self-join)
);

-- ── SALARIES ─────────────────────────────────────────────────
CREATE TABLE salaries (
    sal_id          INT           PRIMARY KEY IDENTITY(1,1),
    emp_id          INT           NOT NULL REFERENCES employees(emp_id),
    amount          DECIMAL(10,2) NOT NULL,
    effective_date  DATE          DEFAULT GETDATE()
);

-- ── PROJECTS ─────────────────────────────────────────────────
-- CHECK constraint limits what values 'status' can hold
CREATE TABLE projects (
    proj_id       INT           PRIMARY KEY IDENTITY(1,1),
    emp_id        INT           REFERENCES employees(emp_id),
    project_name  VARCHAR(200)  NOT NULL,
    status        VARCHAR(50)   CHECK (status IN ('active', 'completed', 'paused'))
);
GO


-- SECTION 2 — INSERT SAMPLE DATA

-- Departments first (no dependencies)
INSERT INTO departments (dept_name, location, budget) VALUES
    ('Engineering', 'New York', 500000),
    ('Marketing',   'London',   300000),
    ('HR',          'New York', 150000),
    ('Sales',       'Chicago',  400000);

-- Employees (dept_id must match an existing department)
-- manager_id = NULL means this person IS a top-level manager
INSERT INTO employees (name, dept_id, hire_date, manager_id) VALUES
    ('Alice Johnson', 1, '2019-03-15', NULL),  -- emp_id=1, Engineering manager
    ('Bob Smith',     1, '2020-07-01', 1),     -- emp_id=2, reports to Alice
    ('Carol White',   2, '2018-11-20', NULL),  -- emp_id=3, Marketing manager
    ('David Brown',   2, '2021-02-14', 3),     -- emp_id=4, reports to Carol
    ('Eve Davis',     3, '2022-06-30', NULL),  -- emp_id=5, HR manager
    ('Frank Wilson',  4, '2017-09-10', NULL),  -- emp_id=6, Sales manager
    ('Grace Lee',     4, '2023-01-05', 6),     -- emp_id=7, reports to Frank
    ('Hank Moore',    NULL, '2020-04-20', NULL); -- emp_id=8, NO department assigned

-- Salaries (one per employee for simplicity)
INSERT INTO salaries (emp_id, amount, effective_date) VALUES
    (1, 95000, '2023-01-01'),
    (2, 75000, '2023-01-01'),
    (3, 85000, '2023-01-01'),
    (4, 70000, '2023-01-01'),
    (5, 60000, '2023-01-01'),
    (6, 90000, '2023-01-01'),
    (7, 65000, '2023-01-01'),
    (8, 72000, '2023-01-01');

-- Projects (employees can appear on multiple projects)
INSERT INTO projects (emp_id, project_name, status) VALUES
    (1, 'API Redesign',    'active'),
    (2, 'API Redesign',    'active'),    -- Bob & Alice share this project
    (3, 'Brand Campaign',  'completed'),
    (1, 'Cloud Migration', 'paused'),   -- Alice is on 2 projects
    (6, 'Sales Dashboard', 'active');
GO


-- SECTION 3 — BASIC SELECT
-- Concepts: *, column alias, computed columns, DISTINCT, TOP

-- All columns from a table
SELECT * FROM employees;

-- Specific columns with aliases (AS renames the column in output)
SELECT
    name       AS employee_name,
    hire_date  AS start_date
FROM employees;

-- Computed column: calculate years employed on the fly
SELECT
    name,
    hire_date,
    DATEDIFF(YEAR, hire_date, GETDATE()) AS years_at_company
FROM employees;

-- DISTINCT: remove duplicate values
SELECT DISTINCT dept_id FROM employees;  -- how many unique departments are staffed?

-- TOP: limit the number of rows returned
SELECT TOP 3 * FROM salaries ORDER BY amount DESC;  -- 3 highest paid


-- SECTION 4 — WHERE CLAUSE (filtering rows)
-- Concepts: =, >, BETWEEN, LIKE, IN, IS NULL, AND, OR

-- Exact match
SELECT * FROM employees WHERE dept_id = 1;

-- Greater than
SELECT * FROM salaries WHERE amount > 80000;

-- Range (inclusive on both ends)
SELECT * FROM salaries WHERE amount BETWEEN 70000 AND 90000;

-- LIKE: pattern matching
-- % the wildcard = any number of characters, _ = exactly one character
SELECT * FROM employees WHERE name LIKE 'A%';      -- starts with A
SELECT * FROM employees WHERE name LIKE '%son';    -- ends with son
SELECT * FROM employees WHERE name LIKE '%e%';     -- contains 'e' anywhere

-- IN: match against a list of values
SELECT * FROM employees WHERE dept_id IN (1, 2);

-- IS NULL / IS NOT NULL
-- NEVER use = NULL — it always returns nothing!
SELECT * FROM employees WHERE manager_id IS NULL;      -- top-level managers
SELECT * FROM employees WHERE dept_id   IS NOT NULL;   -- employees with a dept

-- Combine conditions
SELECT * FROM employees
WHERE dept_id = 1
  AND hire_date > '2019-12-31';   -- Engineering hired after 2019


-- SECTION 5 — AGGREGATE FUNCTIONS + GROUP BY + HAVING
-- Concepts: COUNT, SUM, AVG, MAX, MIN, GROUP BY, HAVING

-- Basic aggregates across ALL rows
SELECT
    COUNT(*)        AS total_rows,
    COUNT(emp_id)   AS rows_with_employee,  --  emp_id exists in salaries
    SUM(amount)     AS total_payroll,
    AVG(amount)     AS average_salary,
    MAX(amount)     AS highest_salary,
    MIN(amount)     AS lowest_salary
FROM salaries;

SELECT
    e.dept_id,
    COUNT(e.emp_id)  AS headcount,
    AVG(s.amount)    AS avg_salary    --  now amount is available
FROM employees e
JOIN salaries s ON e.emp_id = s.emp_id  -- brings amount into the query
GROUP BY e.dept_id
ORDER BY headcount DESC;



SELECT
    d.dept_name,                     -- readable name instead of just an ID
    COUNT(e.emp_id)  AS headcount,
    AVG(s.amount)    AS avg_salary
FROM employees   e
JOIN departments d ON e.dept_id = d.dept_id
JOIN salaries    s ON e.emp_id  = s.emp_id
GROUP BY d.dept_name
ORDER BY avg_salary DESC;
```

---

### The Simple Rule to Remember

--Before writing any column in SELECT, always ask yourself:
```
--Which table does this column live in?
--Is that table in my FROM or JOIN?
-- HAVING: filter groups (like WHERE but for aggregated results)
-- KEY DIFFERENCE:
--   WHERE  = filters ROWS   before grouping  → cannot use aggregate functions
--   HAVING = filters GROUPS after  grouping  → can use aggregate functions
SELECT
    dept_id,
    COUNT(emp_id) AS headcount
FROM employees
GROUP BY dept_id
HAVING COUNT(emp_id) > 1;   -- only departments with more than 1 employee


-- SECTION 6 — JOINS
-- Concepts: INNER, LEFT, RIGHT, FULL OUTER, SELF, CROSS

-- ── INNER JOIN ───────────────────────────────────────────────
-- Returns ONLY rows that have a match in BOTH tables
-- Hank (no dept_id) will NOT appear
SELECT
    e.name,
    d.dept_name,
    d.location
FROM employees  e                             -- left table
INNER JOIN departments d ON e.dept_id = d.dept_id;  -- right table

-- ── LEFT JOIN ────────────────────────────────────────────────
-- Returns ALL rows from the LEFT table
-- Right side shows NULL when there is no match
-- Hank WILL appear with NULL dept_name
SELECT
    e.name,
    d.dept_name    -- NULL for Hank
FROM employees  e
LEFT JOIN departments d ON e.dept_id = d.dept_id;

-- TRICK: Find employees WITHOUT a department
-- Get all left rows, keep only those where right side is NULL
SELECT e.name
FROM employees  e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;   -- only unmatched rows come through

-- ── RIGHT JOIN ───────────────────────────────────────────────
-- Returns ALL rows from the RIGHT table
-- Use case: find departments that have NO employees
SELECT
    e.name,        -- NULL if department has no employees
    d.dept_name
FROM employees  e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

-- ── FULL OUTER JOIN ──────────────────────────────────────────
-- Returns ALL rows from BOTH tables
-- NULLs appear on whichever side has no match
SELECT
    e.name,
    d.dept_name
FROM employees  e
FULL OUTER JOIN departments d ON e.dept_id = d.dept_id;

-- ── SELF JOIN ────────────────────────────────────────────────
-- Join a table to ITSELF — classic use case: employee + their manager
-- We alias the same table twice with different names
SELECT
    e.name  AS employee,
    m.name  AS manager        -- NULL for top-level managers
FROM employees e              -- 'e' = the employee
LEFT JOIN employees m         -- 'm' = the same table acting as manager
    ON e.manager_id = m.emp_id;

-- ── 3-TABLE JOIN ─────────────────────────────────────────────
-- Chain as many JOINs as you need
SELECT
    e.name,
    d.dept_name,
    s.amount AS salary
FROM employees   e
JOIN departments d ON e.dept_id = d.dept_id
JOIN salaries    s ON e.emp_id  = s.emp_id
ORDER BY s.amount DESC;

-- ── CROSS JOIN ───────────────────────────────────────────────
-- Every row from table A × every row from table B
-- 8 employees × 4 departments = 32 rows
-- Use carefully — no ON clause needed
SELECT e.name, d.dept_name
FROM employees e
CROSS JOIN departments d;


-- SECTION 7 — SUBQUERIES
-- Concepts: subquery in WHERE, FROM (derived table),
--           correlated subquery, EXISTS vs IN A .Subquery is simply a SELECT statement
--written inside another SELECT statement. It runs first, produces a result, and the outer query uses that result

-- ── SUBQUERY IN WHERE ────────────────────────────────────────
-- Find employees whose salary is above average
SELECT name
FROM employees
WHERE emp_id IN (
    SELECT emp_id
    FROM salaries
    WHERE amount > (SELECT AVG(amount) FROM salaries)  -- nested subquery!
);

-- ── SUBQUERY IN FROM (Derived Table) ─────────────────────────
-- The inner query runs first and becomes a "virtual table"
-- You MUST give it an alias
SELECT dept_name, avg_sal
FROM (
    SELECT d.dept_name, AVG(s.amount) AS avg_sal
    FROM employees   e
    JOIN departments d ON e.dept_id = d.dept_id
    JOIN salaries    s ON e.emp_id  = s.emp_id
    GROUP BY d.dept_name
) AS dept_averages           -- alias is required
WHERE avg_sal > 75000;

-- ── CORRELATED SUBQUERY ──────────────────────────────────────
-- The subquery REFERENCES the outer query (runs once per outer row)
-- Find employees earning more than their OWN department's average
SELECT e.name, s.amount
FROM employees e
JOIN salaries  s ON e.emp_id = s.emp_id
WHERE s.amount > (
    SELECT AVG(s2.amount)
    FROM salaries  s2
    JOIN employees e2 ON s2.emp_id = e2.emp_id
    WHERE e2.dept_id = e.dept_id   -- ← ties inner query to outer row's dept
);

-- ── EXISTS vs IN ─────────────────────────────────────────────
-- Both find the same rows, but EXISTS is faster on large tables
-- because it stops as soon as it finds ONE match

-- IN version
SELECT name FROM employees
WHERE emp_id IN (SELECT emp_id FROM projects);

-- EXISTS version (preferred for performance)
SELECT name FROM employees e
WHERE EXISTS (
    SELECT 1                       -- '1' is conventional — value doesn't matter
    FROM projects p
    WHERE p.emp_id = e.emp_id      -- correlated condition
);

-- NOT EXISTS: find employees with NO projects
SELECT name FROM employees e
WHERE NOT EXISTS (
    SELECT 1 FROM projects p
    WHERE p.emp_id = e.emp_id
);


-- SECTION 8 — CTEs (Common Table Expressions)
-- Concepts: basic CTE, multiple CTEs, recursive CTE
-- 

-- ── BASIC CTE ────────────────────────────────────────────────
-- WITH defines a named temporary result — cleaner than subqueries
-- It only exists for the ONE query that follows it
--A CTE is a subquery with a name — you define it once at the top with WITH, give it a name, and then use that name like a table

WITH dept_avg AS (
    SELECT
        d.dept_name,
        AVG(s.amount) AS avg_salary
    FROM employees   e
    JOIN departments d ON e.dept_id = d.dept_id
    JOIN salaries    s ON e.emp_id  = s.emp_id
    GROUP BY d.dept_name
)
SELECT dept_name, avg_salary
FROM dept_avg;


-- ── MULTIPLE CTEs ────────────────────────────────────────────
-- Chain them with commas — each can reference the ones before it
WITH
high_earners AS (
    SELECT emp_id FROM salaries WHERE amount > 80000
),
active_workers AS (
    SELECT DISTINCT emp_id FROM projects WHERE status = 'active'
)
-- Employees who are BOTH high earners AND on active projects
SELECT e.name
FROM employees e
WHERE e.emp_id IN (SELECT emp_id FROM high_earners)
  AND e.emp_id IN (SELECT emp_id FROM active_workers);

-- ── RECURSIVE CTE ────────────────────────────────────────────
-- Used for HIERARCHICAL data (org charts, folder trees, categories)
-- Structure: Anchor query UNION ALL Recursive query
WITH org_chart AS (
    -- ANCHOR
    SELECT
        emp_id,
        name,
        manager_id,
        0                        AS level,
        CAST(name AS VARCHAR(1000)) AS path   -- ✅ tell SQL the max size upfront
    FROM employees
    WHERE emp_id = 1

    UNION ALL

    -- RECURSIVE PART
    SELECT
        e.emp_id,
        e.name,
        e.manager_id,
        oc.level + 1,
        CAST(oc.path + ' → ' + e.name AS VARCHAR(1000))  -- ✅ same size
    FROM employees  e
    INNER JOIN org_chart oc ON e.manager_id = oc.emp_id
)
SELECT
    REPLICATE('    ', level) + name  AS org_tree,
    level,
    path
FROM org_chart
ORDER BY level, name;
```

---

### Why VARCHAR(1000)?

--Because as the path gets deeper it keeps growing:
```
---Level 0 → 'Alice Johnson'                            (13 chars)
---Level 1 → 'Alice Johnson → Bob Smith'                (26 chars)
---Level 2 → 'Alice Johnson → Bob Smith → Someone'      (39 chars)



-- SECTION 9 — WINDOW FUNCTIONS
-- Concepts: ROW_NUMBER, RANK, DENSE_RANK, PARTITION BY,
--           LAG, LEAD, running totals

-- ── ROW_NUMBER, RANK, DENSE_RANK ─────────────────────────────
-- OVER() defines the "window" — which rows to look at
-- PARTITION BY = reset numbering per group (like GROUP BY but keeps all rows)
-- ORDER BY inside OVER = determines the rank order
SELECT
    e.name,
    d.dept_name,
    s.amount,
    -- ROW_NUMBER: always unique, no ties (1,2,3,4...)
    ROW_NUMBER() OVER (PARTITION BY d.dept_name ORDER BY s.amount DESC) AS row_num,

    -- RANK: ties get same number, SKIPS next numbers (1,2,2,4...)
    RANK()       OVER (PARTITION BY d.dept_name ORDER BY s.amount DESC) AS rank_num,

    -- DENSE_RANK: ties get same number, does NOT skip (1,2,2,3...)
    DENSE_RANK() OVER (PARTITION BY d.dept_name ORDER BY s.amount DESC) AS dense_rank
FROM employees   e
JOIN departments d ON e.dept_id = d.dept_id
JOIN salaries    s ON e.emp_id  = s.emp_id;

-- ── TOP N PER GROUP ──────────────────────────────────────────
-- Classic interview question: "Get the highest paid person per department"
-- Step 1: rank inside a CTE, Step 2: filter where rank = 1
WITH ranked_salaries AS (
    SELECT
        e.name,
        d.dept_name,
        s.amount,
        ROW_NUMBER() OVER (PARTITION BY d.dept_name ORDER BY s.amount DESC) AS rn
    FROM employees   e
    JOIN departments d ON e.dept_id = d.dept_id
    JOIN salaries    s ON e.emp_id  = s.emp_id
)
SELECT name, dept_name, amount
FROM ranked_salaries
WHERE rn = 1;    -- keep only the #1 in each department

-- ── LAG & LEAD ───────────────────────────────────────────────
-- LAG  = look at the PREVIOUS row's value
-- LEAD = look at the NEXT row's value
-- Useful for: comparing to previous period, calculating differences
SELECT
    e.name,
    e.hire_date,
    s.amount,
    LAG(s.amount)  OVER (ORDER BY e.hire_date) AS prev_employee_salary,
    LEAD(s.amount) OVER (ORDER BY e.hire_date) AS next_employee_salary,
    -- Calculate difference from previous employee
    s.amount - LAG(s.amount) OVER (ORDER BY e.hire_date) AS diff_from_prev
FROM employees e
JOIN salaries  s ON e.emp_id = s.emp_id;

-- ── RUNNING TOTAL ────────────────────────────────────────────
-- Cumulative SUM as rows accumulate
SELECT
    e.name,
    e.hire_date,
    s.amount,
    SUM(s.amount) OVER (ORDER BY e.hire_date) AS running_total_payroll,
    AVG(s.amount) OVER (
        ORDER BY e.hire_date
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW  -- moving average of last 2 rows
    ) AS moving_avg
FROM employees e
JOIN salaries  s ON e.emp_id = s.emp_id;


-- SECTION 10 — UPDATE & DELETE

-- UPDATE: modify existing rows
-- ALWAYS use WHERE — without it you update EVERY row!
UPDATE salaries
SET amount = amount * 1.10     -- give everyone a 10% raise
WHERE emp_id = 2;              -- only Bob

-- Update multiple columns at once
UPDATE employees
SET dept_id   = 1,
    manager_id = 1
WHERE emp_id = 8;              -- assign Hank to Engineering under Alice

-- DELETE: remove specific rows
-- ALWAYS use WHERE — without it you delete ALL rows!
-- DELETE FROM salaries;       -- ← DANGEROUS: deletes everything!
DELETE FROM projects
WHERE status = 'completed';    -- remove completed projects

-- TRUNCATE: delete ALL rows, fast, no WHERE possible
-- TRUNCATE TABLE projects;    -- commented out — just for reference



-- SECTION 11 — STORED PROCEDURES
-- Concepts: CREATE PROCEDURE, parameters, OUTPUT params,
--           EXEC, error handling

-- Drop if exists so we can recreate cleanly
IF OBJECT_ID('GetEmployeesByDept', 'P') IS NOT NULL
    DROP PROCEDURE GetEmployeesByDept;
GO

-- ── BASIC STORED PROCEDURE ───────────────────────────────────
-- Accepts a parameter, runs a query, returns a result set
CREATE PROCEDURE GetEmployeesByDept
    @dept_id INT            -- input parameter
AS
BEGIN
    SELECT
        e.name,
        d.dept_name,
        s.amount AS salary
    FROM employees   e
    JOIN departments d ON e.dept_id = d.dept_id
    JOIN salaries    s ON e.emp_id  = s.emp_id
    WHERE e.dept_id = @dept_id
    ORDER BY s.amount DESC;
END;
GO

-- Execute the stored procedure
EXEC GetEmployeesByDept @dept_id = 1;   -- get Engineering employees
EXEC GetEmployeesByDept @dept_id = 4;   -- get Sales employees
GO

-- ── STORED PROCEDURE WITH OUTPUT PARAMETER ───────────────────
IF OBJECT_ID('GetDeptStats', 'P') IS NOT NULL DROP PROCEDURE GetDeptStats;
GO

CREATE PROCEDURE GetDeptStats
    @dept_id     INT,
    @avg_salary  DECIMAL(10,2) OUTPUT,   -- OUTPUT = caller can read this back
    @headcount   INT           OUTPUT
AS
BEGIN
    SELECT
        @avg_salary = AVG(s.amount),
        @headcount  = COUNT(e.emp_id)
    FROM employees e
    JOIN salaries  s ON e.emp_id = s.emp_id
    WHERE e.dept_id = @dept_id;
END;
GO

-- Calling a procedure with OUTPUT parameters:
DECLARE @avg  DECIMAL(10,2);
DECLARE @cnt  INT;

EXEC GetDeptStats
    @dept_id    = 1,
    @avg_salary = @avg OUTPUT,   -- pass variable + OUTPUT keyword
    @headcount  = @cnt OUTPUT;

SELECT @avg AS avg_salary, @cnt AS headcount;   -- read the output values
GO

-- ── STORED PROCEDURE WITH ERROR HANDLING ─────────────────────
IF OBJECT_ID('GiveRaise', 'P') IS NOT NULL DROP PROCEDURE GiveRaise;
GO

CREATE PROCEDURE GiveRaise
    @emp_id     INT,
    @raise_pct  DECIMAL(5,2)    -- e.g. pass 10 for 10%
AS
BEGIN
    BEGIN TRY
        -- Validate: employee must exist
        IF NOT EXISTS (SELECT 1 FROM employees WHERE emp_id = @emp_id)
        BEGIN
            RAISERROR('Employee not found.', 16, 1);
            RETURN;
        END

        -- Apply the raise
        UPDATE salaries
        SET amount = amount * (1 + @raise_pct / 100)
        WHERE emp_id = @emp_id;

        PRINT 'Raise applied successfully.';
    END TRY
    BEGIN CATCH
        -- CATCH block runs if any error occurs in TRY
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

EXEC GiveRaise @emp_id = 2, @raise_pct = 15;   -- give Bob a 15% raise
EXEC GiveRaise @emp_id = 99, @raise_pct = 10;  -- emp 99 doesn't exist → error caught
GO


-- SECTION 12 — USER DEFINED FUNCTIONS (UDF)

IF OBJECT_ID('dbo.GetYearsEmployed', 'FN') IS NOT NULL
    DROP FUNCTION dbo.GetYearsEmployed;
GO

-- SCALAR function: takes input, returns a SINGLE value
CREATE FUNCTION dbo.GetYearsEmployed(@emp_id INT)
RETURNS INT
AS
BEGIN
    DECLARE @years INT;
    SELECT @years = DATEDIFF(YEAR, hire_date, GETDATE())
    FROM employees
    WHERE emp_id = @emp_id;
    RETURN @years;
END;
GO

-- Use the function in a SELECT — just like a built-in function
SELECT
    name,
    hire_date,
    dbo.GetYearsEmployed(emp_id) AS years_employed
FROM employees;
GO


-- ============================================================
-- SECTION 13 — VIEWS
-- Concepts: CREATE VIEW, use like a table, ALTER, DROP
-- ============================================================

IF OBJECT_ID('employee_summary', 'V') IS NOT NULL DROP VIEW employee_summary;
GO

-- A VIEW is a saved SELECT query — no data is stored, just the query definition
-- Use it to simplify complex joins that you query often
CREATE VIEW employee_summary AS
SELECT
    e.emp_id,
    e.name,
    d.dept_name,
    s.amount    AS salary,
    e.hire_date,
    dbo.GetYearsEmployed(e.emp_id) AS years_employed
FROM employees   e
LEFT JOIN departments d ON e.dept_id = d.dept_id
LEFT JOIN salaries    s ON e.emp_id  = s.emp_id;
GO

-- Query the view exactly like a regular table
SELECT * FROM employee_summary;
SELECT * FROM employee_summary WHERE salary > 80000;
SELECT dept_name, AVG(salary) AS avg_sal FROM employee_summary GROUP BY dept_name;
GO


-- ============================================================
-- SECTION 14 — INDEXES
-- Concepts: clustered, non-clustered, composite, unique
-- ============================================================

-- Non-clustered index: speeds up queries that filter by dept_id
CREATE NONCLUSTERED INDEX idx_emp_dept
    ON employees(dept_id);

-- Composite index: useful when you often filter by BOTH columns
CREATE INDEX idx_salary_emp_date
    ON salaries(emp_id, effective_date);

-- Unique index: like a unique constraint, prevents duplicate values
CREATE UNIQUE INDEX idx_dept_name_unique
    ON departments(dept_name);

-- Check existing indexes on a table
EXEC sp_helpindex 'employees';

-- Drop an index
DROP INDEX idx_emp_dept ON employees;


-- ============================================================
-- SECTION 15 — TRANSACTIONS
-- Concepts: BEGIN, COMMIT, ROLLBACK, ACID properties
-- ACID = Atomicity, Consistency, Isolation, Durability
-- ============================================================

-- Example: transfer budget between departments
-- Either BOTH updates happen, or NEITHER does (atomicity)
BEGIN TRANSACTION;

BEGIN TRY
    -- Deduct from HR budget
    UPDATE departments
    SET budget = budget - 50000
    WHERE dept_name = 'HR';

    -- Add to Engineering budget
    UPDATE departments
    SET budget = budget + 50000
    WHERE dept_name = 'Engineering';

    -- Validate: no department should go negative
    IF EXISTS (SELECT 1 FROM departments WHERE budget < 0)
    BEGIN
        ROLLBACK;   -- undo ALL changes in this transaction
        PRINT 'Transfer failed: insufficient budget';
        RETURN;
    END

    COMMIT;         -- make ALL changes permanent
    PRINT 'Budget transfer successful';
END TRY
BEGIN CATCH
    ROLLBACK;       -- undo everything if any error occurred
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH;


-- SECTION 16 — STRING & DATE FUNCTIONS (BONUS)

SELECT
    -- String functions
    UPPER(name)                          AS name_upper,
    LOWER(name)                          AS name_lower,
    LEN(name)                            AS name_length,
    LEFT(name, 5)                        AS first_5_chars,
    RIGHT(name, 4)                       AS last_4_chars,
    SUBSTRING(name, 1, 5)               AS substr,
    REPLACE(name, 'o', '0')             AS leet_speak,
    LTRIM(RTRIM('  hello  '))           AS trimmed,
    CONCAT(name, ' (', dept_id, ')')   AS name_with_dept,

    -- Date functions
    GETDATE()                            AS right_now,
    YEAR(hire_date)                      AS hire_year,
    MONTH(hire_date)                     AS hire_month,
    DAY(hire_date)                       AS hire_day,
    DATEDIFF(DAY,  hire_date, GETDATE()) AS days_employed,
    DATEDIFF(YEAR, hire_date, GETDATE()) AS years_employed,
    DATEADD(YEAR, 1, hire_date)         AS one_year_anniversary,
    FORMAT(hire_date, 'dd/MM/yyyy')      AS formatted_date

FROM employees;


-- SECTION 17 — CASE EXPRESSION (conditional logic in SQL)

-- CASE is SQL's IF-THEN-ELSE
SELECT
    name,
    amount,
    -- Simple classification based on salary
    CASE
        WHEN amount >= 90000 THEN 'Senior'
        WHEN amount >= 70000 THEN 'Mid-level'
        ELSE                      'Junior'
    END AS seniority_level,

    -- Bonus calculation using CASE
    amount * CASE
        WHEN amount >= 90000 THEN 0.20   -- 20% bonus for seniors
        WHEN amount >= 70000 THEN 0.10   -- 10% for mid-level
        ELSE                      0.05   -- 5% for juniors
    END AS bonus_amount

FROM employees e
JOIN salaries  s ON e.emp_id = s.emp_id;


-- SECTION 18 — INTERVIEW PRACTICE QUERIES
-- Try to write these yourself before looking at the solution!


-- Q1: List all employees and their salary, sorted highest to lowest
SELECT e.name, s.amount
FROM employees e
JOIN salaries  s ON e.emp_id = s.emp_id
ORDER BY s.amount DESC;

-- Q2: How many employees are in each department?
SELECT d.dept_name, COUNT(e.emp_id) AS headcount
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id   -- LEFT so empty depts show 0
GROUP BY d.dept_name
ORDER BY headcount DESC;

-- Q3: Which departments have an average salary above 75,000?
SELECT d.dept_name, AVG(s.amount) AS avg_salary
FROM employees   e
JOIN departments d ON e.dept_id = d.dept_id
JOIN salaries    s ON e.emp_id  = s.emp_id
GROUP BY d.dept_name
HAVING AVG(s.amount) > 75000;

-- Q4: Find the second highest salary (classic interview question)
-- Method 1: using OFFSET-FETCH
SELECT DISTINCT amount
FROM salaries
ORDER BY amount DESC
OFFSET 1 ROW FETCH NEXT 1 ROW ONLY;

-- Method 2: using subquery
SELECT MAX(amount) AS second_highest
FROM salaries
WHERE amount < (SELECT MAX(amount) FROM salaries);

-- Q5: Employees who are NOT assigned to any project
SELECT e.name
FROM employees e
WHERE NOT EXISTS (
    SELECT 1 FROM projects p WHERE p.emp_id = e.emp_id
);

-- Q6: For each employee, show their salary vs department average
SELECT
    e.name,
    d.dept_name,
    s.amount                                                AS my_salary,
    AVG(s.amount) OVER (PARTITION BY d.dept_name)          AS dept_avg,
    s.amount - AVG(s.amount) OVER (PARTITION BY d.dept_name) AS diff_from_avg
FROM employees   e
JOIN departments d ON e.dept_id = d.dept_id
JOIN salaries    s ON e.emp_id  = s.emp_id;

-- Q7: Duplicate detection — find any duplicate employee names
SELECT name, COUNT(*) AS occurrences
FROM employees
GROUP BY name
HAVING COUNT(*) > 1;

-- Q8: Employees hired in the last 3 years
SELECT name, hire_date
FROM employees
WHERE hire_date >= DATEADD(YEAR, -3, GETDATE());

--  END OF SCRIPT
