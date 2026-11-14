package com.springbootacademy.departmentservice.events;

import com.springbootacademy.departmentservice.stats.DepartmentStatsRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Idempotent consumer: the dedupe row and the read-model update commit together,
 * so a redelivered event (RabbitMQ is at-least-once) never counts twice.
 */
@Service
public class EmployeeEventHandler {

    private static final Logger log = LoggerFactory.getLogger(EmployeeEventHandler.class);
    private final ProcessedEventRepository processedEvents;
    private final DepartmentStatsRepository stats;

    public EmployeeEventHandler(ProcessedEventRepository processedEvents, DepartmentStatsRepository stats) {
        this.processedEvents = processedEvents;
        this.stats = stats;
    }

    /** @return true if applied, false if it was a duplicate. */
    @Transactional
    public boolean handle(EmployeeCreatedEvent event) {
        if (event.eventId() == null || event.departmentCode() == null) {
            // Not retryable: reject straight to the dead-letter queue.
            throw new org.springframework.amqp.AmqpRejectAndDontRequeueException("invalid event: " + event);
        }
        if (processedEvents.markProcessed(event.eventId()) == 0) {
            log.info("duplicate event {} ignored", event.eventId());
            return false;
        }
        stats.increment(event.departmentCode());
        return true;
    }
}
