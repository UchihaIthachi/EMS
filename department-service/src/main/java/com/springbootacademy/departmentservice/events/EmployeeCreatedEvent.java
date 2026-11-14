package com.springbootacademy.departmentservice.events;

import java.time.Instant;

/** Mirror of employee-service's event; matched by JSON shape, not by Java type. */
public record EmployeeCreatedEvent(String eventId, Long employeeId, String email, String departmentCode, Instant occurredAt) {
}
