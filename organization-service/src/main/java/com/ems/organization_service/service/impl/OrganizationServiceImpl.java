package com.ems.organization_service.service.impl;

import com.ems.organization_service.dto.OrganizationDto;
import com.ems.organization_service.entity.Organization;
import com.ems.organization_service.repository.OrganizationRepository;
import com.ems.organization_service.service.OrganizationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class OrganizationServiceImpl implements OrganizationService {

    @Autowired
    private OrganizationRepository organizationRepository;

    @Override
    public OrganizationDto saveOrganization(OrganizationDto organizationDto) {
        // Manually map OrganizationDto to Organization
        Organization organization = new Organization();
        organization.setId(organizationDto.getId());
        organization.setOrganizationName(organizationDto.getOrganizationName());
        organization.setOrganizationDescription(organizationDto.getOrganizationDescription());
        organization.setOrganizationCode(organizationDto.getOrganizationCode());
        organization.setCreateDate(organizationDto.getCreateDate());

        // Save the organization
        Organization savedOrganization = organizationRepository.save(organization);

        // Manually map Organization to OrganizationDto
        OrganizationDto savedOrganizationDto = new OrganizationDto();
        savedOrganizationDto.setId(savedOrganization.getId());
        savedOrganizationDto.setOrganizationName(savedOrganization.getOrganizationName());
        savedOrganizationDto.setOrganizationDescription(savedOrganization.getOrganizationDescription());
        savedOrganizationDto.setOrganizationCode(savedOrganization.getOrganizationCode());
        savedOrganizationDto.setCreateDate(savedOrganization.getCreateDate());

        return savedOrganizationDto;
    }

    @Override
    public OrganizationDto getOrganizationByCode(String organizationCode) {
        // Find the organization by code
        Organization organization = organizationRepository.findByOrganizationCode(organizationCode);

        // Manually map Organization to OrganizationDto
        OrganizationDto organizationDto = new OrganizationDto();
        organizationDto.setId(organization.getId());
        organizationDto.setOrganizationName(organization.getOrganizationName());
        organizationDto.setOrganizationDescription(organization.getOrganizationDescription());
        organizationDto.setOrganizationCode(organization.getOrganizationCode());
        organizationDto.setCreateDate(organization.getCreateDate());

        return organizationDto;
    }
}
