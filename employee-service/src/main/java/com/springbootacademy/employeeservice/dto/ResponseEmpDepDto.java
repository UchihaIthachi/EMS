package com.springbootacademy.employeeservice.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ResponseEmpDepDto {

    private EmployeeDTO employeeDTO;
    private DepartmentDTO departmentDTO;
}
