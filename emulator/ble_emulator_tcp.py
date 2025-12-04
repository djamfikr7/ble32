#!/usr/bin/env python3
"""
BLE Scale Emulator (TCP/WebSocket Mode)
Simulates ESP32 Scale - Flutter app connects via WebSocket.

Usage:
    python ble_emulator_tcp.py

Controls:
    w <grams>  - Set weight (e.g., "w 500")
    t          - Tare (zero)
    b <level>  - Set battery level (e.g., "b 75")
    s          - Toggle stability
    q          - Quit

The Flutter app connects to ws://localhost:8765
"""

import asyncio
import json
import struct
import sys
import threading

try:
    import websockets
except ImportError:
    print("Installing websockets...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "websockets"])
    import websockets


class ScaleEmulator:
    """Simulates ESP32 Scale behavior."""
    
    def __init__(self):
        self.weight = 0.0           # Current weight in grams
        self.tare_offset = 0.0      # Tare offset
        self.calibration = 1.0      # Calibration factor
        self.battery_level = 85     # Battery percentage
        self.is_stable = True       # Weight stability
        self.unit = "g"             # Unit: g, kg, lb, oz
        self.error_code = 0         # 0 = no error
        self.clients = set()        # Connected WebSocket clients
        
    def get_display_weight(self) -> float:
        """Get weight after tare and calibration."""
        return (self.weight - self.tare_offset) * self.calibration
        
    def to_json(self) -> str:
        """Create JSON data packet."""
        return json.dumps({
            "type": "weight",
            "weight": round(self.get_display_weight(), 1),
            "raw_weight": round(self.weight, 1),
            "unit": self.unit,
            "stable": self.is_stable,
            "battery": self.battery_level,
            "error": self.error_code
        })
    
    def tare(self):
        """Zero the scale."""
        self.tare_offset = self.weight
        print(f"⚖️  Tared at {self.weight:.1f}g")
        
    def calibrate(self, known_weight: float):
        """Calibrate with known weight."""
        if self.weight > 10:
            self.calibration = known_weight / self.weight
            print(f"🔧 Calibrated: factor = {self.calibration:.4f}")
        else:
            print("⚠️  Cannot calibrate: weight too low")
            
    def set_weight(self, grams: float):
        """Set simulated weight."""
        self.weight = max(0, grams)
        display = self.get_display_weight()
        print(f"📦 Weight: {self.weight:.1f}g → Display: {display:.1f}g")


# Global emulator instance
scale = ScaleEmulator()


async def handler(websocket):
    """Handle WebSocket connections."""
    scale.clients.add(websocket)
    client_addr = websocket.remote_address
    print(f"📱 Client connected: {client_addr}")
    
    try:
        async for message in websocket:
            try:
                data = json.loads(message)
                cmd = data.get("command", "")
                
                if cmd == "tare":
                    scale.tare()
                elif cmd == "calibrate":
                    scale.calibrate(data.get("weight", 100))
                elif cmd == "set_weight":
                    scale.set_weight(data.get("weight", 0))
                    
                # Send acknowledgment
                await websocket.send(scale.to_json())
                
            except json.JSONDecodeError:
                pass
                
    except websockets.exceptions.ConnectionClosed:
        pass
    finally:
        scale.clients.discard(websocket)
        print(f"📱 Client disconnected: {client_addr}")


async def broadcast_weight():
    """Send weight updates to all connected clients."""
    while True:
        if scale.clients:
            message = scale.to_json()
            await asyncio.gather(
                *[client.send(message) for client in scale.clients],
                return_exceptions=True
            )
        await asyncio.sleep(0.1)  # 10 Hz updates


def input_thread():
    """Handle user input in separate thread."""
    print("""
╔══════════════════════════════════════════════════════╗
║         BLE Scale Emulator (WebSocket Mode)          ║
╠══════════════════════════════════════════════════════╣
║  Server: ws://localhost:8765                         ║
╠══════════════════════════════════════════════════════╣
║  Commands:                                           ║
║    w <grams>  - Set weight (e.g., w 500)             ║
║    t          - Tare (zero)                          ║
║    b <level>  - Set battery (e.g., b 75)             ║
║    s          - Toggle stability                     ║
║    q          - Quit                                 ║
╚══════════════════════════════════════════════════════╝
""")
    
    while True:
        try:
            line = input("> ").strip().lower()
            if not line:
                continue
                
            parts = line.split()
            cmd = parts[0]
            
            if cmd == 'q':
                print("\n👋 Shutting down...")
                import os
                os._exit(0)
            elif cmd == 'w' and len(parts) > 1:
                try:
                    weight = float(parts[1])
                    scale.set_weight(weight)
                except ValueError:
                    print("❌ Invalid weight value")
            elif cmd == 't':
                scale.tare()
            elif cmd == 'b' and len(parts) > 1:
                try:
                    level = int(parts[1])
                    scale.battery_level = max(0, min(100, level))
                    print(f"🔋 Battery: {scale.battery_level}%")
                except ValueError:
                    print("❌ Invalid battery value")
            elif cmd == 's':
                scale.is_stable = not scale.is_stable
                print(f"📊 Stability: {'Stable' if scale.is_stable else 'Unstable'}")
            else:
                print("❓ Commands: w <grams>, t, b <level>, s, q")
                
        except EOFError:
            break
        except Exception as e:
            print(f"Error: {e}")


async def main():
    """Main entry point."""
    # Start input handler in background thread
    threading.Thread(target=input_thread, daemon=True).start()
    
    # Start WebSocket server
    print("🚀 Starting WebSocket server on ws://localhost:8765")
    
    async with websockets.serve(handler, "0.0.0.0", 8765):
        await broadcast_weight()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n👋 Bye!")
