# Design System Strategy: The Elevated Agent

## 1. Overview & Creative North Star: "The Precision Atelier"
For high-performing agents, "standard" is the enemy of efficiency. This design system moves away from the generic "app-in-a-box" look toward **The Precision Atelier**. Our Creative North Star focuses on a high-end, editorial approach to utility. We replace rigid, boxed-in grids with a fluid, layered experience that feels like a bespoke digital workspace. 

By leveraging intentional asymmetry, high-contrast typography scales, and a departure from traditional structural lines, we create an environment that feels authoritative yet breathable. We are not just building a tool; we are designing a signature workflow where every pixel feels curated, not just placed.

---

## 2. Colors & Surface Philosophy
The palette is rooted in a sophisticated light-gray base, using our emerald, amber, and red accents as functional "beacons" rather than mere decoration.

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders to section content. Boundaries must be defined solely through background color shifts or subtle tonal transitions. For example, a `surface-container-low` section sitting on a `surface` background provides enough contrast to indicate a change in context without the visual noise of a stroke.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers—like stacked sheets of fine vellum.
- **Base:** `surface` (#f8f9fb)
- **Deepest Depth:** `surface-container-low` (#f3f4f6) for background grouping.
- **Primary Interaction Surface:** `surface-container-lowest` (#ffffff) for the highest-priority cards.
- **Nesting:** To define importance, nest a `surface-container-highest` element within a `surface-container` to create a "recessed" look for secondary metadata.

### The "Glass & Gradient" Rule
To elevate the experience beyond flat Material Design:
- **Floating Elements:** Use `surface-container-lowest` at 80% opacity with a `backdrop-filter: blur(20px)` for bottom navigation bars and floating action buttons.
- **Signature CTAs:** Main action buttons should use a linear gradient from `primary` (#006c49) to `primary-container` (#10b981) at a 135-degree angle. This adds "soul" and a tactile, premium depth.

---

## 3. Typography: Editorial Authority
We use **Inter** not as a system font, but as a brand anchor. The hierarchy is designed to guide the agent's eye to critical data points through extreme scale contrast.

- **Display (Large/Medium):** Reserved for high-impact status updates or daily targets. These should feel like magazine headlines—bold and unapologetic.
- **Headline (Small) & Title (Large):** Used for navigation and section headers. Combine these with `primary` color accents to denote current location.
- **The "Data-Heavy" Body:** `body-md` is our workhorse. Ensure a line height of at least 1.5x to maintain readability during fast-paced field work.
- **Labels:** Use `label-md` in `on-surface-variant` (#3c4a42) for metadata. The slight green tint in the gray provides a "custom-mixed" feel that aligns with the emerald brand identity.

---

## 4. Elevation & Depth: Tonal Layering
Traditional shadows are often "muddy." In this system, we use light to define space.

- **The Layering Principle:** Use the spacing scale (e.g., `8` or `2rem`) to create "breathing room" between containers. Depth is achieved by stacking `surface-container-lowest` cards on `surface-dim` backgrounds.
- **Ambient Shadows:** When a card must float, use a multi-layered shadow: `0 4px 20px 0 rgba(25, 28, 30, 0.04), 0 12px 40px 0 rgba(25, 28, 30, 0.08)`. This mimics soft, natural ambient light.
- **The "Ghost Border" Fallback:** If a border is required for accessibility in complex forms, use `outline-variant` (#bbcabf) at **15% opacity**. High-contrast, 100% opaque borders are strictly forbidden.
- **Glassmorphism:** Use for "Overlays." When a modal appears, the background should not just dim; it should blur, keeping the agent grounded in their previous context while focusing on the task at hand.

---

## 5. Components

### Buttons & Chips
- **Primary Button:** Gradient-filled (`primary` to `primary-container`), `xl` (1.5rem) rounded corners. No border.
- **Secondary/Ghost:** `surface-container-high` background with `on-surface` text. 
- **Chips:** For status (e.g., "Active," "Pending"), use `primary-fixed` or `secondary-fixed` backgrounds. The roundedness should be `full` to contrast against the `lg` (1rem) roundedness of the main cards.

### Input Fields
- **Floating Architecture:** Input fields should not have bottom lines. Use a `surface-container-low` background with an `md` (0.75rem) corner radius. Upon focus, transition the background to `surface-container-lowest` and apply a "Ghost Border" of `primary`.

### Cards & Lists
- **The No-Divider Rule:** Forbid the use of 1px dividers between list items. Instead, use a `1.5` (0.375rem) vertical spacing gap or an alternating tonal shift between `surface-container-low` and `surface-container-lowest`.
- **Asymmetric Cards:** For "Featured" agent stats, use a card that spans the full width on the left but maintains a `spacing-4` margin on the right to create a sophisticated, unbalanced editorial look.

### Bottom Navigation
- **Floating Dock:** The bottom nav should not be pinned to the screen edge. Use a "floating dock" style: a `surface-container-lowest` container with `xl` (1.5rem) rounded corners, sitting `spacing-4` away from the screen bottom, utilizing the Glassmorphism rule.

---

## 6. Do's and Don'ts

### Do
- **Do** use whitespace as a structural element. If a section feels crowded, increase the spacing from `4` to `6` rather than adding a line.
- **Do** use `primary` (#006c49) for positive actions and `tertiary` (#b91a24) for destructive ones, but keep them within containers to prevent the UI from feeling "loud."
- **Do** prioritize `surface-container-lowest` for information the agent needs to touch/interact with.

### Don't
- **Don't** use pure black (#000000) for text. Always use `on-surface` (#191c1e) to maintain the premium, soft-contrast feel.
- **Don't** use standard Material Design "Drop Shadows" (Level 1-5). Use the Ambient Shadow specification defined in Section 4.
- **Don't** use icons without purpose. Every icon must be accompanied by a label or have a globally recognized meaning within the agent's specific industry.