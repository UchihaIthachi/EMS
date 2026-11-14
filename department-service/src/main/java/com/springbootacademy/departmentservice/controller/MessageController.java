package com.springbootacademy.departmentservice.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class MessageController {

    // Set with the APP_MESSAGE environment variable (ConfigMap) instead of the old config server.
    @Value("${app.message:Department service is up}")
    private String msg;

    @GetMapping({"/message", "/api/v1/department-service/message"})
    public String getMessage() {
        return msg;
    }
}
