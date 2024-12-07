package com.springbootacademy.organizationservice.service;

import com.springbootacademy.organizationservice.dto.DepartmentDTO;
import org.springframework.stereotype.Service;

@Service
public interface DepartmentService {

    DepartmentDTO saveDepartment(DepartmentDTO departmentDTO);
    DepartmentDTO getDepartmentByCode(String code);
}
