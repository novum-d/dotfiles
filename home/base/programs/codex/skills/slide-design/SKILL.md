---
name: slide-design
description: Create, revise, or review presentation slides with clear hierarchy, the four design principles, consistent styling, safe image fitting, and render-based quality checks. Use for Marp, PowerPoint-like decks, or Figma Slides; do not use for ordinary documents or application UI design.
---

# Slide Design

Create slides that communicate one clear point at presentation distance and remain consistent with the deck's existing visual system.

## Start from context

- Read applicable `AGENTS.md`, templates, theme files, and deck-specific rules before editing.
- Preserve the user's chosen format and existing design language unless redesign is requested.
- Identify the audience, allotted time, central takeaway, and whether the deck is for projection, reading, or both.
- Treat the editable source as canonical and generated HTML, PDF, or images as outputs.

## Apply the four design principles

- **Proximity:** Group a heading, explanation, image, and caption when they belong together. Separate unrelated groups with visibly larger space.
- **Alignment:** Align edges, baselines, columns, and repeated elements to a small number of guides. Avoid almost-aligned objects.
- **Repetition:** Reuse typography, colors, spacing, card shapes, image treatment, and slide patterns to make the deck feel like one system.
- **Contrast:** Create an obvious reading order with size, weight, color, and whitespace. Ensure foreground/background contrast; do not use color alone to encode meaning.

Use contrast deliberately. When every element is emphasized, nothing is emphasized.

## Control information density

- Give each slide one communicative role: claim, comparison, sequence, example, diagram, or conclusion.
- Write a takeaway title rather than a topic label when possible.
- Prefer about three visual groups or points. Split a slide before shrinking text to fit.
- Keep body copy in short phrases. Move detailed explanations, evidence, and transitions to speaker notes when appropriate.
- Use a diagram, table, or flow only when it makes a relationship easier to understand than concise prose.

## Fit images safely

- Reserve a bounded image area before choosing the displayed size.
- Preserve the source aspect ratio. Do not set both width and height unless they match that ratio.
- Prefer `max-width: 100%`, `max-height: 100%`, and `object-fit: contain` for images that must remain fully visible.
- Use intentional cropping with `object-fit: cover` only when losing edge content cannot change the meaning.
- Leave padding between an image and its container edge; include borders and captions in the available-height calculation.
- For wide or tall diagrams, enlarge the useful content, split the diagram, or redesign it instead of distorting it or making labels unreadable.
- Store images according to project conventions, reference them with stable paths, and give informative images meaningful alternative text.

For HTML-based slides, a safe default is:

```css
.image-frame {
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.image-frame img {
  display: block;
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
}
```

Adapt the container height to the title, subtitle, caption, and margins on the slide.

## Maintain visual consistency

- Reuse theme tokens and shared styles before adding one-off values.
- Keep title position, margins, column gaps, corner radii, and accent usage consistent across equivalent slide types.
- Use a limited type scale and color palette. Introduce a new visual pattern only when it communicates a different kind of content.
- Compare new slides with representative existing slides, especially the title, content, comparison, diagram, and summary patterns.

## Protect sensitive content

- Follow the user's disclosure constraints. Generalize company, service, customer, environment, and identifier names when requested.
- Keep enough technical detail to preserve the point, while removing names or values that could identify the system.

## Validate the rendered deck

After editing, render the deck in its actual output format and inspect every slide. Source review alone is insufficient.

Check:

- text, images, borders, shadows, and captions stay inside the slide;
- images load, preserve aspect ratio, and remain legible;
- no accidental clipping, awkward wrapping, or undersized text appears;
- alignment, spacing, contrast, and repeated styles remain consistent;
- the first slide, densest slides, diagrams, transitions, and final slide work at presentation size;
- speaker notes and timing still match the slide order.

Fix visible issues and render again. Do not declare completion from a successful export alone.
