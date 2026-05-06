import sys

# USER DEFINED VARIABLES:

# define the characters to be added to the beginning of each line
# I used `#` for python comments + ` ` (space) for personal preference
comment_start = "# "

# define text width using a full line across the window.
# edit this test line to fit your window size
test_line = """
The script will count every character in this line and use that number. AAAAAAAA
"""

# END OF USER DEFINED VARIABLES

# line length defined by above line minus the specified comment characters
line_length = len(test_line.strip()) - len(comment_start)

# clear prompt to paste text.
print("-----Text Fit and Comment Tool-----\n\n\
This tool takes pasted text, fits it to a specified line length,\n\
and comments it out, for pasting into your code.\n\n\
Instructions:\n\
Paste text\n\
Press ENTER\n\
Type `END` (all caps, no quotes) on its own line.\n\
Press ENTER.\n\
Commented text will print for you to copy/paste.\n\n\
Paste text below:\n")

# create list of lines with END defined
lines = []
for line in sys.stdin:
    if line.strip() == "END":
        break
    lines.append(line.rstrip("\n"))
    
# loop to count, break, and comment lines, while preserving line breaks
for line in lines:
    if line != "":
        words = line.split()
        fitted_line = ""
        new_list = []
        new_line = ""
        for word in words:
            new_list.append(word)
            new_line = " ".join(new_list)
            if len(new_line) <= line_length:
                fitted_line = new_line
            else:
                commented_line = comment_start + fitted_line
                print(commented_line)
                new_list = [word]
                fitted_line = word
                new_line = word
        print(comment_start + fitted_line)
    else:
        print("\n")
                       
                   
        


