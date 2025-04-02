.data
    # Light durations (in milliseconds)
    green_duration_ns:  .word 10000
    green_duration_ew:  .word 10000
    yellow_duration_ns: .word 3000
    yellow_duration_ew: .word 3000
    pedestrian_duration: .word 5000
    
    # Speed limits (in km/h)
    speed_limit_ns:     .word 50
    speed_limit_ew:     .word 50

    # loop repetitions
    loop_repetitions: .word 5
    
    # Messages
    newline: .asciiz "\n"
    north_south_msg: .asciiz "North-South: "
    east_west_msg: .asciiz "East-West: "
    invalid_input_msg: .asciiz "Invalid input. Please enter Y or N.\n"
    invalid_iterations_msg: .asciiz "Invalid number of iterations. Please enter a value between 1 and 10.\n"
    default_params_msg: .asciiz "Using default parameters.\n"
    adjusted_msg: .asciiz "Parameters:\n"
    adjusted_green_ns: .asciiz "North-South Green Duration (ms): "
    adjusted_green_ew: .asciiz "East-West Green Duration (ms): "
    adjusted_yellow_ns: .asciiz "North-South Yellow Duration (ms): "
    adjusted_yellow_ew: .asciiz "East-West Yellow Duration (ms): "
    adjusted_speed: .asciiz "Speed Limit (North-South): "
    adjusted_speed_value: .asciiz " km/h\n"
    invalid_duration_msg: .asciiz "Invalid duration. Please enter a value greater than 0.\n"

    # Prompt messages
    prompt_start: .asciiz "Start simulation? [Y/N]: "
    prompt_adjust: .asciiz "Do you want to adjust parameters? [Y/N]: "
    prompt_iterations: .asciiz "Enter number of iterations for simulation (1-10): "
    loop_finished_msg: .asciiz "Simulation has run for specified number of iterations.\nRestart simulation [Y/N]: \n"
    prompt_speed_ns: .asciiz "Enter speed limit north-south (km/h, 30-100): "
    prompt_speed_ew: .asciiz "Enter speed limit east-west (km/h, 30-100): "
    invalid_speed_msg: .asciiz "Invalid speed limit. Please enter a value between 30 and 100.\n"
    prompt_green_ns: .asciiz "Enter green duration for north-south road (s): "
    prompt_green_ew: .asciiz "Enter green duration for east-west road (s): "
    prompt_button: .asciiz "Do you want to press the button to request a pedestrian crossing? [Y/N]: "

    
    # Traffic light colors
    red_msg: .asciiz "RED"
    green_msg: .asciiz "GREEN"
    yellow_msg: .asciiz "YELLOW"
    separator: .asciiz " | "

    # Pedestrian light states
    pedestrian_red_msg: .asciiz "Pedestrian RED"
    pedestrian_green_msg: .asciiz "Pedestrian GREEN"
    
    # Traffic light states
    NS_light: .word 0  # 0=red, 1=green, 2=yellow
    EW_light: .word 1  # Opposite of NS
    # Button pressed state
    button_pressed: .word 0  # 0=not pressed, 1=pressed
    
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

    # Prompt for number of iterations
    li $v0, 4
    la $a0, prompt_iterations
    syscall
    li $v0, 5
    syscall
    # sll $v0, $v0, 2  # Multiply by 4 to represent actual repetitions
    sw $v0, loop_repetitions

    # Validate iterations
    lw $t0, loop_repetitions
    li $t1, 1
    blt $t0, $t1, invalid_iterations
    li $t1, 10
    bgt $t0, $t1, invalid_iterations
    j number_of_iterations_input_done
    invalid_iterations:
        li $v0, 4
        la $a0, invalid_iterations_msg
        syscall
        j start_simulation
    

    number_of_iterations_input_done:

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
    li $v0, 4
    la $a0, default_params_msg
    syscall
    j print_params

    parameter_adjustment:
        jal adjust_parameters  # Adjust light durations based on user input

    print_params:
        jal print_parameters  # Print adjusted parameters
    
    # Initialize light states
    li $t0, 0
    sw $t0, NS_light        # NS starts with red
    li $t0, 1
    sw $t0, EW_light        # EW starts with green
    
    # initialize loop count
    li $s0, 0

simulation_loop:

    # Display current light states
    jal display_lights

    # if loop has run for the specified number of iterations, go to end
    lw $t0, loop_repetitions
    beq $s0, $t0, end_simulation

    # # check if one cycle has completed
    # srl $t1, $s0, 2
    # li $t2, 4
    # div $t1, $t2
    # mfhi $t3 # check if remainder is 0
    # bnez $t3, increment_loop


    # li $v0, 4
    # la $a0, prompt_button
    # syscall
    # li $v0, 12 #
    # syscall
    # move $t0, $v0
    # # Print newline
    # li $v0, 4
    # la $a0, newline
    # syscall

    # # Check if user pressed the button
    # bne $t0, 'Y', increment_loop
    # bne $t0, 'y', increment_loop
    # # If not pressed, continue with the simulation

    # # Set button pressed state
    # li $t0, 1
    # sw $t0, button_pressed



    increment_loop:
    # increment loop count
    # addi $s0, $s0, 1

    
    
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
        jal delay
        # Change to yellow
        li $t0, 2
        sw $t0, EW_light
        j simulation_loop
    
    ew_yellow:
        lw $a0, yellow_duration_ew
        jal delay

        # check if button was pressed and turn on pedestrian light
        # jal pedestrian_crossing_check

        # Change both lights
        li $t0, 1
        sw $t0, NS_light    # NS goes green
        li $t0, 0
        sw $t0, EW_light    # EW goes red
        j simulation_loop

ns_green:
    lw $a0, green_duration_ns
    jal delay
    # Change to yellow
    li $t0, 2
    sw $t0, NS_light
    j simulation_loop

ns_yellow:
    lw $a0, yellow_duration_ns
    jal delay
    # Change both lights
    li $t0, 0
    sw $t0, NS_light        # NS goes red
    li $t0, 1
    sw $t0, EW_light        # EW goes green

    # increment loop count
    addi $s0, $s0, 1

    j simulation_loop

# Display current light states
display_lights:
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


# function to adjust light durations
adjust_parameters:

    # Get speed limit for north-south road
    speed_adjustment_ns:
        # Get speed limit from user
        li $v0, 4
        la $a0, prompt_speed_ns
        syscall
        
        li $v0, 5
        syscall
        sw $v0, speed_limit_ns

        # validate speed limit
        lw $t0, speed_limit_ns
        li $t1, 30
        blt $t0, $t1, invalid_speed_ns
        li $t1, 100
        bgt $t0, $t1, invalid_speed_ns
        j speed_adjustment_ew

        invalid_speed_ns:
        # Print invalid speed message
            li $v0, 4
            la $a0, invalid_speed_msg
            syscall
            j speed_adjustment_ns

    # Get speed limit for east-west road
    speed_adjustment_ew:
        # Get speed limit from user
        li $v0, 4
        la $a0, prompt_speed_ew
        syscall
        
        li $v0, 5
        syscall
        sw $v0, speed_limit_ew

        # validate speed limit
        lw $t0, speed_limit_ew
        li $t1, 30
        blt $t0, $t1, invalid_speed_ew
        li $t1, 100
        bgt $t0, $t1, invalid_speed_ew
        j light_duration_adjustments

        invalid_speed_ew:
        # Print invalid speed message
            li $v0, 4
            la $a0, invalid_speed_msg
            syscall
            j speed_adjustment_ew

    light_duration_adjustments: 

        light_duration_adjustment_ns:
        # get green duration for north-south road
        li $v0, 4
        la $a0, prompt_green_ns
        syscall
        li $v0, 5
        syscall
        bnez $v0, valid_duration_ns
        li $v0, 4
        la $a0, invalid_duration_msg
        syscall
        j light_duration_adjustment_ns

        valid_duration_ns:
            mul $v0, $v0, 1000  # convert to milliseconds
            sw $v0, green_duration_ns
            # get green duration for east-west road

        light_duration_adjustment_ew:
        li $v0, 4
        la $a0, prompt_green_ew
        syscall
        li $v0, 5
        syscall
        bnez $v0, valid_duration_ew
        li $v0, 4
        la $a0, invalid_duration_msg
        syscall
        j light_duration_adjustment_ew
        valid_duration_ew:
            mul $v0, $v0, 1000  # convert to milliseconds
            sw $v0, green_duration_ew

        # # adjust yellow duration in percentage of green duration (25%)
        # lw $t0, green_duration_ns
        # srl $t0, $t0, 2  # divide by 4
        # bge $t0, 2000, set_yellow_ns # if yellow duration is greater than 3000ms, set it to 3000ms
        # li $t0, 2000 # minimum yellow duration
        # set_yellow_ns:
        #     sw $t0, yellow_duration_ns

        # lw $t0, green_duration_ew
        # srl $t0, $t0, 2  # divide by 4
        # bge $t0, 2000, set_yellow_ew # if yellow duration is greater than 3000ms, set it to 3000ms
        # li $t0, 2000 # minimum yellow duration
        # set_yellow_ew:
        #     sw $t0, yellow_duration_ew


        # Adjust yellow duration based on speed limit
        lw $t0, speed_limit_ns
        sll $t0, $t0, 10
        li $t1, 50
        div $t0, $t1
        mflo $t2                # speed_limit_ns / 50
        lw $t3, yellow_duration_ns
        mul $t3, $t3, $t2      # yellow_duration_ns = yellow_duration_ns * (speed_limit_ns / 50)
        srl $t3, $t3, 10
        sw $t3, yellow_duration_ns

        lw $t0, speed_limit_ew
        sll $t0, $t0, 10
        li $t1, 50
        div $t0, $t1
        mflo $t2                # speed_limit_ew / 50
        lw $t3, yellow_duration_ew
        mul $t3, $t3, $t2      # yellow_duration_ew = yellow_duration_ew * (speed_limit_ns / 50)
        srl $t3, $t3, 10
        sw $t3, yellow_duration_ew

    jr $ra


# Print parameters
print_parameters:
    li $v0, 4
    la $a0, adjusted_msg
    syscall
    li $v0, 4
    la $a0, adjusted_green_ns
    syscall
    li $v0, 1
    lw $a0, green_duration_ns
    syscall
    # Print newline
    li $v0, 4
    la $a0, newline
    syscall
    li $v0, 4
    la $a0, adjusted_green_ew
    syscall
    li $v0, 1
    lw $a0, green_duration_ew
    syscall
    # Print newline
    li $v0, 4
    la $a0, newline
    syscall
    li $v0, 4
    la $a0, adjusted_yellow_ns
    syscall
    li $v0, 1
    lw $a0, yellow_duration_ns
    syscall
    # Print newline
    li $v0, 4
    la $a0, newline
    syscall
    li $v0, 4
    la $a0, adjusted_yellow_ew
    syscall
    li $v0, 1
    lw $a0, yellow_duration_ew
    syscall
    # Print newline
    li $v0, 4
    la $a0, newline
    syscall
    li $v0, 4
    la $a0, adjusted_speed
    syscall
    li $v0, 1
    lw $a0, speed_limit_ns
    syscall
    li $v0, 4
    la $a0, adjusted_speed_value
    syscall
    # Print newline
    li $v0, 4
    la $a0, newline
    syscall

    jr $ra


# function to check button pressed state and change light states
pedestrian_crossing_check:
    lw $t0, button_pressed
    beqz $t0, no_button_pressed

    # If button pressed, turn both lights red and print pedestrian light state
    li $t0, 0
    sw $t0, NS_light        # NS goes red
    sw $t0, EW_light        # EW goes red

    # Print pedestrian light state
    li $v0, 4
    la $a0, pedestrian_green_msg
    syscall
    # Delay for pedestrian crossing
    lw $a0, pedestrian_duration
    jal delay
    # Change pedestrian light to red
    li $t0, 0
    sw $t0, button_pressed  # Reset button pressed state
    li $v0, 4
    la $a0, pedestrian_red_msg
    syscall


    no_button_pressed:
    jr $ra



# Delay subroutine
delay:
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

# End of simulation
end_simulation: 
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