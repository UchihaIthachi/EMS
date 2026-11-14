package com.springbootacademy.departmentservice.stats;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/** Query side of the read model (eventually consistent with employee-service). */
@RestController
@RequestMapping("api/v1/department-controller")
public class DepartmentStatsController {

    private final DepartmentStatsRepository repository;

    public DepartmentStatsController(DepartmentStatsRepository repository) {
        this.repository = repository;
    }

    @GetMapping("{department-code}/stats")
    public Map<String, Object> stats(@PathVariable("department-code") String code) {
        long count = repository.findById(code).map(DepartmentStats::getEmployeeCount).orElse(0L);
        return Map.of("departmentCode", code, "employeeCount", count);
    }
}
