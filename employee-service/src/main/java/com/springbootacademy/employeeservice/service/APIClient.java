package com.springbootacademy.employeeservice.service;

import com.springbootacademy.employeeservice.dto.DepartmentDTO;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

//@FeignClient(url = "http://localhost:8081",value = "DEPARTMENT-SERVICE")
@FeignClient(name = "DEPARTMENT-SERVICE") //get the application name from properties file.
public interface APIClient {

    @GetMapping("/api/v1/department-controller/{department-code}")
    DepartmentDTO getDepartmentById(@PathVariable(value = "department-code") String code);

}
