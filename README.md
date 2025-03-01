# Snake Game on NIOS II (Gecko4Education Board)

## Overview
This project is an implementation of the classic **Snake Game** coded entirely in **NIOS II Assembly** on a **Gecko4Education Board**. The game is displayed using the board's LEDs, where the snake navigates the grid to eat randomly generated food. If the snake collides with the edges or itself, the game is over.

The project also involves custom hardware configuration using **VHDL**, setting up the RAM, ROM, CPU, and other essential units to support the game logic.

## Features
1. **Snake Gameplay**
   - The snake is displayed using the board's LEDs.
   - Food is randomly generated on the map.
   - The snake grows when it eats the food.
   - Game over occurs when the snake hits the edges or itself.

2. **Hardware Configuration**
   - Custom hardware setup using VHDL to support:
     - RAM and ROM modules
     - NIOS II CPU
     - Necessary peripheral units for the game logic

## Getting Started
1. **Prerequisites**
   - Gecko4Education Board
   - Quartus II for VHDL compilation and hardware configuration
   - NIOS II IDE or relevant assembly development environment

2. **Setting up the Board**
   - Ensure the Gecko4Education Board is connected and powered.
   - Compile the VHDL configuration files using Quartus II.
   - Upload the compiled configuration to the board.

3. **Loading the Game**
   - Compile the NIOS II Assembly code.
   - Load the compiled game into the board’s ROM.
   - Start the game using the reset/start button on the board.

## Controls
- Use the designated buttons on the Gecko4Education Board to control the direction of the snake.
- Navigate carefully to avoid hitting the edges or the snake itself.

## Game Rules
- Eat the food to grow longer.
- Avoid hitting the edges or the snake's own body.
- The game ends upon collision, displaying a game-over sequence using the LEDs.

