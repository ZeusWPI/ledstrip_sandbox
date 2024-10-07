+ # Loop test value (1)
[
    <         # Go to rightmost cell
    [+<+<+<]  # Find first zero value to the left and set all others to zero by overflow from 255
    -<-<->>   # Set it to 255 by underflow
    > -[+>-]+ # Return to loop test value (1)
    ,,,,, ,,,,, ,,,,, ,,,,, ,,,,, ,,,,,
]
