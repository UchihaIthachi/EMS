package com.ems.organization_service.controller;

import com.ems.organization_service.dto.OrganizationDto;
import com.ems.organization_service.service.OrganizationService;
import lombok.AllArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("api/organizations")
@AllArgsConstructor
public class OrganizationController {
    @Autowired
    private OrganizationService organizationService;

    @PostMapping
    public ResponseEntity<OrganizationDto> saveOrganization(@RequestBody OrganizationDto organizationDto) {
        OrganizationDto savedOrganization = organizationService.saveOrganization(organizationDto);
        return new ResponseEntity<>(savedOrganization, HttpStatus.CREATED);
    }

    @GetMapping("{code}")
    public ResponseEntity<OrganizationDto> getOrganization(@PathVariable("code") String organizationCode) {
        OrganizationDto savedOrganizationDto = organizationService.getOrganizationByCode(organizationCode);
        return  ResponseEntity.ok(savedOrganizationDto);
    }
}
