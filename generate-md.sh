#!/bin/bash

#
# Generates graphs and Markdown for all the resulting tests from
# `execute_perf_test.sh`
#
# Given a directory with suites like this:
# ├── suite-vulcand-http-keepalive
# │   ├── 105000-conc-3500-keepalive
# │   ├── 12000-conc-400-keepalive
# │   ├── 120000-conc-4000-keepalive
# │   ├── 60000-conc-2000-keepalive
# │   ├── 75000-conc-2500-keepalive
# │   ├── 9000-conc-300-keepalive
# │   ├── 90000-conc-3000-keepalive
# ├── suite-vulcand-ssl
# │   ├── 10500-conc-350
# │   ├── 1200-conc-40
# │   ├── 12000-conc-400
# │   ├── 6000-conc-200
# │   ├── 7500-conc-250
# │   ├── 9000-conc-300
# └── suite-vulcand-ssl-keepalive
#     ├── 10500-conc-350-keepalive
#     ├── 1200-conc-40-keepalive
#     ├── 12000-conc-400-keepalive
#     ├── 6000-conc-200-keepalive
#     ├── 7500-conc-250-keepalive
#     ├── 9000-conc-300-keepalive
#
# It will create graphs and readmes for:
#  - response time plot per test (in each test in each suite)
#  - CPU per test
#  - Agregate per suite
#

generate_test_graphs() {
    datadir=$1; shift
    gnuplot \
    	-e "input_file='${datadir}/ab_output.tsv'" \
    	-e "output_file='${datadir}/sequence.jpg'" \
    	sequence.plot
    gnuplot \
    	-e "input_file='${datadir}/ab_output.tsv'" \
    	-e "output_file='${datadir}/timeseries.jpg'" \
    	timeseries.plot
    gnuplot \
    	-e "input_file='${datadir}/dstat.raw'" \
    	-e "output_file='${datadir}/cpu.jpg'" \
    	cpu.plot
}

generate_suite_markdown(){
    suite_dir=$1
    if [ -f "$suite_dir/description.txt" ]; then
	DESCRIPTION=$(<$suite_dir/description.txt)
    else
	DESCRIPTION=$suite_dir
    fi

    echo "Processing suite $suite_dir: $DESCRIPTION"

    echo "# $DESCRIPTION" > $suite_dir/README.md
    executions=$(find $suite_dir -name 'dstat.raw' | xargs -n1 dirname | sort -n)

    for i in $executions; do
    	echo "Generating graphs for $i..."
	generate_test_graphs $i
	pathname=$(basename $i)
	cat <<EOF >> $suite_dir/README.md
## $pathname

![cpu]($pathname/cpu.jpg) ![sequence]($pathname/sequence.jpg) ![timeseries]($pathname/timeseries.jpg)

\`\`\`
$(<$i/ab_report.txt)
\`\`\`

EOF
    done
}


get_metrics_from_ab_output() {

    file=$1
    label=$(basename $(dirname $(dirname $file)))

    if grep -q 'Keep-Alive requests' $file; then
	keepalive=1
    else
	keepalive=0
    fi

    total_reqs=$(awk '/Complete requests/ { print $3 }' < $file)
    failed_reqs=$(awk '/Failed requests/ { print $3 }' < $file)
    conc=$(awk '/Concurrency Level/ { print $3 }' < $file)
    mean=$(awk '/Time per request.*\(mean\)/ { print $4 }' < $file)
    p95=$(awk '/95%/ { print $2 };' < $file)
    p98=$(awk '/98%/ { print $2 };' < $file)
    rqs=$(awk '/Requests per second/ { print $4 }' < $file)


    echo -e "$label\t$keepalive\t$total_reqs\t$failed_reqs\t$conc\t$mean\t$p95\t$p98\t$rqs"
}

get_csv_from_test() {
    # Print headers
    echo -e "label\tkeepalive\ttotal_reqs\tfailed_reqs\tconc\tmean\tp95\tp98\trqs"

    for test in $@; do
	for f in $(find $test -name ab_report.txt) ; do
	    get_metrics_from_ab_output $f
	done | sort -k 3 -n
    done
}

generate_aggregate_graph() {
    test_dir=$1
    readme=$2
    if [ -f "$test_dir/description.txt" ]; then
	test_title=$(<$test_dir/description.txt)
    else
	test_title=$(basename $test_dir)
    fi
    echo "Generating aggragate graph for $test_dir"
    get_csv_from_test $test_dir > ${test_dir}/aggregate.csv
    gnuplot \
	-e "filename='${test_dir}/aggregate.csv'" \
	-e "output_file='${test_dir}/aggregate.jpg'" \
	-e "title='${test_title}'" \
	aggregate.plot

    echo "# $test_title" >> $readme
    echo "![$test_title]($(basename ${test_dir})/aggregate.jpg)" >> $readme
}

if [ ! -d "$1" ]; then
    echo "Must specify a directory with the test results"
    exit 1
fi

MAIN_README=$1/README.md
echo -n > $MAIN_README
SUITES=$(find $1 -name suite-* | sort)
for suite in $SUITES; do
    generate_suite_markdown $suite
    generate_aggregate_graph $suite $MAIN_README
done

echo "Done in $MAIN_README"

