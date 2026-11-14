package com.springbootacademy.employeeservice.service;

import com.springbootacademy.employeeservice.dto.DepartmentDTO;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

// Fixed URL resolved by Kubernetes DNS (no service registry). Override with CLIENTS_DEPARTMENT_URL.
@FeignClient(name = "department-service", url = "${clients.department.url}")
public interface APIClient {

    @GetMapping("/api/v1/department-controller/{department-code}")
    DepartmentDTO getDepartmentById(@PathVariable(value = "department-code") String code);

}
