# Design System Strategy: The Sonic Architect

## 1. Overview & Creative North Star
The design system for this call monitoring dashboard is governed by the Creative North Star: **"The Sonic Architect."** In an industry often cluttered with chaotic waveforms and rigid data tables, our goal is to transform auditory data into a cinematic, structured environment. We move away from the "standard dashboard" by treating the UI not as a flat screen, but as a deep, layered command center.

This system rejects the "template" look. We utilize **intentional asymmetry**—offsetting metric cards and utilizing variable-width columns—to guide the eye toward critical anomalies. By leveraging high-contrast typography scales and tonal depth, we create an editorial experience that feels less like a utility and more like a high-end intelligence tool.

## 2. Colors & Surface Philosophy
The palette is rooted in a deep, nocturnal foundation. It is designed to reduce ocular strain during long monitoring shifts while making accent colors "pop" with intent.

*   **Primary (Emerald):** Used exclusively for "Active," "Resolved," or "Positive Sentiment" states.
*   **Secondary (Amber):** Reserved for "Caution," "High Latency," or "Escalating Tones."
*   **Tertiary (Red):** Used sparingly for "Dropped Calls" or "Critical Compliance Violations."

### The "No-Line" Rule
Standard UI relies on 1px borders to separate content. **This design system prohibits the use of solid lines for sectioning.** Boundaries must be defined through background color shifts. Use `surface-container-low` for the main workspace and `surface-container-high` for elevated widgets. This creates a sophisticated, "carved" aesthetic rather than a "pasted" one.

### Surface Hierarchy & Nesting
Think of the UI as physical layers of smoked glass:
*   **Base Layer:** `surface` (#0b1326) – The infinite depth.
*   **The Workspace:** `surface-container-low` (#131b2e) – The primary stage for content.
*   **The Widget:** `surface-container-high` (#222a3d) – Interactive modules.
*   **The Floating Element:** `surface-bright` (#31394d) – Modals or tooltips.

### The "Glass & Gradient" Rule
To add "soul" to the data, use a subtle linear gradient on primary action items (e.g., from `primary_container` to `primary`). For the sidebar, apply a `backdrop-blur` of 20px over a semi-transparent `surface_container` to let the background depth bleed through, creating an integrated, premium feel.

## 3. Typography: Editorial Authority
We use **Inter** not as a generic sans-serif, but as a tool for hierarchy.

*   **Display Scales:** Use `display-lg` (3.5rem) for singular, high-impact metrics (e.g., "Total Active Calls"). Tighten the letter-spacing to -0.02em to give it an authoritative, "newsroom" feel.
*   **The Label Contrast:** Pair large displays with `label-sm` (0.6875rem) in all-caps with increased letter-spacing (0.05em). This juxtaposition between massive numbers and tiny, precise labels is a hallmark of high-end editorial design.
*   **Body Copy:** Use `body-md` for call transcripts. Maintain a generous line height to ensure readability in high-stress environments.

## 4. Elevation & Depth
In this system, depth is a functional tool, not just a decoration.

*   **Tonal Layering:** Instead of a shadow, place a `surface_container_highest` card inside a `surface_container_low` area. This "inverted lift" creates a natural focal point.
*   **Ambient Shadows:** For floating modals, use a custom shadow: `0px 24px 48px rgba(6, 14, 32, 0.4)`. The shadow color must be a darkened version of our background, never pure black, to maintain the "navy" atmospheric glow.
*   **The Ghost Border:** If a boundary is required for accessibility (e.g., an input field), use the `outline_variant` at 15% opacity. It should be felt, not seen.
*   **Glassmorphism:** Navigation sidebars and top-level filters should use a "frosted" effect. This keeps the user grounded in the dashboard's depth even when menus are open.

## 5. Components

### Sidebar Navigation
The sidebar is the "anchor." Use a `surface-container-low` background with a subtle right-side `surface-bright` glow instead of a border. Active states should not use a box; instead, use a vertical "pill" of `primary` color (#4edea3) 4px wide on the far left, with the text shifting to `on_surface`.

### Interactive Cards & Lists
*   **No Dividers:** Forbid the use of horizontal rules. Separate list items using a `1.5` (0.3rem) spacing gap or a subtle shift from `surface-container` to `surface-container-low` on hover.
*   **Roundedness:** Use `lg` (1rem) for main dashboard cards to feel modern and approachable. Use `sm` (0.25rem) for small internal utility buttons to maintain a "precise instrument" look.

### Buttons
*   **Primary:** A gradient from `primary_container` (#10b981) to `primary` (#4edea3). No border.
*   **Tertiary:** Ghost style. Only text in `on_surface_variant`, transitioning to `on_surface` with a subtle `surface-container-high` background on hover.

### Input Fields
Avoid the "box" look. Use `surface-container-lowest` as the fill color with a `sm` (0.25rem) corner radius. The label should sit above the field in `label-md` with 60% opacity.

### Call Monitoring Chips
Use `full` roundedness. A "Live" chip should use a pulsing `primary` dot next to the text. For warning states, use `secondary_container` background with `on_secondary_container` text—ensuring the amber tones are legible against the dark slate.

## 6. Do's and Don'ts

### Do:
*   **Do** use `20` (4.5rem) and `24` (5.5rem) spacing scales to create "breathing room" between major sections. Space is a luxury; use it.
*   **Do** use `primary_fixed_dim` for icons to ensure they don't overpower the textual data.
*   **Do** use "Negative Space" as a separator. If two sections feel cluttered, increase the margin rather than adding a line.

### Don't:
*   **Don't** use 100% white (#FFFFFF). Use `on_surface` (#dae2fd) to keep the contrast elegant and soft on the eyes.
*   **Don't** use standard "drop shadows" with grey colors. Always tint your shadows with the background navy.
*   **Don't** use "Alert Red" for everything. Reserve `tertiary` for system-critical issues; use `secondary` (Amber) for general user attention.
*   **Don't** use a flat grid. Offset your columns slightly to create a more dynamic, editorial flow.