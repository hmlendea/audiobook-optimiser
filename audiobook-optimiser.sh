#!/bin/bash

INCLUDE_DURATION_IN_DESCRIPTION=false

METADATA_FILE="./metadata.txt"
CHAPTERS_FILE="./.chapters.txt"
INPUT_FILE="${*}"
INPUT_DIRECTORY="."
INPUT_FILE_NAME=$(basename "${INPUT_FILE}")
INPUT_FILE_LABEL="${INPUT_FILE_NAME%%.*}"
INPUT_FILE_FORMAT="${INPUT_FILE_NAME##*.}"

function getDuration() {
    for FILE in ./*.mp3; do
        ffprobe -v error -select_streams a:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "${FILE}";
    done | \
        paste -sd+|\
        bc -l | \
        dc -e '?1~r60~r60~r[[0]P]szn[:]ndZ2>zn[:]ndZ2>zn[[.]n]sad0=ap' | \
        awk -F"." '{print $1}'
}

function getMetadata() {
    local KEY="${1}"

    [ -f "${METADATA_FILE}" ] && \
        grep "^${KEY}=" "${METADATA_FILE}" | \
        tail -n 1 | \
        awk -F"=" '{print $2}'
}

function getTitle() {
    local TITLE=""

    TITLE="$(getMetadata title)"

    if [ -z "${TITLE}" ] \
    && [ -n "${INPUT_FILE_NAME}" ]; then
        TITLE="${INPUT_FILE_NAME%%.*}"
    fi

    echo "${TITLE}"
}

function getSubtitle() {
    local SUBTITLE=""

    SUBTITLE="$(getMetadata subtitle)"

    echo "${SUBTITLE}"
}

function getFullTitle() {
    local TITLE="$(getTitle)"
    local SUBTITLE="$(getSubtitle)"

    if [ -n "${SUBTITLE}" ]; then
        echo "${TITLE} - ${SUBTITLE}"
    else
        echo "${TITLE}"
    fi
}

function getNarrator() {
    local NARRATOR_NAME=""

    [ -z "${NARRATOR_NAME}" ] && NARRATOR_NAME="$(getMetadata narrator)"
    [ -z "${NARRATOR_NAME}" ] && [ -f "reader.txt" ] && NARRATOR_NAME="$(grep '^\s*$' reader.txt | head -n 1)"

    echo "${NARRATOR_NAME}"
}

function generateDescription() {
    local DESCRIPTION=""
    local BOOK_NAME=""

    if [ -n "${SERIES_NAME}" ] \
    && [ -n "${SERIES_ORDER}" ] \
    && [ -n "${TITLE}" ] \
    && [ -n "${SUBTITLE}" ]; then
        BOOK_NAME="${SERIES_NAME} - Book ${SERIES_ORDER}, ${TITLE} - ${SUBTITLE}"
    elif [ -n "${SERIES_NAME}" ] \
    && [ -n "${SERIES_ORDER}" ] \
    && [ -n "${TITLE}" ]; then
        BOOK_NAME="${SERIES_NAME} - Book ${SERIES_ORDER}, ${TITLE}"
    elif [ -n "${SERIES_NAME}" ] \
      && [ -n "${SERIES_ORDER}" ]; then
        BOOK_NAME="${SERIES_NAME} - Book ${SERIES_ORDER}"
    elif [ -n "${SERIES_NAME}" ] \
      && [ -n "${TITLE}" ]; then
        BOOK_NAME="${SERIES_NAME}, ${TITLE}"
    elif [ -n "${TITLE}" ] \
    && [ -n "${SUBTITLE}" ]; then
        BOOK_NAME="${TITLE} - ${SUBTITLE}"
    elif [ -n "${TITLE}" ]; then
        BOOK_NAME="${TITLE}"
    fi

    if [ -n "${BOOK_NAME}" ]; then
        if [ -n "${AUTHOR}" ]; then
            DESCRIPTION="${AUTHOR}'s ${BOOK_NAME}"
        else
            DESCRIPTION="${BOOK_NAME}"
        fi

        [ -n "${NARRATOR_NAME}" ] && DESCRIPTION="${DESCRIPTION}, narrated by ${NARRATOR_NAME}"
    fi

    echo "${DESCRIPTION}"
}

function getDescription() {
    local DESCRIPTION=""

    [ -z "${DESCRIPTION}" ] && DESCRIPTION="$(getMetadata description)"
#    [ -z "${DESCRIPTION}" ] && [ -f "desc.txt" ] && DESCRIPTION="$(cat desc.txt)"
    [ -z "${DESCRIPTION}" ] && DESCRIPTION="$(generateDescription)"

    if ${INCLUDE_DURATION_IN_DESCRIPTION} && [ -n "${DURATION}" ]; then
        DESCRIPTION="${DESCRIPTION} (Duration: ${DURATION})"
    fi

    echo "${DESCRIPTION}"
}

TITLE="$(getTitle)"
SUBTITLE="$(getSubtitle)"
FULL_TITLE="$(getFullTitle)"
AUTHOR="$(getMetadata author)"
YEAR="$(getMetadata year)"
DURATION="$(getDuration)"
NARRATOR_NAME="$(getNarrator)"
SERIES_NAME="$(getMetadata series)"
SERIES_ORDER="$(getMetadata series_order)"
DESCRIPTION="$(getDescription)"
FIRST_CHAPTER_NUMBER=1

[ $(ls *.mp3 | wc -l) != 0 ] && FIRST_CHAPTER_NUMBER=$(ls *.mp3 | \
                                        sed 's/^.*\(Chapter\s\)*\([0-9][0-9]*\).*$/\1/g' | \
                                        sort -h | head -n 1 | \
                                        sed 's/^0*\([0-9]\)/\1/g')

[[ -z "${FIRST_CHAPTER_NUMBER}" ]] && FIRST_CHAPTER_NUMBER=1

echo "Title:         ${FULL_TITLE}"

[ -n "${SERIES_NAME}" ]     && echo "Series:        ${SERIES_NAME}"
[ -n "${SERIES_ORDER}" ]    && echo "Series order:  ${SERIES_ORDER}"

echo "Author:        ${AUTHOR}"
echo "Year:          ${YEAR}"
echo "Narrator:      ${NARRATOR_NAME}"
echo "Description:   ${DESCRIPTION}"
echo "First chapter: ${FIRST_CHAPTER_NUMBER}"

# Save metadata to Booksonic-specific files
[ -n "${NARRATOR_NAME}" ]    && echo "${NARRATOR_NAME}"  > "reader.txt"
[ -n "${DESCRIPTION}" ]      && echo "${DESCRIPTION}"    > "desc.txt"

function generate_chapters_list_from_cue() {
    local CUE_FILE="${1}"
    local TEMP_FILE=".tmp.txt"

    grep "^\s*\(TRACK\|TITLE\|INDEX\)" "${CUE_FILE}" | tr '\n' ' ' | sed 's/\s\s*/ /g' > "${CHAPTERS_FILE}"
    sed -i \
        -e's/TRACK [0-9]* AUDIO TITLE \"\([^\"]*\)\" INDEX [0-9]* \([0-9:]*\):[0-9][0-9]*/\2 END%NL%/g' \
        -e 's/END%NL%\s*\([0-9][0-9:]*\)/\1%NL%\1/g' \
        -e 's/%NL%/\n/g' \
        -e 's/^\s*//g' \
        "${CHAPTERS_FILE}"

    local TIMESTAMPS_COUNT=0
    TIMESTAMPS_COUNT=$(wc -l "${CHAPTERS_FILE}" | awk '{print $1}')
    [ -f "${TEMP_FILE}" ] && rm "${TEMP_FILE}"

    for (( INDEX=1; INDEX<=TIMESTAMPS_COUNT; INDEX++ )); do
        TIMESTAMP=$(head -n "${INDEX}" "${CHAPTERS_FILE}" | tail -n 1) # | awk '{print $1}')

        TIMESTAMP_START=$(awk -F" " '{print $1}' <<< "${TIMESTAMP}")
        TIMESTAMP_END=$(awk -F" " '{print $2}' <<< "${TIMESTAMP}")

        grep -q "^[0-9][0-9]*:[0-9][0-9]*$" <<< "${TIMESTAMP_START}" && TIMESTAMP_START="00:${TIMESTAMP_START}"
        grep -q "^[0-9]:" <<< "${TIMESTAMP_START}" && TIMESTAMP_START="0${TIMESTAMP_START}"
        grep -q ":[0-9]:" <<< "${TIMESTAMP_START}" && TIMESTAMP_START=$(sed 's/:\([0-9]\):/:0\1:/g' <<< "${TIMESTAMP_START}")
        grep -q ":[0-9]$" <<< "${TIMESTAMP_START}" && TIMESTAMP_START=$(sed 's/^\(.*\):\([0-9]\)$/\1:0\2/g' <<< "${TIMESTAMP_START}")

        grep -q "^[0-9][0-9]*:[0-9][0-9]*$" <<< "${TIMESTAMP_END}" && TIMESTAMP_END="00:${TIMESTAMP_END}"
        grep -q "^[0-9]:" <<< "${TIMESTAMP_END}" && TIMESTAMP_END="0${TIMESTAMP_END}"
        grep -q ":[0-9]:" <<< "${TIMESTAMP_END}" && TIMESTAMP_END=$(sed 's/:\([0-9]\):/:0\1:/g' <<< "${TIMESTAMP_END}")
        grep -q ":[0-9]$" <<< "${TIMESTAMP_END}" && TIMESTAMP_END=$(sed 's/^\(.*\):\([0-9]\)$/\1:0\2/g' <<< "${TIMESTAMP_END}")

        echo "${TIMESTAMP_START} ${TIMESTAMP_END}" >> "${TEMP_FILE}"
    done

    mv "${TEMP_FILE}" "${CHAPTERS_FILE}"
}

function generate_chapters_list_from_m4b() {
    local M4B_FILE="${1}"
    local TEMP_FILE=".tmp.txt"

    ffmpeg -i "${M4B_FILE}" 2> "${TEMP_FILE}"
    grep "Chapter " "${TEMP_FILE}" | grep "start" | grep "end" | \
        sed 's/^\s*Chapter \#[0-9][0-9]*:\([0-9]*\): start \([0-9\.]*\), end \([0-9\.]*\).*$/\2 \3/g' \
        > "${CHAPTERS_FILE}"

    rm "${TEMP_FILE}"
}

function extract_chapters_from_file() {
    local FILE_TO_EXTRACT="${1}"
    
    local TIMESTAMP=""
    local TIMESTAMP_START=""
    local TIMESTAMP_END=""
    local TIMESTAMPS_COUNT=0

    TIMESTAMPS_COUNT=$(wc -l "${CHAPTERS_FILE}" | awk '{print $1}')

    local CHAPTER_NR=0
    local CHAPTER_PREFIX=""
    local CHAPTER_FILE=""

    for (( INDEX=1; INDEX<=TIMESTAMPS_COUNT; INDEX++ )); do
        TIMESTAMP=$(head -n "${INDEX}" "${CHAPTERS_FILE}" | tail -n 1) # | awk '{print $1}')

        TIMESTAMP_START=$(echo "${TIMESTAMP}" | awk -F" " '{print $1}')
        TIMESTAMP_END=$(echo "${TIMESTAMP}" | awk -F" " '{print $2}')

        CHAPTER_NR=${INDEX} #$((INDEX-1))

        [ ${CHAPTER_NR} -lt 1 ] && continue

        if [ ${CHAPTER_NR} -lt 10 ] && [ ${TIMESTAMPS_COUNT} -ge 10 ]; then
            CHAPTER_NR_PREFIX="0"
        else
            CHAPTER_NR_PREFIX=""
        fi
        
        CHAPTER_FILE="Chapter ${CHAPTER_NR_PREFIX}${CHAPTER_NR}.mp3"

        echo "Extracting chapter ${CHAPTER_NR} of ${TIMESTAMPS_COUNT} (${TIMESTAMP_START} -> ${TIMESTAMP_END}) into '${CHAPTER_FILE}'..."
        if [ "${TIMESTAMP_END}" == "END" ]; then
            ffmpeg -y -i "${FILE_TO_EXTRACT}" -ss "${TIMESTAMP_START}" -map 0:a:0 -c:a:0 mp3 "${CHAPTER_FILE}" 2>/dev/null
        else
            ffmpeg -y -i "${FILE_TO_EXTRACT}" -ss "${TIMESTAMP_START}" -to "${TIMESTAMP_END}" -map 0:a:0 -c:a:0 mp3 "${CHAPTER_FILE}" 2>/dev/null
        fi
    done
}

if [ "${INPUT_FILE_FORMAT}" == "mp3" ]; then
    CUE_FILE="${INPUT_DIRECTORY}/${INPUT_FILE_LABEL}.cue"
    if [ -f "${CUE_FILE}" ]; then
        generate_chapters_list_from_cue "${CUE_FILE}"
        extract_chapters_from_file "${INPUT_FILE}"
        rm "${CHAPTERS_FILE}"
    fi    
elif [ "${INPUT_FILE_FORMAT}" == "m4b" ]; then
    generate_chapters_list_from_m4b "${INPUT_FILE}"
    extract_chapters_from_file "${INPUT_FILE}"
    rm "${CHAPTERS_FILE}"
fi

TRACK_INDEX=1
TRACKS_PROCESSED=${FIRST_CHAPTER_NUMBER}

for CHAPTER_FILE in *.mp3; do
    if echo "${CHAPTER_FILE}" | grep -q "Chapter"; then
        CHAPTER_NUMBER=$(echo "${CHAPTER_FILE}" | sed 's/^.*Chapter\s*\([0-9]*\).*/\1/g')
        CHAPTER_TITLE=$(echo "${CHAPTER_FILE}" | sed 's/^.*Chapter\s*[0-9][0-9]*\s*\(-\s*\)*\([^\.]*\).mp3/\2/g')
    else
        CHAPTER_NUMBER=$(echo "${CHAPTER_FILE}" | sed 's/^[^0-9]*\([0-9]\+\).*\.mp3/\1/g')
        CHAPTER_TITLE=$(echo "${CHAPTER_FILE}" | sed 's/^[0-9]*\s*\(.*\)\.mp3$/\1/g')
    fi

    CHAPTER_NUMBER=$(echo "${CHAPTER_NUMBER}" | sed 's/^0*\([0-9]\)/\1/g')
    TRACK_NUMBER=${CHAPTER_NUMBER}

    if [ -z "${CHAPTER_NUMBER}" ] \
    || [ "${CHAPTER_NUMBER}" == "${CHAPTER_FILE}" ]; then
        CHAPTER_NUMBER=${TRACKS_PROCESSED}
    fi

    if [ -z "${CHAPTER_TITLE}" ] \
    || [ "${CHAPTER_TITLE}" == "${CHAPTER_FILE}" ]; then
        CHAPTER_TITLE="Chapter ${CHAPTER_NUMBER}"
    fi

    [[ "${FIRST_CHAPTER_NUMBER}" -eq 0 ]] && TRACK_NUMBER=$((CHAPTER_NUMBER+1))

    CHAPTER_DESCRIPTION="Chapter ${CHAPTER_NUMBER}"

    [ "${CHAPTER_DESCRIPTION}" != "${CHAPTER_TITLE}" ] && CHAPTER_DESCRIPTION="${CHAPTER_DESCRIPTION} - ${CHAPTER_TITLE}"

    echo "Setting the tags for '${CHAPTER_FILE}' (Index=${TRACK_INDEX}; Chapter=${CHAPTER_NUMBER}; Title=${CHAPTER_TITLE})..."
    id3v2 \
        -A "${FULL_TITLE}" \
        --TALB "${FULL_TITLE}" \
        --TOAL "" \
        -a "${AUTHOR}" \
        --TCOM "${AUTHOR}" \
        --TPE1 "${AUTHOR}" \
        --TPE2 "${NARRATOR_NAME}" \
        --TOPE "${AUTHOR}" \
        -t "${CHAPTER_TITLE}" \
        --TIT2 "${CHAPTER_TITLE}" \
        --TIT3 "" \
        -T "${TRACK_NUMBER}" \
        --TRCK "${TRACK_INDEX}" \
        -c "${CHAPTER_DESCRIPTION}" \
        --COMM "${CHAPTER_DESCRIPTION}" \
        -y "${YEAR}" \
        --TYER "${YEAR}" \
        --TORY "" \
        --TCON "Audio Book" \
        --TLAN "eng" \
        "${CHAPTER_FILE}"

        TRACKS_PROCESSED=$((TRACKS_PROCESSED+1))
        TRACK_INDEX=$((TRACK_INDEX+1))

#exit
    continue

    mp3info \
        -l "${FULL_TITLE}" \
        -t "${CHAPTER_TITLE}" \
        -n "${TRACK_NUMBER}" \
        -a "${NARRATOR_NAME}" \
        -c "${CHAPTER_DESCRIPTION}" \
        -y "${YEAR}" \
        "${CHAPTER_FILE}" &> /dev/null
done
