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
    private final long delayMs;

    public EmployeeEventsListener(@Value("${ems.events.consumer-delay-ms:0}") long delayMs) {
        this.delayMs = delayMs;
    }

    @RabbitListener(queues = "${ems.events.queue}")
    public void onEmployeeCreated(EmployeeCreatedEvent event) throws InterruptedException {
        if (delayMs > 0) {
            Thread.sleep(delayMs); // simulated work, used to demo KEDA scaling on queue length
        }
        long n = processed.incrementAndGet();
        log.info("employee.created: employee={} department={} (processed {})", event.employeeId(), event.departmentCode(), n);
    }

    public long processedCount() {
        return processed.get();
    }
}
