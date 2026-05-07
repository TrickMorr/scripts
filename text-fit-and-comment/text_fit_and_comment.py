import sys
import re

# USER DEFINED VARIABLES:

# set True for printed text for copy/paste
# set False for creating a new file with commented text
print_to_terminal = False

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
This tool fits a block of text to specified line lengths\n\
and adds comment characters to the beginning of each line.\n\
Output is either to the terminal or a new file.\n\n\
Instructions:\n\n\
Paste text, press ENTER\n\n\
Type `END` (all caps, no quotes), press ENTER.\n\n\
Paste text below:\n")

# create list of lines with END defined
lines = []
for line in sys.stdin:
    if line.strip() == "END":
        break
    lines.append(line.rstrip("\n"))

output_lines = []
for line in lines:
    if line != "":
        words = line.split()
        new_list = []
        fitted_line = ""
        new_line = ""
        for word in words:
            new_list.append(word)
            new_line = " ".join(new_list)
            if len(new_line) <= line_length:
                fitted_line = new_line
            else:
                output_lines.append(comment_start + fitted_line)
                new_list = [word]
                fitted_line = word
                new_line = word
        output_lines.append(comment_start + fitted_line)
    else:
        output_lines.append("")

output = "\n".join(output_lines)

if print_to_terminal:
    print(output)
else: # write to file

# extract default name from first line and ask about filename
# logic here comes from pynative.com challenges beging titled like:
# Exercise 10: Name of Challenge (optional condition)
# you can delete or comment out this section
# but it does prompt for manually entered filename

    line1 = lines[0]
    first_split = line1.split(" ")
    remove_beginning = " ".join(first_split[2:])
    filename = (re.sub(r'[ ()/]+', '_', remove_beginning).strip("_")).lower() + ".py"

    confirm = "n"
    while confirm != "y":
        temp = input(f"\n\n\n\nPress ENTER for filename of: {filename}\n\n\
OR Type name of file to be created here: ")
        if temp != "":
            filename = temp
        confirm = input(f"\n\nOK! Filename will be:       {filename}\n\n\
                        Type Y to confirm, N to rename, ctrl+c to cancel: ").strip().lower()

    with open(filename, "w") as file:
        file.write(output)
    print(f"File: {filename} created successfully")
