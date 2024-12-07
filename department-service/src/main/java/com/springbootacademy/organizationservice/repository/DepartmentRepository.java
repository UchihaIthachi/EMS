package com.springbootacademy.organizationservice.repository;

import com.springbootacademy.organizationservice.entity.Department;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DepartmentRepository extends JpaRepository<Department,Long> {
    Department findDepartmentByDepartmentCode(String code);
}
