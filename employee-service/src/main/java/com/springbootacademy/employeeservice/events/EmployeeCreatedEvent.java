package com.springbootacademy.employeeservice.events;

import java.time.Instant;

/**
 * Published after an employee is saved. Consumed by department-service.
 * eventId is unique per event so consumers can ignore redeliveries (idempotent consumer).
 */
public record EmployeeCreatedEvent(String eventId, Long employeeId, String email, String departmentCode, Instant occurredAt) {
}
