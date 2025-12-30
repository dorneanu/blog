#!/bin/bash

# Loop Habits to Blog Data Converter
# Converts Loop Habits CSV export to blog-compatible habit tracking data
# Only counts YES_MANUAL entries (actual sessions), ignoring YES_AUTO (weekly goal achievements)

set -e

# Default paths
INPUT_FILE="${1:-tmp/Checkmarks.csv}"
OUTPUT_FILE="${2:-static/data/habits-2025.csv}"

# Validate input file exists
if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: Input file '$INPUT_FILE' not found!"
    echo "Usage: $0 [input_csv] [output_csv]"
    echo "Example: $0 tmp/Checkmarks.csv static/data/habits-2025.csv"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$(dirname "$OUTPUT_FILE")"

echo "Converting Loop Habits data..."
echo "Input:  $INPUT_FILE"
echo "Output: $OUTPUT_FILE"

# Convert the data using awk
awk -F',' '
# Process header row
NR==1 {
    print "date,meditation,cold_shower,pranayama,reading,sport,djembe,session_20min"
    next
}

# Process data rows
NR>1 {
    # Extract date and habit values
    date = $1
    meditation = ($2 == "YES_MANUAL") ? 1 : 0
    cold_shower = ($3 == "YES_MANUAL") ? 1 : 0
    pranayama = ($4 == "YES_MANUAL") ? 1 : 0
    reading = ($5 == "YES_MANUAL") ? 1 : 0
    sport = ($6 == "YES_MANUAL") ? 1 : 0
    djembe = ($7 == "YES_MANUAL") ? 1 : 0
    session_20min = ($8 == "YES_MANUAL") ? 1 : 0

    # Output the converted row
    print date "," meditation "," cold_shower "," pranayama "," reading "," sport "," djembe "," session_20min
}' "$INPUT_FILE" > "$OUTPUT_FILE"

# Generate summary statistics
echo ""
echo "Conversion complete! Summary:"
echo "=========================="

# Count total entries and completed sessions for each habit
tail -n +2 "$OUTPUT_FILE" | awk -F',' '
{
    total++
    meditation_count += $2
    cold_shower_count += $3
    pranayama_count += $4
    reading_count += $5
    sport_count += $6
    djembe_count += $7
    session_20min_count += $8
}
END {
    printf "Total days: %d\n", total
    printf "Meditation: %d/%d (%.1f%%)\n", meditation_count, total, (meditation_count/total)*100
    printf "Cold Shower: %d/%d (%.1f%%)\n", cold_shower_count, total, (cold_shower_count/total)*100
    printf "Pranayama: %d/%d (%.1f%%)\n", pranayama_count, total, (pranayama_count/total)*100
    printf "Reading: %d/%d (%.1f%%)\n", reading_count, total, (reading_count/total)*100
    printf "Sport: %d/%d (%.1f%%)\n", sport_count, total, (sport_count/total)*100
    printf "Djembe: %d/%d (%.1f%%)\n", djembe_count, total, (djembe_count/total)*100
    printf "20min Session: %d/%d (%.1f%%)\n", session_20min_count, total, (session_20min_count/total)*100
}'

echo ""
echo "✅ Data conversion successful!"
echo "📊 Use these habit names in your shortcodes:"
echo "   - meditation"
echo "   - cold_shower"
echo "   - pranayama"
echo "   - reading"
echo "   - sport"
echo "   - djembe"
echo "   - session_20min"
echo ""
echo "📝 Shortcode example:"
echo "   {{< habit-tracker-filtered csv=\"/data/habits-2025.csv\" year=\"2025\" habit=\"reading\" >}}"