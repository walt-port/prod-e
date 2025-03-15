# Documentation Style Guide

## Overview

This style guide establishes consistent formatting and organization standards for all documentation in the Production Experience Showcase (prod-e) project. Following these guidelines ensures documentation is clear, consistent, and easy to navigate.

## Table of Contents

- [File Organization](#file-organization)
- [File Naming](#file-naming)
- [Document Structure](#document-structure)
- [Markdown Formatting](#markdown-formatting)
- [Writing Style](#writing-style)
- [Visual Elements](#visual-elements)
- [Version Control](#version-control)
- [Templates](#templates)

## File Organization

- Store all project-wide documentation in the `/docs` directory
- Store audit-related documentation in the `/audits` directory
- Group related documents in subdirectories when appropriate
- Reference locations with relative paths to maintain portability

## File Naming

- Use kebab-case for all documentation files (e.g., `network-architecture.md`)
- Be descriptive but concise with filenames
- Avoid special characters, spaces, and lengthy filenames
- Use consistent naming patterns for related documents

## Document Structure

Every documentation file should include:

1. **Title**: Single level-1 heading (`#`) with the document's purpose
2. **Overview**: Brief introduction explaining the document's purpose
3. **Table of Contents**: For documents longer than three sections
4. **Content Sections**: Organized with appropriate headings
5. **Related Documentation**: Links to related documents
6. **Version Information**: Last updated date and version number

Example structure:

```markdown
# Document Title

## Overview

Brief description of the document's purpose and scope.

## Table of Contents

- [Section 1](#section-1)
- [Section 2](#section-2)

## Section 1

Content...

## Section 2

Content...

## Related Documentation

- [Document 1](./document-1.md)
- [Document 2](./document-2.md)

---

**Last Updated**: 2025-03-15
**Version**: 1.0
```

## Markdown Formatting

### Headings

- Use title case for all headings (e.g., "Network Architecture Overview")
- Maintain a clear heading hierarchy (don't skip levels)
- Include a single level-1 heading (`#`) as the document title
- Use level-2 headings (`##`) for main sections
- Use level-3 headings (`###`) for subsections

### Lists

- Use unordered lists (`-`) for items without sequence
- Use ordered lists (`1.`) for sequential steps or prioritized items
- Maintain consistent indentation for nested lists (2 spaces)
- End each list item with a period if it's a complete sentence

### Code Blocks

- Use fenced code blocks with language identifiers:

  ```typescript
  const example = 'This is TypeScript code';
  ```

- Use inline code formatting for short code snippets, commands, or filenames: `npm install`
- For terminal commands, include the command prompt:

  ```bash
  $ npm run deploy
  ```

### Tables

- Include a header row with column titles
- Use column alignment as appropriate (default left-aligned)
- Keep tables simple and readable
- Include a blank line before and after tables

Example:

```markdown
| Name | Type | Description  |
| ---- | ---- | ------------ |
| VPC  | AWS  | Main network |
```

### Links

- Use descriptive link text, not "click here" or URLs
- Use relative paths for internal documentation links
- Include the file extension in links
- For external links, include the full URL

### Emphasis

- Use **bold** (`**text**`) for emphasis or UI elements
- Use _italics_ (`*text*`) for introducing new terms or parameters
- Use `code formatting` for code, commands, or file paths
- Use blockquotes (`>`) for notes, warnings, or quoted text

## Writing Style

- Use clear, concise language
- Write in present tense (e.g., "The system sends a notification")
- Use active voice over passive voice
- Define acronyms on first use
- Use consistent terminology throughout documentation
- Target a technical audience but avoid unnecessary jargon
- Include examples when explaining complex concepts

## Visual Elements

### Diagrams

- Include architecture diagrams for complex systems
- Use consistent visual style across all diagrams
- Include captions explaining the diagram
- Store diagram source files if available
- Format:

```markdown
![Diagram Title](../assets/images/diagram-name.png)

_Figure 1: Description of the diagram_
```

### Screenshots

- Include screenshots of UIs and dashboards when relevant
- Crop screenshots to focus on relevant content
- Highlight important areas when appropriate
- Include captions explaining the screenshot

## Version Control

- Include a version information section at the end of each document
- Format the version information consistently:

```markdown
---

**Last Updated**: YYYY-MM-DD
**Version**: X.Y
**Updated By**: Name
```

- Update this information whenever the document changes
- Consider including a brief changelog for significant documents

## Templates

Use the provided templates for specific documentation types:

- [General Documentation Template](./templates/general-documentation-template.md)
- [Component Documentation Template](./templates/component-documentation-template.md)
- [Process Documentation Template](./templates/process-documentation-template.md)

## Related Documentation

- [Documentation Inventory](./documentation-inventory.md)
