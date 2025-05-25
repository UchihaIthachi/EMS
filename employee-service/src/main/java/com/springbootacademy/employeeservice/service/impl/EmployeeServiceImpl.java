package com.springbootacademy.employeeservice.service.impl;

import com.springbootacademy.employeeservice.dto.DepartmentDTO;
import com.springbootacademy.employeeservice.dto.EmployeeDTO;
import com.springbootacademy.employeeservice.dto.ResponseEmpDepDto;
import com.springbootacademy.employeeservice.entity.Employee;
import com.springbootacademy.employeeservice.repo.EmployeeRepository;
import com.springbootacademy.employeeservice.service.APIClient;
import com.springbootacademy.employeeservice.service.EmployeeService;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

@Service
@AllArgsConstructor
public class EmployeeServiceImpl implements EmployeeService {

    private EmployeeRepository employeeRepository;
    private APIClient apiClient;
    //private WebClient webClient;
    //private RestTemplate restTemplate;

    @Override
    public EmployeeDTO saveEmployee(EmployeeDTO employeeDTO) {
        Employee employee = new Employee(
                employeeDTO.getId(),
                employeeDTO.getFirstName(),
                employeeDTO.getLastName(),
                employeeDTO.getEmail(),
                employeeDTO.getDepartmentCode(),
                employeeDTO.getPosition(),
                employeeDTO.getSalary(),
                employeeDTO.getHireDate()
        );

        Employee savedEmployee = employeeRepository.save(employee);

        EmployeeDTO employeeDTO1 = new EmployeeDTO(
                savedEmployee.getId(),
                savedEmployee.getFirstName(),
                savedEmployee.getLastName(),
                savedEmployee.getEmail(),
                savedEmployee.getDepartmentCode(),
                savedEmployee.getPosition(),
                savedEmployee.getSalary(),
                savedEmployee.getHireDate()
        );

        return employeeDTO1;
    }

    @Override
    public ResponseEmpDepDto getEmployee(long id) {
        Employee employeeById = employeeRepository.findById(id)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Employee not found"));

        if (employeeById == null) {
            throw new RuntimeException("Employee not found with ID: " + id);
        }
    
        EmployeeDTO employeeDTO = new EmployeeDTO(
                employeeById.getId(),
                employeeById.getFirstName(),
                employeeById.getLastName(),
                employeeById.getEmail(),
                employeeById.getDepartmentCode(),
                employeeById.getPosition(),
                employeeById.getSalary(),
                employeeById.getHireDate()
        );
    
        DepartmentDTO departmentDTO = apiClient.getDepartmentById(employeeById.getDepartmentCode());
    
        ResponseEmpDepDto response = new ResponseEmpDepDto();
        response.setEmployeeDTO(employeeDTO);
        response.setDepartmentDTO(departmentDTO);
    
        return response;
    }
    
}
