package com.ems.organization_service.dto;

import java.time.LocalDateTime;

public class OrganizationDto {
    private Long id;
    private String organizationName;
    private String organizationDescription;
    private String organizationCode;
    private LocalDateTime createDate;

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
