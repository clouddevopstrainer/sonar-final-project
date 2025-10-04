package com.example.demo;

import com.example.demo.model.User;
import com.example.demo.service.HelloService;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class HelloServiceTest {

    private final HelloService helloService = new HelloService();

    @Test
    void testSayHello() {
        String result = helloService.sayHello();
        assertEquals("Hello from Spring Boot CI/CD pipeline!", result);
    }

    @Test
    void testGreetUser() {
        User user = new User("Alice", "alice@example.com");
        String result = helloService.greetUser(user);
        assertTrue(result.contains("Alice"));
        assertTrue(result.contains("alice@example.com"));
    }
}
