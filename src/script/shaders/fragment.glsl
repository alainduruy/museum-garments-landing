precision highp float;

uniform vec2 uResolution;
uniform float uTime;
uniform sampler2D uBackgroundTexture;
uniform float uPixelSize;
uniform float uDitherIntensity;
uniform float uIsMobile;

// Mouse and click interaction uniforms
uniform vec2 uMousePos;
const int MAX_CLICKS = 10;
uniform vec2 uClickPos[MAX_CLICKS];
uniform float uClickTimes[MAX_CLICKS];

out vec4 fragColor;

// ─────────────────────────────────────────────────────────────
// Bayer matrix helpers (ordered dithering thresholds)
// ─────────────────────────────────────────────────────────────
float Bayer2(vec2 a) {
    a = floor(a);
    return fract(a.x / 2. + a.y * a.y * .75);
}

#define Bayer4(a) (Bayer2(.5*(a))*0.25 + Bayer2(a))
#define Bayer8(a) (Bayer4(.5*(a))*0.25 + Bayer2(a))

// ─────────────────────────────────────────────────────────────
// Noise functions for subtle animation
// ─────────────────────────────────────────────────────────────
float hash11(float n) { 
    return fract(sin(n) * 43758.5453); 
}

float vnoise(vec3 p) {
    vec3 ip = floor(p);
    vec3 fp = fract(p);

    float n000 = hash11(dot(ip + vec3(0.0,0.0,0.0), vec3(1.0,57.0,113.0)));
    float n100 = hash11(dot(ip + vec3(1.0,0.0,0.0), vec3(1.0,57.0,113.0)));
    float n010 = hash11(dot(ip + vec3(0.0,1.0,0.0), vec3(1.0,57.0,113.0)));
    float n110 = hash11(dot(ip + vec3(1.0,1.0,0.0), vec3(1.0,57.0,113.0)));
    float n001 = hash11(dot(ip + vec3(0.0,0.0,1.0), vec3(1.0,57.0,113.0)));
    float n101 = hash11(dot(ip + vec3(1.0,0.0,1.0), vec3(1.0,57.0,113.0)));
    float n011 = hash11(dot(ip + vec3(0.0,1.0,1.0), vec3(1.0,57.0,113.0)));
    float n111 = hash11(dot(ip + vec3(1.0,1.0,1.0), vec3(1.0,57.0,113.0)));

    vec3 w = fp * fp * fp * (fp * (fp * 6.0 - 15.0) + 10.0);

    float x00 = mix(n000, n100, w.x);
    float x10 = mix(n010, n110, w.x);
    float x01 = mix(n001, n101, w.x);
    float x11 = mix(n011, n111, w.x);

    float y0 = mix(x00, x10, w.y);
    float y1 = mix(x01, x11, w.y);

    return mix(y0, y1, w.z) * 2.0 - 1.0;
}

// ─────────────────────────────────────────────────────────────
// Main fragment shader
// ─────────────────────────────────────────────────────────────
void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 uv = fragCoord / uResolution;
    
    // Calculate aspect ratio corrected UV coordinates for cover behavior
    vec2 texSize = vec2(textureSize(uBackgroundTexture, 0));
    float textureAspect = texSize.x / texSize.y;
    float screenAspect = uResolution.x / uResolution.y;
    
    vec2 correctedUV = uv;
    if (screenAspect > textureAspect) {
        // Screen is wider than texture - scale to fill width, crop height
        float scale = textureAspect / screenAspect;
        correctedUV.y = (uv.y - 0.5) * scale + 0.5;
    } else {
        // Screen is taller than texture - scale to fill height, crop width
        float scale = screenAspect / textureAspect;
        correctedUV.x = (uv.x - 0.5) * scale + 0.5;
    }
    
    // Sample the background texture with corrected UV
    vec4 bgColor = texture(uBackgroundTexture, correctedUV);
    
    // Convert to grayscale for dithering calculation
    float luminance = dot(bgColor.rgb, vec3(0.299, 0.587, 0.114));
    
    // Add subtle noise animation
    float noise = vnoise(vec3(uv * 8.0, uTime * 0.02)) * 0.1;
    luminance += noise;
    
    // Click ripple effects
    float rippleEffect = 0.0;
    const float speed = 0.8;
    const float thickness = 0.15;
    const float dampT = 1.2;
    const float dampR = 8.0;
    
    for (int i = 0; i < MAX_CLICKS; ++i) {
        vec2 pos = uClickPos[i];
        if (pos.x < 0.0) continue; // Skip empty slots
        
        // Convert click position to UV coordinates
        vec2 clickUV = pos / uResolution;
        
        float t = max(uTime - uClickTimes[i], 0.0);
        float r = distance(uv, clickUV);
        
        float waveR = speed * t;
        float ring = exp(-pow((r - waveR) / thickness, 2.0));
        float atten = exp(-dampT * t) * exp(-dampR * r);
        
        rippleEffect += ring * atten * 0.5;
    }
    
    // Apply ripple effect to luminance
    luminance = clamp(luminance + rippleEffect, 0.0, 1.0);
    
    // Dither effect logic
    float ditherMask = 0.0;
    vec3 finalColor = bgColor.rgb; // Default to normal image
    
    // On mobile, apply dither effect globally
    if (uIsMobile > 0.5) {
        ditherMask = 1.0; // Full effect on mobile
    } else if (uMousePos.x >= 0.0) {
        // On desktop, only apply within cursor area
        vec2 mouseUV = uMousePos / uResolution;
        float mouseDist = distance(uv, mouseUV);
        
        // Create a smooth circular mask around the cursor
        float cursorRadius = 0.6; // Radius of effect (5x larger)
        ditherMask = 1.0 - smoothstep(0.0, cursorRadius, mouseDist);
    }
    
    // Apply dithering if mask is active
    if (ditherMask > 0.0) {
        // Apply diamond dithering pattern with time-based movement
        vec2 ditherCoord = fragCoord / uPixelSize + uTime * 0.02;
        float diamondPattern = abs(fract(ditherCoord.x + ditherCoord.y) - 0.5) + abs(fract(ditherCoord.x - ditherCoord.y) - 0.5);
        float bayerThreshold = diamondPattern - 0.5;
        float ditheredValue = step(bayerThreshold * uDitherIntensity, luminance - 0.5);
        
        // Create the dithered effect
        vec3 ditheredColor = mix(
            bgColor.rgb * 0.3,  // Darker version for dither "off" pixels
            bgColor.rgb,        // Original color for dither "on" pixels
            ditheredValue
        );
        
        // Blend between normal and dithered based on mask
        finalColor = mix(bgColor.rgb, ditheredColor, ditherMask);
    }
    
    // Add subtle color variation based on diamond dither pattern with movement
    vec2 ditherCoord2 = fragCoord / uPixelSize + uTime * 0.02;
    float ditherPattern = abs(fract(ditherCoord2.x + ditherCoord2.y) - 0.5) + abs(fract(ditherCoord2.x - ditherCoord2.y) - 0.5);
    finalColor += vec3(ditherPattern * 0.02 - 0.01); // Very subtle color shift
    
    fragColor = vec4(finalColor, 1.0);
}
