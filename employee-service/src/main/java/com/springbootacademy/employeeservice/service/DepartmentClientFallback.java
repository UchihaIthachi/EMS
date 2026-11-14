package com.springbootacademy.employeeservice.service;

import com.springbootacademy.employeeservice.dto.DepartmentDTO;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cloud.openfeign.FallbackFactory;
import org.springframework.stereotype.Component;

/**
 * Graceful degradation: if department-service fails, times out or the circuit is open,
 * return the employee without department details instead of failing the whole request.
 */
@Component
public class DepartmentClientFallback implements FallbackFactory<APIClient> {

    private static final Logger log = LoggerFactory.getLogger(DepartmentClientFallback.class);

    @Override
    public APIClient create(Throwable cause) {
        return code -> {
            log.warn("department-service unavailable for code {} ({}); returning employee without department",
                    code, cause.toString());
            return null;
        };
    }
}
