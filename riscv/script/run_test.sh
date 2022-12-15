#!/bin/sh
# build testcase
./build_test.sh $@
# copy test input
if [ -f ../testcase/$@.in ]; then cp ../testcase/$@.in ../testdata/test.in; fi
# copy test output
if [ -f ../testcase/$@.ans ]; then cp ../testcase/$@.ans ../testdata/test.ans; fi
# add your own test script here
# Example:
# - iverilog/gtkwave/vivado
# - diff ../test/test.ans ../test/test.out
