#!/usr/bin/env python
fo = open("test_data.vhdl", "w")
fo.write('''---
-- Auto-generated file - PLEASE DONT EDIT THIS
-- Instead, edit tb/test_data.vhdl.template
''')
for line in open("test_data.vhdl.template"):
    if line.startswith("###"):
        for newline in open(line.split()[-1]):
            fo.write(newline)
    else:
        fo.write(line)
