#!/bin/sh
# Simple script for auto encoding files with label set to $INTERESTING_LABEL using handbrake and limiting cpu usage with cpulimit
# Instructions:
# 1) install HandBrakeCLI (the command line version) (http://handbrake.fr/downloads.php)
# 2) (optional but if you don't do this, read instructions at CPU_LIMIT definition) install cpulimit (https://github.com/opsengine/cpulimit)
# 3) copy the script in ~/.rtorrent
# 4) Add the following line in your .rtorrent.rc
# system.method.set_key=event.download.finished,autoencode,"execute=~/.rtorrent/auto_encode.sh,$d.custom1=,$d.base_path="

LOG_FILE="${HOME}/.rtorrent/auto_encode.log"
INTERESTING_LABEL="ToEncode"
INTERESTING_FILES='.*\.(avi|mp4|mpeg)$'
OUT_DIR="${HOME}/Desktop/AutoEncoded"
CPU_LIMIT="cpulimit -l 100"
# If you don't want to limit handbrake cpu usage, comment the previous line and uncomment next line
# CPU_LIMIT=""
HANDBRAKE="HandBrakeCLI -e x264  -q 20.0  --pfr  -a 1 -E faac -B 160 -6 dpl2 -R Auto -D 0.0 -f mp4 -4 -X 1920 --decomb=\"7:2:6:9:1:80\" --loose-anamorphic --modulus 2 -m -x b-adapt=2"

function find_files_to_encode() {
  if [ ! -e "$1" ]; then
    echo "Weird! File \"$1\" that I am supposed to encode, doesn't exist"
  elif [ -d "$1" ]; then
    echo "File \"$1\" is a directory, switching recursively"
    find -E "$1" -iregex "$INTERESTING_FILES" | while read vfile; do
      find_files_to_encode "$vfile"
    done
  elif [ "`echo "$1" | grep -E "$INTERESTING_FILES"`" ]; then
    extension="`echo "$1" | sed -E 's/.*\.([a-z]+)/\1/'`"
    basefile="`basename "$1" .$extension`"
    CMD="$CPU_LIMIT $HANDBRAKE -i \"$1\" -o \"${OUT_DIR}/${basefile}.mp4\""
    echo "Running \"$CMD\""
    $CMD
  else
    echo "File \"$1\" does not match given INTERESTING_FILES regexp (${INTERESTING_FILES})"
  fi
}

function main() {
  # Params <label> <file path>
  if [ "$1" != "$INTERESTING_LABEL" ]; then
    echo "File \"$2\" does not have the $INTERESTING_LABEL label, it has label \"$1\", skipping."
    return
  fi
  find_files_to_encode "$2"
}

# The script has to go in background otherwise rtorrent would freeze while encoding
main "$1" "$2" >> ${LOG_FILE} &
