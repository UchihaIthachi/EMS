package com.springbootacademy.departmentservice.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;

@Entity
@Table(name = "departments")
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Department {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private int id;
    @Column(name = "name") // map to actual column
    private String departmentName;

    @Column(name = "description")
    private String departmentDescription;

    @Column(name = "department_code")
    private String departmentCode;
}
