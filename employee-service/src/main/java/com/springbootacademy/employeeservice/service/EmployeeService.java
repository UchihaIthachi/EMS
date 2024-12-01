package com.springbootacademy.employeeservice.service;

import com.springbootacademy.employeeservice.dto.EmployeeDTO;
import com.springbootacademy.employeeservice.dto.ResponseEmpDepDto;

public interface EmployeeService {
    EmployeeDTO saveEmployee(EmployeeDTO employeeDTO);

    ResponseEmpDepDto getEmployee(long id);
}
