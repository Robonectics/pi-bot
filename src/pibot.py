#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Pi-Bot Tank Robot Controller
Controls two tank tracks via L298N motor driver
"""

import time

# Try to import RPi.GPIO, fall back to mock for testing on non-Pi systems
try:
    import RPi.GPIO as GPIO
    MOCK_GPIO = False
except (ImportError, RuntimeError):
    print("WARNING: RPi.GPIO not available - using mock GPIO for testing")
    MOCK_GPIO = True

    # Mock GPIO module for testing on non-Pi systems
    class MockGPIO:
        BCM = "BCM"
        OUT = "OUT"
        HIGH = 1
        LOW = 0

        @staticmethod
        def setmode(mode): pass

        @staticmethod
        def setwarnings(flag): pass

        @staticmethod
        def setup(pin, mode): pass

        @staticmethod
        def output(pin, state): pass

        @staticmethod
        def cleanup(): pass

        class PWM:
            def __init__(self, pin, freq):
                self.pin = pin
                self.freq = freq
                self.duty = 0

            def start(self, duty):
                self.duty = duty

            def ChangeDutyCycle(self, duty):
                self.duty = duty

            def stop(self):
                pass

    GPIO = MockGPIO()

class TankBot:
    def __init__(self):
        # Pin definitions
        # Left track (Motor A)
        self.ENA = 12   # PWM - speed control
        self.IN1 = 17   # Direction
        self.IN2 = 27   # Direction

        # Right track (Motor B)
        self.ENB = 13   # PWM - speed control
        self.IN3 = 22   # Direction
        self.IN4 = 23   # Direction

        # Setup GPIO
        GPIO.setmode(GPIO.BCM)
        GPIO.setwarnings(False)

        # Setup pins
        GPIO.setup(self.ENA, GPIO.OUT)
        GPIO.setup(self.IN1, GPIO.OUT)
        GPIO.setup(self.IN2, GPIO.OUT)
        GPIO.setup(self.ENB, GPIO.OUT)
        GPIO.setup(self.IN3, GPIO.OUT)
        GPIO.setup(self.IN4, GPIO.OUT)

        # Setup PWM (frequency 1000Hz)
        self.pwm_left = GPIO.PWM(self.ENA, 1000)
        self.pwm_right = GPIO.PWM(self.ENB, 1000)

        # Start PWM with 0% duty cycle
        self.pwm_left.start(0)
        self.pwm_right.start(0)

        # Track multipliers for calibration (0.0 to 1.0)
        self.left_multiplier = 1.0
        self.right_multiplier = 1.0

        print("TankBot initialized")

    def set_multipliers(self, left=None, right=None):
        """Set track speed multipliers for calibration"""
        if left is not None:
            self.left_multiplier = max(0.0, min(1.0, left))
        if right is not None:
            self.right_multiplier = max(0.0, min(1.0, right))

    def set_left_track(self, speed):
        """
        Set left track speed and direction
        speed: -100 to 100 (negative = backward, positive = forward)
        """
        # Apply multiplier
        adjusted_speed = speed * self.left_multiplier

        if adjusted_speed > 0:
            GPIO.output(self.IN1, GPIO.HIGH)
            GPIO.output(self.IN2, GPIO.LOW)
            self.pwm_left.ChangeDutyCycle(abs(adjusted_speed))
        elif adjusted_speed < 0:
            GPIO.output(self.IN1, GPIO.LOW)
            GPIO.output(self.IN2, GPIO.HIGH)
            self.pwm_left.ChangeDutyCycle(abs(adjusted_speed))
        else:
            GPIO.output(self.IN1, GPIO.LOW)
            GPIO.output(self.IN2, GPIO.LOW)
            self.pwm_left.ChangeDutyCycle(0)

    def set_right_track(self, speed):
        """
        Set right track speed and direction
        speed: -100 to 100 (negative = backward, positive = forward)
        """
        # Apply multiplier
        adjusted_speed = speed * self.right_multiplier

        if adjusted_speed > 0:
            GPIO.output(self.IN3, GPIO.HIGH)
            GPIO.output(self.IN4, GPIO.LOW)
            self.pwm_right.ChangeDutyCycle(abs(adjusted_speed))
        elif adjusted_speed < 0:
            GPIO.output(self.IN3, GPIO.LOW)
            GPIO.output(self.IN4, GPIO.HIGH)
            self.pwm_right.ChangeDutyCycle(abs(adjusted_speed))
        else:
            GPIO.output(self.IN3, GPIO.LOW)
            GPIO.output(self.IN4, GPIO.LOW)
            self.pwm_right.ChangeDutyCycle(0)

    def forward(self, speed=50):
        """Move forward at given speed (0-100)"""
        self.set_left_track(speed)
        self.set_right_track(speed)

    def backward(self, speed=50):
        """Move backward at given speed (0-100)"""
        self.set_left_track(-speed)
        self.set_right_track(-speed)

    def pivot_left(self, speed=50):
        """Pivot left - left track backward, right track forward"""
        self.set_left_track(-speed)
        self.set_right_track(speed)

    def pivot_right(self, speed=50):
        """Pivot right - left track forward, right track backward"""
        self.set_left_track(speed)
        self.set_right_track(-speed)

    def turn_left(self, speed=50):
        """Turn left - only right track moves forward, left track stopped"""
        self.set_left_track(0)
        self.set_right_track(speed)

    def turn_right(self, speed=50):
        """Turn right - only left track moves forward, right track stopped"""
        self.set_left_track(speed)
        self.set_right_track(0)

    def arc_left(self, speed=50):
        """Arc left by slowing left track"""
        self.set_left_track(speed * 0.3)
        self.set_right_track(speed)

    def arc_right(self, speed=50):
        """Arc right by slowing right track"""
        self.set_left_track(speed)
        self.set_right_track(speed * 0.3)

    def stop(self):
        """Stop both tracks"""
        self.set_left_track(0)
        self.set_right_track(0)

    def cleanup(self):
        """Cleanup GPIO"""
        self.stop()
        self.pwm_left.stop()
        self.pwm_right.stop()
        GPIO.cleanup()
        print("TankBot cleanup complete")


def main():
    """Demo program - test all movements"""
    bot = TankBot()

    try:
        print("Testing forward...")
        bot.forward(60)
        time.sleep(2)

        print("Testing backward...")
        bot.backward(60)
        time.sleep(2)

        print("Testing pivot left (tank turn)...")
        bot.pivot_left(50)
        time.sleep(1)

        print("Testing pivot right (tank turn)...")
        bot.pivot_right(50)
        time.sleep(1)

        print("Testing turn left (right track only)...")
        bot.turn_left(60)
        time.sleep(2)

        print("Testing turn right (left track only)...")
        bot.turn_right(60)
        time.sleep(2)

        print("Testing arc left...")
        bot.arc_left(60)
        time.sleep(2)

        print("Testing arc right...")
        bot.arc_right(60)
        time.sleep(2)

        print("Stopping...")
        bot.stop()

    except KeyboardInterrupt:
        print("\nInterrupted by user")
    finally:
        bot.cleanup()


if __name__ == "__main__":
    main()
