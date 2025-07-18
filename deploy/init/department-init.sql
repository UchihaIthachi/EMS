CREATE DATABASE IF NOT EXISTS department_db_1;
USE department_db_1;

CREATE TABLE IF NOT EXISTS departments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    department_code VARCHAR(50) UNIQUE NOT NULL,
    description VARCHAR(500)
);

INSERT INTO departments (name, department_code, description) VALUES
('Information Technology', 'DEP001', 'Handles IT infrastructure, software, and support'),
('Human Resources', 'DEP002', 'Manages recruitment, onboarding, and employee relations'),
('Finance', 'DEP003', 'Oversees budgeting, accounting, and financial reporting'),
('Marketing', 'DEP004', 'Responsible for market research, advertising, and promotions');
