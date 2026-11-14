package com.springbootacademy.employeeservice.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class MessageController {

    // Set with the APP_MESSAGE environment variable (ConfigMap) instead of the old config server.
    @Value("${app.message:Employee service is up}")
    private String msg;

    @GetMapping({"/users/message", "/api/v1/employee-service/users/message"})
    public String getMessage() {
        return msg;
    }
}
