#!/bin/sh
# Generates csv data without EOL distros
#
# Usage: gldt_active.sh inputfile outputfile

active=0

# has_active_descendants filename lineno
has_active_descendants(){
	# If active itself
	if [ -z "$(sed -e $2'!d' -e 's/"//g' -e 's/^\([^,]*,\)\{5\}//' -e \
		's/,.*//' $1)" ]
	then
		active=1
		return
	else
		active=0
	fi

	# Get line numbers, Run recursively
	for childline in $(grep -n \
			'^"N",\([^,]*,\)\{2\}"'$(sed -e $2'!d' -e \
			's/^[^,]*,"//' -e 's/".*//' -e \
			's/[[:space:]]/\[\[\:space\:\]\]/g' $1)'".*' $1 | \
			sed -e 's/:.*//'); do
		has_active_descendants $1 $childline
		if [ $active -eq 1 ]; then
			return
		fi
	done
}

echo ',,,,,,,,,,,,,,,,' > $2
echo '"//!","Generated by gldt_active.sh from '$1'",,,,,,,,,,,,,,,' >> $2

for lineno in $(seq 1 $(wc -l < $1)); do
	entry=$(sed $lineno'!d' $1)
	# If blacklisted
	if echo $entry | grep -q '^"#N"*\|^"//N"*\|^"#C"*'; then
		continue
	# If a connection
	elif echo $entry | grep -q '^"C"*'; then
		# Test first distro for EOL
		has_active_descendants $1 $(grep -n \
			'^"N","'$(sed -e $lineno'!d' -e \
			's/^\([^,]*,\)\{2\}"//' -e 's/".*//' -e \
			's/[[:space:]]/\[\[\:space\:\]\]/g' $1)'".*' $1 | \
			sed -e '1!d' -e 's/:.*//')
		if [ $active -eq 0 ]; then
			continue
		fi

		# Test second distro for EOL
                has_active_descendants $1 $(grep -n \
			'^"N","'$(sed -e $lineno'!d' -e \
			's/^\([^,]*,\)\{4\}"//' -e 's/".*//' -e \
			's/[[:space:]]/\[\[\:space\:\]\]/g' $1)'".*' $1 | \
			sed -e '1!d' -e 's/:.*//')
		if [ $active -eq 0 ]; then
			continue
		fi
	# If a node
	elif echo $entry | grep -q '^"N"*'; then
		has_active_descendants $1 $lineno
		if [ $active -eq 0 ]; then
			continue
		fi
	fi

	# If all tests passed
	echo $entry >> $2
done
