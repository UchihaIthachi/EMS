package com.ems.organization_service.entity;

import org.hibernate.annotations.CreationTimestamp;

import javax.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "organizations")
public class Organization {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String organizationName;

    private String organizationDescription;

    @Column(nullable = false, unique = true)
    private String organizationCode;

    @CreationTimestamp
    private LocalDateTime createDate;

    // Default Constructor
    public Organization() {
    }

    // Parameterized Constructor
    public Organization(Long id, String organizationName, String organizationDescription, String organizationCode, LocalDateTime createDate) {
        this.id = id;
        this.organizationName = organizationName;
        this.organizationDescription = organizationDescription;
        this.organizationCode = organizationCode;
        this.createDate = createDate;
    }

    // Getter and Setter for id
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    // Getter and Setter for organizationName
    public String getOrganizationName() {
        return organizationName;
    }

    public void setOrganizationName(String organizationName) {
        this.organizationName = organizationName;
    }

    // Getter and Setter for organizationDescription
    public String getOrganizationDescription() {
        return organizationDescription;
    }

    public void setOrganizationDescription(String organizationDescription) {
        this.organizationDescription = organizationDescription;
    }

    // Getter and Setter for organizationCode
    public String getOrganizationCode() {
        return organizationCode;
    }

    public void setOrganizationCode(String organizationCode) {
        this.organizationCode = organizationCode;
    }

    // Getter and Setter for createDate
    public LocalDateTime getCreateDate() {
        return createDate;
    }

    public void setCreateDate(LocalDateTime createDate) {
        this.createDate = createDate;
    }
}
