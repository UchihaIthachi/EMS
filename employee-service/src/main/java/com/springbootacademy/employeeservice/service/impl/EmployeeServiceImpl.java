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
                employeeDTO.getDepartment_code()
        );

        Employee savedEmployee = employeeRepository.save(employee);

        EmployeeDTO employeeDTO1 = new EmployeeDTO(
                savedEmployee.getId(),
                savedEmployee.getFirstName(),
                savedEmployee.getLastName(),
                savedEmployee.getEmail(),
                savedEmployee.getDepartment_code()
        );

        return employeeDTO1;
    }

    @Override
    public ResponseEmpDepDto getEmployee(long id) {
        Employee employeeById = employeeRepository.getEmployeeById(id);
        EmployeeDTO employeeDTO = new EmployeeDTO(
                employeeById.getId(),
                employeeById.getFirstName(),
                employeeById.getLastName(),
                employeeById.getEmail(),
                employeeById.getDepartment_code()
        );

        //Rest template is to be implemented

//        DepartmentDTO departmentDTO1 = webClient.get()
//                .uri("http://localhost:8081/api/v1/department_service/"+employeeById.getDepartment_code())
//                .retrieve()
//                .bodyToMono(DepartmentDTO.class)
//                .block();

        DepartmentDTO departmentDTO = apiClient.getDepartmentById(employeeById.getDepartment_code());

        ResponseEmpDepDto responseEmpDepDto = new ResponseEmpDepDto();
        responseEmpDepDto.setEmployeeDTO(employeeDTO);
        responseEmpDepDto.setDepartmentDTO(departmentDTO);

        return responseEmpDepDto;
    }
}
