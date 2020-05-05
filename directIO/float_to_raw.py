import struct
import math

fp = [math.pi, 5.1, 6.234, 0.43125, 0.91234]
output = open('out.txt','wb+')
for f in fp:
    output.write(struct.pack("<f", f))
