package com.springbootacademy.employeeservice.controller;

import com.springbootacademy.employeeservice.dto.EmployeeDTO;
import com.springbootacademy.employeeservice.dto.ResponseEmpDepDto;
import com.springbootacademy.employeeservice.service.EmployeeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("api/v1/employee-service")
public class EmployeeController {

    @Autowired
    private EmployeeService employeeService;

    @PostMapping
    public ResponseEntity<EmployeeDTO> saveEmployee(@RequestBody EmployeeDTO employeeDTO){
        EmployeeDTO employeeDTO1 = employeeService.saveEmployee(employeeDTO);
        return new ResponseEntity<>(employeeDTO1, HttpStatus.CREATED);
    }

    @GetMapping("{id}")
    public ResponseEntity<ResponseEmpDepDto> getEmployeeById(@PathVariable long id){
        ResponseEmpDepDto responseEmpDepDto = employeeService.getEmployee(id);
        return new ResponseEntity<>(responseEmpDepDto,HttpStatus.OK);
    }
}
