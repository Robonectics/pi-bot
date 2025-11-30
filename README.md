# Pi-Bot Tank Robot Controller

A web-based controller for a tank-style robot using Raspberry Pi and L298N motor driver.

## Install

### Option 1: Pi already has internet

```bash
curl -sSL https://raw.githubusercontent.com/Robonectics/pi-bot/main/install.sh | sudo bash
```

### Option 2: Use phone hotspot (DroidAir)

If your Pi isn't online yet, use your phone as a hotspot named "DroidAir":

```bash
curl -sSL https://raw.githubusercontent.com/Robonectics/pi-bot/main/install-via-droidair.sh -o install.sh
sudo bash install.sh <your-hotspot-password>
```

### Custom WiFi name/password

```bash
curl -sSL https://raw.githubusercontent.com/Robonectics/pi-bot/main/install.sh | sudo bash -s -- MyBot mypassword
```

### After install

Connect to the **PiBot** WiFi (password: `pibot1234`) and open `http://192.168.4.1:5000`

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
   sudo venv/bin/python3 src/pibotweb.py
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

## Project Structure

```
pi-bot/
├── src/
│   ├── pibot.py          # Core robot control library
│   ├── pibotweb.py       # Flask web server
│   └── test_motor.py     # Motor testing script
├── scripts/
│   ├── setup-ap-mode.sh      # Configure WiFi AP mode
│   ├── disable-ap-mode.sh    # Restore WiFi client mode
│   ├── network-status.sh     # Show network status
│   ├── install-service.sh    # Install systemd service
│   └── uninstall-service.sh  # Remove systemd service
├── install.sh            # One-line installer (curl | bash)
├── install-via-droidair.sh  # Install via phone hotspot
├── README.md
├── SETUP.md
├── wiring.md
├── requirements.txt
└── .env                  # Configuration (create from .env.example)
```

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

To auto-start Pi-Bot on boot:

```bash
sudo ./scripts/install-service.sh
```

This installs a systemd service that:
- Starts automatically on boot
- Waits for network (works with AP mode or normal WiFi)
- Auto-restarts on failure

Service commands:
```bash
sudo systemctl status pibot    # Check status
sudo systemctl stop pibot      # Stop
sudo systemctl restart pibot   # Restart
sudo journalctl -u pibot -f    # View logs
sudo ./scripts/uninstall-service.sh    # Remove service
```

## Troubleshooting

### Motors don't respond
- Verify wiring matches `wiring.md`
- Check common ground between Pi and L298N
- Ensure motors are wired in parallel, not series
- Run with sudo: `sudo venv/bin/python3 src/pibotweb.py`

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
- Use: `sudo venv/bin/python3 src/pibotweb.py`

See [SETUP.md](SETUP.md) for more troubleshooting tips.

## Development

### Test without hardware

```python
# Mock GPIO in src/pibot.py for testing
# Run without sudo on any computer
python3 src/pibotweb.py
```

### Adding new movements

Edit `src/pibot.py` to add methods:

```python
def custom_move(self, speed=50):
    """Your custom movement"""
    self.set_left_track(speed * 0.5)
    self.set_right_track(speed)
```

Then add API endpoint in `src/pibotweb.py`:

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
4. Test basic functionality with `src/pibot.py` demo

---

**Happy Robot Building! 🤖**
