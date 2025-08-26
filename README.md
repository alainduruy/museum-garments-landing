# Museum Garments Landing Page

A modern landing page for Museum Garments featuring an interactive WebGL background with Bayer dithering effects. Built with [**Astro**](https://astro.build/) and [**Three.js**](https://threejs.org/).

## Features

- **Interactive Dither Effect**: Hover over the background to reveal a localized dithering effect
- **Responsive Design**: Automatically switches between desktop and mobile background images
- **Click Ripples**: Click anywhere to spawn animated ripple effects
- **Modern Typography**: Clean, minimalist design with Inter font
- **WebGL Shaders**: Custom fragment and vertex shaders for smooth performance

## Getting Started

```bash
npm install
npm run dev        # http://localhost:4321
```

## Build

```bash
npm run build
npm run preview
```

## Project Structure

```
src/
├── components/
│   └── ThreeShader.astro    # WebGL canvas component
├── layouts/
│   └── BaseLayout.astro     # Main page layout
├── pages/
│   └── index.astro          # Landing page
├── script/
│   ├── main.ts              # Three.js setup and interaction logic
│   └── shaders/
│       ├── fragment.glsl    # Fragment shader with dither effects
│       └── vertex.glsl      # Vertex shader
└── styles/
    └── main.css             # Responsive styles
```

## Technologies

- **Astro** - Static site generator
- **Three.js** - WebGL rendering
- **TypeScript** - Type-safe JavaScript
- **GLSL** - Custom shaders for visual effects
