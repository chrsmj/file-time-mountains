#!/usr/bin/tclsh
#
# file-time-mountains.tcl
# Helps visualize file time stats of many files.
# Copyright 2019 chris at penguin pbx dot com
# License GPLv3
#
# Spins through the given directory (default: current)
# and spits out a graph showing a count by hour
# of file creation, modification and then access times.
#
# So it looks like three sideways mountains, 'c' 'm' 'a':
# 'c' for hour-by-hour tally of file creation times
# 'm' for hour-by-hour tally of file modification times
# 'a' for hour-by-hour tally of file access times
#
# This might be useful to help plan rsync jobs.
#
# USAGES:
# $ tclsh file-time-mountains.tcl 
# $ tclsh file-time-mountains.tcl /SOME/PATH 10
#
# TIP: Pipe the output to less.
#
# HEALTH AND SAFETY WARNING:
# This is an experiment in terminal visualization.
# Please stretch your neck before using this.
# Looking sideways at your monitor may hurt!
# Or just look really weird!
#
# TODO:
# * Error checking on file access.
# * Add recursive directory traversal option.

# Check user input for a directory name.
set unsafe_dir [string trim [lindex $argv 0]]
if { [file isdirectory $unsafe_dir] } {
    set dir $unsafe_dir
} else {
    set dir "."
}

# Check user input for display modulus.
# Default 1 means each letter 'c' 'm' 'a' is one file.
# But using 10 means each letter represents between 1-10 files.
# So 'aaa' could represent the access hour of 21-30 files.
# Similar with modulus 100 for 1-100 files per letter.
set unsafe_mod [string trim [lindex $argv 1]]
if { [string length $unsafe_mod] > 0 && [string is integer $unsafe_mod] } {
    set mod [expr {abs($unsafe_mod)}]
} else {
    set mod 1
}

# Keep track of total file count.
set tally 0

# Plan to draw a mountain for each type.
set l_ftimes [list "ctime" "mtime" "atime"]

# Build and zero a 'd_day' dictionary: 24 hours * 3 file times
set d_day [dict create]
for {set h 0} {$h < 24} {incr h} {
    foreach t $l_ftimes {
        dict set d_day $t $h 0
    }
}

# Read through directory for files' meta-data into the 'd_day' dictionary.
foreach f [glob -directory $dir -type f "*"] {
    incr tally
    file stat $f s
    foreach t $l_ftimes {
        set k [clock format $s($t) -format "%k"]
        set h [string trim $k]
        set x [dict get $d_day $t $h]
        dict set d_day $t $h [incr x]
    }
}

# Display data from the 'd_day' dictionary.
foreach t $l_ftimes {
    set u [string range $t 0 0]
    for {set h 0} {$h < 24} {incr h} {
        if { $h < 10 } {
            set hh "0${h}"
        } else {
            set hh $h
        }
        puts -nonewline "${hh} "
        set c [dict get $d_day $t $h]
        for {set i 0} {$i < $c} {incr i} {
            if { [expr {$i % $mod}] == 0 } {
                puts -nonewline $u
            }
        }
        if { $c > 0 } {
            puts -nonewline " ${c}"
        }
        puts ""
    }
    puts ""
}

# Summary statistics.
puts "Directory: ${dir}"
puts "Number of Files: ${tally}"
puts "Displayed one letter per file time (c, m, a) for every part of ${mod} files in that hour."

