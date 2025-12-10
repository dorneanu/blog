---
title: "Habit Tracker Demo"
date: 2025-12-09
draft: false
tags: ["demo", "habits", "visualization", "d3"]
---

# Habit Tracker Feature Demo

This post demonstrates the habit tracker shortcode functionality using D3.js. The tracker visualizes your daily habits in a GitHub-style contribution calendar, making it easy to see patterns and track consistency over time.

## Live Demo: 2025 Reading Habit

Below is a live habit tracker showing real reading tracking data for 2025. The visualization displays actual completion data with statistics.

{{< habit-tracker-simple csv="/data/reading-2025.csv" year="2025" >}}

## Using Tabs with Multiple Habits

You can organize multiple habit trackers in tabs for a cleaner interface:

```
{{</* tabs */>}}
  {{</* tab title="Reading" */>}}
    {{</* habit-tracker-simple csv="/data/reading-2025.csv" year="2025" */>}}
  {{</* /tab */>}}
  {{</* tab title="Exercise" */>}}
    {{</* habit-tracker-simple csv="/data/exercise-2025.csv" year="2025" */>}}
  {{</* /tab */>}}
{{</* /tabs */>}}
```

This creates a tabbed interface where each habit has its own tab.

## How It Works

The habit tracker shortcode loads data from a CSV file and creates an interactive annual calendar visualization for each habit. The visualization shows:

- **Completion heatmap** - Green intensity indicates consistency (darker = more consistent)
- **Statistics** - Total days completed, completion rate, and current streak
- **Interactive tooltips** - Hover over any day to see the date and completion status
- **Monthly layout** - Organized by weeks with month labels at the top

### Data Format

Your CSV file should follow this simple format:

```csv
date,reading
2025-01-01,0
2025-01-02,1
2025-01-03,1
2025-01-04,0
```

For multiple habits:

```csv
date,reading,exercise,meditation,writing
2025-01-01,1,0,1,0
2025-01-02,1,1,1,1
2025-01-03,1,1,0,1
```

**Requirements:**
- First column must be named `date` in `YYYY-MM-DD` format
- Subsequent columns are your habits (use any names you want)
- Use `1` for days you completed the habit, `0` for days you missed
- The tracker automatically detects all habits from your column names

### Usage Example

1. **Create your CSV file** and save it to `static/data/`:
   ```
   static/data/reading-2025.csv
   ```

2. **Add the shortcode** to your blog post (markdown or org-mode):
   ```markdown
   {{</* habit-tracker-simple csv="/data/reading-2025.csv" year="2025" */>}}
   ```

3. **Build your site** - Hugo will render the interactive visualization

**Note:** There are two versions available:
- `habit-tracker-simple` - Lightweight, uses CSS Grid (recommended)
- `habit-tracker` - Full D3.js version with more features but heavier

### Shortcode Parameters

- `csv` (required) - Path to your CSV file relative to `static/` directory
- `year` (optional) - Year to display, defaults to current year

## Features

- **Multiple Habits** - Automatically creates a separate calendar for each habit in your CSV
- **Annual View** - Shows the entire year at a glance, just like GitHub's contribution graph
- **Real-time Stats** - Calculates completion rate, total completed days, and current streak
- **Interactive** - Hover over any day to see detailed information
- **Responsive Design** - Works on all screen sizes
- **Self-contained** - Loads D3.js automatically, no additional setup needed
- **Color-coded** - Uses GitHub's familiar green color scale for consistency visualization

## Use Cases

This habit tracker is perfect for:

- **Personal Goals** - Track daily habits like reading, exercise, meditation
- **Productivity** - Monitor writing, coding, or learning streaks
- **Health** - Log daily activities, water intake, sleep quality
- **Professional** - Track client calls, blog posts, or study sessions
- **Annual Reviews** - Visualize your consistency over the entire year

## Tips

- **Update regularly** - Add new entries to your CSV as you complete habits
- **Rebuild to refresh** - Run `hugo` to update the visualization with new data
- **Multiple trackers** - You can have different CSV files for different years or categories
- **Descriptive names** - Use clear habit names - they appear as section titles
- **No database needed** - Everything runs client-side from your static CSV file

## Technical Details

- Built with [D3.js v7](https://d3js.org/) for data visualization
- GitHub-style color scheme for familiarity
- Calendar layout optimized for annual viewing
- Handles future dates gracefully (grays them out)
- Calculates streaks from most recent day backwards
