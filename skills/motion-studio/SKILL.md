---
name: motion-studio
description: House rules for motion pieces, animated loops, and rendered videos (render contract, look, sound, review loop). Use when building, editing, scoring, or rendering any motion graphic, animation loop, or video with render.mjs, HyperFrames, or seek(t)-driven HTML.
---

# Motion studio: house rules

## Render contract
- Every piece is a pure function of time: window.seek(t) paints the frame at t seconds.
- No CSS transitions, no setTimeout/setInterval, no Date.now, no unseeded Math.random.
- Seeded randomness only (mulberry32). Same input, same frame, every run.
- Loops render frames 0..N-1. Frame N-1 must flow into frame 0.
- Render with: node render.mjs <file> --secs S --fps F --w W --h H

## Look
- Banned: centered title on a gradient, purple/blue gradients, glow, bloom, lens flares,
  decorative particles, everything fading in at once, text in the corners, turntable spins.
- One display face, one UI face, one accent color unless the brief says otherwise.
- Something new on screen every 2-4 seconds. One hero move per shot.
- All easing and spring values live in one MOTION object at the top of the file.

## Sound
- Synthesize score and SFX in code unless a track is supplied.
- If a track is supplied, run beats.py first and cut on beats.json.
- Loudness -14 LUFS, true peak under -1 dBTP.
- A sound lands on its picture frame or 1 frame after it, never before.

## Before you show me anything
1. Render one still per shot and a contact sheet. Look at them.
2. Score 1-10: hook in the first 2 s, readability at phone size, motion quality,
   variety, composition, brand accuracy, sound sync.
3. Fix the 3 worst problems. Repeat until every score is 8+.
4. Then do the full render, and report the scores with the file.
