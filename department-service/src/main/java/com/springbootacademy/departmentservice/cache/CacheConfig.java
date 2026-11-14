package com.springbootacademy.departmentservice.cache;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.cache.RedisCacheManagerBuilderCustomizer;
import org.springframework.cache.Cache;
import org.springframework.cache.annotation.CachingConfigurerSupport;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.interceptor.CacheErrorHandler;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.serializer.GenericJackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.RedisSerializationContext;

import java.time.Duration;

/**
 * Cache-aside for department lookups (read-heavy: every employee GET asks for its department).
 * Redis is an optimisation, not a dependency: if it is down, reads fall through to MySQL.
 */
@Configuration
@EnableCaching
public class CacheConfig extends CachingConfigurerSupport {

    public static final String DEPARTMENTS = "departments";
    private static final Logger log = LoggerFactory.getLogger(CacheConfig.class);

    @Bean
    public RedisCacheManagerBuilderCustomizer departmentsCache(@Value("${ems.cache.departments-ttl:10m}") Duration ttl) {
        RedisCacheConfiguration config = RedisCacheConfiguration.defaultCacheConfig()
                .entryTtl(ttl)
                .disableCachingNullValues()
                .serializeValuesWith(RedisSerializationContext.SerializationPair
                        .fromSerializer(new GenericJackson2JsonRedisSerializer()));
        return builder -> builder.withCacheConfiguration(DEPARTMENTS, config);
    }

    @Override
    public CacheErrorHandler errorHandler() {
        return new CacheErrorHandler() {
            @Override public void handleCacheGetError(RuntimeException e, Cache c, Object key) { warn("get", key, e); }
            @Override public void handleCachePutError(RuntimeException e, Cache c, Object key, Object v) { warn("put", key, e); }
            @Override public void handleCacheEvictError(RuntimeException e, Cache c, Object key) { warn("evict", key, e); }
            @Override public void handleCacheClearError(RuntimeException e, Cache c) { warn("clear", "*", e); }
        };
    }

    private static void warn(String op, Object key, RuntimeException e) {
        log.warn("cache {} failed for key {} ({}); continuing without cache", op, key, e.getMessage());
    }
}
