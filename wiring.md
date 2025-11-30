# Pi-Bot Wiring Guide

## Overview

This tank robot has **4 motors total**: 2 motors per track (left and right). The L298N motor driver has 2 channels (Motor A and Motor B), so we wire the 2 motors on each track in **parallel** to share one channel.

## Why Parallel Wiring?

**Parallel wiring for motors on the same track:**
- ✅ Both motors get full voltage (6V each from 6V supply)
- ✅ Both motors run at the same speed
- ✅ Combined torque (more power)
- ✅ Current is shared between motors
- ✅ L298N can handle up to 2A per channel

**Never use series wiring:**
- ❌ Each motor only gets half voltage (3V each)
- ❌ Weak/slow performance
- ❌ Unequal motor characteristics cause one to dominate
- ❌ One motor will spin fast, the other barely moves

## Motor Connections

### LEFT TRACK (Motor A - Channel 1)

Connect both left track motors in parallel:

```
L298N OUT1 ----+----> Left Motor 1 (+)
               |
               +----> Left Motor 2 (+)

L298N OUT2 ----+----> Left Motor 1 (-)
               |
               +----> Left Motor 2 (-)
```

### RIGHT TRACK (Motor B - Channel 2)

Connect both right track motors in parallel:

```
L298N OUT3 ----+----> Right Motor 1 (+)
               |
               +----> Right Motor 2 (+)

L298N OUT4 ----+----> Right Motor 1 (-)
               |
               +----> Right Motor 2 (-)
```

## Complete L298N Wiring Diagram

```
┌─────────────────────────────────────┐
│         L298N Motor Driver          │
├─────────────────────────────────────┤
│                                     │
│  Power Input:                       │
│  ┌───┐  12V ← Battery/Supply (+)   │
│  │   │  GND ← Battery/Supply (-)   │
│  └───┘  5V  → (Optional, not used) │
│                                     │
│  Motor A (Left Track):              │
│  ┌───┐  OUT1 → Left Motors (+)     │
│  │   │  OUT2 → Left Motors (-)     │
│  └───┘                              │
│                                     │
│  Motor B (Right Track):             │
│  ┌───┐  OUT3 → Right Motors (+)    │
│  │   │  OUT4 → Right Motors (-)    │
│  └───┘                              │
│                                     │
│  Logic Control:                     │
│  ENA → Pi GPIO12 (Pin 32) PWM      │
│  IN1 → Pi GPIO17 (Pin 11)          │
│  IN2 → Pi GPIO27 (Pin 13)          │
│  ENB → Pi GPIO13 (Pin 33) PWM      │
│  IN3 → Pi GPIO22 (Pin 15)          │
│  IN4 → Pi GPIO23 (Pin 16)          │
│  GND → Pi GND (CRITICAL!)          │
│                                     │
└─────────────────────────────────────┘
```

## Raspberry Pi 3B Complete Pinout with L298N Connections

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        Raspberry Pi 3B GPIO Header                           │
│                             (40-Pin Layout)                                  │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│                        3.3V      [1]  [2]   5V                               │
│                        GPIO2     [3]  [4]   5V                               │
│                        GPIO3     [5]  [6]   GND → L298N GND (CRITICAL!)      │
│                        GPIO4     [7]  [8]   GPIO14                           │
│                        GND       [9]  [10]  GPIO15                           │
│  L298N IN1 (Left Dir)  → GPIO17 [11]  [12]  GPIO18                           │
│  L298N IN2 (Left Dir)  → GPIO27 [13]  [14]  GND                              │
│  L298N IN3 (Right Dir) → GPIO22 [15]  [16]  GPIO23 → L298N IN4 (Right Dir)   │
│                        3.3V     [17]  [18]  GPIO24                           │
│                        GPIO10   [19]  [20]  GND                              │
│                        GPIO9    [21]  [22]  GPIO25                           │
│                        GPIO11   [23]  [24]  GPIO8                            │
│                        GND      [25]  [26]  GPIO7                            │
│                        ID_SD    [27]  [28]  ID_SC                            │
│                        GPIO5    [29]  [30]  GND     5                         │
│                        GPIO6    [31]  [32]  GPIO12 → L298N ENA (Left PWM)    │
│  L298N ENB (Right PWM) → GPIO13 [33]  [34]  GND                              │
│                        GPIO19   [35]  [36]  GPIO16                           │
│                        GPIO26   [37]  [38]  GPIO20                           │
│                        GND      [39]  [40]  GPIO21                           │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘

     ┌─────────────────────────────────────────────┐
     │  Pin Layout (view from top of Pi board)   │
     │  USB ports facing you, GPIO on top edge    │
     └─────────────────────────────────────────────┘

Note: Pin numbering is physical pin position (1-40).
      Odd pins (1,3,5...) are on the LEFT column.
      Even pins (2,4,6...) are on the RIGHT column.
      Arrows (→) indicate pins connected to L298N.
```

## L298N Motor Driver Pinout

```
┌─────────────────────────────────────────────────────────────┐
│                   L298N Motor Driver Module                 │
│                      (Top View Layout)                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  POWER INPUT (Screw Terminals):                            │
│  ┌──────────────┐                                          │
│  │ +12V  GND  5V │  ← 12V: Motor power (+6-12V)           │
│  └──────────────┘     GND: Power ground                    │
│                       5V: 5V output (if jumper enabled)    │
│                                                             │
│  MOTOR A OUTPUT (Screw Terminals):                         │
│  ┌────────┐                                                │
│  │ OUT1  OUT2 │  ← To LEFT track motors (in parallel)     │
│  └────────┘                                                │
│                                                             │
│  MOTOR B OUTPUT (Screw Terminals):                         │
│  ┌────────┐                                                │
│  │ OUT3  OUT4 │  ← To RIGHT track motors (in parallel)    │
│  └────────┘                                                │
│                                                             │
│  CONTROL INPUTS (Pin Headers):                             │
│  ┌────────────────────────────────┐                        │
│  │ ENA  IN1  IN2  IN3  IN4  ENB  │                        │
│  └────────────────────────────────┘                        │
│    │    │    │    │    │    │                             │
│    │    │    │    │    │    └─→ Pi GPIO13 (Pin 33)       │
│    │    │    │    │    └──────→ Pi GPIO23 (Pin 16)       │
│    │    │    │    └───────────→ Pi GPIO22 (Pin 15)       │
│    │    │    └────────────────→ Pi GPIO27 (Pin 13)       │
│    │    └─────────────────────→ Pi GPIO17 (Pin 11)       │
│    └──────────────────────────→ Pi GPIO12 (Pin 32)       │
│                                                             │
│  GROUND (Pin Header):                                      │
│  ┌─────┐                                                   │
│  │ GND │ ← MUST connect to Pi GND (Pin 6, 9, 14, etc.)   │
│  └─────┘                                                   │
│                                                             │
│  JUMPERS:                                                  │
│  [ENA] [ENB] - Remove these to enable PWM speed control   │
│  [5V Enable] - Optional: enables 5V output regulator      │
│                                                             │
└─────────────────────────────────────────────────────────────┘

         ┌──────────────────────────────────────┐
         │  L298N Pin Functions                │
         └──────────────────────────────────────┘

  MOTOR A (Left Track):
  • ENA  - Enable/Speed (PWM from Pi GPIO12)
  • IN1  - Direction control 1 (from Pi GPIO17)
  • IN2  - Direction control 2 (from Pi GPIO27)
  • OUT1 - Motor A output (+)
  • OUT2 - Motor A output (-)

  MOTOR B (Right Track):
  • ENB  - Enable/Speed (PWM from Pi GPIO13)
  • IN3  - Direction control 1 (from Pi GPIO22)
  • IN4  - Direction control 2 (from Pi GPIO23)
  • OUT3 - Motor B output (+)
  • OUT4 - Motor B output (-)

  Direction Control Logic:
  IN1=HIGH, IN2=LOW  → Motor A forward
  IN1=LOW,  IN2=HIGH → Motor A backward
  IN1=LOW,  IN2=LOW  → Motor A brake

  IN3=HIGH, IN4=LOW  → Motor B forward
  IN3=LOW,  IN4=HIGH → Motor B backward
  IN3=LOW,  IN4=LOW  → Motor B brake
```

## Complete Wiring Connection Summary

| L298N Pin | Pi GPIO | Pi Physical Pin | Function              |
|-----------|---------|-----------------|------------------------|
| ENA       | GPIO12  | Pin 32          | Left track PWM speed   |
| IN1       | GPIO17  | Pin 11          | Left track direction   |
| IN2       | GPIO27  | Pin 13          | Left track direction   |
| ENB       | GPIO13  | Pin 33          | Right track PWM speed  |
| IN3       | GPIO22  | Pin 15          | Right track direction  |
| IN4       | GPIO23  | Pin 16          | Right track direction  |
| GND       | GND     | Pin 6 (or any)  | Common ground          |

## Power Supply

**Motor Power:**
- Voltage: 6-12V DC (use 6V for 3-6V motors, up to 12V for higher voltage motors)
- Connect to L298N `12V` and `GND` terminals
- Recommended: 6-12V battery pack or power supply

**Raspberry Pi Power:**
- Power the Pi **separately** via USB-C or GPIO 5V pin
- Do NOT power the Pi from the motor supply
- The Pi draws significant current - keep it isolated from motor power

**Common Ground:**
- Connect L298N GND to Raspberry Pi GND
- This is **CRITICAL** for proper logic level communication
- Without common ground, control signals won't work correctly

## Physical Assembly Tips

**For Parallel Motor Connections:**

1. **Wire Nuts**: Quick and easy for prototyping
2. **Terminal Blocks**: More secure, easy to disconnect
3. **Solder + Heat Shrink**: Most reliable for permanent installation
4. **Breadboard/Protoboard**: Good for testing

**Polarity Check:**
- Ensure both motors on the same track have **consistent polarity**
- Both red wires → OUT1/OUT3
- Both black wires → OUT2/OUT4
- This ensures they rotate in the same direction

## L298N Configuration

**Important Settings:**

1. **Remove ENA/ENB Jumpers**: The L298N usually comes with jumpers on ENA and ENB. **Remove these** to enable PWM speed control from the Pi.

2. **5V Regulator Jumper**: If present, you can leave this on (it powers the L298N logic), but don't use it to power the Pi.

## Current Considerations

**L298N Specifications:**
- Maximum current: 2A per channel (4A peak)
- With 2 motors per channel, each motor should draw < 1A
- The L298N has built-in protection but can get hot

**Check Your Motors:**
- Measure stall current (maximum current draw)
- If motors draw > 1A each, consider:
  - Using lower PWM speeds
  - Adding heatsinks to L298N
  - Upgrading to a higher current driver (BTS7960, VNH5019, etc.)

## Testing Procedure

1. **Power off everything** before making connections
2. **Double-check all wiring** - wrong connections can damage components
3. **Test at low speed first** (30-50% PWM)
4. **Verify both motors on each track spin the same direction**
5. **Check for heating** on the L298N - some warmth is normal, but it shouldn't be too hot to touch

## Troubleshooting

| Problem | Solution |
|---------|----------|
| One motor spins faster than the other | Normal - compensate in software by adjusting PWM |
| Motors barely move | Check parallel wiring, increase PWM, check power supply voltage |
| L298N gets very hot | Reduce speed, add heatsink, or upgrade driver |
| Motors spin opposite directions on same track | Swap polarity of one motor (swap + and -) |
| No motor movement | Check common ground connection, verify GPIO pins |
| Erratic behavior | Check power supply current capacity, add capacitors across motor terminals |

## Safety Notes

- Never hot-swap motor connections while powered
- Use appropriate wire gauge (20-22 AWG recommended)
- Add fuses to protect against shorts
- Disconnect power before modifying wiring
- Keep wiring neat to avoid shorts

## Optional Improvements

1. **Flyback Diodes**: L298N has built-in protection, but external diodes can help
2. **Capacitors**: 0.1μF ceramic caps across motor terminals reduce electrical noise
3. **Heatsink**: Adhesive heatsink for L298N if running at high currents
4. **Power Switch**: In-line switch for easy power control
5. **Voltage Monitor**: Display or LED to monitor battery voltage
