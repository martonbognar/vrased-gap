#!/bin/bash

unbuffer make ATTACK=2 run | tee output.txt
grep -oP "key: \w{62}\K(\w{66})" output.txt > key1.txt
grep -oP "leak\[31:63\]: \K(\w{66})" output.txt > key2.txt
cat key1.txt key2.txt

test -s key1.txt && test -s key2.txt && diff key1.txt key2.txt
