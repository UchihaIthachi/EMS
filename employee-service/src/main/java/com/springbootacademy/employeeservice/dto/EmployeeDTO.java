package com.springbootacademy.employeeservice.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class EmployeeDTO {

    long id;
    String firstName;
    String lastName;
    String email;
    String department_code;
}
