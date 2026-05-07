## Text Fit and Comment Tool

I got into solving Python challenges on pynative.com.  
I copy and paste python problem descriptions into my python file for clear reference later.   
I was manually formatting the text to comfortably fit the default window size, and manually commenting out each line.

This tool does that work for me.

It takes a pasted block of text and breaks it into lines of whole words that are less than or equal to a specified length.  
It then comments out each line of text.  
It preserves line breaks for legibility.
It prints to the terminal for you to highlight, copy, and paste into your code editor,
OR it prompts you for a filename and outputs the commented text to a new file in the current working directory. 
(still a work in progress for how conveniently that works if you run this from any other directory than the one you want things in)

### User-defined parts of script

- the `print_to_terminal` variable, if `True` will print output to your screen for you to simply copy and paste wherever you plan to put it. If `False`, running the script will prompt you for a filename and output to that file created in the current working directory.
- the `comment_start` variable contains the characters to add to the beginning of each line. Change as you like. Script will handle it.
- the `test_line` variable contains the line I typed to fill one full line of the default window size in my preferred code editor. Delete or add characters as you like. It is contained in triple quotes to visually isolate the line across the full window. .strip() is necessary later to remove the 2 invisible newline characters contained in the string. The script subtracts the length of the specified `comment_start` variable. The characters used in this variable don't matter as it's just the length that is used.

### To Use

- edit script as necessary: `print_to_terminal`, `comment_start` and `test_line` variables
- run the script using your preferred method.
- follow the instructions:
- paste your text, press ENTER, type `END` all caps no quotes, and press ENTER once more
- the text should be generated to stdout (the terminal) or to a new file
- copy the output text to paste into your code editor or go open the file