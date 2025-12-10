---
title: "Garmin Activity Tracker Demo"
date: 2025-12-10
draft: false
tags: [fitness, visualization, hugo]
---

This page demonstrates the Garmin activity tracker shortcode that visualizes your workout activities from a Garmin watch export.

## Activity Dashboard

### All Activities (Stacked)

{{< garmin-tracker csv="/data/garmin-activities-demo.csv" year="2025" >}}

### With Tabs (Organized)

{{< garmin-tracker csv="/data/garmin-activities-demo.csv" year="2025" summary="true" >}}

{{< tabs >}}
  {{< tab title="Cycling" >}}
    {{< garmin-tracker csv="/data/garmin-activities-demo.csv" year="2025" activities="Cycling" >}}
  {{< /tab >}}
  {{< tab title="Strength Training" >}}
    {{< garmin-tracker csv="/data/garmin-activities-demo.csv" year="2025" activities="Strength Training" >}}
  {{< /tab >}}
  {{< tab title="Running" >}}
    {{< garmin-tracker csv="/data/garmin-activities-demo.csv" year="2025" activities="Running" >}}
  {{< /tab >}}
{{< /tabs >}}

## How to Use

1. Export your activities from Garmin Connect as CSV
2. Save the file to `static/data/garmin-activities-YEAR.csv`
3. Add the shortcode to your post

### Show All Activities (default)

```
{{</* garmin-tracker csv="/data/garmin-activities-demo.csv" year="2025" */>}}
```

### Show Only Specific Activities

```
{{</* garmin-tracker csv="/data/garmin-activities-demo.csv" year="2025" activities="Cycling" */>}}
```

### Organize Activities in Tabs

For a cleaner UI with multiple activity types, show the summary first, then use the tabs shortcode:

```
{{</* garmin-tracker csv="/data/garmin-activities-demo.csv" year="2025" summary="true" */>}}

{{</* tabs */>}}
  {{</* tab title="Cycling" */>}}
    {{</* garmin-tracker csv="/data/garmin-activities-demo.csv" year="2025" activities="Cycling" */>}}
  {{</* /tab */>}}
  {{</* tab title="Strength Training" */>}}
    {{</* garmin-tracker csv="/data/garmin-activities-demo.csv" year="2025" activities="Strength Training" */>}}
  {{</* /tab */>}}
  {{</* tab title="Running" */>}}
    {{</* garmin-tracker csv="/data/garmin-activities-demo.csv" year="2025" activities="Running" */>}}
  {{</* /tab */>}}
{{</* /tabs */>}}
```

**Parameters:**
- `summary="true"` - Shows only the summary statistics (no charts)

The tracker will automatically:
- Calculate summary statistics (activities, distance, time)
- Group activities by type
- Show monthly bar charts for each activity type
- Display values directly on bars with activity count on hover
- Filter by activity types if specified

## Features

- **Smart Metrics**: Shows distance (km) for activities like cycling, time (minutes) for activities like strength training
- **Interactive Charts**: Hover over bars to see detailed activity counts
- **Responsive Design**: Uses Tachyons CSS for clean, responsive styling
- **Flexible Filtering**: Show all activities or filter to specific types
- **Composable**: Combine with tabs shortcode for organized multi-activity views
