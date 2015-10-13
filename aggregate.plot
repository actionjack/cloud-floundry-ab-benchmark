#
# Call it with:
#
#
#
# Use filename for plotting
#
if (!exists("filename")) filename='default.csv'
if (!exists("output_file")) output_file='output.jpg'

# Let's output to a jpeg file
set terminal jpeg size 800,600
# This sets the aspect ratio of the graph
set size 1, 1
# The file we'll write to
set output output_file
# The graph title
set title title

# Where to place the legend/key
set key left top
# Draw gridlines oriented on the y axis
set grid y
# Label the x-axis
set xlabel 'requests'
# Label the y-axis
set ylabel "response-time"
# Tell gnuplot to use tabs as the delimiter instead of spaces (default)
set datafile separator '\t'

# Second axis
set y2label 'requests'
set y2tics nomirror
set autoscale y2

# Plot the data
plot \
 filename every ::2 using 9:xticlabels(5) title "request/sec" axes x1y2 with boxes fs solid 0.1, \
 "" every ::2 using 4 title "Failures" axes x1y2 with boxes fs solid 0.1 linecolor rgb "#FF0000", \
 "" every ::2 using 6 title "mean" with lines lw 3, \
 "" every ::2 using 7 title "p95" with lines lw 3, \
 "" every ::2 using 8 title "p98" with lines lw 3
exit

