# Belote Counter - Vision-Based Point Calculator

Automated playing card detection and Belote point calculation using YOLO and OpenCV.

## Installation

Requires Python 3.12+

```bash
uv init
uv add ultralytics opencv-python huggingface-hub
```

## Usage

```bash
uv run python main.py
```

### Keyboard Controls

- **1-4**: Set trump suit (Coeur, Pique, Carreau, Trefle)
- **5**: No trump mode
- **6**: All trump mode
- **R**: Reset score
- **Q**: Quit

## How It Works

1. Select a game mode (1-6)
2. Position playing cards in front of webcam
3. Hold card steady for ~1 second to register
4. Points automatically calculate based on mode
5. Reset with R to start over

## Features

- Real-time card detection via webcam
- Automatic point calculation (Belote rules)
- Visual overlay with detection feedback
- 6 game modes supported

## Project Structure

- `detector.py` - YOLO card detection
- `belote.py` - Point scoring logic
- `stability.py` - Card detection tracking
- `display.py` - OpenCV rendering
- `main.py` - Main application loop
