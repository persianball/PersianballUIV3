---
name: Obsidian Gold Athletics
colors:
  surface: '#16130b'
  surface-dim: '#16130b'
  surface-bright: '#37393a'
  surface-container-lowest: '#110e07'
  surface-container-low: '#1f1b13'
  surface-container: '#231f17'
  surface-container-high: '#2d2a21'
  surface-container-highest: '#38342b'
  on-surface: '#eae1d4'
  on-surface-variant: '#d0c5af'
  inverse-surface: '#eae1d4'
  inverse-on-surface: '#343027'
  outline: '#99907c'
  outline-variant: '#4d4635'
  surface-tint: '#eac249'
  primary: '#ffe9b0'
  on-primary: '#3d2f00'
  primary-container: '#f2ca50'
  on-primary-container: '#6b5500'
  inverse-primary: '#745b00'
  secondary: '#c6c6c6'
  on-secondary: '#2f3131'
  secondary-container: '#454747'
  on-secondary-container: '#b5b5b5'
  tertiary: '#d1efff'
  on-tertiary: '#003546'
  tertiary-container: '#82d9ff'
  on-tertiary-container: '#005f7a'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffe08a'
  primary-fixed-dim: '#eac249'
  on-primary-fixed: '#241a00'
  on-primary-fixed-variant: '#574400'
  secondary-fixed: '#e2e2e2'
  secondary-fixed-dim: '#c6c6c6'
  on-secondary-fixed: '#1a1c1c'
  on-secondary-fixed-variant: '#454747'
  tertiary-fixed: '#bde9ff'
  tertiary-fixed-dim: '#7ad1f7'
  on-tertiary-fixed: '#001f2a'
  on-tertiary-fixed-variant: '#004d64'
  background: '#16130b'
  on-background: '#eae1d4'
  surface-variant: '#38342b'
  gold-metallic: '#d4af37'
  obsidian-deep: '#0c0f0f'
  graphite-tint: '#333535'
typography:
  display-lg:
    fontFamily: Vazirmatn
    fontSize: 42px
    fontWeight: '800'
    lineHeight: 52px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Vazirmatn
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-md:
    fontFamily: Vazirmatn
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  body-lg:
    fontFamily: Vazirmatn
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Vazirmatn
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-sm:
    fontFamily: Vazirmatn
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
spacing:
  unit: 8px
  margin-mobile: 20px
  gutter: 16px
  stack-sm: 8px
  stack-md: 24px
  stack-lg: 48px
  max-width: 1280px
---

## Brand & Style

This design system is engineered for the elite athlete and enthusiast, blending the raw intensity of the field with the structural precision of high-end architecture. The brand personality is prestigious, authoritative, and uncompromising.

The aesthetic follows a **Brutalist-Minimalist** hybrid. It utilizes deep blacks to create a "void" where content and gold accents appear to float, but rejects all softness in favor of sharp, 90-degree geometry. The emotional response is one of exclusivity and technical excellence—moving away from the cluttered look of traditional sports apps toward a gallery-like experience. Every interaction is deliberate, sharp, and high-stakes.

## Colors

The palette is anchored in a dark-mode-first philosophy to highlight premium content and high-contrast photography.

- **Primary (Metallic Gold):** Used for key calls-to-action, active states, and achievement-based iconography. It represents excellence and the podium.
- **Secondary (Obsidian):** The foundation of the UI. This deep charcoal-black provides the necessary depth for structural layering.
- **Tertiary (Graphite):** Used for surface levels that require subtle separation from the primary obsidian background.
- **Neutral (Silver/White):** High-readiness typography uses a crisp silver-white, while lower-priority metadata uses a muted variant to maintain hierarchy.

## Typography

The typography system is optimized for **RTL (Right-to-Left)** Persian script using Vazirmatn. 

- **Alignment:** All text is right-aligned by default. 
- **Hierarchy:** Display and Headline levels use extra-bold weights to mimic the impact of physical sports headlines and architectural signage.
- **Numerals:** Use Western Arabic numerals for scores, rankings, and clock times (e.g., 90', 2-1) for international clarity, but localized Persian numerals for long-form body text and dates.
- **Readability:** Body text maintains a generous line height (1.5x) to ensure legibility against the deep dark background, preventing "haloing" effects.

## Layout & Spacing

The layout follows a **Fluid Grid** model with high-margin "breathing room" to maintain a luxury, spacious feel.

- **Mobile:** A 4-column grid with 20px side margins. 
- **Desktop:** A 12-column centered grid with a maximum content width of 1280px.
- **RTL Logic:** Spacing and padding must flip horizontally.
- **Rhythm:** An 8px base unit governs all dimensions. Use aggressive vertical stacks (48px+) between major sections to emphasize the "gallery" aesthetic and prevent a cluttered appearance.

## Elevation & Depth

This design system rejects soft shadows in favor of **Tonal Layering** and **High-Contrast Outlines**.

1.  **Base:** Obsidian (#121414) background.
2.  **Surface Tier:** Surfaces are defined by 1px solid borders rather than shadows. Use `outline-variant` (#4D4635) for standard containers and `primary` gold for active ones.
3.  **Flat Stacking:** Elements are visually elevated by using lighter charcoal values (Surface Container High) against the Base Obsidian, creating a "step" effect.
4.  **Ghost Borders:** A 1px solid stroke at 10-15% white opacity is used to define edges of cards without adding weight or blur.
5.  **No Shadows:** Do not use drop shadows or ambient blurs. All depth is communicated through color contrast and crisp line-work.

## Shapes

The shape language is "Absolute Geometric." All UI elements—including buttons, cards, input fields, and images—must have **zero roundedness**.

- **Sharp Corners:** Every corner is a 90-degree angle. This reinforces the technical, architectural, and brutalist nature of the design system.
- **Media:** Player portraits and stadium imagery should be cropped into sharp rectangles. Do not use circular avatars; use square crops to maintain the rigid visual language.

## Components

- **Buttons:** All buttons are perfectly rectangular. Primary buttons feature a solid gold (#D4AF37) fill with black text. Secondary buttons use a 1.5px gold border with no fill.
- **Cards:** Defined by a 1px `outline-variant` border. No rounded corners and no shadows. Backgrounds should be `surface-container-low`.
- **Live Badges:** A sharp-edged rectangle with a solid primary gold fill and black "LIVE" text in Persian (زنده).
- **Lists:** Player rankings or league tables use alternating obsidian and graphite rows. Dividers are 1px solid lines; avoid soft transitions.
- **Inputs:** Sharp-cornered fields with 1px graphite borders. On focus, the entire perimeter transitions to gold.
- **Scoreboard:** Large, high-contrast numerals. The container is a solid, sharp-edged block.
- **Imagery:** Use high-contrast, desaturated photography. All images must be framed in sharp-edged containers with no border radius.