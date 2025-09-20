import math

def generate_sine_wave():
    values = []
    for i in range(256):
        # Angle from 0 to 2π
        angle = (2 * math.pi * i) / 256
        # Sine value in range [-1, 1]
        sine_val = math.sin(angle)
        # Scale to [0, 255]
        scaled_val = int((sine_val + 1) * 127.5)
        values.append(scaled_val)
    return values

def format_c_array(values, name="sine_table"):
    lines = []
    lines.append(f"const uint8_t {name}[256] = {{")
    for i in range(0, 256, 16):  # 16 values per line
        chunk = ", ".join(f"{v:3d}" for v in values[i:i+16])
        lines.append("    " + chunk + ",")
    lines.append("};")
    return "\n".join(lines)

if __name__ == "__main__":
    sine_wave = generate_sine_wave()

    # Print Python list (optional)
    print("Python List:")
    print(sine_wave)

    print("\nC Lookup Table:")
    print(format_c_array(sine_wave))