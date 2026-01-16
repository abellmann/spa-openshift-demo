package com.example.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @GetMapping("/api/hello")
    public Message hello() {
        return new Message("Hello from Spring Boot Backend");
    }

    @GetMapping("/api/health")
    public Status health() {
        return new Status("UP");
    }

    public record Message(String message) {}
    public record Status(String status) {}
}
