CREATE DATABASE IF NOT EXISTS employee_db_1;
USE employee_db_1;

CREATE TABLE IF NOT EXISTS employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    department_code VARCHAR(50) NOT NULL,
    position VARCHAR(100),
    salary DECIMAL(10,2),
    hire_date DATE
);

INSERT INTO employees (first_name, last_name, email, department_code, position, salary, hire_date) VALUES
('John', 'Doe', 'john.doe@example.com', 'DEP001', 'Software Engineer', 75000.00, '2022-01-15'),
('Jane', 'Smith', 'jane.smith@example.com', 'DEP002', 'HR Manager', 68000.00, '2021-07-01'),
('Robert', 'Johnson', 'robert.johnson@example.com', 'DEP003', 'Financial Analyst', 72000.00, '2023-02-10'),
('Emily', 'Davis', 'emily.davis@example.com', 'DEP004', 'Marketing Coordinator', 55000.00, '2022-08-22'),
('Michael', 'Brown', 'michael.brown@example.com', 'DEP001', 'DevOps Engineer', 80000.00, '2020-11-03'),
('Laura', 'Wilson', 'laura.wilson@example.com', 'DEP003', 'Accountant', 65000.00, '2021-03-19');
