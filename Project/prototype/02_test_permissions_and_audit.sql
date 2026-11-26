-- ============================================================================
-- PERMISSION & AUDIT LOG VERIFICATION SCRIPT
-- Run these statements logged in as each respective user to demonstrate RBAC.
-- ============================================================================

-- A. TEST AS 'lecturer_user'@'localhost'
-- [ALLOWED] View allowed columns:
SELECT student_id, full_name, program, gpa FROM zuct_student_records.students;
-- [ALLOWED] Update GPA:
UPDATE zuct_student_records.students SET gpa = 4.45 WHERE student_id = 'ZUCT2026001';
-- [DENIED] Attempt to view restricted NRC column (Throws ERROR 1143: SELECT command denied):
SELECT nrc_number FROM zuct_student_records.students;
-- [DENIED] Attempt to modify fee balance (Throws ERROR 1143: UPDATE command denied):
UPDATE zuct_student_records.students SET fee_balance = 0.00 WHERE student_id = 'ZUCT2026002';
-- [DENIED] Attempt to delete a student record (Throws ERROR 1142: DELETE command denied):
DELETE FROM zuct_student_records.students WHERE student_id = 'ZUCT2026004';

-- B. TEST AS 'finance_clerk'@'localhost'
-- [ALLOWED] View fee balances:
SELECT student_id, full_name, fee_balance FROM zuct_student_records.students;
-- [ALLOWED] Update fee balance after payment:
UPDATE zuct_student_records.students SET fee_balance = 1000.00 WHERE student_id = 'ZUCT2026002';
-- [DENIED] Attempt to alter student GPA (Throws ERROR 1143: UPDATE command denied):
UPDATE zuct_student_records.students SET gpa = 5.00 WHERE student_id = 'ZUCT2410048';

-- C. TEST AS 'student_portal'@'localhost'
-- [ALLOWED] Read student dashboard info:
SELECT student_id, full_name, program, gpa, fee_balance FROM zuct_student_records.students;
-- [DENIED] Attempt to access audit logs (Throws ERROR 1142: SELECT command denied):
SELECT * FROM zuct_student_records.audit_logs;

-- D. VERIFY AUDIT LOGS AS 'db_admin'@'localhost'
SELECT * FROM zuct_student_records.audit_logs ORDER BY action_time DESC;
