# BIT3360: Advanced Databases — Database Security Prototype
**Institution:** Zambia University College of Technology (ZUCT)  
**Topic Chosen:** Option 2 — Database Security  

## Files Included
1. `01_setup_database_and_security.sql` — Creates the `zuct_student_records` database, sample student records, `audit_logs` table, `AFTER INSERT/UPDATE/DELETE` audit triggers, and four least-privilege MySQL/MariaDB database users (`db_admin`, `lecturer_user`, `finance_clerk`, `student_portal`).
2. `02_test_permissions_and_audit.sql` — Verification commands demonstrating allowed vs. denied SQL statements per user role and inspecting the audit log.
3. `03_security_prototype_demo.py` — Standalone Python prototype demonstrating Role-Based Access Control (RBAC), SQL Injection prevention using parameterised queries, and automated database audit logging.

## How to Run the Prototype During Presentation
### Option A: Live Python Demo (Zero setup required)
```bash
python 03_security_prototype_demo.py
```
### Option B: Live MySQL / MariaDB Demo
1. Log into MySQL as `root`: `mysql -u root -p`
2. Run setup script: `SOURCE 01_setup_database_and_security.sql;`
3. Log in as each user (e.g., `mysql -u lecturer_user -p` with password `Lect@Zuct2026!`) and execute the test queries in `02_test_permissions_and_audit.sql`.
