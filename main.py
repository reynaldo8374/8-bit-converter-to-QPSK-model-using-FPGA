import matplotlib.pyplot as plt
import numpy as np
from matplotlib.animation import FuncAnimation
import serial
import time

class SerialVisualizer:
    def __init__(self, port=None, baudrate=9600):
        self.port = port
        self.baudrate = baudrate
        self.serial_conn = None
        self.data_buffer = []
        self.bit_buffer = []
        self.max_points = 1000
        
        # Setup plot
        self.fig, self.ax = plt.subplots(figsize=(15, 8))
        self.ax.set_xlim(0, self.max_points)
        self.ax.set_ylim(-150, 150)
        self.ax.set_xlabel('Sample')
        self.ax.set_ylabel('Amplitude')
        self.ax.set_title('FPGA Serial Output Visualization (8-bit Binary to Analog)')
        self.ax.grid(True, alpha=0.3)
        self.ax.set_facecolor('black')
        
        # Gunakan scatter plot (titik) bukan line plot (garis)
        self.scatter = None  # Akan diinisialisasi di plot_static
        
    def binary_to_signed(self, binary_str):
        """Konversi 8-bit binary string ke signed integer (-128 to 127)"""
        # Convert binary to unsigned integer
        unsigned_val = int(binary_str, 2)
        # Convert to signed 8-bit
        if unsigned_val > 127:
            return unsigned_val - 256
        else:
            return unsigned_val
    
    def process_binary_data(self, data_string):
        """Process binary data string menjadi array analog values"""
        # Split by spaces dan clean
        binary_values = data_string.strip().split()
        analog_values = []
        
        for binary_str in binary_values:
            if len(binary_str) == 8 and all(c in '01' for c in binary_str):
                signed_val = self.binary_to_signed(binary_str)
                analog_values.append(signed_val)
        
        return analog_values
    
    def add_data(self, data_string):
        """Tambah data ke buffer"""
        analog_values = self.process_binary_data(data_string)
        self.data_buffer.extend(analog_values)
        
        # Batasi buffer size
        if len(self.data_buffer) > self.max_points:
            self.data_buffer = self.data_buffer[-self.max_points:]
        
        print(f"Added {len(analog_values)} data points")
        return len(analog_values)
    
    def plot_static(self):
        """Plot static dari data yang ada menggunakan titik (scatter plot)"""
        if self.data_buffer:
            x_data = list(range(len(self.data_buffer)))
            
            # Clear previous scatter plot if exists
            if self.scatter:
                self.scatter.remove()
            
            # Create new scatter plot with points
            self.scatter = self.ax.scatter(
                x_data, 
                self.data_buffer, 
                color='lime', 
                s=15,  # Ukuran titik
                alpha=0.8  # Transparansi
            )
            
            self.ax.set_xlim(0, len(self.data_buffer))
            self.ax.set_ylim(min(self.data_buffer)-5, max(self.data_buffer)+5)
            plt.draw()
            plt.show()
        else:
            print("No data to plot")
    
    def clear_buffer(self):
        """Clear data buffer"""
        self.data_buffer = []
        print("Buffer cleared")
    
    def save_plot(self, filename):
        """Simpan plot ke file"""
        if self.data_buffer:
            plt.savefig(filename, dpi=300, bbox_inches='tight', facecolor='black')
            print(f"Plot saved as {filename}")
    
    def print_stats(self):
        """Print statistik data"""
        if self.data_buffer:
            print(f"Total samples: {len(self.data_buffer)}")
            print(f"Min value: {min(self.data_buffer)}")
            print(f"Max value: {max(self.data_buffer)}")
            print(f"Mean value: {np.mean(self.data_buffer):.2f}")

# Plot data langsung
if __name__ == "__main__":
    # Data dari FPGA
    fpga_data = """00000000 00010110 00010101 00010011 00010001 00001111 00001101 00001011 
00001001 00000111 00000101 00000010 00000000 11111110 11111100 11111001 
11110111 11110101 11110011 11110001 11101111 11101101 11101011 11101010 
11101000 11100111 11100101 11100100 11100011 11100010 11100001 11100001 
11100000 11100000 11011111 11011111 11100000 11100000 11100000 11100001 
11100010 11100010 11100011 11100101 11100110 11100111 11101001 11101010 
11101100 11101110 11110000 11110010 11110100 11110110 11111000 11111010 
11111101 11111111 00000001 00000011 00000110 00001000 00001010 00001100 
00001110 00010000 00010010 00010100 00010101 00010111 00011000 00011010 
00011011 00011100 00011101 00011110 00011110 00011111 00011111 00100000 
00100000 00011111 00011111 00011111 00011110 00011101 00011101 00011100 
00011010 00011001 00011000 00010110 00010101 00010011 00010001 00001111 
00001101 00001011 00001001 00000111 00000101 00000010 00000000 11111110 
11111100 11111001 11110111 11110101 11110011 11110001 11101111 11101101 
11101011 11101010 11101000 11100111 11100101 11100100 11100011 11100010 
11100001 11100001 11100000 11100000 11011111 11011111 11100000 11100000 
11100000 11100001 11100010 11100010 11100011 11100101 11100110 11100111 
11101001 11101010 11101100 11101110 11110000 11110010 11110100 11110110 
11111000 11111010 11111101 11111111 00000001 00000011 00000110 00001000 
00001010 00001100 00001110 00010000 00010010 00010100 00010101 00010111 
00011000 00011010 00011011 00011100 00011101 00011110 00011110 00011111 
00011111 00100000 00100000 00011111 00011111 00011111 00011110 00011101 
00011101 00011100 00011010 00011001 00011000 00010110 00010101 00010011 
00010001 00001111 00001101 00001011 00001001 00000111 00000101 00000010 
00000000 11111110 11111100 11111001 11110111 11110101 11110011 11110001 
11101111 11101101 11101011 11101010 11101000 11100111 11100101 11100100 
11100011 11100010 11100001 11100001 11100000 11100000 11011111 11011111 
11100000 11100000 11100000 11100001 11100010 11100010 11100011 11100101 
11100110 11100111 11101001 11101010 11101100 11101110 11110000 11110010 
11110100 11110110 11111000 11111010 11111101 11111111 00000001 00000011 
00000110 00001000 00001010 00001100 00001110 00010000 00010010 00010100 
00010101 00010111 00011000 00011010 00011011 00011100 00011101 00011110 
00011110 00011111 00011111 00100000 00100000 00011111 00011111 00011111 
00011110 00011101 00011101 00011100 00011010 00011001 00011000 00010110 
00010101 00010011 00010001 00001111 00001101 00001011 00001001 00000111 
00000101 00000010 00000000 11111110 11111100 11111001 11110111 11110101 
11110011 11110001 11101111 11101101 11101011 11101010 11101000 11100111 
11100101 11100100 11100011 11100010 11100001 11100001 11100000 11100000 
11011111 11011111 11100000 11100000 11100000 11100001 11100010 11100010 
11100011 11100101 11100110 11100111 11101001 11101010 11101100 11101110 
11110000 11110010 11110100 11110110 11111000 11111010 11111101 11111111 
00000001 00000011 00000110 00001000 00001010 00001100 00001110 00010000 
00010010 00010100 00010101 00010111 00011000 00011010 00011011 00011100 
00011101 00011110 00011110 00011111 00011111 00100000 00100000 00011111 
00011111 00011111 00011110 00011101 00011101 00011100 00011010"""
    
    # Buat visualizer dan plot
    viz = SerialVisualizer()
    
    print("FPGA Data Visualization")
    print("=" * 50)
    
    # Process dan plot data
    count = viz.add_data(fpga_data)
    viz.print_stats()
    
    print("\nPlotting data...")
    viz.plot_static()
    
    # Option untuk save
    save_option = input("\nSave plot? (y/n): ")
    if save_option.lower() == 'y':
        filename = input("Filename (default: fpga_output.png): ") or "fpga_output.png"
        viz.save_plot(filename)