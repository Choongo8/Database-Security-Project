-- ============================================================================
-- ZAMBIA UNIVERSITY COLLEGE OF TECHNOLOGY (ZUCT)
-- BIT3360: ADVANCED DATABASES - DATABASE SECURITY PROTOTYPE
-- Database: zuct_student_records
-- ============================================================================

-- 1. Create Dedicated Database
DROP DATABASE IF EXISTS zuct_student_records;
CREATE DATABASE zuct_student_records;
USE zuct_student_records;

-- 2. Create Main Tables
CREATE TABLE students (
    student_id VARCHAR(15) PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    nrc_number VARCHAR(20) UNIQUE NOT NULL,
    program VARCHAR(50) NOT NULL,
    gpa DECIMAL(3, 2) CHECK (gpa >= 0.00 AND gpa <= 5.00),
    fee_balance DECIMAL(10, 2) DEFAULT 0.00,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE audit_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    db_user VARCHAR(100) NOT NULL,
    action_type ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    target_student_id VARCHAR(15) NOT NULL,
    old_values TEXT,
    new_values TEXT
);

-- 3. Insert Sample Student Data
INSERT INTO students (student_id, full_name, nrc_number, program, gpa, fee_balance) VALUES
('ZUCT2026001', 'Chanda Mwamba', '123456/10/1', 'BSc Computer Science', 4.35, 0.00),
('ZUCT2026002', 'Mutale Banda', '234567/10/1', 'BSc Information Technology', 3.80, 2500.00),
('ZUCT2026003', 'Thabo Phiri', '345678/61/1', 'BSc Software Engineering', 4.60, 0.00),
('ZUCT2026004', 'Kabwe Zulu', '456789/10/1', 'BSc Cybersecurity', 3.45, 4200.00),
('ZUCT2026005', 'Natasha Tembo', '567890/31/1', 'BSc Data Science', 4.10, 1000.00);

-- 4. Create Audit Triggers (Additional Security Measure)
DELIMITER //

CREATE TRIGGER trg_students_after_insert
AFTER INSERT ON students
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (db_user, action_type, target_student_id, old_values, new_values)
    VALUES (
        CURRENT_USER(),
        'INSERT',
        NEW.student_id,
        NULL,
        CONCAT('Name: ', NEW.full_name, ', Program: ', NEW.program, ', GPA: ', NEW.gpa, ', Balance: ', NEW.fee_balance)
    );
END //

CREATE TRIGGER trg_students_after_update
AFTER UPDATE ON students
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (db_user, action_type, target_student_id, old_values, new_values)
    VALUES (
        CURRENT_USER(),
        'UPDATE',
        NEW.student_id,
        CONCAT('GPA: ', OLD.gpa, ', Balance: ', OLD.fee_balance),
        CONCAT('GPA: ', NEW.gpa, ', Balance: ', NEW.fee_balance)
    );
END //

CREATE TRIGGER trg_students_after_delete
AFTER DELETE ON students
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (db_user, action_type, target_student_id, old_values, new_values)
    VALUES (
        CURRENT_USER(),
        'DELETE',
        OLD.student_id,
        CONCAT('Name: ', OLD.full_name, ', Program: ', OLD.program, ', GPA: ', OLD.gpa),
        NULL
    );
END //

DELIMITER ;

-- 5. Role-Based Access Control (RBAC) & Least Privilege Users
DROP USER IF EXISTS 'db_admin'@'localhost';
DROP USER IF EXISTS 'lecturer_user'@'localhost';
DROP USER IF EXISTS 'finance_clerk'@'localhost';
DROP USER IF EXISTS 'student_portal'@'localhost';

-- User 1: Database Administrator (Full Privileges)
CREATE USER 'db_admin'@'localhost' IDENTIFIED BY 'Admin@Zuct2026!';
GRANT ALL PRIVILEGES ON zuct_student_records.* TO 'db_admin'@'localhost';

-- User 2: Lecturer (Can view student records and update GPA only; cannot modify fee_balance or delete)
CREATE USER 'lecturer_user'@'localhost' IDENTIFIED BY 'Lect@Zuct2026!';
GRANT SELECT (student_id, full_name, program, gpa) ON zuct_student_records.students TO 'lecturer_user'@'localhost';
GRANT UPDATE (gpa) ON zuct_student_records.students TO 'lecturer_user'@'localhost';

-- User 3: Finance Clerk (Can view student details and update fee_balance only; cannot see/edit GPA or NRC)
CREATE USER 'finance_clerk'@'localhost' IDENTIFIED BY 'Fin@Zuct2026!';
GRANT SELECT (student_id, full_name, program, fee_balance) ON zuct_student_records.students TO 'finance_clerk'@'localhost';
GRANT UPDATE (fee_balance) ON zuct_student_records.students TO 'finance_clerk'@'localhost';

-- User 4: Public Student Portal (Read-only on non-sensitive fields; no NRC, no audit_logs)
CREATE USER 'student_portal'@'localhost' IDENTIFIED BY 'Portal@Zuct2026!';
GRANT SELECT (student_id, full_name, program, gpa, fee_balance) ON zuct_student_records.students TO 'student_portal'@'localhost';

FLUSH PRIVILEGES;
