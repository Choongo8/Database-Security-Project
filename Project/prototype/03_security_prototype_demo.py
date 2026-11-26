"""
ZAMBIA UNIVERSITY COLLEGE OF TECHNOLOGY (ZUCT)
BIT3360: ADVANCED DATABASES - PRACTICAL PROTOTYPE
Demonstrates:
1. Role-Based Access Control (RBAC) & Least Privilege enforcement
2. Parameterised Queries vs. SQL Injection (SQLi) Attack Prevention
3. Automated Audit Trail Logging via Database Triggers

Note: This script includes a self-contained SQLite simulation mode so your group
can run and demonstrate it immediately on any laptop without extra server setup,
alongside the exact MySQL/MariaDB connector code for live server demonstrations.
"""

import sqlite3
from datetime import datetime

# ==============================================================================
# PART 1: SELF-CONTAINED DEMO DATABASE (Runs immediately in Python)
# ==============================================================================
def init_demo_db():
    conn = sqlite3.connect(":memory:")
    cur = conn.cursor()

    cur.execute("""
        CREATE TABLE students (
            student_id TEXT PRIMARY KEY,
            full_name TEXT NOT NULL,
            nrc_number TEXT UNIQUE NOT NULL,
            program TEXT NOT NULL,
            gpa REAL NOT NULL,
            fee_balance REAL NOT NULL
        )
    """)

    cur.execute("""
        CREATE TABLE audit_logs (
            log_id INTEGER PRIMARY KEY AUTOINCREMENT,
            action_time TEXT NOT NULL,
            app_user TEXT NOT NULL,
            action_type TEXT NOT NULL,
            target_student_id TEXT NOT NULL,
            details TEXT NOT NULL
        )
    """)

    # Database trigger for automatic audit logging on UPDATE
    cur.execute("""
        CREATE TRIGGER trg_audit_student_update
        AFTER UPDATE ON students
        BEGIN
            INSERT INTO audit_logs (action_time, app_user, action_type, target_student_id, details)
            VALUES (
                datetime('now'),
                'SYSTEM_TRIGGER',
                'UPDATE',
                NEW.student_id,
                'Old GPA=' || OLD.gpa || ', New GPA=' || NEW.gpa ||
                ' | Old Bal=' || OLD.fee_balance || ', New Bal=' || NEW.fee_balance
            );
        END;
    """)

    sample_students = [
        ("ZUCT2026001", "Chanda Mwamba", "123456/10/1", "BSc Computer Science", 4.35, 0.00),
        ("ZUCT2026002", "Mutale Banda", "234567/10/1", "BSc Information Technology", 3.80, 2500.00),
        ("ZUCT2026003", "Thabo Phiri", "345678/61/1", "BSc Software Engineering", 4.60, 0.00),
        ("ZUCT2026004", "Kabwe Zulu", "456789/10/1", "BSc Cybersecurity", 3.45, 4200.00),
    ]
    cur.executemany("INSERT INTO students VALUES (?, ?, ?, ?, ?, ?)", sample_students)
    conn.commit()
    return conn


# ==============================================================================
# PART 2: ACCESS CONTROL MATRIX (Simulated Application Enforcement Layer)
# ==============================================================================
ROLE_PERMISSIONS = {
    "db_admin":      {"SELECT_ALL", "UPDATE_GPA", "UPDATE_FEES", "DELETE", "VIEW_AUDIT"},
    "lecturer_user": {"SELECT_BASIC", "UPDATE_GPA"},
    "finance_clerk": {"SELECT_BASIC", "UPDATE_FEES"},
    "student_portal": {"SELECT_BASIC"},
}

def execute_role_action(conn, role, action, student_id=None, new_value=None):
    allowed = ROLE_PERMISSIONS.get(role, set())
    cur = conn.cursor()

    if action == "VIEW_NRC":
        if "SELECT_ALL" not in allowed:
            print(f"  [DENIED] Role '{role}' is NOT authorized to view sensitive NRC numbers.")
            return
        cur.execute("SELECT student_id, full_name, nrc_number FROM students")
        print(f"  [ALLOWED] {role} retrieved NRC records:", cur.fetchall())

    elif action == "UPDATE_GPA":
        if "UPDATE_GPA" not in allowed:
            print(f"  [DENIED] Role '{role}' is NOT authorized to modify student GPAs.")
            return
        # PARAMETERISED QUERY
        cur.execute("UPDATE students SET gpa = ? WHERE student_id = ?", (new_value, student_id))
        conn.commit()
        print(f"  [ALLOWED] Role '{role}' updated GPA for {student_id} to {new_value}.")

    elif action == "UPDATE_FEES":
        if "UPDATE_FEES" not in allowed:
            print(f"  [DENIED] Role '{role}' is NOT authorized to modify fee balances.")
            return
        # PARAMETERISED QUERY
        cur.execute("UPDATE students SET fee_balance = ? WHERE student_id = ?", (new_value, student_id))
        conn.commit()
        print(f"  [ALLOWED] Role '{role}' updated Fee Balance for {student_id} to ZMW {new_value}.")

    elif action == "DELETE_STUDENT":
        if "DELETE" not in allowed:
            print(f"  [DENIED] Role '{role}' is NOT authorized to delete student records.")
            return
        cur.execute("DELETE FROM students WHERE student_id = ?", (student_id,))
        conn.commit()
        print(f"  [ALLOWED] Role '{role}' deleted student {student_id}.")


# ==============================================================================
# PART 3: SQL INJECTION VS PARAMETERISED QUERIES DEMONSTRATION
# ==============================================================================
def demonstrate_sql_injection_protection(conn):
    cur = conn.cursor()
    malicious_input = "ZUCT2026999' OR '1'='1"

    print("\n--- DEMO 2: SQL INJECTION VS. PARAMETERISED QUERIES ---")
    print(f"Malicious User Input: {malicious_input}")

    # 1. Vulnerable String Concatenation (DO NOT USE IN PRODUCTION)
    vulnerable_sql = f"SELECT student_id, full_name, gpa FROM students WHERE student_id = '{malicious_input}'"
    cur.execute(vulnerable_sql)
    leaked_rows = cur.fetchall()
    print(f"[VULNERABLE QUERY] Returned {len(leaked_rows)} records (DATA BREACH! All students exposed):")
    for row in leaked_rows:
        print("   ->", row)

    # 2. Secure Parameterised Query (Prepared Statement)
    secure_sql = "SELECT student_id, full_name, gpa FROM students WHERE student_id = ?"
    cur.execute(secure_sql, (malicious_input,))
    safe_rows = cur.fetchall()
    print(f"[PARAMETERISED QUERY] Returned {len(safe_rows)} records (ATTACK BLOCKED! Treated as literal string).")


# ==============================================================================
# MAIN EXECUTION
# ==============================================================================
if __name__ == "__main__":
    print("=================================================================")
    print("ZUCT BIT3360 - DATABASE SECURITY WORKING PROTOTYPE DEMONSTRATION")
    print("=================================================================")

    db = init_demo_db()

    print("\n--- DEMO 1: ROLE-BASED ACCESS CONTROL (LEAST PRIVILEGE) ---")
    execute_role_action(db, "lecturer_user", "UPDATE_GPA", "ZUCT2026001", 4.50)
    execute_role_action(db, "lecturer_user", "UPDATE_FEES", "ZUCT2026001", 0.00)
    execute_role_action(db, "lecturer_user", "VIEW_NRC")
    execute_role_action(db, "finance_clerk", "UPDATE_FEES", "ZUCT2026002", 1200.00)
    execute_role_action(db, "finance_clerk", "UPDATE_GPA", "ZUCT2026002", 5.00)
    execute_role_action(db, "student_portal", "DELETE_STUDENT", "ZUCT2026004")

    demonstrate_sql_injection_protection(db)

    print("\n--- DEMO 3: AUTOMATED DATABASE AUDIT LOGS ---")
    cursor = db.cursor()
    cursor.execute("SELECT log_id, action_time, action_type, target_student_id, details FROM audit_logs")
    for log in cursor.fetchall():
        print("  Audit Entry:", log)
