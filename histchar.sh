#!/bin/bash -eE
####
#
#   Copyright 2020 Perihelios LLC
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
####
#   Obtainable from: https://github.com/perihelios/histchar-bash
####

set -o pipefail
shopt -s inherit_errexit extglob

declare -a LABELS
declare -A BUCKETS
declare -A FORMAT

main() {
	initializeBuckets "$@"
	gatherData
	computeFormat
	renderPlot
	renderLabels
}

initializeBuckets() {
	local label

	LABELS=("$@")

	for label in "${LABELS[@]}"; do
		BUCKETS["$label"]=0
	done
}

gatherData() {
	local c
	local EOT=$'\04'

	while IFS= read -r -N 1 c; do
		if [[ $c == $EOT ]]; then
			break
		fi

		if [[ $c == [[:space:]] ]]; then
			continue
		fi

		if [[ -z ${BUCKETS["$c"]} ]]; then
			continue
		fi

		BUCKETS["$c"]=$((BUCKETS["$c"] + 1))
	done
}

computeFormat() {
	local ttySettings ttyRows ttyCols
	local padding=1

	ttySettings=$(stty -F $(findAvailableTty) -a)
	ttyRows=$(grep -oP '(?<=rows )\d+' <<<"$ttySettings")
	ttyCols=$(grep -oP '(?<=columns )\d+' <<<"$ttySettings")

	local barWidth
	barWidth=$(( (ttyCols - (${#LABELS[@]} - 1) * padding) / ${#LABELS[@]} ))

	if [[ $barWidth -eq 0 ]]; then
		echo "ERROR: Terminal width not sufficient to render ${#LABELS[@]} bars" >&2
		exit 1
	fi

	if [[ $((barWidth & 1)) -eq 0 ]]; then
		let barWidth--
	fi

	if [[ $barWidth -lt $ttyCols ]]; then
		linePrintf+='\n'
	fi

	FORMAT[padding]=$padding
	FORMAT[barWidth]=$barWidth
	FORMAT[barHeight]=$((ttyRows / 2 - 3))
	FORMAT[barSegment]=$(repeat '#' barWidth)
	FORMAT[linePrintf]=$(repeat "% ${barWidth}s" ${#LABELS[@]} ' ')'\n'
	FORMAT[maxValue]=$(maxBucketValue)
}

renderPlot() {
	local i j

	for ((i = FORMAT[barHeight]; i > 0; i--)); do
		local -a barLine=()

		for ((j = 0; j < ${#LABELS[@]}; j++)); do
			local label=${LABELS[$j]}
			local value=${BUCKETS["$label"]}

			if ((FORMAT[barHeight] * value / FORMAT[maxValue] >= i)); then
				barLine[$j]=${FORMAT[barSegment]}
			else
				barLine[$j]=''
			fi
		done

		printf "${FORMAT[linePrintf]}" "${barLine[@]}"
	done
}

renderLabels() {
	local label labelLine

	for ((i = 0; i < ${#LABELS[@]}; i++)); do
		label=${LABELS[$i]}

		if [[ $i -gt 0 ]]; then
			labelLine+="% $((FORMAT[barWidth] + FORMAT[padding]))s"
		else
			labelLine+="% $((FORMAT[barWidth] / 2 + 1))s"
		fi
	done

	labelLine+='\n\n'

	printf "$labelLine" "${LABELS[@]}"
}

findAvailableTty() {
	echo /dev/$(ps -o tty= -p $$)
}

maxBucketValue() {
	local value
	local maxValue=0

	for value in ${BUCKETS[@]}; do
		if [[ $value -gt $maxValue ]]; then
			maxValue=$value
		fi
	done

	echo "$maxValue"
}

repeat() {
	local repeated=$1
	local count=$2
	local separator=$3

	local i
	local result

	for ((i = 0; i < count; i++)); do
		if [[ $i -gt 0 ]]; then
			result+=$separator
		fi

		result+=$repeated
	done

	echo "$result"
}

main "$@"
