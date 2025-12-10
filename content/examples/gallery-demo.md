---
title: "GLightbox Gallery Demo"
date: 2025-12-09
draft: false
tags: ["demo", "gallery", "images"]
---

# GLightbox Gallery Feature Demo

This post demonstrates the new gallery shortcode functionality using GLightbox. Galleries allow you to group related images together and navigate through them in the lightbox viewer.

## Gallery 1: Conference Photos

Here's a gallery of conference photos. Click any image to open the lightbox, then use arrow keys or on-screen controls to navigate between images in the gallery.

{{< gallery name="conference" >}}
  {{< gallery-img
      src="/posts/img/2014/berlinsides/799eb9f276fed2ef043b83af21c41094.jpg"
      title="Conference Venue"
      caption="The main conference hall setup with attendees gathering for the opening session"
      pos="bottom" >}}
  {{< gallery-img
      src="/posts/img/2014/berlinsides/382f305b366cbb0d544207ae28eff003.jpg"
      title="Speaker Session"
      caption="A speaker presenting technical content to an engaged audience"
      pos="bottom" >}}
  {{< gallery-img
      src="/posts/img/2014/berlinsides/48aa1cf9082a5fab4172f49cb2f890c3.jpg"
      title="Networking Break"
      caption="Attendees networking and discussing ideas during the conference break"
      pos="bottom" >}}
{{< /gallery >}}

## Gallery 2: Development Screenshots

This is a separate gallery showing development environment screenshots. Notice how these images are grouped separately from the conference gallery above.

{{< gallery name="development" >}}
  {{< gallery-img
      src="/posts/img/2014/eclipse-ddms/eclipse_project_src.png"
      title="Project Structure"
      caption="Eclipse IDE showing the project source code structure and file organization"
      pos="left" >}}
  {{< gallery-img
      src="/posts/img/2014/eclipse-ddms/eclipse_running_processes.png"
      title="Running Processes"
      caption="DDMS perspective displaying running processes and their resource usage"
      pos="left" >}}
  {{< gallery-img
      src="/posts/img/2014/eclipse-ddms/eclipse_debug_set_port.png"
      title="Debug Configuration"
      caption="Setting up debug port configuration for remote debugging session"
      pos="left" >}}
  {{< gallery-img
      src="/posts/img/2014/eclipse-ddms/eclipse_view_breakpoints.png"
      title="Breakpoints View"
      caption="Debugging interface showing configured breakpoints and their conditions"
      pos="left" >}}
{{< /gallery >}}

## How It Works

The gallery shortcode system consists of two parts:

1. **Gallery Container** - Wraps images in a responsive grid layout
2. **Gallery Images** - Individual images that belong to the same gallery group

### Usage Example

```markdown
{{</* gallery name="my-gallery" */>}}
  {{</* gallery-img
      src="/path/to/image.jpg"
      title="Image Title"
      caption="Detailed description shown in lightbox"
      pos="bottom" */>}}
  {{</* gallery-img
      src="/path/to/another.jpg"
      title="Another Image"
      caption="More details here" */>}}
{{</* /gallery */>}}
```

### Features

- **Grouped Navigation**: Images in the same gallery can be navigated using arrow keys or on-screen controls
- **Separate Galleries**: Multiple galleries on the same page remain independent
- **Responsive Grid**: Automatically adjusts to screen size
- **Captions & Titles**: Each image can have a title (shown below thumbnail) and detailed caption (shown in lightbox)
- **Flexible Positioning**: Caption position in lightbox can be customized (top, bottom, left, right)

## Comparison with Single Image Shortcode

You can still use the original `gbox` shortcode for standalone images:

{{< gbox src="/posts/img/2014/82130fa5ef04488358dd08b0a22542cf.jpg"
          title="Standalone Image"
          caption="This is a single image using the gbox shortcode, not part of any gallery"
          pos="left" >}}

The standalone image opens independently and doesn't group with the galleries above.
