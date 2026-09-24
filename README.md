# TextForge

TextForge is a lightweight Bash CLI that renders large multi-line ASCII banners directly in the terminal. It is built for quick, dependency-free text rendering and supports multiple fonts, colors, alignment, and simple installation.

## Features

- Pure Bash implementation
- Multiple built-in fonts
- ANSI color support
- Adjustable alignment, width, and spacing
- Simple install and uninstall workflow
- Works from any directory once installed

## Requirements

- Bash 4+
- A Unix-like environment
- Standard shell utilities already present on most Linux systems

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/MichaelAcostaDev/TextForge.git
cd TextForge
```

### 2. Install TextForge

```bash
./install.sh
```

### 3. Make sure the executable is on your PATH

If `textforge` is not found in your current shell, run:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then verify the installation:

```bash
textforge --help
textforge --version
```

## Usage

### Basic banner

```bash
textforge "Hello"
```

### Choose a font

```bash
textforge -f block "Hello"
textforge -f digital "Hello"
textforge -f banner "Hello"
textforge -f small "Hello"
```

### List available fonts

```bash
textforge --list-fonts
textforge -l
```

### View available colors

```bash
textforge --colors
```

### Disable ANSI colors

```bash
textforge --no-color "Hello"
```

### Show help and version

```bash
textforge --help
textforge --version
textforge -v
```

## Uninstall

```bash
./uninstall.sh
```

This removes the installed TextForge executable and its shared resource directory under `$HOME/.local/share/textforge`.

## Project Structure

```text
TextForge/
├── src/
├── fonts/
├── tests/
├── textforge
├── install.sh
├── uninstall.sh
├── README.md
├── LICENSE
├── .gitignore
└── .git/
```

## License

This project is licensed under the [MIT License](LICENSE).

## Author

Michael Acosta / [@MichaelAcostaDev](https://github.com/MichaelAcostaDev)
