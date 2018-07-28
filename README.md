# eng-string-encode
Program to encode English strings to short binary string. Input chars allowed: a-z lowercase, space, comma, dot, dash. Language: Delphi.

Main purpose of this program is to be used to shorten vocabulary or text provided by wiktionary. 
I decided to write such program, because I want extract some data from wiktionary and save them to 
binary file.

Some comments are in Czech (use translator if needed).

In this version the function encode() and procedure decode() are the main layer. 

However I plan to make one more layer to replace prefixes and suffixes of English Word(s) so these function should be moved to 2nd layer.

No bugs found.
