#!/usr/bin/env python
fo = open("mandel_tb.vhdl", "w")
fo.write('''---
-- Auto-generated file - PLEASE DONT EDIT THIS
-- Instead, edit tb/mandel_tb.vhdl
''')
for line in open("mandel_tb.vhdl.template"):
    if line.startswith("###"):
        for newline in open(line.split()[-1]):
            fo.write(newline)
    else:
        fo.write(line)
