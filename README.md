# histchar (Bash)

This is a simple script to show columnar histograms of character distributions
in data. It was intended for a fairly specific analysis problem, so will likely
require some adaptation for other uses.

## Usage

You can pipe data into the script:
```
dd if=/dev/urandom bs=1000 count=1 status=none | od -t x1 -A n | ./histchar.sh {0..9} {a..f}
```
Or you can just run it and enter data in the terminal:
```
./histchar.sh A B C
AAAAABB
CCCCCCCCC
DD<Ctrl+D>
```
Note that you press the &lt;Ctrl+D> key combination to end input.

Output scales itself horizontally to terminal width, and vertically to half
terminal height.

## Limitations

* Whitespace characters are always ignored
* Binary data won't work extremely well, due to Bash's inability to hold a null
  byte in a string
* The EOT character (0x04) is used to indicate end-of-data, as this allows the
  &lt;Ctrl+D> combination to terminate manual input
