# Image Processing(Filter, upscale) System

## Overview
This project implements a VGA display system with image processing capabilities using an OV7670 camera module and a FPGA. The system supports a variety of image processing features such as filtering, upscaling, and manipulation of RGB values, and displays the processed image on a VGA monitor. The project is designed for FPGA-based hardware development.

## Features:
- VGA signal generation for displaying images on a monitor
- Interface with OV7670 camera for capturing images
- Image processing capabilities such as RGB to grayscale conversion, filtering, and contrast adjustments
- Support for upscaling, brightening, and darkening images
- Control via switches and buttons to manipulate display settings and image processing modes

## Modules

### 1. VGA_Test Module
This is the top-level module that integrates all components for VGA display and image processing.

#### Inputs:
- `clk`: Clock input signal
- `reset`: Reset signal
- `sw`: Switch inputs for various settings
- `btn`: Button inputs for interaction
- Camera signals: `ov7670_pclk`, `ov7670_href`, `ov7670_v_sync`, and `ov7670_data`

#### Outputs:
- `scl`, `sda`: Signals for camera communication
- `ov7670_xclk`: Camera clock signal
- `h_sync`, `v_sync`: VGA sync signals
- `red_port`, `green_port`, `blue_port`: RGB color signals for VGA display

#### Sub-modules:
- `clk_wiz_0`: Clock generator for the VGA and camera clocks
- `camera_configure`: Configures the OV7670 camera module via SCCB protocol
- `vga_controller`: Controls VGA signal generation
- `frameBuffer`: Handles frame buffer for storing and reading image data
- `ov7670_SetData`: Interface for the OV7670 camera data
- `ISP`: Image signal processing module

### 2. mux (Multiplexer)
A simple 2-input multiplexer module that selects between two 12-bit RGB color inputs based on a select signal.

#### Inputs:
- `sel`: Select signal for choosing between two inputs
- `x0`, `x1`: Two 12-bit RGB inputs

#### Output:
- `y`: Output 12-bit RGB signal

### 3. mux_4x1 (4-Input Multiplexer)
A 4-input multiplexer that selects among four 12-bit RGB color inputs based on a 2-bit select signal.

#### Inputs:
- `sel`: 2-bit select signal for choosing between four inputs
- `x0`, `x1`, `x2`, `x3`: Four 12-bit RGB inputs

#### Output:
- `y`: Output 12-bit RGB signal

### 4. ISP (Image Signal Processing)
This module processes image data by upscaling, filtering, and converting to grayscale, along with applying other image manipulations based on the input control signals.

#### Inputs:
- `clk`, `reset`: Clock and reset signals
- `x_pixel`, `y_pixel`: Current pixel coordinates
- `h_sync`, `v_sync`: VGA sync signals
- `btn`, `sw`: Button and switch inputs for user control
- `disp_enable`: Enable signal for display
- `buffer`: Input buffer with the image data

#### Outputs:
- `o_RGB`: Output RGB color data for VGA display
- `qvga_addr`: Address for the QVGA buffer
- `qvga_en`: Enable signal for QVGA resolution

### 5. filter (Image Filter)
This module applies different types of filters (e.g., Gaussian, Sobel, average, brightening, darkening) to the image data.

#### Inputs:
- `clk`, `reset`: Clock and reset signals
- `x_pixel`, `y_pixel`: Current pixel coordinates
- `sw`: Switch inputs for selecting filter type
- `buffer`: Input 12-bit RGB color buffer
- `disp_enable`: Enable signal for display

#### Output:
- `o_RGB`: Output 12-bit RGB color data for the display

### 6. RGB to Red, Green, Blue
These modules extract individual color components (Red, Green, Blue) from an RGB color input.

#### Inputs:
- `RGB_Color`: Input 12-bit RGB color data

#### Outputs:
- `Red_Color`, `Green_Color`, `Blue_Color`: Output 12-bit color components

### 7. bright_mode (Brightness Adjustment)
This module adjusts the brightness of an RGB color input based on a switch control.

#### Inputs:
- `RGB_Color`: Input 12-bit RGB color data
- `bright_sw`: Switch input controlling the brightness level

#### Output:
- `bright_Color`: Output 12-bit RGB color with adjusted brightness

### 8. dark_mode (Darkness Adjustment)
This module adjusts the darkness (reduction in intensity) of an RGB color input based on a switch control.

#### Inputs:
- `RGB_Color`: Input 12-bit RGB color data
- `dark_sw`: Switch input controlling the darkness level

#### Output:
- `dark_Color`: Output 12-bit RGB color with reduced intensity

## Usage

### FPGA Setup
- Load the Verilog files into your FPGA development environment.
- Connect the OV7670 camera module to the appropriate pins on the FPGA.
- Connect the VGA display to the corresponding output pins.
- Use the switches and buttons for controlling the display modes and image processing features.

### Controls
- **Buttons**: Control various operations such as zoom, image manipulation (brighten, darken), and switching modes.
- **Switches**: Select between different image filters or effects (grayscale, Gaussian, Sobel, etc.).

## Dependencies
- **FPGA Development Board**: Compatible with Verilog and supports VGA and camera interfacing.
- **OV7670 Camera Module**: For capturing images.
- **VGA Monitor**: For displaying processed images.

- **Interactivity**: Develop more advanced interactive features using additional buttons or external controllers.

## License
This project is licensed under the MIT License.
