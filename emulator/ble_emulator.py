#!/usr/bin/env python3
"""
BLE Scale Emulator - Simulates ESP32 Scale as BLE Peripheral
Run this on your laptop to test the Flutter app with real BLE.

Usage:
    pip install bleak bless
    python ble_emulator.py

Controls:
    w <grams>  - Set weight (e.g., "w 500")
    t          - Tare (zero)
    b <level>  - Set battery level (e.g., "b 75")
    s          - Toggle stability
    q          - Quit

Requirements:
    - Windows 10+ / macOS / Linux with Bluetooth adapter
    - bleak and bless Python packages
"""

import sys
import os

# Add user site-packages to path for Windows
user_site = os.path.join(os.environ.get('APPDATA', ''), 'Python', 'Python312', 'site-packages')
if os.path.exists(user_site) and user_site not in sys.path:
    sys.path.insert(0, user_site)

import asyncio
import struct
from typing import Any

try:
    from bless import BlessServer, BlessGATTCharacteristic, GATTCharacteristicProperties, GATTAttributePermissions
except ImportError as e:
    print(f"❌ Missing 'bless' package: {e}")
    print("Install with: pip install bless==0.2.5 bleak==0.21.1")
    sys.exit(1)
    print("❌ Missing 'bless' package. Install with: pip install bless")
    sys.exit(1)

# Match ESP32 firmware UUIDs
SERVICE_UUID = "4a4e0001-6746-4b4e-8164-656e67696e65"
WEIGHT_CHAR_UUID = "4a4e0002-6746-4b4e-8164-656e67696e65"
TARE_CHAR_UUID = "4a4e0003-6746-4b4e-8164-656e67696e65"
CALIBRATE_CHAR_UUID = "4a4e0004-6746-4b4e-8164-656e67696e65"
BATTERY_CHAR_UUID = "4a4e0005-6746-4b4e-8164-656e67696e65"
SETTINGS_CHAR_UUID = "4a4e0006-6746-4b4e-8164-656e67696e65"
STATUS_CHAR_UUID = "4a4e0007-6746-4b4e-8164-656e67696e65"


class ScaleEmulator:
    """Simulates ESP32 Scale behavior."""
    
    def __init__(self):
        self.weight = 0.0           # Current weight in grams
        self.tare_offset = 0.0      # Tare offset
        self.calibration = 1.0      # Calibration factor
        self.battery_level = 85     # Battery percentage
        self.is_stable = True       # Weight stability
        self.unit = 0               # 0=grams, 1=kg, 2=lb, 3=oz
        self.error_code = 0         # 0 = no error
        
    def get_weight_packet(self) -> bytes:
        """Create weight data packet matching ESP32 format."""
        display_weight = (self.weight - self.tare_offset) * self.calibration
        
        # Packet structure: [header(4), weight(4), unit(1), stable(1), battery(1), error(1)]
        packet = struct.pack(
            '<4sfBBBB',
            b'SCLE',                    # Header
            float(display_weight),       # Weight as float32
            self.unit,                   # Unit
            1 if self.is_stable else 0,  # Stability flag
            self.battery_level,          # Battery level
            self.error_code              # Error code
        )
        return packet
    
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
        print(f"📦 Weight set to {self.weight:.1f}g (display: {(self.weight - self.tare_offset) * self.calibration:.1f}g)")


class BLEScaleServer:
    """BLE GATT Server simulating ESP32 Scale."""
    
    def __init__(self):
        self.server: BlessServer = None
        self.scale = ScaleEmulator()
        self.running = False
        
    async def start(self):
        """Start the BLE server."""
        self.server = BlessServer(name="BLE-Scale-Emulator")
        self.server.read_request_func = self.read_request
        self.server.write_request_func = self.write_request
        
        # Add Scale Service
        await self.server.add_new_service(SERVICE_UUID)
        
        # Weight Characteristic (Read + Notify)
        await self.server.add_new_characteristic(
            SERVICE_UUID,
            WEIGHT_CHAR_UUID,
            GATTCharacteristicProperties.read | GATTCharacteristicProperties.notify,
            self.scale.get_weight_packet(),
            GATTAttributePermissions.readable
        )
        
        # Tare Characteristic (Write)
        await self.server.add_new_characteristic(
            SERVICE_UUID,
            TARE_CHAR_UUID,
            GATTCharacteristicProperties.write,
            bytes([0]),
            GATTAttributePermissions.writeable
        )
        
        # Calibrate Characteristic (Write)
        await self.server.add_new_characteristic(
            SERVICE_UUID,
            CALIBRATE_CHAR_UUID,
            GATTCharacteristicProperties.read | GATTCharacteristicProperties.write,
            bytes([0]),
            GATTAttributePermissions.readable | GATTAttributePermissions.writeable
        )
        
        # Battery Characteristic (Read + Notify)
        await self.server.add_new_characteristic(
            SERVICE_UUID,
            BATTERY_CHAR_UUID,
            GATTCharacteristicProperties.read | GATTCharacteristicProperties.notify,
            bytes([self.scale.battery_level]),
            GATTAttributePermissions.readable
        )
        
        # Start advertising
        await self.server.start()
        self.running = True
        print(f"""
╔══════════════════════════════════════════════════════╗
║           BLE Scale Emulator - Running               ║
╠══════════════════════════════════════════════════════╣
║  Device Name: BLE-Scale-Emulator                     ║
║  Service UUID: {SERVICE_UUID}  ║
╠══════════════════════════════════════════════════════╣
║  Commands:                                           ║
║    w <grams>  - Set weight (e.g., w 500)             ║
║    t          - Tare (zero)                          ║
║    b <level>  - Set battery (e.g., b 75)             ║
║    s          - Toggle stability                     ║
║    q          - Quit                                 ║
╚══════════════════════════════════════════════════════╝
""")
        
    async def stop(self):
        """Stop the BLE server."""
        if self.server:
            await self.server.stop()
        self.running = False
        print("\n👋 BLE Emulator stopped")
        
    def read_request(self, characteristic: BlessGATTCharacteristic, **kwargs) -> bytearray:
        """Handle read requests."""
        uuid = str(characteristic.uuid).lower()
        
        if uuid == WEIGHT_CHAR_UUID.lower():
            return bytearray(self.scale.get_weight_packet())
        elif uuid == BATTERY_CHAR_UUID.lower():
            return bytearray([self.scale.battery_level])
            
        return bytearray()
    
    def write_request(self, characteristic: BlessGATTCharacteristic, value: Any, **kwargs):
        """Handle write requests."""
        uuid = str(characteristic.uuid).lower()
        
        if uuid == TARE_CHAR_UUID.lower():
            self.scale.tare()
        elif uuid == CALIBRATE_CHAR_UUID.lower():
            if len(value) >= 5:
                # First byte is command, next 4 are float32 weight
                known_weight = struct.unpack('<f', bytes(value[1:5]))[0]
                self.scale.calibrate(known_weight)
                
    async def notify_weight(self):
        """Send weight notifications."""
        while self.running:
            try:
                if self.server:
                    self.server.update_value(
                        SERVICE_UUID,
                        WEIGHT_CHAR_UUID
                    )
            except Exception:
                pass
            await asyncio.sleep(0.1)  # 10 Hz updates


async def input_handler(server: BLEScaleServer):
    """Handle user input for controlling the emulator."""
    loop = asyncio.get_event_loop()
    
    while server.running:
        try:
            # Read input in a non-blocking way
            line = await loop.run_in_executor(None, sys.stdin.readline)
            line = line.strip().lower()
            
            if not line:
                continue
                
            parts = line.split()
            cmd = parts[0]
            
            if cmd == 'q':
                await server.stop()
                break
            elif cmd == 'w' and len(parts) > 1:
                try:
                    weight = float(parts[1])
                    server.scale.set_weight(weight)
                except ValueError:
                    print("❌ Invalid weight value")
            elif cmd == 't':
                server.scale.tare()
            elif cmd == 'b' and len(parts) > 1:
                try:
                    level = int(parts[1])
                    server.scale.battery_level = max(0, min(100, level))
                    print(f"🔋 Battery set to {server.scale.battery_level}%")
                except ValueError:
                    print("❌ Invalid battery value")
            elif cmd == 's':
                server.scale.is_stable = not server.scale.is_stable
                print(f"📊 Stability: {'Stable' if server.scale.is_stable else 'Unstable'}")
            else:
                print("❓ Unknown command. Use: w, t, b, s, q")
                
        except Exception as e:
            print(f"Error: {e}")


async def main():
    """Main entry point."""
    server = BLEScaleServer()
    
    try:
        await server.start()
        
        # Run notification loop and input handler
        await asyncio.gather(
            server.notify_weight(),
            input_handler(server)
        )
    except KeyboardInterrupt:
        await server.stop()
    except Exception as e:
        print(f"❌ Error: {e}")
        print("\n💡 Make sure Bluetooth is enabled and you have admin/root access.")
        await server.stop()


if __name__ == "__main__":
    print("🚀 Starting BLE Scale Emulator...")
    asyncio.run(main())
