package com.springbootacademy.employeeservice.events;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.AmqpException;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.UUID;

/**
 * Best-effort publisher: a RabbitMQ outage must not fail the HTTP request.
 * (A transactional outbox would make this reliable; that pattern is covered in another project.)
 */
@Component
public class EmployeeEventPublisher {

    public static final String EMPLOYEE_CREATED = "employee.created";
    private static final Logger log = LoggerFactory.getLogger(EmployeeEventPublisher.class);

    private final RabbitTemplate rabbitTemplate;
    private final String exchange;

    public EmployeeEventPublisher(RabbitTemplate rabbitTemplate, @Value("${ems.events.exchange}") String exchange) {
        this.rabbitTemplate = rabbitTemplate;
        this.exchange = exchange;
    }

    public void employeeCreated(Long id, String email, String departmentCode) {
        EmployeeCreatedEvent event = new EmployeeCreatedEvent(UUID.randomUUID().toString(), id, email, departmentCode, Instant.now());
        try {
            rabbitTemplate.convertAndSend(exchange, EMPLOYEE_CREATED, event);
        } catch (AmqpException e) {
            log.warn("Could not publish {} for employee {}: {}", EMPLOYEE_CREATED, id, e.getMessage());
        }
    }
}
