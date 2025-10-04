package com.example.demo;

import com.example.demo.controller.HelloController;
import com.example.demo.model.User;
import com.example.demo.service.HelloService;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class HelloControllerTest {

    private final HelloService helloService = new HelloService();
    private final HelloController helloController = new HelloController(helloService);

    @Test
    void testHelloEndpoint() {
        String response = helloController.hello();
        assertEquals("Hello from Spring Boot CI/CD pipeline!", response);
    }

    @Test
    void testUserEndpoint() {
        User user = new User("Bob", "bob@example.com");
        String response = helloController.createUser(user);
        assertTrue(response.contains("Bob"));
        assertTrue(response.contains("bob@example.com"));
    }
}
