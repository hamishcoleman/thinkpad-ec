#!/bin/bash
#
# Copyright (C) 2019 onwards, Samveen S. Gulati
#
# Script to extract FL1 or FL2 files from Lenovo BIOS update ISO image
#

# EL TORITO offset count (thanks to Hamish Coleman)
FAT_OFFSET=71680

USAGE="${0} [[-1|--fl1] [-2|--fl2]] {[-i|--iso] ISO_FILE} {[-d|--desc] DESC_FILE} [[-m|--model] PREFIX] [[-s|--suffix] SUFFIX] | [-h|--help]
    -1|--fl1    Extract BIOS update file (.FL1)
    -2|--fl2    Extract EC update file (.FL2) (Default if no option)
    -i|--iso    Update ISO to extract the file from
    -d|--desc   Path of Descriptions.txt file
    -m|--model  Optional model prefix to attach to extracted filenames.
    -s|--suffix Optional suffix to attach to extracted filenames.
    -h|--help   Show this help"

# Get and parse options
OPTIONS=$(getopt -o 12i:d:m:s:h --long fl1,fl2,iso:,desc:,model:,suffix:,help -n "$0" -- "$@")
# Note the quotes around `$OPTIONS': they are essential!
eval set -- "$OPTIONS"

while true ; do
    case "$1" in
        -1|--fl1) FL1=Y ; shift ;;
        -2|--fl2) FL2=Y ; shift ;;
        -i|--iso) ISO=$2 ; shift 2 ;;
        -d|--desc) DESC=$2 ; shift 2 ;;
        -m|--model) MODEL="${2%%.}." ; shift 2 ;;
        -s|--suffix) SUFFIX=".${2##.}" ; shift 2 ;;
        -h|--help) echo "$USAGE"; exit ;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

# Reasonable Defaults: extract only FL2
if [[ -z $FL1 ]] && [[ -z $FL2 ]]; then
    FL2=Y
fi

[[ -n "$ISO" ]]  || { echo -e "Error: Missing ISO filename\n${USAGE}" >&2; exit 2; }
[[ -f "$ISO" ]]  || { echo -e "Error: ${ISO} not found or not a file\n${USAGE}" >&2; exit 4; }
[[ -f "$DESC" ]]  || { echo -e "Error: Missing Descriptions file.\n${USAGE}" >&2; exit 8; }
[[ -n "$MODEL" ]] && echo "Using ${MODEL} as prefix" >&2 || echo "No model name provided. Not using any prefix" >&2
[[ -n "$SUFFIX" ]] && echo "Using ${SUFFIX} as suffix" >&2 || echo "Not using any suffix." >&2

# ./scripts/ISO_copyFL2 from_iso $< $@ $(1)

if ! which mdir >/dev/null; then
    echo "Fatal: mtools package not installed or not in path" >&2
    exit 16
fi

read -r FL1VERNUM FL1VER FL2VERNUM FL2VER < <(grep -E "^${ISO%%.iso*}" ../Descriptions.txt| \
                    grep BIOS| \
                    grep -v BROKEN| \
                    sed 's/.\+ BIOS //; s/ EC / /; s/[()]//g')

# The "internal" filename pattern to match - used in the BIOS update image
FILELIST="$(mdir -/ -b -f -i "$ISO"@@"$FAT_OFFSET")"

if [[ -n $FL1 ]]; then
    FL1PATH="$(echo "$FILELIST" |grep '.FL1$')"
    if [ -z "$FL1PATH" ]; then
        echo "Error: could not find any files in $ISO matching *.FL1" >&2
        exit 32
    fi
    if [[ $(echo "$FL1PATH" |wc -l) -gt 1 ]]; then
        echo "Error: $ISO has more than one FL1 files" >&2
        echo "$FL1PATH"
        exit 64
    fi


    FL1NAME="${MODEL}${FL1VER}.${FL1PATH##*/}${SUFFIX}"
    echo "Extracting $FL1PATH (ver $FL1VERNUM) to ${FL1NAME/$/s}"
    mcopy -n -i "$ISO"@@"$FAT_OFFSET" "$FL1PATH" "${FL1NAME/\$/s}"
fi

if [[ -n $FL2 ]]; then
    FL2PATH="$(echo "$FILELIST" |grep '.FL2$')"
    if [ -z "$FL2PATH" ]; then
        echo "Error: could not find any files in $ISO matching *.FL2" >&2
        exit 32
    fi
    if [[ $(echo "$FL2PATH" |wc -l) -gt 1 ]]; then
        echo "Error: $ISO has more than one FL2 files" >&2
        echo "$FL2PATH"
        exit 64
    fi
    FL2NAME="${MODEL}${FL2VER}.${FL2PATH##*/}${SUFFIX}"
    echo "Extracting $FL2PATH (ver $FL2VERNUM) to ${FL2NAME/$/s}"
    mcopy -n -i "$ISO"@@"$FAT_OFFSET" "$FL2PATH" "${FL2NAME/$/s}"
fi

# vim: expandtab sw=4 ts=4:
