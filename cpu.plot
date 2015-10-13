set xdata time
set timefmt "%s"
set format x "%M:%S"
set output output_file
set terminal jpeg size 500,500
plot input_file using 1:2 title "User" with lines, "" using 1:3 title "Sys" with lines, "" using 1:4 title "Idle" with lines

