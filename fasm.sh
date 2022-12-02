#!/bin/bash
# Fix local jump labels
sed -i -E 's/^@@(\w+):(\s+db)/.@\1\2/g' p2com.v37
sed -i -E 's/^@@(\w+):(\s+dq)/.@\1\2/g' p2com.v37
sed -i -E 's/@@(\w+):/.\1:/g' p2com.v37
sed -i -E 's/(jmp\s+)@@(\w+)/\1.\2/g' p2com.v37
sed -i -E 's/(jne\s+)@@(\w+)/\1.\2/g' p2com.v37
sed -i -E 's/(jnz\s+)@@(\w+)/\1.\2/g' p2com.v37
sed -i -E 's/(jae\s+)@@(\w+)/\1.\2/g' p2com.v37
sed -i -E 's/(jle\s+)@@(\w+)/\1.\2/g' p2com.v37
sed -i -E 's/(jbe\s+)@@(\w+)/\1.\2/g' p2com.v37
sed -i -E 's/(jge\s+)@@(\w+)/\1.\2/g' p2com.v37
sed -i -E 's/(jnc\s+)@@(\w+)/\1.\2/g' p2com.v37
sed -i -E 's/(jns\s+)@@(\w+)/\1.\2/g' p2com.v37
sed -i -E 's/(j[a|b|e|z|c|g|l|s]\s+)@@(\w+)/\1.\2/g' p2com.v37
sed -i -E 's/(loop\s+)@@(\w+)/\1.\2/g' p2com.v37
sed -i -E 's/(call\s+)@@(\w+)/\1.\2/g' p2com.v37
sed -i -E 's/(jecxz\s+)@@(\w+)/\1.\2/g' p2com.v37
sed -i -E 's/(lea\s+\w+),\[@@(\w+)\]/\1,\[.\2\]/g' p2com.v37
# Remove TASM 'offset' modifier
sed -i -E 's/dd\toffset\s@@(\w+)/dd\toffset .\1/g' p2com.v37
sed -i -E 's/dd\toffset\s(\.\w+)/dd\t\1/g' p2com.v37
sed -i -E 's/,\s*offset\s+/,/g' p2com.v37
sed -i -E 's/push\toffset\s+/push\t/g' p2com.v37
sed -i -E 's/dd\toffset\s+(\w+)/dd\t\1/g' p2com.v37
# Fix local var labels
sed -i -E 's/@@(\w+)/.@\1/g' p2com.v37
# Fix addr size modifiers
sed -i -E 's/\[dword\s+(\S+)\]/dword \[\1\]/g' p2com.v37
sed -i -E 's/\[word\s+(\S+)\]/word \[\1\]/g' p2com.v37
sed -i -E 's/\[byte\s+(\S+)\]/byte \[\1\]/g' p2com.v37
