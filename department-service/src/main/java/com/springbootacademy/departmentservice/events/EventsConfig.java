package com.springbootacademy.departmentservice.events;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.DirectExchange;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.QueueBuilder;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * ems.events (topic) --employee.created--> department.employee-events
 * Messages that still fail after the listener's retries are dead-lettered to
 * ems.events.dlx --> department.employee-events.dlq for inspection and replay.
 */
@Configuration
public class EventsConfig {

    @Bean
    public TopicExchange eventsExchange(@Value("${ems.events.exchange}") String name) {
        return new TopicExchange(name, true, false);
    }

    @Bean
    public DirectExchange deadLetterExchange(@Value("${ems.events.exchange}") String name) {
        return new DirectExchange(name + ".dlx", true, false);
    }

    @Bean
    public Queue employeeEventsQueue(@Value("${ems.events.queue}") String name,
                                     @Value("${ems.events.exchange}") String exchange) {
        return QueueBuilder.durable(name)
                .deadLetterExchange(exchange + ".dlx")
                .deadLetterRoutingKey(name + ".dlq")
                .build();
    }

    @Bean
    public Queue employeeEventsDlq(@Value("${ems.events.queue}") String name) {
        return QueueBuilder.durable(name + ".dlq").build();
    }

    @Bean
    public Binding employeeCreatedBinding(Queue employeeEventsQueue, TopicExchange eventsExchange) {
        return BindingBuilder.bind(employeeEventsQueue).to(eventsExchange).with("employee.created");
    }

    @Bean
    public Binding deadLetterBinding(Queue employeeEventsDlq, DirectExchange deadLetterExchange,
                                     @Value("${ems.events.queue}") String name) {
        return BindingBuilder.bind(employeeEventsDlq).to(deadLetterExchange).with(name + ".dlq");
    }

    @Bean
    public MessageConverter jsonMessageConverter(ObjectMapper objectMapper) {
        // Spring Boot's ObjectMapper already handles java.time types (Instant) and ISO dates.
        Jackson2JsonMessageConverter converter = new Jackson2JsonMessageConverter(objectMapper);
        // The producer's __TypeId__ header names a class that doesn't exist here: use the listener's parameter type.
        converter.setAlwaysConvertToInferredType(true);
        return converter;
    }
}
