# CompanyHR-SQL-Server-Database-Project
This project simulates a company HR database used to manage employees, departments, salaries, and projects. It was built to practice and showcase core SQL Server concepts including joins, subqueries, CTEs, window functions, stored procedures,
views, indexes, and transactions.


departments              employees
───────────               ─────────────
dept_id (PK)    ←──       dept_id (FK)
dept_name                 emp_id (PK)
location                  name
budget                    hire_date
                          manager_id (FK → employees)
                            │
                ┌───────────┴───────────┐
           salaries              projects
           ────────              ────────
           sal_id (PK)           proj_id (PK)
           emp_id (FK)           emp_id (FK)
           amount                project_name
           effective_date        status






                    companyhr-sql/
│
├── 01_create_tables.sql        # Schema definition
├── 02_insert_data.sql          # Sample data
├── 03_select_queries.sql       # Basic SELECT, WHERE, ORDER BY
├── 04_joins.sql                # All JOIN types with examples
├── 05_subqueries.sql           # Subqueries in WHERE, FROM, SELECT
├── 06_ctes.sql                 # CTEs including recursive org chart
├── 07_window_functions.sql     # Rankings, LAG/LEAD, running totals
├── 08_stored_procedures.sql    # Business logic procedures
├── 09_views_indexes.sql        # Views and index creation
├── 10_transactions.sql         # Transaction management
└── README.md
