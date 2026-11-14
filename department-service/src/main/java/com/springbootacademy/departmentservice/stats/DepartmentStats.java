package com.springbootacademy.departmentservice.stats;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.Table;

/** CQRS read model: employee count per department, built from employee.created events. */
@Entity
@Table(name = "department_stats")
public class DepartmentStats {

    @Id
    @Column(name = "department_code", length = 64)
    private String departmentCode;

    @Column(name = "employee_count", nullable = false)
    private long employeeCount;

    protected DepartmentStats() {
    }

    public String getDepartmentCode() { return departmentCode; }
    public long getEmployeeCount() { return employeeCount; }
}
