package com.springbootacademy.departmentservice.stats;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface DepartmentStatsRepository extends JpaRepository<DepartmentStats, String> {

    /** Atomic upsert, safe when several consumer pods (KEDA scale-out) update the same row. */
    @Modifying
    @Query(value = "INSERT INTO department_stats (department_code, employee_count) VALUES (:code, 1) "
            + "ON DUPLICATE KEY UPDATE employee_count = employee_count + 1", nativeQuery = true)
    int increment(@Param("code") String departmentCode);
}
