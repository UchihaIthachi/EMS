package com.springbootacademy.departmentservice.events;

import java.time.Instant;

/** Mirror of employee-service's event; matched by JSON shape, not by Java type. */
public record EmployeeCreatedEvent(Long employeeId, String email, String departmentCode, Instant occurredAt) {
}
