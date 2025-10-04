package com.example.demo.controller;

import com.example.demo.model.User;
import com.example.demo.service.HelloService;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class HelloController {

    private final HelloService helloService;

    public HelloController(HelloService helloService) {
        this.helloService = helloService;
    }

    @GetMapping("/hello")
    public String hello() {
        return helloService.sayHello();
    }

    @PostMapping("/user")
    public String createUser(@RequestBody User user) {
        return helloService.greetUser(user);
    }
}
