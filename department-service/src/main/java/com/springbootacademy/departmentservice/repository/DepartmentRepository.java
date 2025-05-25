package com.springbootacademy.departmentservice.repository;

import com.springbootacademy.departmentservice.entity.Department;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface DepartmentRepository extends JpaRepository<Department,Long> {
    // Department findDepartmentByDepartmentCode(String code);
    @Query("SELECT d FROM Department d WHERE d.departmentCode = :code")
    Optional<Department> findByDepartmentCode(@Param("code") String code);
}
