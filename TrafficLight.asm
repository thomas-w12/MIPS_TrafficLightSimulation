.data
    # Light durations (in milliseconds)
    green_duration_ns:  .word 10000
    green_duration_ew:  .word 10000
    yellow_duration_ns: .word 5000
    yellow_duration_ew: .word 5000
    yellow_to_green: .word 2000
    pedestrian_duration: .word 5000
    pedestrian_delay: .word 2000
    
    # Speed limits (in km/h)
    speed_limit_ns:     .word 50
    speed_limit_ew:     .word 50

    # loop repetitions
    loop_repetitions: .word 1

    # Traffic light states
    NS_light: .word 0  # 0=red, 1=green, 2=yellow
    EW_light: .word 1
    next_green_light: .word 0  # Next green light state (0=NS, 1=EW)

    # Button pressed state
    button_pressed: .word 0  # 0=not pressed, 1=pressed
    
    # Messages
    newline: .asciiz "\n"
    north_south_msg: .asciiz "North-South: "
    east_west_msg: .asciiz "East-West: "
    pedestrian_signal_msg: .asciiz "Pedestrian Signal: "
    invalid_input_msg: .asciiz "Invalid input. Please enter Y or N.\n"
    invalid_iterations_msg: .asciiz "Invalid number of iterations. Please enter a value between 1 and 10.\n"
    default_params_msg: .asciiz "Using default parameters.\n"
    adjusted_msg: .asciiz "Parameters:\n"
    adjusted_green_ns: .asciiz "North-South Green Duration (ms): "
    adjusted_green_ew: .asciiz "East-West Green Duration (ms): "
    adjusted_yellow_ns: .asciiz "North-South Yellow Duration (ms): "
    adjusted_yellow_ew: .asciiz "East-West Yellow Duration (ms): "
    adjusted_pedestrian: .asciiz "Pedestrian Crossing Duration (ms): "
    adjusted_speed_ns: .asciiz "Speed Limit (North-South): "
    adjusted_speed_ew: .asciiz "Speed Limit (East-West): "
    adjusted_speed_unit: .asciiz " km/h\n"
    invalid_duration_msg: .asciiz "Invalid duration. Please enter a value greater than 0.\n"

    # Prompt messages
    prompt_start: .asciiz "Start simulation? [Y/N]: "
    prompt_adjust: .asciiz "Do you want to adjust parameters? [Y/N]: "
    prompt_iterations: .asciiz "Enter number of iterations for simulation (1-10): "
    loop_finished_msg: .asciiz "Simulation has run for specified number of iterations.\nRestart simulation [Y/N]: \n"
    prompt_speed_ns: .asciiz "Enter speed limit north-south (km/h, 30-100): "
    prompt_speed_ew: .asciiz "Enter speed limit east-west (km/h, 30-100): "
    invalid_speed_msg: .asciiz "Invalid speed limit. Please enter a value between 30 and 100.\n"
    prompt_green_ns: .asciiz "Enter green duration for north-south road (s, 1-60): "
    prompt_green_ew: .asciiz "Enter green duration for east-west road (s, 1-60): "
    prompt_pedestrian: .asciiz "Enter pedestrian crossing duration (s, 1-60): "
    prompt_button: .asciiz "Do you want to press the button to request a pedestrian crossing? [Y/N]: "

    # Traffic light colors
    red_msg: .asciiz "RED"
    green_msg: .asciiz "GREEN"
    yellow_msg: .asciiz "YELLOW"
    separator: .asciiz " | "

    
.text
.globl main

main:
    # Print start prompt
    li $v0, 4
    la $a0, prompt_start
    syscall
    
    # Get user input
    li $v0, 12
    syscall
    move $t0, $v0
    
    # Print newline
    li $v0, 4
    la $a0, newline
    syscall
    
    # Check if user wants to start
    beq $t0, 'Y', start_simulation
    beq $t0, 'y', start_simulation
    
    # Exit if not Y/y
    li $v0, 10
    syscall

start_simulation:

    li $s0, 0 # initialize loop count
    li $s1, 0 # parameter adjustment flag
    li $s2, 1 # prompt for pedestrian button

    jal func_get_iterations  # Get number of iterations from user
    
    jal func_get_params  # Get parameters from user
    

# simulation loop is the main loop of the program
simulation_loop:

    # if loop has run for the specified number of iterations, go to end
    lw $t0, loop_repetitions
    beq $s0, $t0, end_simulation

    # check if one cycle has completed
    beqz $s2, in_light_cycle # if not, continue with light cycle
    jal func_prompt_pedestrian_button # and ask if user wants to press the button
    li $s2, 0 # reset pedestrian button prompt

    in_light_cycle:
    jal func_display_lights

    # Determine which lights are active and delay accordingly
    lw $t0, NS_light
    beq $t0, 0, ns_red
    beq $t0, 1, ns_green
    beq $t0, 2, ns_yellow        

        
    ns_red:
        lw $t0, EW_light
        beq $t0, 1, ew_green
        beq $t0, 2, ew_yellow
        
        ew_green:
            lw $a0, green_duration_ew
            jal func_delay
            # Change to yellow
            li $t0, 2
            sw $t0, EW_light
            li $t0, 0
            sw $t0, next_green_light # NS is next green light

            j simulation_loop
        
        ew_yellow:
            # check if yellow is before red light or before green light
            lw $t0, next_green_light
            bnez $t0, switch_ew_to_green # if next green light is EW, switch to green


            switch_ew_to_red:
                lw $a0, yellow_duration_ew
                jal func_delay
                # check if button was pressed and turn on pedestrian light
                jal func_pedestrian_crossing_check
                
                beqz $v0, skip_pedestrian_ew_yellow # if pedestrian crossing not requested, continue with yellow light

                # if pedestrian crossing happened, make ns green
                li $t0, 2
                sw $t0, NS_light    # NS goes yellow
                li $t0, 0
                sw $t0, EW_light    # EW stays red
                li $t0, 0 
                sw $t0, next_green_light # NS is next green light
                j simulation_loop


                skip_pedestrian_ew_yellow:
                # Change both lights
                li $t0, 2
                sw $t0, NS_light    # NS goes yellow
                li $t0, 0
                sw $t0, EW_light    # EW goes red
                li $t0, 0
                sw $t0, next_green_light # NS is next green light
                j simulation_loop


            switch_ew_to_green:
                lw $a0, yellow_to_green
                jal func_delay

                li $t0, 1
                sw $t0, EW_light    # EW goes green
                li $t0, 0
                sw $t0, NS_light    # NS goes red
                li $s2, 1 # prompt for pedestrian button 
                # increment loop count: since we start with ns_red and ew_green, we need
                # to increment the loop count here
                addi $s0, $s0, 1
                jal simulation_loop

    ns_green:
        lw $a0, green_duration_ns
        jal func_delay
        # Change to yellow
        li $t0, 2
        sw $t0, NS_light
        li $t0, 1
        sw $t0, next_green_light # EW is next green light
        j simulation_loop

    ns_yellow:
        # check if yellow is before red light or before green light
        lw $t0, next_green_light
        beqz $t0, switch_ns_to_green # if next green light is EW, switch to green

        switch_ns_to_red:
            lw $a0, yellow_duration_ns
            jal func_delay
            # check if button was pressed and turn on pedestrian light
            jal func_pedestrian_crossing_check
            beqz $v0, skip_pedestrian_ns_yellow # if pedestrian crossing not requested, continue with yellow light

            # if pedestrian crossing happened, make ew green
            li $t0, 2
            sw $t0, EW_light    # EW goes yellow
            li $t0, 0
            sw $t0, NS_light    # NS stay red
            li $t0, 1
            sw $t0, next_green_light # EW is next green light
            j simulation_loop

            skip_pedestrian_ns_yellow:
            # Change both lights
            li $t0, 0
            sw $t0, NS_light        # NS goes red
            li $t0, 2
            sw $t0, EW_light        # EW goes yellow
            li $t0, 1
            sw $t0, next_green_light # EW is next green light
            j simulation_loop

        switch_ns_to_green:
            lw $a0, yellow_to_green
            jal func_delay
            li $t0, 1
            sw $t0, NS_light    # NS goes green
            li $t0, 0
            sw $t0, EW_light    # EW goes red
            jal simulation_loop


# Display current light states
func_display_lights:
    # Print North-South light
    li $v0, 4
    la $a0, north_south_msg
    syscall
    
    lw $t0, NS_light
    beq $t0, 0, print_ns_red
    beq $t0, 1, print_ns_green
    beq $t0, 2, print_ns_yellow
    
    print_ns_red:
        la $a0, red_msg
        j print_ns_done
    print_ns_green:
        la $a0, green_msg
        j print_ns_done
    print_ns_yellow:
        la $a0, yellow_msg
    
    print_ns_done:
    li $v0, 4
    syscall
    
    # Print separator
    li $v0, 4
    la $a0, separator
    syscall
    
    # Print East-West light
    li $v0, 4
    la $a0, east_west_msg
    syscall
    
    lw $t0, EW_light
    beq $t0, 0, print_ew_red
    beq $t0, 1, print_ew_green
    beq $t0, 2, print_ew_yellow
    
    print_ew_red:
        la $a0, red_msg
        j print_ew_done
    print_ew_green:
        la $a0, green_msg
        j print_ew_done
    print_ew_yellow:
        la $a0, yellow_msg
    
    print_ew_done:
    li $v0, 4
    syscall
    
    # Print newline
    li $v0, 4
    la $a0, newline
    syscall
    
    jr $ra

# Function to get parameters from user
func_get_params:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    # Prompt for parameter adjustment
    li $v0, 4
    la $a0, prompt_adjust
    syscall
    li $v0, 12
    syscall
    move $t0, $v0
    # Print newline
    li $v0, 4
    la $a0, newline
    syscall

    # Check if user wants to adjust parameters
    beq $t0, 'Y', parameter_adjustment
    beq $t0, 'y', parameter_adjustment
    bnez $s1, print_params # if parameters were already adjusted, print them
    li $v0, 4
    la $a0, default_params_msg
    syscall
    j print_params

    parameter_adjustment:
        jal func_adjust_parameters  # Adjust light durations based on user input

    print_params:
        jal func_print_parameters  # Print adjusted parameters
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Function to get number of iterations from user
func_get_iterations:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    la $a0, prompt_iterations # Prompt message
    li $a1, 1 # Minimum value
    li $a2, 10 # Maximum value
    la $a3, invalid_iterations_msg # Error message
    jal func_validate_input # Validate number of iterations
    sw $v0, loop_repetitions # Store validated input
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# function to adjust light durations
func_adjust_parameters:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    li $s1, 1 # set to 1 to indicate that parameters got modified

    # Get speed limit for north-south road
    la $a0, prompt_speed_ns # Prompt message
    li $a1, 30 # Minimum value (in km/h)
    li $a2, 100 # Maximum value (in km/h)
    la $a3, invalid_speed_msg # Error message
    jal func_validate_input # Validate speed limit for north-south road
    sw $v0, speed_limit_ns # Store validated input

    # Get speed limit for east-west road
    la $a0, prompt_speed_ew # Prompt message
    li $a1, 30 # Minimum value (in km/h)
    li $a2, 100 # Maximum value (in km/h)
    la $a3, invalid_speed_msg # Validate speed limit for east-west road
    jal func_validate_input # Validate speed limit for east-west road
    sw $v0, speed_limit_ew # Store validated input

    # get green duration for north-south road
    la $a0, prompt_green_ns # Prompt message
    li $a1, 1 # Minimum value (in seconds)
    li $a2, 60 # Maximum value (in seconds)
    la $a3, invalid_duration_msg # Error message
    jal func_validate_input # Validate green duration for north-south road
    mul $v0, $v0, 1000 # Convert to milliseconds
    sw $v0, green_duration_ns # Store validated input

    # get green duration for east-west road
    la $a0, prompt_green_ew # Prompt message
    li $a1, 1 # Minimum value (in seconds)
    li $a2, 60 # Maximum value (in seconds)
    la $a3, invalid_duration_msg # Error message
    jal func_validate_input # Validate green duration for east-west road
    mul $v0, $v0, 1000 # Convert to milliseconds
    sw $v0, green_duration_ew # Store validated input

    # get green duration for pedestrian
    la $a0, prompt_pedestrian # Prompt message
    li $a1, 1 # Minimum value (in seconds)
    li $a2, 60 # Maximum value (in seconds)
    la $a3, invalid_duration_msg # Error message
    jal func_validate_input # Validate pedestrian duration
    mul $v0, $v0, 1000 # Convert to milliseconds
    sw $v0, pedestrian_duration # Store validated input

    # Adjust yellow duration based on speed limit
    lw $t0, speed_limit_ns
    li $t1, 100
    mul $t0, $t0, $t1 # speed_limit_ns * 100 ms
    sw $t0, yellow_duration_ns
    lw $t0, speed_limit_ew
    mul $t0, $t0, $t1 # speed_limit_ew * 100 ms
    sw $t0, yellow_duration_ew

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# Print parameters
func_print_parameters:
    li $v0, 4
    la $a0, newline # Print newline
    syscall
    # print green duration for north-south
    li $v0, 4
    la $a0, adjusted_msg
    syscall
    li $v0, 4
    la $a0, adjusted_green_ns
    syscall
    li $v0, 1
    lw $a0, green_duration_ns
    syscall
    li $v0, 4
    la $a0, newline # Print newline
    syscall
    # print green duration for east-west
    li $v0, 4
    la $a0, adjusted_green_ew
    syscall
    li $v0, 1
    lw $a0, green_duration_ew
    syscall
    li $v0, 4
    la $a0, newline # Print newline
    syscall
    # print yellow duration for north-south
    li $v0, 4
    la $a0, adjusted_yellow_ns
    syscall
    li $v0, 1
    lw $a0, yellow_duration_ns
    syscall
    li $v0, 4
    la $a0, newline # Print newline
    # print yellow duration for east-west
    syscall
    li $v0, 4
    la $a0, adjusted_yellow_ew
    syscall
    li $v0, 1
    lw $a0, yellow_duration_ew
    syscall
    li $v0, 4
    la $a0, newline # Print newline
    syscall
    # print pedestrian duration
    li $v0, 4
    la $a0, adjusted_pedestrian
    syscall
    li $v0, 1
    lw $a0, pedestrian_duration
    syscall
    li $v0, 4
    la $a0, newline # Print newline
    syscall
    # print speed limit for north-south
    li $v0, 4
    la $a0, adjusted_speed_ns
    syscall
    li $v0, 1
    lw $a0, speed_limit_ns
    syscall
    li $v0, 4
    la $a0, adjusted_speed_unit
    syscall
    # print speed limit for east-west
    li $v0, 4
    la $a0, adjusted_speed_ew
    syscall
    li $v0, 1
    lw $a0, speed_limit_ew
    syscall
    li $v0, 4
    la $a0, adjusted_speed_unit
    syscall

    li $v0, 4
    la $a0, newline # Print newline
    syscall

    jr $ra

func_prompt_pedestrian_button:
    li $v0, 4
    la $a0, prompt_button
    syscall
    li $v0, 12 #
    syscall
    move $t0, $v0
    # Print newline
    li $v0, 4
    la $a0, newline
    syscall

    # Check if user pressed the button
    beq $t0, 'Y', set_button_state
    beq $t0, 'y', set_button_state
    # If not pressed, continue with the simulation
    jr $ra

    set_button_state:
    # Set button pressed state
    li $t0, 1
    sw $t0, button_pressed
    jr $ra


# function to check button pressed state and change light states
func_pedestrian_crossing_check:
    # save $ra
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    lw $t0, button_pressed
    beqz $t0, no_button_pressed

    # If button pressed, turn both lights red and print pedestrian light state
    li $t0, 0
    sw $t0, NS_light        # NS goes red
    sw $t0, EW_light        # EW goes red
    jal func_display_lights

    lw $a0, pedestrian_delay
    jal func_delay

    # Print pedestrian light state
    li $v0, 4
    la $a0, pedestrian_signal_msg
    syscall
    la $a0, green_msg
    syscall
    la $a0, newline
    syscall


    # Delay for pedestrian crossing
    lw $a0, pedestrian_duration
    jal func_delay

    # Change pedestrian light to red
    li $t0, 0
    sw $t0, button_pressed  # Reset button pressed state
    
    li $v0, 4
    la $a0, pedestrian_signal_msg
    syscall
    la $a0, red_msg
    syscall
    la $a0, newline
    syscall

    # Delay for pedestrian crossing
    lw $a0, pedestrian_delay
    jal func_delay

    # restore $ra
    lw $ra, 0($sp)
    addi $sp, $sp, 4

    # return that pedestrian crossing occured
    li $v0, 1
    jr $ra

    no_button_pressed:
    # If button not pressed, just return
    li $v0, 0
    jr $ra


# Delay subroutine
func_delay:
    move $t0, $a0  # Save duration
    li $v0, 30      # Get system time
    syscall
    move $t1, $a0   # Save start time
    
    delay_loop:
        li $v0, 30      # Get current time
        syscall
        sub $t2, $a0, $t1  # Calculate elapsed time
        blt $t2, $t0, delay_loop  # Loop if elapsed < duration
        jr $ra

# Function to validate user input within a range
# Arguments:
#   $a0 - Prompt message address
#   $a1 - Minimum valid value
#   $a2 - Maximum valid value
#   $a3 - Error message address
# Returns:
#   $v0 - Validated user input
func_validate_input:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    add $t2, $zero, $a0  # Copy prompt message address to $t2

    validate_input_loop:
        # Print the prompt message
        li $v0, 4
        la $a0, ($t2)
        syscall

        # Get user input
        li $v0, 5
        syscall
        move $t0, $v0  # Save user input

        # Validate input (check if input >= min)
        move $t1, $a1  # Minimum value
        blt $t0, $t1, invalid_input

        # Validate input (check if input <= max)
        move $t1, $a2  # Maximum value
        bgt $t0, $t1, invalid_input

        # Input is valid, return it
        move $v0, $t0
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra

    invalid_input:
        # Print the error message
        li $v0, 4
        la $a0, ($a3)
        syscall

        # Loop back to prompt
        j validate_input_loop


# End of simulation
end_simulation: 
    # display lights a last time
    jal func_display_lights

    li $v0, 4
    la $a0, loop_finished_msg
    syscall
    
    # Prompt for restart
    li $v0, 12
    syscall
    move $t0, $v0
    # Print newline
    li $v0, 4
    la $a0, newline
    syscall

    # Check if user wants to restart
    beq $t0, 'Y', start_simulation
    beq $t0, 'y', start_simulation
    
    # Exit if not Y/y
    li $v0, 10
    syscall
