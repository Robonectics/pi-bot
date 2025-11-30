# Pi-Bot Tank Robot Controller

A web-based controller for a tank-style robot using Raspberry Pi and L298N motor driver.

## Features

- 🎮 **Web Interface**: Control your robot from any device on your network
- 📱 **Mobile Friendly**: Responsive design works on phones and tablets
- ⌨️ **Keyboard Support**: WASD/Arrow keys for desktop control
- 🎯 **Multiple Movement Modes**: Forward, backward, pivot turns, arc turns
- ⚡ **Adjustable Speed**: Real-time speed control from 30-100%
- 🔧 **Configurable**: Easy setup via `.env` file
- 🚀 **Auto-start**: Optional systemd service for boot-time startup

## Quick Start

1. **Setup Virtual Environment**:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

2. **Configure Settings**:
   ```bash
   cp .env.example .env
   nano .env  # Adjust settings if needed
   ```

3. **Run the Web Server**:
   ```bash
   sudo venv/bin/python3 pibotweb.py
   ```

4. **Access the Interface**:
   - On Pi: `http://localhost:5000`
   - On network: `http://[PI_IP]:5000`

For detailed setup instructions, see [SETUP.md](SETUP.md).

## Hardware Requirements

- Raspberry Pi (any model with GPIO)
- L298N motor driver module
- 4 DC motors (3-6V) - 2 per tank track
- 6-12V power supply for motors
- Tank chassis with tracks

## Wiring

See [wiring.md](wiring.md) for complete wiring diagrams and instructions.

**Quick Reference:**

| L298N | Raspberry Pi | Function |
|-------|-------------|----------|
| ENA | GPIO12 (Pin 32) | Left track speed (PWM) |
| IN1 | GPIO17 (Pin 11) | Left track direction |
| IN2 | GPIO27 (Pin 13) | Left track direction |
| ENB | GPIO13 (Pin 33) | Right track speed (PWM) |
| IN3 | GPIO22 (Pin 15) | Right track direction |
| IN4 | GPIO23 (Pin 16) | Right track direction |
| GND | GND | Common ground |

**Important**: Wire the 2 motors on each track in **parallel**, not series!

## Files

- `pibot.py` - Core robot control library with TankBot class
- `pibotweb.py` - Flask web server with control interface
- `wiring.md` - Complete hardware wiring guide
- `SETUP.md` - Detailed setup and installation instructions
- `requirements.txt` - Python dependencies
- `.env` - Configuration file (create from `.env.example`)

## Control Modes

### Web Interface Buttons

- **↑ Forward**: Both tracks forward
- **↓ Backward**: Both tracks backward
- **← Left**: Pivot left (spin in place)
- **→ Right**: Pivot right (spin in place)
- **↖ Forward-Left**: Arc turn left while moving forward
- **↗ Forward-Right**: Arc turn right while moving forward
- **↙ Backward-Left**: Arc turn left while reversing
- **↘ Backward-Right**: Arc turn right while reversing
- **⬛ STOP**: Emergency stop

### Keyboard Controls

- `W` or `↑` - Forward
- `S` or `↓` - Backward
- `A` or `←` - Pivot left
- `D` or `→` - Pivot right
- `Q` - Arc forward-left
- `E` - Arc forward-right
- `Z` - Arc backward-left
- `C` - Arc backward-right
- `Space` - Stop

### Python API

```python
from pibot import TankBot

bot = TankBot()

# Basic movement
bot.forward(60)      # 60% speed
bot.backward(50)
bot.stop()

# Turning
bot.pivot_left(50)   # Spin in place
bot.pivot_right(50)
bot.turn_left(60)    # Wide turn (one track stopped)
bot.turn_right(60)
bot.arc_left(70)     # Gentle arc (one track slower)
bot.arc_right(70)

# Manual control
bot.set_left_track(80)   # -100 to 100
bot.set_right_track(-60)

# Cleanup
bot.cleanup()
```

## Configuration

Edit `.env` to customize:

```bash
# Server
HOST=0.0.0.0        # Listen on all interfaces
PORT=5000           # Web server port
DEBUG=False         # Enable debug mode

# Speed limits
MIN_SPEED=30        # Minimum speed %
MAX_SPEED=100       # Maximum speed %
DEFAULT_SPEED=60    # Starting speed %

# Motor calibration (if one track is faster)
LEFT_TRACK_MULTIPLIER=1.0
RIGHT_TRACK_MULTIPLIER=1.0

# GPIO pins (BCM numbering)
PIN_ENA=12
PIN_IN1=17
# ... see .env.example for all options
```

## Running as a Service

To auto-start on boot:

```bash
sudo nano /etc/systemd/system/pibot.service
# Copy service configuration from SETUP.md

sudo systemctl daemon-reload
sudo systemctl enable pibot.service
sudo systemctl start pibot.service
```

## Troubleshooting

### Motors don't respond
- Verify wiring matches `wiring.md`
- Check common ground between Pi and L298N
- Ensure motors are wired in parallel, not series
- Run with sudo: `sudo venv/bin/python3 pibotweb.py`

### One motor spins faster
- Adjust multipliers in `.env`:
  ```
  LEFT_TRACK_MULTIPLIER=0.9   # Slow down left track
  RIGHT_TRACK_MULTIPLIER=1.0
  ```

### Can't access from phone
- Check firewall: `sudo ufw allow 5000`
- Verify Pi and phone on same WiFi network
- Use Pi's IP address, not `localhost`
- Ensure `HOST=0.0.0.0` in `.env`

### Permission denied errors
- Must run with `sudo` for GPIO access
- Use: `sudo venv/bin/python3 pibotweb.py`

See [SETUP.md](SETUP.md) for more troubleshooting tips.

## Development

### Test without hardware

```python
# Mock GPIO in pibot.py for testing
# Run without sudo on any computer
python3 pibotweb.py
```

### Adding new movements

Edit `pibot.py` to add methods:

```python
def custom_move(self, speed=50):
    """Your custom movement"""
    self.set_left_track(speed * 0.5)
    self.set_right_track(speed)
```

Then add API endpoint in `pibotweb.py`:

```python
elif action == 'custom':
    bot.custom_move(speed)
    command = f"Custom move at {speed}%"
```

## Safety

- Always have a way to quickly stop the robot
- Test at low speeds first
- Ensure adequate motor driver cooling
- Use proper wire gauge for motor current
- Never run debug mode on public networks
- Add emergency stop button if needed

## License

This project is open source. Feel free to modify and improve!

## Contributing

Suggestions and improvements welcome! Areas for enhancement:
- Video streaming from Pi Camera
- Autonomous navigation
- Ultrasonic sensor integration
- Battery voltage monitoring
- Speed telemetry
- Multiple robot support

## Credits

Built with:
- Flask - Web framework
- RPi.GPIO - Raspberry Pi GPIO control
- L298N - Dual H-Bridge motor driver

## Support

For issues and questions:
1. Check [SETUP.md](SETUP.md) troubleshooting section
2. Review [wiring.md](wiring.md) for connection issues
3. Verify `.env` configuration
4. Test basic functionality with `pibot.py` demo

---

**Happy Robot Building! 🤖**
