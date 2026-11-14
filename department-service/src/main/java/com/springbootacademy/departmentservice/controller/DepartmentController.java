package com.springbootacademy.departmentservice.controller;

import com.springbootacademy.departmentservice.dto.DepartmentDTO;
import com.springbootacademy.departmentservice.service.DepartmentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("api/v1/department-controller")
public class DepartmentController {

    @Autowired
    private DepartmentService departmentService;
    @PostMapping
    public ResponseEntity<DepartmentDTO> saveDepartment(@RequestBody DepartmentDTO departmentDTO){

        DepartmentDTO departmentDTO1 = departmentService.saveDepartment(departmentDTO);

        return new ResponseEntity<>(departmentDTO1, HttpStatus.CREATED);
    }

    @GetMapping("{department-code}")
    public ResponseEntity<DepartmentDTO> findDepartmentByCode(@PathVariable(value = "department-code") String code){
        return new ResponseEntity<>(departmentService.getDepartmentByCode(code),HttpStatus.OK);
    }
}
