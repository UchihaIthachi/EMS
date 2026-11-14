package com.springbootacademy.departmentservice.events;

import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

/** Idempotency ledger: one row per handled eventId. */
public interface ProcessedEventRepository extends Repository<ProcessedEvent, String> {

    /** @return 1 if this eventId is new, 0 if it was already processed (duplicate delivery). */
    @Modifying
    @Query(value = "INSERT IGNORE INTO processed_events (event_id, processed_at) VALUES (:id, CURRENT_TIMESTAMP(6))", nativeQuery = true)
    int markProcessed(@Param("id") String eventId);
}
