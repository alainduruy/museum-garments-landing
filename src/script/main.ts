import * as THREE from "three";
import vertexSrc from "./shaders/vertex.glsl?raw";
import fragmentSrc from "./shaders/fragment.glsl?raw";

/* ---------------------------------------------------------- */
/* Museum Garments Landing Page with Interactive Dither Effect */
/* ---------------------------------------------------------- */

const bg = document.getElementById("hero_bg");
if (!bg) throw new Error("hero_bg element not found");

/* ---------- Responsive image paths ------------------------- */
const getBackgroundImagePath = () => {
  const isMobile = window.innerWidth <= 768;
  return isMobile
    ? "/museum-garments-coming-soon-mobile (1).jpg"
    : "/museum-garments-coming-soon-desktop.jpg";
};

/* ---------- Texture loader -------------------------------- */
const textureLoader = new THREE.TextureLoader();
let backgroundTexture: THREE.Texture;

/* ---------- Renderer setup ----------------------------- */
const canvas = document.createElement("canvas");
const gl = canvas.getContext("webgl2")!;
const renderer = new THREE.WebGLRenderer({
  canvas,
  context: gl,
  antialias: true,
  alpha: true,
});
renderer.setClearColor(0x000000, 1.0);
// Set pixel ratio for crisp rendering on retina screens
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
bg.appendChild(canvas);

/* ---------- Uniforms ----------------------------------- */
const MAX_CLICKS = 10;
const uniforms = {
  uResolution: { value: new THREE.Vector2() },
  uTime: { value: 0 },
  uBackgroundTexture: { value: null },
  uMousePos: { value: new THREE.Vector2(-1, -1) },
  uClickPos: {
    value: (() => {
      const arr = [];
      for (let i = 0; i < MAX_CLICKS; i++) {
        arr.push(new THREE.Vector2(-1, -1));
      }
      return arr;
    })(),
  },
  uClickTimes: { value: new Float32Array(MAX_CLICKS) },
  uPixelSize: { value: 5.0 },
  uDitherIntensity: { value: 2 },
  uIsMobile: { value: 0.0 },
};

/* ---------- Scene, camera, and material ---------------- */
const scene = new THREE.Scene();
const camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
const material = new THREE.ShaderMaterial({
  vertexShader: vertexSrc,
  fragmentShader: fragmentSrc,
  uniforms,
  glslVersion: THREE.GLSL3,
  transparent: true,
});

const geometry = new THREE.PlaneGeometry(2, 2);
const mesh = new THREE.Mesh(geometry, material);
scene.add(mesh);

/* ---------- Load background texture -------------------- */
const loadBackgroundTexture = () => {
  const imagePath = getBackgroundImagePath();
  currentImagePath = imagePath;

  textureLoader.load(
    imagePath,
    (texture) => {
      // Configure texture
      texture.wrapS = THREE.ClampToEdgeWrapping;
      texture.wrapT = THREE.ClampToEdgeWrapping;
      texture.minFilter = THREE.LinearFilter;
      texture.magFilter = THREE.LinearFilter;

      // Update uniform
      uniforms.uBackgroundTexture.value = texture;
      backgroundTexture = texture;

      console.log(`Loaded background texture: ${imagePath}`);
    },
    (progress) => {
      console.log(
        "Loading progress:",
        (progress.loaded / progress.total) * 100 + "%"
      );
    },
    (error) => {
      console.error("Error loading background texture:", error);
      console.log(`Failed to load: ${imagePath}`);
    }
  );
};

/* ---------- Resize handler ----------------------------- */
let currentImagePath = "";

const resize = () => {
  const w = canvas.clientWidth || window.innerWidth;
  const h = canvas.clientHeight || window.innerHeight;

  // Set pixel ratio for crisp rendering on retina screens
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.setSize(w, h, false);

  // Use actual canvas resolution for uniforms (accounts for pixel ratio)
  const actualWidth = renderer.domElement.width;
  const actualHeight = renderer.domElement.height;
  uniforms.uResolution.value.set(actualWidth, actualHeight);
  
  // Update mobile detection
  uniforms.uIsMobile.value = isDesktop() ? 0.0 : 1.0;

  // Check if we need to switch background image
  const newImagePath = getBackgroundImagePath();

  if (currentImagePath !== newImagePath) {
    currentImagePath = newImagePath;
    loadBackgroundTexture();
  }
};

window.addEventListener("resize", resize);

/* ---------- Mouse interaction (desktop only) ----------- */
const isDesktop = () => window.innerWidth > 768 && !("ontouchstart" in window);

let clickIx = 0;
canvas.addEventListener("pointerdown", (e) => {
  const rect = canvas.getBoundingClientRect();
  const fx = (e.clientX - rect.left) * (canvas.width / rect.width);
  const fy =
    (rect.height - (e.clientY - rect.top)) * (canvas.height / rect.height);

  uniforms.uClickPos.value[clickIx].set(fx, fy);
  uniforms.uClickTimes.value[clickIx] = uniforms.uTime.value;
  clickIx = (clickIx + 1) % MAX_CLICKS;
});

// Track mouse movement on desktop only
canvas.addEventListener("pointermove", (e) => {
  if (!isDesktop()) {
    uniforms.uMousePos.value.set(-1, -1);
    return;
  }

  const rect = canvas.getBoundingClientRect();
  const fx = (e.clientX - rect.left) * (canvas.width / rect.width);
  const fy =
    (rect.height - (e.clientY - rect.top)) * (canvas.height / rect.height);

  uniforms.uMousePos.value.set(fx, fy);
});

// Hide mouse effect when leaving canvas on desktop
canvas.addEventListener("pointerleave", () => {
  if (isDesktop()) {
    uniforms.uMousePos.value.set(-1, -1);
  }
});

/* ---------- Animation loop ------------------------------ */
const clock = new THREE.Clock();

const animate = () => {
  uniforms.uTime.value = clock.getElapsedTime();
  renderer.render(scene, camera);
  requestAnimationFrame(animate);
};

/* ---------- Initialize ---------------------------------- */
loadBackgroundTexture();
resize();
animate();

/* ---------- Export for debugging ----------------------- */
(window as any).museumGarmentsDebug = {
  uniforms,
  renderer,
  scene,
  camera,
  material,
  loadBackgroundTexture,
};
