package com.springbootacademy.departmentservice.service.impl;

import com.springbootacademy.departmentservice.dto.DepartmentDTO;
import com.springbootacademy.departmentservice.entity.Department;
import com.springbootacademy.departmentservice.repository.DepartmentRepository;
import com.springbootacademy.departmentservice.service.DepartmentService;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@AllArgsConstructor
public class DepartmentServiceIMPL implements DepartmentService {

    private DepartmentRepository departmentRepository;


    @Override
    public DepartmentDTO saveDepartment(DepartmentDTO departmentDTO) {

        Department department = new Department(
                departmentDTO.getId(),
                departmentDTO.getDepartmentName(),
                departmentDTO.getDepartmentDescription(),
                departmentDTO.getDepartmentCode()
        );

       Department department1=  departmentRepository.save(department);
       DepartmentDTO departmentDTO1 = new DepartmentDTO(
               department1.getId(),
               department1.getDepartmentName(),
               department1.getDepartmentDescription(),
               department1.getDepartmentCode()
       );
        return departmentDTO1;
    }

    @Override
    public DepartmentDTO getDepartmentByCode(String code) {
        Department department = departmentRepository.findDepartmentByDepartmentCode(code);

        DepartmentDTO departmentDTO = new DepartmentDTO(
                department.getId(),
                department.getDepartmentName(),
                department.getDepartmentDescription(),
                department.getDepartmentCode()
        );

        return departmentDTO;
    }
}
