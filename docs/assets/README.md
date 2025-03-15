# Documentation Assets

## Overview

This directory contains assets used in project documentation, such as diagrams, screenshots, and other visual elements. Organizing these assets centrally helps maintain consistency and makes them easier to update.

## Directory Structure

- `images/` - Contains image files (PNG, JPG, SVG) for diagrams and screenshots
  - `architecture/` - System architecture diagrams
  - `ui/` - User interface screenshots
  - `workflow/` - Process and workflow diagrams

## Asset Guidelines

### File Naming

- Use kebab-case for all filenames (e.g., `network-diagram.png`)
- Include a descriptor of the content type (e.g., `alb-architecture-diagram.svg`)
- For versioned assets, include the version number (e.g., `system-architecture-v2.png`)

### Image Formats

- Use **SVG** for diagrams when possible (better for scaling and updates)
- Use **PNG** for screenshots and diagrams with transparency
- Use **JPG** only for photographs or complex images with no transparency needs

### Resolution and Size

- Optimize images for web display (compress when possible)
- Diagrams should be readable at standard viewing sizes
- Screenshots should be cropped to focus on relevant content

## Source Files

For diagrams created with tools like Draw.io, Lucidchart, or Figma, consider storing the source files in this directory as well. This allows for easier updates in the future.

## Usage in Documentation

When referencing assets in Markdown documentation, use relative paths:

```markdown
![Architecture Diagram](../assets/images/architecture/system-overview.png)

_Figure 1: Overview of system architecture_
```

---

**Last Updated**: 2025-03-15
**Version**: 1.0
