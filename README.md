# Welcome to the "Mini Super Mario Demo Assembly 8088" Repository!

This project brings back the classic Super Mario game on the Intel 8088 processor using assembly language. It's a simple demonstration of Mario's adventure on a single screen, featuring obstacles, enemies, and an end goal.

## Highlights:

- **Assembly Language:** The entire game is coded in assembly language for the Intel 8088 processor, showcasing low-level programming skills.
- **Single-Screen Gameplay:** Unlike the original game, this demo focuses on a single-screen level, challenging you to reach the end goal without side-scrolling.
- **Educational:** This project aims to educate and inspire assembly language enthusiasts and retro computing fans.

**Note:** This is a demo, not a full game, designed to teach assembly programming.

## Getting Started:

To run the 8088 Super Mario Demo, you'll need an Intel 8088 emulator or compatible vintage computer. Assemble and load the provided source code, and you're ready to guide Mario through this single-screen adventure.

## Instructions to Run '8088 Super Mario Demo' in DOSBox

**Note: For the best experience, use Dosbox Daum or Dosbox Enhanced and set cycles to 9999999.**

### Build:
To build the binary file from the assembly source code, you'll need NASM (Netwide Assembler). On the command prompt run the following command:

`nasm main.asm -o main.com`


This command will compile `main.asm` and produce the `main.com` binary file.

### Run:
To run this produced binary file, navigate to the folder containing the `main.com` binary. Then, simply type:

`main.com`


The Super Mario demo should start, and you can enjoy the classic gaming experience on the vintage hardware.

Feel free to explore the assembly code and make changes to `main.asm` to further customize the demo.


## Contributions:

Feedback and contributions are welcome! If you find bugs or have suggestions, submit a pull request. Let's improve this demo together and celebrate the charm of assembly language programming.

Thank you for visiting "Mini Super Mario Demo Assembly 8088" Enjoy the simple pleasure of Super Mario on classic hardware!
