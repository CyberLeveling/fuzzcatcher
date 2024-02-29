#!/bin/bash

yellowColour='\e[1;33m'
endColour='\e[0m'
purpleColour='\e[1;35m'

function download_urls() {
  echo -e "${yellowColour}[*]${endColour}${purpleColour} Working... ${endColour}"

  if [ ! -f "urls.txt" ]; then
    echo "Error: the input file does not exist."
    exit 1
  fi

  while read -r line; do
    wget -q -nv "$line" > /dev/null 2>&1
    curl -s -I "$line" >> headers.txt
  done < "urls.txt"
}

download_urls

sleep 1

function process_files() {
  tmp_sorted="sorted_$$.txt"
  tmp_not_sorted="notsorted_$$.txt"

  for file in ./*; do
    if [ "$file" != "./fuzzcatcher.sh" ] && [ "$file" != "./urls.txt" ]; then
      tr -sc '[:alnum:]' '\n' < "$file" >> "$tmp_not_sorted"
      sort -u "$tmp_not_sorted" > "$tmp_sorted"
    fi
  done

  mv "$tmp_sorted" sorted.txt
  rm -f "$tmp_not_sorted"
}

process_files

sleep 1

function run_fuzzing() {
  tmp_comb="comb_$$.txt"
  tmp_output="output_$$.txt"
  tmp_merged="merged_$$.txt"
  tmp_mergedswap="mergedswap_$$.txt"
  tmp_fuzz="fuzz_$$.txt"

  paste -d/ - - < sorted.txt | xargs | tr '/' '\n' > "$tmp_comb"

  cat "$tmp_comb" | sed 's/\([^ ]*\) \(.*\)/\1\/\2/' > "$tmp_merged"
  rm "$tmp_comb"

  while read -r line; do
    echo "$line" | awk -F'/' '{ temp=$1; $1=$2; $2=temp; print }' >> "$tmp_output"
  done < "$tmp_merged"

  cat "$tmp_output" | sed 's/\([^ ]*\) \(.*\)/\1\/\2/' > "$tmp_mergedswap"
  rm "$tmp_output"

  cat sorted.txt > "$tmp_fuzz"
  cat "$tmp_merged" >> "$tmp_fuzz"
  cat "$tmp_mergedswap" >> "$tmp_fuzz"

  sort -u "$tmp_fuzz" > fuzzing.txt
  rm -f "$tmp_fuzz" "$tmp_merged" "$tmp_mergedswap"
}

run_fuzzing

sleep 1

function replace_slashes() {
  sed -i 's/\//-/g' fuzzing.txt
  sed -i 's/\//_/g' fuzzing.txt
  shuf fuzzing.txt > fuzzing_shuf.txt
  mv fuzzing_shuf.txt fuzzing.txt
  sort -u fuzzing.txt > final.txt
}

replace_slashes

function remove_files() {
  rm -f headers.txt fuzzing.txt
}

remove_files

exit 0
