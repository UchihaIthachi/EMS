package com.springbootacademy.departmentservice.events;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.concurrent.atomic.AtomicLong;

@Component
public class EmployeeEventsListener {

    private static final Logger log = LoggerFactory.getLogger(EmployeeEventsListener.class);
    private final AtomicLong processed = new AtomicLong();
    private final EmployeeEventHandler handler;
    private final long delayMs;

    public EmployeeEventsListener(EmployeeEventHandler handler, @Value("${ems.events.consumer-delay-ms:0}") long delayMs) {
        this.handler = handler;
        this.delayMs = delayMs;
    }

    @RabbitListener(queues = "${ems.events.queue}")
    public void onEmployeeCreated(EmployeeCreatedEvent event) throws InterruptedException {
        if (delayMs > 0) {
            Thread.sleep(delayMs); // simulated work, used to demo KEDA scaling on queue length
        }
        boolean applied = handler.handle(event);
        long n = processed.incrementAndGet();
        log.info("employee.created event={} employee={} department={} applied={} (handled {})",
                event.eventId(), event.employeeId(), event.departmentCode(), applied, n);
    }
}
