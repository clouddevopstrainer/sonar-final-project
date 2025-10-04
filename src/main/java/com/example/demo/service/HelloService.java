package com.example.demo.service;

import com.example.demo.model.User;
import org.springframework.stereotype.Service;

@Service
public class HelloService {

    public String sayHello() {
        return "Hello from Spring Boot CI/CD pipeline!";
    }

    public String greetUser(User user) {
        return "Hello, " + user.getName() + "! Your email is " + user.getEmail();
    }
}
