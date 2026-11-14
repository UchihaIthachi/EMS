package com.springbootacademy.departmentservice.events;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class EventsConfig {

    @Bean
    public TopicExchange eventsExchange(@Value("${ems.events.exchange}") String name) {
        return new TopicExchange(name, true, false);
    }

    @Bean
    public Queue employeeEventsQueue(@Value("${ems.events.queue}") String name) {
        return new Queue(name, true);
    }

    @Bean
    public Binding employeeCreatedBinding(Queue employeeEventsQueue, TopicExchange eventsExchange) {
        return BindingBuilder.bind(employeeEventsQueue).to(eventsExchange).with("employee.created");
    }

    @Bean
    public MessageConverter jsonMessageConverter() {
        Jackson2JsonMessageConverter converter = new Jackson2JsonMessageConverter();
        // The producer's __TypeId__ header names a class that doesn't exist here: use the listener's parameter type.
        converter.setAlwaysConvertToInferredType(true);
        return converter;
    }
}
