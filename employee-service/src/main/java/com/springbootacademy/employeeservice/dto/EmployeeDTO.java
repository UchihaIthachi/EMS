package com.springbootacademy.employeeservice.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class EmployeeDTO {

    long id;
    String firstName;
    String lastName;
    String email;
    String departmentCode;
    String position;
    Double salary;
    LocalDate hireDate;
}
