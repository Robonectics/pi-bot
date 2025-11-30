#!/usr/bin/env python3
"""
Pi-Bot Web Controller
Web interface for controlling tank robot via L298N motor driver
"""

from flask import Flask, render_template_string, jsonify, request
from pibot import TankBot
from dotenv import load_dotenv
import threading
import time
import os

# Load environment variables from .env file
load_dotenv()

# Configuration from environment
HOST = os.getenv('HOST', '0.0.0.0')
PORT = int(os.getenv('PORT', 5000))
DEBUG = os.getenv('DEBUG', 'False').lower() == 'true'
MIN_SPEED = int(os.getenv('MIN_SPEED', 30))
MAX_SPEED = int(os.getenv('MAX_SPEED', 100))
DEFAULT_SPEED = int(os.getenv('DEFAULT_SPEED', 60))

app = Flask(__name__)
bot = None
command_lock = threading.Lock()

# HTML template for the control interface
HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Pi-Bot Controller</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #1a1a1a;
            color: #fff;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            padding: 20px;
            box-sizing: border-box;
        }

        .container {
            text-align: center;
            max-width: 500px;
            width: 100%;
        }

        h1 {
            margin-bottom: 30px;
            color: #4CAF50;
        }

        .controls {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 10px;
            max-width: 400px;
            margin: 0 auto;
        }

        .btn {
            background-color: #333;
            border: 2px solid #4CAF50;
            color: white;
            padding: 0;
            font-size: 18px;
            cursor: pointer;
            border-radius: 10px;
            transition: all 0.1s;
            user-select: none;
            -webkit-user-select: none;
            -moz-user-select: none;
            aspect-ratio: 1;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 80px;
        }

        .btn:active {
            background-color: #4CAF50;
            transform: scale(0.95);
        }

        .btn:disabled {
            opacity: 0.3;
            cursor: not-allowed;
        }

        .btn-forward {
            grid-column: 2;
            grid-row: 1;
        }

        .btn-left {
            grid-column: 1;
            grid-row: 2;
        }

        .btn-stop {
            grid-column: 2;
            grid-row: 2;
            background-color: #d32f2f;
            border-color: #f44336;
        }

        .btn-stop:active {
            background-color: #f44336;
        }

        .btn-right {
            grid-column: 3;
            grid-row: 2;
        }

        .btn-backward {
            grid-column: 2;
            grid-row: 3;
        }

        .btn-forward-left {
            grid-column: 1;
            grid-row: 1;
        }

        .btn-forward-right {
            grid-column: 3;
            grid-row: 1;
        }

        .btn-backward-left {
            grid-column: 1;
            grid-row: 3;
        }

        .btn-backward-right {
            grid-column: 3;
            grid-row: 3;
        }

        .status {
            margin-top: 30px;
            padding: 15px;
            background-color: #333;
            border-radius: 5px;
            font-size: 14px;
        }

        .speed-control {
            margin-top: 20px;
            padding: 15px;
            background-color: #333;
            border-radius: 5px;
        }

        .speed-control input {
            width: 100%;
            max-width: 300px;
        }

        .speed-value {
            color: #4CAF50;
            font-weight: bold;
            font-size: 18px;
        }

        @media (max-width: 480px) {
            .btn {
                font-size: 14px;
                min-height: 60px;
            }

            h1 {
                font-size: 24px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🤖 Pi-Bot Controller</h1>

        <div class="speed-control">
            <label for="speed">Speed: <span class="speed-value" id="speedValue">{{ default_speed }}</span>%</label><br>
            <input type="range" id="speed" min="{{ min_speed }}" max="{{ max_speed }}" value="{{ default_speed }}" step="10">
        </div>

        <br>

        <div class="controls">
            <button class="btn btn-forward-left" data-action="forward-left">↖</button>
            <button class="btn btn-forward" data-action="forward">↑<br>Forward</button>
            <button class="btn btn-forward-right" data-action="forward-right">↗</button>

            <button class="btn btn-left" data-action="left">←<br>Left</button>
            <button class="btn btn-stop" data-action="stop">⬛<br>STOP</button>
            <button class="btn btn-right" data-action="right">→<br>Right</button>

            <button class="btn btn-backward-left" data-action="backward-left">↙</button>
            <button class="btn btn-backward" data-action="backward">↓<br>Backward</button>
            <button class="btn btn-backward-right" data-action="backward-right">↘</button>
        </div>

        <div class="status">
            <div>Status: <span id="status">Ready</span></div>
            <div>Last Command: <span id="lastCommand">None</span></div>
        </div>
    </div>

    <script>
        const speedSlider = document.getElementById('speed');
        const speedValue = document.getElementById('speedValue');
        const statusEl = document.getElementById('status');
        const lastCommandEl = document.getElementById('lastCommand');
        const buttons = document.querySelectorAll('.btn');

        // Update speed display
        speedSlider.addEventListener('input', function() {
            speedValue.textContent = this.value;
        });

        // Handle button presses
        buttons.forEach(button => {
            // Mouse/touch start
            button.addEventListener('mousedown', handlePress);
            button.addEventListener('touchstart', handlePress);

            // Mouse/touch end
            button.addEventListener('mouseup', handleRelease);
            button.addEventListener('touchend', handleRelease);
            button.addEventListener('mouseleave', handleRelease);
        });

        function handlePress(e) {
            e.preventDefault();
            const action = e.currentTarget.dataset.action;
            const speed = speedSlider.value;

            if (action === 'stop') {
                sendCommand('stop');
            } else {
                sendCommand(action, speed);
            }
        }

        function handleRelease(e) {
            e.preventDefault();
            const action = e.currentTarget.dataset.action;

            // Don't auto-stop on stop button release
            if (action !== 'stop') {
                sendCommand('stop');
            }
        }

        function sendCommand(action, speed = 0) {
            fetch('/api/control', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    action: action,
                    speed: parseInt(speed)
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.status === 'ok') {
                    statusEl.textContent = 'Connected';
                    statusEl.style.color = '#4CAF50';
                    lastCommandEl.textContent = data.command;
                } else {
                    statusEl.textContent = 'Error: ' + data.message;
                    statusEl.style.color = '#f44336';
                }
            })
            .catch(error => {
                statusEl.textContent = 'Connection Error';
                statusEl.style.color = '#f44336';
                console.error('Error:', error);
            });
        }

        // Keyboard controls
        const keyMap = {
            'w': 'forward',
            'ArrowUp': 'forward',
            's': 'backward',
            'ArrowDown': 'backward',
            'a': 'left',
            'ArrowLeft': 'left',
            'd': 'right',
            'ArrowRight': 'right',
            'q': 'forward-left',
            'e': 'forward-right',
            'z': 'backward-left',
            'c': 'backward-right',
            ' ': 'stop'
        };

        const activeKeys = new Set();

        document.addEventListener('keydown', (e) => {
            if (keyMap[e.key] && !activeKeys.has(e.key)) {
                activeKeys.add(e.key);
                const speed = speedSlider.value;
                sendCommand(keyMap[e.key], speed);
            }
        });

        document.addEventListener('keyup', (e) => {
            if (keyMap[e.key]) {
                activeKeys.delete(e.key);
                if (e.key !== ' ') {  // Don't auto-stop on spacebar release
                    sendCommand('stop');
                }
            }
        });
    </script>
</body>
</html>
"""

@app.route('/')
def index():
    """Serve the main control page"""
    return render_template_string(
        HTML_TEMPLATE,
        min_speed=MIN_SPEED,
        max_speed=MAX_SPEED,
        default_speed=DEFAULT_SPEED
    )

@app.route('/api/control', methods=['POST'])
def control():
    """Handle control commands from the web interface"""
    global bot

    try:
        data = request.get_json()
        action = data.get('action')
        speed = data.get('speed', 60)

        with command_lock:
            if action == 'forward':
                bot.forward(speed)
                command = f"Forward at {speed}%"

            elif action == 'backward':
                bot.backward(speed)
                command = f"Backward at {speed}%"

            elif action == 'left':
                bot.pivot_left(speed)
                command = f"Pivot left at {speed}%"

            elif action == 'right':
                bot.pivot_right(speed)
                command = f"Pivot right at {speed}%"

            elif action == 'forward-left':
                bot.arc_left(speed)
                command = f"Arc forward-left at {speed}%"

            elif action == 'forward-right':
                bot.arc_right(speed)
                command = f"Arc forward-right at {speed}%"

            elif action == 'backward-left':
                # Backward while turning left
                bot.set_left_track(-speed * 0.3)
                bot.set_right_track(-speed)
                command = f"Arc backward-left at {speed}%"

            elif action == 'backward-right':
                # Backward while turning right
                bot.set_left_track(-speed)
                bot.set_right_track(-speed * 0.3)
                command = f"Arc backward-right at {speed}%"

            elif action == 'stop':
                bot.stop()
                command = "Stopped"

            else:
                return jsonify({'status': 'error', 'message': 'Unknown action'}), 400

        return jsonify({'status': 'ok', 'command': command})

    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/status', methods=['GET'])
def status():
    """Get current status"""
    return jsonify({'status': 'ok', 'message': 'Pi-Bot is ready'})

def main():
    """Start the web server"""
    global bot

    print("Initializing TankBot...")
    bot = TankBot()

    print("\nPi-Bot Web Controller")
    print("=" * 50)
    print(f"Starting web server on http://{HOST}:{PORT}")
    print("Access from your browser or phone on the same network")
    print(f"Speed range: {MIN_SPEED}% - {MAX_SPEED}%")
    print(f"Default speed: {DEFAULT_SPEED}%")
    print(f"Debug mode: {DEBUG}")
    print("Press Ctrl+C to stop")
    print("=" * 50)

    try:
        app.run(host=HOST, port=PORT, debug=DEBUG, threaded=True)
    except KeyboardInterrupt:
        print("\n\nShutting down...")
    finally:
        if bot:
            bot.cleanup()

if __name__ == "__main__":
    main()
