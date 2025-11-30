#!/usr/bin/env python3
"""
Simple L298N motor test - tests one motor at a time
"""
import RPi.GPIO as GPIO
import time

# Motor A pins
ENA = 12
IN1 = 17
IN2 = 27

GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)

GPIO.setup(ENA, GPIO.OUT)
GPIO.setup(IN1, GPIO.OUT)
GPIO.setup(IN2, GPIO.OUT)

# Set ENA HIGH (full speed, no PWM)
print("Testing Motor A with ENA permanently HIGH...")
GPIO.output(ENA, GPIO.HIGH)  # Enable at full speed

print("Motor A should spin FORWARD for 3 seconds...")
GPIO.output(IN1, GPIO.HIGH)
GPIO.output(IN2, GPIO.LOW)
time.sleep(3)

print("Motor A should spin BACKWARD for 3 seconds...")
GPIO.output(IN1, GPIO.LOW)
GPIO.output(IN2, GPIO.HIGH)
time.sleep(3)

print("Stopping...")
GPIO.output(IN1, GPIO.LOW)
GPIO.output(IN2, GPIO.LOW)

GPIO.cleanup()
print("Test complete!")
