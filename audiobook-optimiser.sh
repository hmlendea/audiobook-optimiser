#!/bin/bash

INCLUDE_DURATION_IN_DESCRIPTION=false

METADATA_FILE="./metadata.txt"
INPUT_FILE="${*}"
INPUT_FILE_NAME=$(basename "${INPUT_FILE}")

FILE_FORMAT="${INPUT_FILE_NAME##*.}"

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

if [ "${FILE_FORMAT}" == "m4b" ]; then
    TIMESTAMP_START=""
    TIMESTAMP_END=""

    TEMP_FILE=".tmp.txt"
    CHAPTERS_FILE=".chapters.txt"

    ffmpeg -i "${INPUT_FILE}" 2> "${TEMP_FILE}"
    grep "Chapter " "${TEMP_FILE}" | grep "start" | grep "end" | \
        sed 's/^\s*Chapter \#[0-9][0-9]*:\([0-9]*\): start \([0-9\.]*\), end \([0-9\.]*\).*$/\2 \3/g' \
        > "${CHAPTERS_FILE}"

    TIMESTAMPS_COUNT=$(wc -l "${CHAPTERS_FILE}" | awk '{print $1}')

    echo "Starting to extract the ${TIMESTAMPS_COUNT} chapters..."

    for (( INDEX=1; INDEX<=TIMESTAMPS_COUNT; INDEX++ )); do
        TIMESTAMP=$(head -n "${INDEX}" "${CHAPTERS_FILE}" | tail -n 1) # | awk '{print $1}')
#        TIMESTAMP_START="${TIMESTAMP_END}"
#        TIMESTAMP_END="${TIMESTAMP}"

        TIMESTAMP_START=$(echo "${TIMESTAMP}" | awk -F" " '{print $1}')
        TIMESTAMP_END=$(echo "${TIMESTAMP}" | awk -F" " '{print $2}')

        CHAPTER_NR=$INDEX #$((INDEX-1))
        CHAPTER_NR_PREFIX=""

        [ ${CHAPTER_NR} -lt 1 ]  && continue
        [ ${CHAPTER_NR} -lt 10 ] && [ ${TIMESTAMPS_COUNT} -ge 10 ] && CHAPTER_NR_PREFIX="0"

        CHAPTER_FILE="Chapter ${CHAPTER_NR_PREFIX}${CHAPTER_NR}.mp3"
        CHAPTER_TEMP_FILE=".temp.${CHAPTER_FILE}"

        echo "Extracting chapter ${CHAPTER_NR} (${TIMESTAMP_START} -> ${TIMESTAMP_END}) into '${CHAPTER_FILE}'..."
        ffmpeg -y -i "${INPUT_FILE}" -ss "${TIMESTAMP_START}" -to "${TIMESTAMP_END}" -map 0:a:0 -c:a:0 mp3 "${CHAPTER_FILE}" 2>/dev/null
        ffmpeg -y -i "${CHAPTER_FILE}" -c copy "${CHAPTER_TEMP_FILE}" 2>/dev/null
        mv "${CHAPTER_TEMP_FILE}" "${CHAPTER_FILE}"
    done

    rm "${TEMP_FILE}"
#    rm "${CHAPTERS_FILE}"
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
