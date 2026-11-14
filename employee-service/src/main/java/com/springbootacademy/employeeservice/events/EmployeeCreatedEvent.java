package com.springbootacademy.employeeservice.events;

import java.time.Instant;

/** Published after an employee is saved. Consumed by department-service. */
public record EmployeeCreatedEvent(Long employeeId, String email, String departmentCode, Instant occurredAt) {
}
