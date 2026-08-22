'use strict';
/* ============================================================
   عرش الهاوية: شظايا النور — Throne of the Abyss: Shards of Light
   الشريحة القابلة للّعب — الفصل الأول: سهول البداية
   Canvas 2D · fixed timestep 60Hz · keyboard + touch · WebAudio
   ============================================================ */

// ---------------- helpers ----------------
const TAU = Math.PI * 2;
const clamp = (v, a, b) => v < a ? a : (v > b ? b : v);
const lerp = (a, b, t) => a + (b - a) * t;
const rand = (a = 1, b) => b === undefined ? Math.random() * a : a + Math.random() * (b - a);
const randi = (a, b) => Math.floor(rand(a, b + 1));
const pick = a => a[Math.floor(Math.random() * a.length)];
const dist = (ax, ay, bx, by) => Math.hypot(bx - ax, by - ay);
const angTo = (ax, ay, bx, by) => Math.atan2(by - ay, bx - ax);
const angDiff = (a, b) => { let d = (a - b) % TAU; if (d > Math.PI) d -= TAU; if (d < -Math.PI) d += TAU; return Math.abs(d); };
const lerpAng = (a, b, t) => { let d = (b - a) % TAU; if (d > Math.PI) d -= TAU; if (d < -Math.PI) d += TAU; return a + d * Math.min(1, t); };
const easeOut = t => 1 - Math.pow(1 - t, 3);
const fmt = n => Math.round(n).toLocaleString('en-US');
const $ = id => document.getElementById(id);

// ---------------- canvas / view ----------------
const DW = 1280, DH = 720;
const canvas = document.getElementById('game');
const ctx = canvas.getContext('2d');
let cssW = 0, cssH = 0, dpr = 1, scale = 1, ox = 0, oy = 0;
function resize() {
  cssW = window.innerWidth; cssH = window.innerHeight;
  dpr = Math.min(2, window.devicePixelRatio || 1);
  canvas.width = Math.round(cssW * dpr); canvas.height = Math.round(cssH * dpr);
  canvas.style.width = cssW + 'px'; canvas.style.height = cssH + 'px';
  scale = Math.min(cssW / DW, cssH / DH);
  ox = (cssW - DW * scale) / 2; oy = (cssH - DH * scale) / 2;
}
function updateRotateHint() {
  const el = document.getElementById('rotate-hint');
  if (!el) return;
  const portrait = window.innerWidth < window.innerHeight * 0.85;
  el.classList.toggle('hidden', !portrait);
}
window.addEventListener('resize', resize);
window.addEventListener('resize', updateRotateHint);
resize();
updateRotateHint();

// rounded rect path
function rr(x, y, w, h, r) {
  r = Math.min(r, w / 2, h / 2);
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + w, y, x + w, y + h, r);
  ctx.arcTo(x + w, y + h, x, y + h, r);
  ctx.arcTo(x, y + h, x, y, r);
  ctx.arcTo(x, y, x + w, y, r);
  ctx.closePath();
}

// arena (shrinks during هياج الهاوية)
const AR_FULL = { minX: 70, minY: 110, maxX: 1210, maxY: 630 };
const AR_TIGHT = { minX: 150, minY: 160, maxX: 1130, maxY: 580 };
let arenaT = 0;
function arena() {
  if (arenaT <= 0) return AR_FULL;
  if (arenaT >= 1) return AR_TIGHT;
  return {
    minX: lerp(AR_FULL.minX, AR_TIGHT.minX, arenaT), minY: lerp(AR_FULL.minY, AR_TIGHT.minY, arenaT),
    maxX: lerp(AR_FULL.maxX, AR_TIGHT.maxX, arenaT), maxY: lerp(AR_FULL.maxY, AR_TIGHT.maxY, arenaT),
  };
}

// pillars (destructible, 2 hits each)
let pillars = [];
function resetPillars() {
  pillars = [
    { x: 320, y: 280, r: 36, hp: 2, alive: true },
    { x: 960, y: 280, r: 36, hp: 2, alive: true },
    { x: 640, y: 500, r: 36, hp: 2, alive: true },
  ];
}

// ---------------- pre-rendered sprites ----------------
function makeCanvas(w, h) { const c = document.createElement('canvas'); c.width = w; c.height = h; return c; }
function glowSprite(size, color) {
  const c = makeCanvas(size, size), g = c.getContext('2d');
  const gr = g.createRadialGradient(size / 2, size / 2, 0, size / 2, size / 2, size / 2);
  gr.addColorStop(0, color); gr.addColorStop(1, 'rgba(0,0,0,0)');
  g.fillStyle = gr; g.fillRect(0, 0, size, size);
  return c;
}
const glowOrange = glowSprite(128, 'rgba(255,150,50,0.85)');
const glowPurple = glowSprite(128, 'rgba(150,60,255,0.8)');
const glowRed = glowSprite(96, 'rgba(255,70,60,0.8)');

let bgCanvas = null, vignette = null, firePatch = null;
function buildStatic() {
  bgCanvas = makeCanvas(DW, DH);
  const g = bgCanvas.getContext('2d');
  // corrupted sky
  let sky = g.createLinearGradient(0, 0, 0, 120);
  sky.addColorStop(0, '#171026'); sky.addColorStop(1, '#2c1c3e');
  g.fillStyle = sky; g.fillRect(0, 0, DW, 120);
  g.fillStyle = 'rgba(10,6,18,0.5)';
  for (let i = 0; i < 7; i++) { g.beginPath(); g.ellipse(rand(0, DW), rand(20, 90), rand(120, 300), rand(12, 24), 0, 0, TAU); g.fill(); }
  // the rift in the sky
  g.strokeStyle = 'rgba(139,70,255,0.5)'; g.lineWidth = 3;
  g.beginPath(); g.moveTo(900, 0); g.bezierCurveTo(930, 30, 880, 60, 940, 120); g.stroke();
  g.strokeStyle = 'rgba(255,80,60,0.3)'; g.lineWidth = 1.5;
  g.beginPath(); g.moveTo(905, 0); g.bezierCurveTo(935, 32, 885, 62, 945, 120); g.stroke();
  // golden plains
  let gr = g.createLinearGradient(0, 100, 0, DH);
  gr.addColorStop(0, '#5d5638'); gr.addColorStop(0.5, '#57503a'); gr.addColorStop(1, '#453f31');
  g.fillStyle = gr; g.fillRect(0, 100, DW, DH - 100);
  for (let i = 0; i < 26; i++) {
    g.fillStyle = pick(['rgba(90,110,60,0.16)', 'rgba(70,60,40,0.2)', 'rgba(120,110,60,0.12)']);
    g.beginPath(); g.ellipse(rand(60, DW - 60), rand(140, DH - 40), rand(40, 140), rand(18, 50), rand(0, TAU), 0, TAU); g.fill();
  }
  // dirt path
  g.strokeStyle = 'rgba(150,125,80,0.35)'; g.lineWidth = 46; g.lineCap = 'round';
  g.beginPath(); g.moveTo(-40, 560); g.bezierCurveTo(300, 520, 500, 380, 700, 400); g.bezierCurveTo(900, 420, 1050, 330, 1330, 300); g.stroke();
  g.strokeStyle = 'rgba(120,100,64,0.3)'; g.lineWidth = 28; g.stroke();
  // grass tufts
  g.strokeStyle = 'rgba(110,130,70,0.5)'; g.lineWidth = 1.5;
  for (let i = 0; i < 120; i++) {
    const x = rand(50, DW - 50), y = rand(130, DH - 30);
    for (let k = -1; k <= 1; k++) { g.beginPath(); g.moveTo(x, y); g.lineTo(x + k * 3, y - 6 - rand(0, 4)); g.stroke(); }
  }
  // old stones
  for (let i = 0; i < 14; i++) {
    const x = rand(60, DW - 60), y = rand(150, DH - 50), s = rand(4, 10);
    g.fillStyle = 'rgba(90,85,80,0.55)'; g.beginPath(); g.ellipse(x, y, s, s * 0.6, rand(0, 1), 0, TAU); g.fill();
    g.fillStyle = 'rgba(200,190,170,0.25)'; g.beginPath(); g.ellipse(x - s * 0.2, y - s * 0.2, s * 0.4, s * 0.25, 0, 0, TAU); g.fill();
  }
  // dead (ash) trees
  for (const [tx, ty, s] of [[140, 230, 1], [1120, 560, 1.2], [1080, 190, 0.8]]) {
    g.strokeStyle = 'rgba(70,64,66,0.8)'; g.lineCap = 'round';
    g.lineWidth = 5 * s; g.beginPath(); g.moveTo(tx, ty); g.lineTo(tx + 10 * s, ty - 46 * s); g.stroke();
    g.lineWidth = 3 * s;
    g.beginPath(); g.moveTo(tx + 4 * s, ty - 24 * s); g.lineTo(tx + 22 * s, ty - 38 * s); g.stroke();
    g.beginPath(); g.moveTo(tx + 7 * s, ty - 36 * s); g.lineTo(tx - 8 * s, ty - 52 * s); g.stroke();
  }
  // ruin arch (أطلال الحارس)
  g.strokeStyle = 'rgba(120,112,100,0.6)'; g.lineWidth = 10;
  g.beginPath(); g.arc(210, 330, 42, Math.PI, 0); g.stroke();
  g.lineWidth = 8;
  g.beginPath(); g.moveTo(168, 330); g.lineTo(168, 368); g.stroke();
  g.beginPath(); g.moveTo(252, 330); g.lineTo(252, 352); g.stroke();
  // stone tablets
  for (const [sx, sy] of [[420, 560], [455, 575]]) {
    g.save(); g.translate(sx, sy); g.rotate(-0.08);
    g.fillStyle = 'rgba(125,118,105,0.8)'; g.fillRect(-12, -26, 24, 34);
    g.strokeStyle = 'rgba(60,55,48,0.7)'; g.lineWidth = 1;
    for (let k = 0; k < 3; k++) { g.beginPath(); g.moveTo(-8, -18 + k * 7); g.lineTo(8, -18 + k * 7); g.stroke(); }
    g.restore();
  }
  // purple corruption veins
  const veins = [
    [[90, 655], [130, 625], [175, 640], [215, 600]],
    [[1180, 140], [1140, 175], [1150, 215], [1105, 240]],
    [[640, 665], [690, 640], [725, 662]],
  ];
  for (const v of veins) {
    g.strokeStyle = 'rgba(139,70,255,0.45)'; g.lineWidth = 3;
    g.beginPath(); g.moveTo(v[0][0], v[0][1]);
    for (let i = 1; i < v.length; i++) g.lineTo(v[i][0], v[i][1]);
    g.stroke();
    g.strokeStyle = 'rgba(255,80,70,0.25)'; g.lineWidth = 1.2; g.stroke();
  }
  // arena border shading
  g.strokeStyle = 'rgba(10,8,16,0.55)'; g.lineWidth = 14;
  g.strokeRect(70, 110, 1140, 520);
  // vignette
  vignette = makeCanvas(DW, DH);
  const vg = vignette.getContext('2d');
  const vr = vg.createRadialGradient(640, 360, 300, 640, 360, 760);
  vr.addColorStop(0, 'rgba(0,0,0,0)'); vr.addColorStop(1, 'rgba(5,3,10,0.62)');
  vg.fillStyle = vr; vg.fillRect(0, 0, DW, DH);
  // fire patch sprite
  firePatch = makeCanvas(160, 100);
  const fg = firePatch.getContext('2d');
  const fgr = fg.createRadialGradient(80, 50, 4, 80, 50, 78);
  fgr.addColorStop(0, 'rgba(255,150,60,0.9)');
  fgr.addColorStop(0.45, 'rgba(150,60,255,0.55)');
  fgr.addColorStop(1, 'rgba(80,20,120,0)');
  fg.fillStyle = fgr; fg.beginPath(); fg.ellipse(80, 50, 78, 50, 0, 0, TAU); fg.fill();
}

// ---------------- audio (procedural WebAudio) ----------------
const SFX = (() => {
  let ac = null, master = null, noiseBuf = null, muted = false;
  try { muted = localStorage.getItem('toa_mute') === '1'; } catch (e) {}
  function ensure() {
    if (ac) return true;
    try {
      const AC = window.AudioContext || window.webkitAudioContext;
      if (!AC) return false;
      ac = new AC();
      master = ac.createGain(); master.gain.value = 0.4; master.connect(ac.destination);
      const len = Math.floor(ac.sampleRate * 0.5);
      noiseBuf = ac.createBuffer(1, len, ac.sampleRate);
      const d = noiseBuf.getChannelData(0);
      for (let i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
      return true;
    } catch (e) { return false; }
  }
  function env(g, t0, a, peak, dur) {
    g.gain.setValueAtTime(0.0001, t0);
    g.gain.linearRampToValueAtTime(peak, t0 + a);
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
  }
  function tone(type, f0, f1, dur, peak, when) {
    if (!ac || muted) return;
    try {
      const t0 = ac.currentTime + (when || 0);
      const o = ac.createOscillator(), g = ac.createGain();
      o.type = type;
      o.frequency.setValueAtTime(Math.max(1, f0), t0);
      o.frequency.exponentialRampToValueAtTime(Math.max(1, f1), t0 + dur);
      env(g, t0, 0.005, peak || 0.3, dur);
      o.connect(g); g.connect(master);
      o.start(t0); o.stop(t0 + dur + 0.05);
    } catch (e) {}
  }
  function noise(dur, peak, f, q, when) {
    if (!ac || muted) return;
    try {
      const t0 = ac.currentTime + (when || 0);
      const s = ac.createBufferSource(); s.buffer = noiseBuf; s.loop = true;
      const fl = ac.createBiquadFilter(); fl.type = 'bandpass'; fl.frequency.value = f; fl.Q.value = q || 1;
      const g = ac.createGain(); env(g, t0, 0.005, peak || 0.3, dur);
      s.connect(fl); fl.connect(g); g.connect(master);
      s.start(t0); s.stop(t0 + dur + 0.05);
    } catch (e) {}
  }
  return {
    ensure,
    get muted() { return muted; },
    toggle() { muted = !muted; try { localStorage.setItem('toa_mute', muted ? '1' : '0'); } catch (e) {} return muted; },
    swing(h) { noise(0.08, h ? 0.22 : 0.14, h ? 480 : 900, 1.5); },
    hit() { noise(0.05, 0.25, 1800, 2); tone('square', 200, 90, 0.06, 0.1); },
    kill() { noise(0.22, 0.28, 700, 1); tone('triangle', 280, 60, 0.22, 0.18); },
    dodge() { noise(0.12, 0.18, 1400, 2); },
    dash() { noise(0.14, 0.18, 2400, 1.5); },
    hurt() { tone('sawtooth', 150, 55, 0.2, 0.32); noise(0.09, 0.22, 400, 1); },
    flame() { tone('sawtooth', 110, 460, 0.5, 0.22); noise(0.5, 0.18, 900, 1); },
    phx() { tone('triangle', 500, 1500, 0.4, 0.26); noise(0.4, 0.26, 600, 1); },
    roar() { tone('sawtooth', 70, 42, 0.9, 0.4); noise(0.7, 0.3, 220, 1); },
    horn() { tone('sine', 1250, 1500, 0.1, 0.28); tone('sine', 1900, 2100, 0.08, 0.18, 0.04); },
    hornBreak() { noise(0.3, 0.35, 280, 1); tone('square', 95, 48, 0.34, 0.28); },
    pillar() { noise(0.26, 0.38, 180, 1); tone('sine', 85, 40, 0.3, 0.35); },
    shock() { tone('sine', 950, 180, 0.3, 0.28); },
    slam() { noise(0.3, 0.4, 150, 1); tone('sine', 70, 35, 0.35, 0.4); },
    charge() { noise(0.4, 0.2, 600, 2); tone('sawtooth', 120, 240, 0.4, 0.15); },
    throwP() { noise(0.08, 0.15, 1200, 2); },
    revive() { tone('triangle', 200, 420, 0.35, 0.2); },
    wave() { tone('triangle', 440, 660, 0.18, 0.18); tone('triangle', 660, 880, 0.18, 0.18, 0.12); },
    coin() { tone('sine', 950, 1500, 0.07, 0.1); },
    ui() { tone('sine', 620, 820, 0.06, 0.13); },
    win() { [523, 659, 784, 1046].forEach((f, i) => tone('triangle', f, f * 1.01, 0.28, 0.22, i * 0.15)); },
    lose() { [330, 262, 196, 147].forEach((f, i) => tone('triangle', f, f * 0.99, 0.3, 0.22, i * 0.18)); },
    bossDeath() { tone('sawtooth', 60, 30, 1.4, 0.45); noise(1.2, 0.35, 180, 1); },
  };
})();

// ---------------- persistence ----------------
function loadBank() { try { const b = JSON.parse(localStorage.getItem('toa_bank')); return b && typeof b === 'object' ? b : { gold: 0, shards: 0, weapon: false }; } catch (e) { return { gold: 0, shards: 0, weapon: false }; } }
let bank = loadBank();
function saveBank() { try { localStorage.setItem('toa_bank', JSON.stringify(bank)); } catch (e) {} }
function loadScores() { try { const s = JSON.parse(localStorage.getItem('toa_scores')); return Array.isArray(s) ? s : []; } catch (e) { return []; } }
function saveScores(list) { try { localStorage.setItem('toa_scores', JSON.stringify(list)); } catch (e) {} }

// ---------------- state ----------------
const game = {
  state: 'menu', score: 0, gold: 0, shards: 0, dmgTaken: 0, bossTime: 0,
  wave: 0, time: 0, waveT: 0, pending: [], phase: 'idle', nextWave: 0,
  bannerT: 0, bannerTitle: '', bannerSub: '', tipT: 0, tip: '',
  scored: false, stars: 0, savedGold: 0, newWeapon: false, inTop5: false,
};
let player = null, boss = null;
let enemies = [], projs = [], motes = [], patches = [];
let parts = [], rings = [], slashes = [], texts = [], ambient = [];
let purpleFlash = 0, goldPop = 0, shardPop = 0, scorePop = 0, bossHintT = 0;
let hitstopT = 0, shake = { t: 0, d: 0, mag: 0 };

function addShake(mag, d = 0.3) { if (shake.t <= 0 || mag >= shake.mag) { shake.mag = mag; shake.d = d; shake.t = d; } }
function shakeOff() { if (shake.t <= 0) return [0, 0]; const k = shake.t / shake.d * shake.mag; return [(Math.random() * 2 - 1) * k, (Math.random() * 2 - 1) * k * 0.7]; }
function hitstop(t) { hitstopT = Math.max(hitstopT, t); }
function banner(title, sub) { game.bannerTitle = title; game.bannerSub = sub || ''; game.bannerT = 3.5; }

function resetRun() {
  player = {
    x: 300, y: 390, hp: 100, maxHp: 100, heat: 0, flameT: 0,
    faceAng: 0, facing: 1, moveA: 0, moving: false,
    atkCd: 0, attackT: 0, comboI: 0, dashCd: 0, dashT: 0, dashA: 0, phCd: 0,
    iframes: 0, patchCd: 0, hurtFlash: 0, chain: 0, chainT: 0, comboPop: 0,
    state: 'alive', deadT: 0,
  };
  boss = null; enemies = []; projs = []; motes = []; patches = [];
  parts = []; rings = []; slashes = []; texts = [];
  resetPillars(); arenaT = 0;
  game.score = 0; game.gold = 0; game.shards = 0; game.dmgTaken = 0; game.bossTime = 0;
  game.wave = 0; game.time = 0; game.waveT = 0; game.pending = []; game.phase = 'idle'; game.nextWave = 0;
  game.bannerT = 0; game.tipT = 0; game.scored = false; game.stars = 0; game.savedGold = 0; game.newWeapon = false;
  purpleFlash = 0; goldPop = 0; shardPop = 0; scorePop = 0; bossHintT = 0; hitstopT = 0;
  shake = { t: 0, d: 0, mag: 0 };
  input.attackHeld = false; input.dashQ = false; input.phxQ = false; input.mx = 0; input.my = 0;
}

// ---------------- particles / fx ----------------
function part(o) {
  if (parts.length >= 350) return;
  o.ttl = o.ttl || 0.6; o.life = o.ttl;
  o.x = o.x || 0; o.y = o.y || 0; o.vx = o.vx || 0; o.vy = o.vy || 0;
  o.size = o.size || 3; o.color = o.color || '#fff';
  o.grav = o.grav || 0; o.drag = o.drag || 0; o.type = o.type || 'dot';
  parts.push(o);
}
function burst(x, y, kind, n, spd = 160, color) {
  for (let i = 0; i < n; i++) {
    const a = rand(TAU), s = rand(spd * 0.3, spd);
    if (kind === 'ember') part({ x, y, vx: Math.cos(a) * s, vy: Math.sin(a) * s - 60, ttl: rand(0.4, 0.9), size: rand(2, 4), color: color || pick(['#ffb054', '#ff7a2f', '#ffd98a']), grav: 140, drag: 1.5, type: 'ember' });
    else if (kind === 'ash') part({ x, y, vx: Math.cos(a) * s * 0.6, vy: Math.sin(a) * s * 0.6 - 30, ttl: rand(0.5, 1.1), size: rand(2, 4), color: pick(['#8a8395', '#6a6474', '#a09aac']), grav: 60, drag: 1.2 });
    else if (kind === 'spark') part({ x, y, vx: Math.cos(a) * s * 1.6, vy: Math.sin(a) * s * 1.6, ttl: rand(0.15, 0.35), size: rand(1.5, 3), color: color || pick(['#fff3c4', '#ffd27a', '#ffffff']), drag: 3 });
    else if (kind === 'dust') part({ x, y, vx: Math.cos(a) * s * 0.5, vy: Math.sin(a) * s * 0.5 - 20, ttl: rand(0.4, 0.8), size: rand(4, 9), color: 'rgba(160,140,110,0.5)', grav: 40, drag: 2 });
    else if (kind === 'rubble') part({ x, y, vx: Math.cos(a) * s, vy: Math.sin(a) * s - 120, ttl: rand(0.6, 1.1), size: rand(3, 7), color: pick(['#8d8272', '#6a6156', '#4a443c']), grav: 420, drag: 0.5 });
  }
}
function updateParts(dt) {
  for (let i = parts.length - 1; i >= 0; i--) {
    const p = parts[i];
    p.ttl -= dt;
    if (p.ttl <= 0) { parts.splice(i, 1); continue; }
    p.vy += p.grav * dt;
    p.vx *= (1 - p.drag * dt); p.vy *= (1 - p.drag * dt);
    p.x += p.vx * dt; p.y += p.vy * dt;
  }
}
function drawParts() {
  for (const p of parts) {
    const a = clamp(p.ttl / p.life, 0, 1);
    ctx.globalAlpha = p.type === 'dust' ? a * 0.5 : a;
    ctx.fillStyle = p.color;
    if (p.type === 'ember') { ctx.beginPath(); ctx.arc(p.x, p.y, p.size * (0.5 + 0.5 * a), 0, TAU); ctx.fill(); }
    else ctx.fillRect(p.x - p.size / 2, p.y - p.size / 2, p.size, p.size);
  }
  ctx.globalAlpha = 1;
}
function ring(x, y, maxR, color, w = 4, ttl = 0.5) { rings.push({ x, y, r: 8, maxR, ttl, life: ttl, color, w }); }
function updateRings(dt) {
  for (let i = rings.length - 1; i >= 0; i--) {
    const r = rings[i];
    r.ttl -= dt;
    if (r.ttl <= 0) { rings.splice(i, 1); continue; }
    r.r = lerp(r.maxR, 8, r.ttl / r.life);
  }
}
function drawRings() {
  for (const r of rings) {
    const a = clamp(r.ttl / r.life, 0, 1);
    ctx.globalAlpha = a; ctx.strokeStyle = r.color; ctx.lineWidth = r.w * a + 1;
    ctx.beginPath(); ctx.arc(r.x, r.y, r.r, 0, TAU); ctx.stroke();
  }
  ctx.globalAlpha = 1;
}
function slash(x, y, ang, spread, range) { slashes.push({ x, y, ang, spread, range, ttl: 0.14, life: 0.14 }); }
function updateSlashes(dt) { for (let i = slashes.length - 1; i >= 0; i--) { slashes[i].ttl -= dt; if (slashes[i].ttl <= 0) slashes.splice(i, 1); } }
function drawSlashes() {
  for (const s of slashes) {
    const a = s.ttl / s.life;
    ctx.save(); ctx.translate(s.x, s.y); ctx.rotate(s.ang);
    ctx.strokeStyle = 'rgba(255,210,120,' + (0.85 * a) + ')';
    ctx.lineWidth = 10 * a + 2; ctx.lineCap = 'round';
    ctx.beginPath(); ctx.arc(0, 0, s.range * 0.8, -s.spread, s.spread); ctx.stroke();
    ctx.strokeStyle = 'rgba(255,255,255,' + (0.7 * a) + ')';
    ctx.lineWidth = 4 * a + 1;
    ctx.beginPath(); ctx.arc(0, 0, s.range * 0.8, -s.spread * 0.7, s.spread * 0.7); ctx.stroke();
    ctx.restore();
  }
}
function floatText(x, y, txt, color, size = 15, big = false) {
  const ttl = big ? 0.9 : 0.7;
  texts.push({ x, y, txt, color, size, ttl, life: ttl, vy: -46, rot: rand(-0.12, 0.12) });
}
function updateTexts(dt) {
  for (let i = texts.length - 1; i >= 0; i--) {
    const t = texts[i];
    t.ttl -= dt; t.y += t.vy * dt; t.vy *= (1 - 2 * dt);
    if (t.ttl <= 0) texts.splice(i, 1);
  }
}
function drawTexts() {
  ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
  for (const t of texts) {
    const a = clamp(t.ttl / t.life, 0, 1);
    ctx.globalAlpha = a;
    ctx.save(); ctx.translate(t.x, t.y); ctx.rotate(t.rot);
    ctx.font = '800 ' + t.size + 'px Cairo, Tahoma, sans-serif';
    ctx.lineWidth = 3; ctx.strokeStyle = 'rgba(10,6,16,0.8)';
    ctx.strokeText(t.txt, 0, 0);
    ctx.fillStyle = t.color; ctx.fillText(t.txt, 0, 0);
    ctx.restore();
  }
  ctx.globalAlpha = 1; ctx.textAlign = 'left';
}
function initAmbient() {
  ambient = [];
  for (let i = 0; i < 30; i++) ambient.push({ x: rand(0, DW), y: rand(110, DH), vx: rand(-18, -6), vy: rand(4, 14), s: rand(1.5, 3.5), ph: rand(TAU) });
}
function updateAmbient(dt) {
  for (const a of ambient) {
    a.x += a.vx * dt; a.y += a.vy * dt; a.ph += dt;
    if (a.x < -10) { a.x = DW + 10; a.y = rand(110, DH); }
    if (a.y > DH + 10) { a.y = 105; a.x = rand(0, DW); }
  }
}
function drawAmbient() {
  ctx.fillStyle = 'rgba(190,180,205,0.35)';
  for (const a of ambient) {
    const s = a.s * (0.7 + 0.3 * Math.sin(a.ph * 2));
    ctx.fillRect(a.x, a.y, s, s);
  }
}

// ---------------- input ----------------
const input = { mx: 0, my: 0, attackHeld: false, dashQ: false, phxQ: false };
const keys = {};
const KEYMAP = { ArrowUp: 'up', KeyW: 'up', ArrowDown: 'down', KeyS: 'down', ArrowLeft: 'left', KeyA: 'left', ArrowRight: 'right', KeyD: 'right' };
const ATK_KEYS = ['KeyJ', 'Space', 'KeyF'];
const DASH_KEYS = ['KeyK', 'ShiftLeft', 'ShiftRight', 'KeyX'];
const PHX_KEYS = ['KeyL', 'KeyC'];
function syncMove() { input.mx = (keys.right ? 1 : 0) - (keys.left ? 1 : 0); input.my = (keys.down ? 1 : 0) - (keys.up ? 1 : 0); }

window.addEventListener('keydown', e => {
  if (['Space', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(e.code)) e.preventDefault();
  SFX.ensure();
  if (KEYMAP[e.code]) { keys[KEYMAP[e.code]] = true; syncMove(); }
  if (ATK_KEYS.includes(e.code) && !e.repeat) input.attackHeld = true;
  if (DASH_KEYS.includes(e.code) && !e.repeat) input.dashQ = true;
  if (PHX_KEYS.includes(e.code) && !e.repeat) input.phxQ = true;
  if (e.repeat) return;
  if (e.code === 'KeyP' || e.code === 'Escape') togglePause();
  if (e.code === 'KeyM') setMute(SFX.toggle());
  if (game.state === 'menu' && (e.code === 'Enter' || e.code === 'Space')) startRun();
  if ((e.code === 'KeyR' || e.code === 'Enter') && (game.state === 'over' || game.state === 'win')) startRun();
});
window.addEventListener('keyup', e => {
  if (KEYMAP[e.code]) { keys[KEYMAP[e.code]] = false; syncMove(); }
  if (ATK_KEYS.includes(e.code)) input.attackHeld = false;
});
window.addEventListener('blur', () => { for (const k in keys) keys[k] = false; syncMove(); input.attackHeld = false; });

// touch: floating joystick (left half) + action buttons
const isTouch = ('ontouchstart' in window) || (window.matchMedia && window.matchMedia('(pointer:coarse)').matches);
const joyEl = $('joy'), knobEl = $('knob');
const stick = { id: null, bx: 0, by: 0 };
canvas.addEventListener('touchstart', e => {
  e.preventDefault(); SFX.ensure();
  for (const t of e.changedTouches) {
    if (t.clientX < window.innerWidth * 0.55 && stick.id === null) {
      stick.id = t.identifier; stick.bx = t.clientX; stick.by = t.clientY;
      joyEl.style.display = 'block';
      joyEl.style.left = (t.clientX - 56) + 'px'; joyEl.style.top = (t.clientY - 56) + 'px';
      knobEl.style.transform = 'translate(0,0)';
    }
  }
}, { passive: false });
canvas.addEventListener('touchmove', e => {
  e.preventDefault();
  for (const t of e.changedTouches) {
    if (t.identifier === stick.id) {
      let dx = t.clientX - stick.bx, dy = t.clientY - stick.by;
      const d = Math.hypot(dx, dy), max = 48;
      if (d > max) { dx *= max / d; dy *= max / d; }
      knobEl.style.transform = 'translate(' + dx + 'px,' + dy + 'px)';
      input.mx = dx / max; input.my = dy / max;
    }
  }
}, { passive: false });
function endStick(t) {
  if (t.identifier === stick.id) {
    stick.id = null; input.mx = 0; input.my = 0;
    joyEl.style.display = 'none'; knobEl.style.transform = 'translate(0,0)';
  }
}
canvas.addEventListener('touchend', e => { e.preventDefault(); for (const t of e.changedTouches) endStick(t); }, { passive: false });
canvas.addEventListener('touchcancel', e => { for (const t of e.changedTouches) endStick(t); }, { passive: false });
function bindTouch(el, down, up) {
  if (!el) return;
  el.addEventListener('touchstart', e => { e.preventDefault(); e.stopPropagation(); SFX.ensure(); down(); }, { passive: false });
  if (up) el.addEventListener('touchend', e => { e.preventDefault(); e.stopPropagation(); up(); }, { passive: false });
  el.addEventListener('touchcancel', e => { e.preventDefault(); e.stopPropagation(); if (up) up(); }, { passive: false });
}
bindTouch($('t-atk'), () => { input.attackHeld = true; }, () => { input.attackHeld = false; });
bindTouch($('t-dash'), () => { input.dashQ = true; });
bindTouch($('t-phx'), () => { input.phxQ = true; });

// ---------------- waves ----------------
const WAVES = [
  { name: 'رماد على البوابة', tip: 'اضرب لتبني حرارة اللهب — والتفادي بالاندفاع (K)', spawns: [['outcast', 3, 0.4], ['outcast', 2, 2.4]] },
  { name: 'أثر الذئاب', tip: 'عندما يشحذ الذئب أنيابه، تفادَ بالاندفاع (K) لتوقفه', spawns: [['outcast', 2, 0.4], ['wolf', 3, 1.4]] },
  { name: 'صرخة في الحقول', tip: 'حارس الحقل مدرّج من الأمام… استدر خلفه قبل الضربة', spawns: [['thrower', 2, 0.4], ['guard', 1, 2], ['outcast', 2, 3.5], ['wolf', 2, 5]] },
  { name: 'حشد الصدع', tip: 'فارس العظم يعود من الموت — دمّر نواته الزرقاء أولًا', spawns: [['beetle', 6, 0.4], ['wolf', 2, 2], ['guard', 1, 4], ['knight', 1, 6]] },
];
function startWave(i) {
  game.wave = i; game.phase = 'spawning'; game.waveT = 0; game.pending = [];
  for (const [kind, count, delay] of WAVES[i].spawns)
    for (let k = 0; k < count; k++) game.pending.push({ kind, at: delay + k * 0.9 });
  game.pending.sort((a, b) => a.at - b.at);
  banner(WAVES[i].name, 'الموجة ' + (i + 1) + ' من ' + WAVES.length + ' — أهلك جميع الوحوش');
  game.tip = WAVES[i].tip; game.tipT = 6;
  SFX.wave();
}
function updateWaves(dt) {
  if (boss) return;
  if (game.phase === 'spawning') {
    game.waveT += dt;
    while (game.pending.length && game.pending[0].at <= game.waveT && enemies.length < 9)
      spawnEnemy(game.pending.shift().kind);
    if (!game.pending.length && enemies.length === 0) {
      if (game.wave >= WAVES.length - 1) { startBoss(); }
      else {
        game.phase = 'cleared'; game.nextWave = 2.0;
        game.gold += 100; game.score += 250; goldPop = 0.3;
        banner('اكتملت الموجة', '+' + fmt(100) + ' ذهب');
        SFX.wave();
      }
    }
  } else if (game.phase === 'cleared') {
    game.nextWave -= dt;
    if (game.nextWave <= 0) startWave(game.wave + 1);
  }
}

// ---------------- enemies ----------------
const ENEMY_DEF = {
  outcast: { hp: 40, r: 15, speed: 70, dmg: 12, score: 50, gold: 8, windup: 0.55, lunge: 430 },
  wolf: { hp: 30, r: 14, speed: 200, dmg: 10, score: 70, gold: 10 },
  thrower: { hp: 35, r: 14, speed: 60, dmg: 10, score: 80, gold: 12 },
  guard: { hp: 90, r: 18, speed: 55, dmg: 15, score: 110, gold: 15, windup: 0.6, lunge: 400 },
  beetle: { hp: 16, r: 10, speed: 235, dmg: 6, score: 30, gold: 4 },
  knight: { hp: 120, r: 20, speed: 85, dmg: 18, score: 150, gold: 25, windup: 0.65, lunge: 450 },
  bwolf: { hp: 45, r: 15, speed: 215, dmg: 12, score: 90, gold: 12 },
};
function mkEnemy(kind, x, y) {
  const def = ENEMY_DEF[kind];
  const st = (kind === 'wolf' || kind === 'bwolf') ? 'strafe' : (kind === 'thrower' ? 'keep' : 'walk');
  return {
    kind, x, y, hp: def.hp, maxHp: def.hp, r: def.r, state: st, t: rand(0.5, 1.4),
    faceAng: 0, hitT: 0, flash: 0, kbx: 0, kby: 0, aimA: 0, stepDir: pick([-1, 1]),
    phase: rand(TAU), coreHp: kind === 'knight' ? 40 : -1, coreDead: false,
    dodged: false, deadT: 0, dead: false,
  };
}
function spawnEnemy(kind) {
  let x, y, tries = 0; const m = 50, A = arena();
  do {
    const s = randi(0, 3);
    if (s === 0) { x = rand(A.minX + m, A.maxX - m); y = A.minY + m; }
    else if (s === 1) { x = rand(A.minX + m, A.maxX - m); y = A.maxY - m; }
    else if (s === 2) { x = A.minX + m; y = rand(A.minY + m, A.maxY - m); }
    else { x = A.maxX - m; y = rand(A.minY + m, A.maxY - m); }
  } while (dist(x, y, player.x, player.y) < 220 && ++tries < 12);
  const e = mkEnemy(kind, x, y);
  enemies.push(e);
  ring(x, y, 42, 'rgba(177,138,255,0.9)', 3, 0.4);
  burst(x, y, 'ash', 8);
}
function updateEnemy(e, dt) {
  if (e.dead) return;
  const p = player, def = ENEMY_DEF[e.kind];
  e.hitT = Math.max(0, e.hitT - dt); e.flash = Math.max(0, e.flash - dt);
  e.x += e.kbx * dt; e.y += e.kby * dt;
  e.kbx *= (1 - 10 * dt); e.kby *= (1 - 10 * dt);
  const A = arena();
  e.x = clamp(e.x, A.minX + 16, A.maxX - 16); e.y = clamp(e.y, A.minY + 16, A.maxY - 16);
  const d = dist(e.x, e.y, p.x, p.y);

  // فارس العظم: الموت المؤقت والعودة
  if (e.kind === 'knight') {
    if (e.state === 'dying') {
      e.deadT -= dt;
      if (e.deadT <= 0) { e.state = 'rising'; e.t = 0.9; burst(e.x, e.y, 'ash', 6); }
      return;
    }
    if (e.state === 'rising') {
      e.t -= dt;
      if (Math.random() < 0.4) burst(e.x, e.y + rand(-10, 10), 'ash', 1, 60);
      if (e.t <= 0) {
        e.hp = Math.round(e.maxHp * 0.35); e.state = 'walk'; e.t = rand(0.5, 1); e.flash = 0.3;
        floatText(e.x, e.y - 40, 'عاد من جديد!', '#c44dff', 15, true);
        SFX.revive();
      }
      return;
    }
  }

  switch (e.kind) {
    case 'outcast': case 'knight': {
      if (e.state === 'walk') {
        e.t -= dt;
        e.faceAng = angTo(e.x, e.y, p.x, p.y);
        e.x += Math.cos(e.faceAng) * def.speed * dt; e.y += Math.sin(e.faceAng) * def.speed * dt;
        if (d < 110 && e.t <= 0) { e.state = 'windup'; e.t = def.windup; e.aimA = angTo(e.x, e.y, p.x, p.y); }
      } else if (e.state === 'windup') {
        e.aimA = angTo(e.x, e.y, p.x, p.y);
        e.t -= dt; if (e.t <= 0) { e.state = 'lunge'; e.t = 0.33; }
      } else if (e.state === 'lunge') {
        e.t -= dt;
        e.x += Math.cos(e.aimA) * def.lunge * dt; e.y += Math.sin(e.aimA) * def.lunge * dt;
        if (e.t <= 0) { e.state = 'rec'; e.t = 0.55; }
      } else if (e.state === 'rec') {
        e.t -= dt; if (e.t <= 0) { e.state = 'walk'; e.t = rand(0.6, 1.4); }
      }
      break;
    }
    case 'guard': {
      e.faceAng = lerpAng(e.faceAng, angTo(e.x, e.y, p.x, p.y), 1.8 * dt);
      if (e.state === 'walk') {
        e.t -= dt;
        if (d > 130) { e.x += Math.cos(e.faceAng) * def.speed * dt; e.y += Math.sin(e.faceAng) * def.speed * dt; }
        else { const per = e.faceAng + Math.PI / 2; e.x += Math.cos(per) * def.speed * 0.5 * dt; e.y += Math.sin(per) * def.speed * 0.5 * dt; }
        if (d < 120 && e.t <= 0) { e.state = 'windup'; e.t = def.windup; e.aimA = e.faceAng; }
      } else if (e.state === 'windup') {
        e.t -= dt; if (e.t <= 0) { e.state = 'lunge'; e.t = 0.35; }
      } else if (e.state === 'lunge') {
        e.t -= dt;
        e.x += Math.cos(e.aimA) * def.lunge * dt; e.y += Math.sin(e.aimA) * def.lunge * dt;
        if (e.t <= 0) { e.state = 'rec'; e.t = 0.6; }
      } else if (e.state === 'rec') {
        e.t -= dt; if (e.t <= 0) { e.state = 'walk'; e.t = rand(0.7, 1.5); }
      }
      break;
    }
    case 'wolf': case 'bwolf': {
      if (e.state === 'strafe') {
        e.t -= dt;
        const aa = angTo(e.x, e.y, p.x, p.y), tan = aa + Math.PI / 2 * e.stepDir;
        let rx = Math.cos(tan) * def.speed, ry = Math.sin(tan) * def.speed;
        if (d > 240) { rx += Math.cos(aa) * def.speed * 0.8; ry += Math.sin(aa) * def.speed * 0.8; }
        if (d < 120) { rx -= Math.cos(aa) * def.speed * 0.8; ry -= Math.sin(aa) * def.speed * 0.8; }
        e.x += rx * dt; e.y += ry * dt;
        if (Math.random() < 0.3) part({ x: e.x - Math.cos(aa) * 14, y: e.y + rand(-6, 6), vx: rand(-10, 10), vy: rand(-30, -10), ttl: 0.5, color: '#8a8395', size: 2.5, type: 'ash' });
        if (e.t <= 0) { e.state = 'tele'; e.t = 0.5; e.aimA = angTo(e.x, e.y, p.x, p.y); }
      } else if (e.state === 'tele') {
        e.aimA = angTo(e.x, e.y, p.x, p.y);
        e.t -= dt;
        if (e.t <= 0) { e.state = 'dash'; e.t = 0.4; e.dodged = false; SFX.dash(); }
      } else if (e.state === 'dash') {
        e.t -= dt;
        e.x += Math.cos(e.aimA) * 640 * dt; e.y += Math.sin(e.aimA) * 640 * dt;
        if (p.iframes > 0 && d < 44) e.dodged = true;
        part({ x: e.x, y: e.y, vx: rand(-15, 15), vy: rand(-40, -10), ttl: 0.4, color: '#8a8395', size: 3, type: 'ash' });
        if (e.t <= 0) {
          if (e.dodged) {
            e.state = 'stagger'; e.t = 0.9;
            game.score += 25;
            floatText(e.x, e.y - 26, 'تفادٍ موفق! +25', '#7fd4ff', 14, true);
            SFX.dodge(); addShake(2, 0.1);
          } else { e.state = 'rec'; e.t = 0.5; }
        }
      } else if (e.state === 'stagger') {
        e.t -= dt;
        if (e.t <= 0) { e.state = 'strafe'; e.t = rand(0.7, 1.3); e.stepDir *= -1; }
      } else if (e.state === 'rec') {
        e.t -= dt;
        if (e.t <= 0) { e.state = 'strafe'; e.t = rand(0.7, 1.3); e.stepDir *= -1; }
      }
      break;
    }
    case 'thrower': {
      if (e.state === 'keep') {
        e.t -= dt;
        const aa = angTo(e.x, e.y, p.x, p.y);
        if (d > 360) { e.x += Math.cos(aa) * def.speed * dt; e.y += Math.sin(aa) * def.speed * dt; }
        else if (d < 270) { e.x -= Math.cos(aa) * def.speed * dt; e.y -= Math.sin(aa) * def.speed * dt; }
        if (e.t <= 0) { e.state = 'windup'; e.t = 0.65; e.aimA = aa; }
      } else if (e.state === 'windup') {
        e.aimA = angTo(e.x, e.y, p.x, p.y);
        e.t -= dt;
        if (e.t <= 0) {
          projs.push({ x: e.x + Math.cos(e.aimA) * 12, y: e.y + Math.sin(e.aimA) * 12, vx: Math.cos(e.aimA) * 360, vy: Math.sin(e.aimA) * 360, r: 7, dmg: 10, life: 2.5 });
          SFX.throwP(); e.state = 'step'; e.t = 0.45;
        }
      } else if (e.state === 'step') {
        const per = e.aimA + Math.PI / 2 * e.stepDir;
        e.x += Math.cos(per) * 260 * dt; e.y += Math.sin(per) * 260 * dt;
        e.t -= dt;
        if (e.t <= 0) { e.state = 'keep'; e.t = rand(1, 1.8); e.stepDir *= -1; }
      }
      break;
    }
    case 'beetle': {
      e.phase += dt * 6;
      const aa = angTo(e.x, e.y, p.x, p.y), per = aa + Math.PI / 2;
      const w = Math.sin(e.phase) * 130;
      e.x += (Math.cos(aa) * def.speed + Math.cos(per) * w) * dt;
      e.y += (Math.sin(aa) * def.speed + Math.sin(per) * w) * dt;
      break;
    }
  }
  // contact damage
  if (p.state === 'alive' && e.state !== 'stagger' && d < e.r + 15)
    hurtPlayer(def.dmg, e.x, e.y);
}

// ---------------- player ----------------
function nearestThreat(x, y, r) {
  let best = null, bd = r * r;
  for (const e of enemies) {
    if (e.state === 'dying' || e.state === 'rising') continue;
    const dx = e.x - x, dy = e.y - y;
    if (dx * dx + dy * dy < bd) { bd = dx * dx + dy * dy; best = e; }
  }
  if (boss && !boss.dead && boss.state !== 'enter') {
    const dx = boss.x - x, dy = boss.y - y;
    if (dx * dx + dy * dy < bd) best = boss;
  }
  return best;
}
function updatePlayer(dt) {
  const p = player;
  p.iframes = Math.max(0, p.iframes - dt);
  p.atkCd = Math.max(0, p.atkCd - dt);
  p.dashCd = Math.max(0, p.dashCd - dt);
  p.phCd = Math.max(0, p.phCd - dt);
  p.patchCd = Math.max(0, p.patchCd - dt);
  p.comboPop = Math.max(0, p.comboPop - dt);
  p.attackT = Math.max(0, p.attackT - dt);
  p.chainT = Math.max(0, p.chainT - dt);
  if (p.chainT <= 0) p.chain = 0;
  if (p.state !== 'alive') return;

  let mx = input.mx, my = input.my;
  const m = Math.hypot(mx, my);
  if (m > 1) { mx /= m; my /= m; }

  // اندفاع الجمر
  if (input.dashQ) {
    input.dashQ = false;
    if (p.dashCd <= 0) {
      p.dashT = 0.16; p.dashCd = 1.1;
      p.iframes = Math.max(p.iframes, 0.3);
      p.dashA = m > 0.15 ? Math.atan2(my, mx) : p.moveA;
      SFX.dash();
      ring(p.x, p.y, 34, 'rgba(255,176,84,0.7)', 3, 0.3);
      burst(p.x, p.y, 'ember', 6, 120);
    }
  }
  if (p.dashT > 0) {
    p.dashT -= dt;
    p.x += Math.cos(p.dashA) * 780 * dt; p.y += Math.sin(p.dashA) * 780 * dt;
    part({ x: p.x + rand(-8, 8), y: p.y + rand(-8, 8), vx: rand(-20, 20), vy: rand(-20, 20), ttl: 0.3, color: '#ffb054', size: 3, type: 'ember' });
  } else {
    p.x += mx * 300 * dt; p.y += my * 300 * dt;
    if (m > 0.15) { p.moveA = Math.atan2(my, mx); p.facing = Math.cos(p.moveA) >= 0 ? 1 : -1; p.moving = true; }
    else p.moving = false;
  }
  const A = arena();
  p.x = clamp(p.x, A.minX + 18, A.maxX - 18);
  p.y = clamp(p.y, A.minY + 18, A.maxY - 18);

  if (input.attackHeld) tryAttack();
  if (input.phxQ) { input.phxQ = false; if (p.phCd <= 0) doPhoenix(); }

  // حرارة اللهب / اللهب المتوج
  if (p.flameT > 0) {
    p.flameT -= dt;
    if (Math.random() < 0.5) part({ x: p.x + rand(-18, 18), y: p.y + rand(-8, 12), vx: rand(-30, 30), vy: rand(-100, -30), ttl: rand(0.3, 0.6), size: rand(2, 4), color: pick(['#ffb054', '#ff7a2f', '#ffd98a']), type: 'ember', grav: -30 });
    if (p.flameT <= 0) { p.flameT = 0; p.heat = 0; floatText(p.x, p.y - 44, 'خمد اللهب', '#b9a8d9', 12); }
  } else {
    p.heat = Math.max(0, p.heat - 2.5 * dt);
    if (p.heat >= 100) {
      p.flameT = 6;
      SFX.flame(); addShake(8, 0.4);
      ring(p.x, p.y, 140, 'rgba(255,176,84,0.9)', 6, 0.6);
      floatText(p.x, p.y - 46, 'اللهب المتوج!', '#ff8c2f', 20, true);
    }
  }
}
function tryAttack() {
  const p = player;
  if (p.state !== 'alive' || p.atkCd > 0 || p.dashT > 0) return;
  p.atkCd = p.flameT > 0 ? 0.16 : 0.21;
  p.attackT = 0.15; p.comboI = (p.comboI + 1) % 3;
  const tgt = nearestThreat(p.x, p.y, p.flameT > 0 ? 150 : 130);
  if (tgt) { p.faceAng = angTo(p.x, p.y, tgt.x, tgt.y); p.facing = Math.cos(p.faceAng) >= 0 ? 1 : -1; }
  const range = p.flameT > 0 ? 112 : 86, heavy = p.comboI === 2;
  const dmg = [13, 13, 24][p.comboI] * (p.flameT > 0 ? 1.6 : 1);
  SFX.swing(heavy);
  slash(p.x, p.y, p.faceAng, 1.15, range);
  let hitAny = false;
  for (const e of enemies) {
    if (e.state === 'dying' || e.state === 'rising') continue;
    const d = dist(p.x, p.y, e.x, e.y);
    if (d <= range + e.r && angDiff(p.faceAng, angTo(p.x, p.y, e.x, e.y)) < 1.2) { hitEnemy(e, dmg, heavy); hitAny = true; }
    if (e.kind === 'knight' && !e.coreDead) {
      const cx = e.x, cy = e.y - 30;
      if (dist(p.x, p.y, cx, cy) <= range + 12 && angDiff(p.faceAng, angTo(p.x, p.y, cx, cy)) < 1.2) {
        e.coreHp -= dmg * 1.5;
        burst(cx, cy, 'spark', 6, 220, '#7fd4ff');
        floatText(cx, cy - 14, 'نواة!', '#7fd4ff', 12);
        if (e.coreHp <= 0) {
          e.coreDead = true;
          burst(cx, cy, 'spark', 16, 280, '#7fd4ff');
          ring(cx, cy, 60, 'rgba(127,212,255,0.9)', 4, 0.4);
          floatText(cx, cy - 26, 'النواة مدمّرة!', '#7fd4ff', 16, true);
          game.score += 50;
          SFX.kill();
        }
      }
    }
  }
  if (boss && !boss.dead && boss.state !== 'enter') {
    const d = dist(p.x, p.y, boss.x, boss.y);
    if (d <= range + 74 && angDiff(p.faceAng, angTo(p.x, p.y, boss.x, boss.y)) < 1.2) { bossHit(dmg, heavy); hitAny = true; }
  }
  if (hitAny && p.flameT <= 0) p.heat = Math.min(100, p.heat + 5);
}
function doPhoenix() {
  const p = player;
  p.phCd = 14;
  ring(p.x, p.y, 220, 'rgba(255,176,84,0.95)', 9, 0.55);
  ring(p.x, p.y, 150, 'rgba(255,255,255,0.8)', 5, 0.4);
  burst(p.x, p.y, 'ember', 36, 300);
  burst(p.x, p.y, 'spark', 18, 380);
  p.hp = Math.min(p.maxHp, p.hp + 30);
  floatText(p.x, p.y - 46, '+30', '#7dff9a', 16, true);
  p.iframes = Math.max(p.iframes, 0.5);
  for (const e of enemies) {
    if (e.state === 'dying' || e.state === 'rising') continue;
    if (dist(p.x, p.y, e.x, e.y) <= 220) hitEnemy(e, 45, true);
  }
  if (boss && !boss.dead && dist(p.x, p.y, boss.x, boss.y) <= 294) bossHit(55, true);
  addShake(12, 0.45); hitstop(0.06);
  SFX.phx();
}
function hurtPlayer(dmg, sx, sy, kb = 200) {
  const p = player;
  if (p.state !== 'alive' || p.iframes > 0) return;
  p.hp -= dmg; game.dmgTaken += dmg;
  p.heat = Math.max(0, p.heat - 15);
  p.iframes = 0.9; p.hurtFlash = 0.5;
  const a = angTo(sx, sy, p.x, p.y);
  p.x += Math.cos(a) * 14; p.y += Math.sin(a) * 14;
  floatText(p.x, p.y - 30, '-' + dmg, '#ff5a5a', 18, true);
  burst(p.x, p.y, 'spark', 8, 200, '#ff5a5a');
  addShake(8, 0.3);
  SFX.hurt();
  if (p.hp <= 0) {
    p.hp = 0; p.state = 'dead'; p.deadT = 1.4;
    burst(p.x, p.y, 'ash', 30, 240);
    burst(p.x, p.y, 'ember', 20, 260);
    addShake(14, 0.6); hitstop(0.08);
  }
}

// ---------------- combat resolution ----------------
function hitEnemy(e, dmg, heavy) {
  let d = dmg, blocked = false;
  if (e.kind === 'guard' && e.state !== 'stagger') {
    if (angDiff(e.faceAng, angTo(e.x, e.y, player.x, player.y)) < 1.05) { d = Math.max(1, d * 0.15); blocked = true; }
  }
  e.hp -= d; e.hitT = 0.1; e.flash = 0.08;
  const a = angTo(player.x, player.y, e.x, e.y), imp = blocked ? 40 : 130;
  e.kbx += Math.cos(a) * imp; e.kby += Math.sin(a) * imp;
  burst(e.x, e.y, blocked ? 'dust' : 'spark', blocked ? 4 : (heavy ? 10 : 6), heavy ? 260 : 180);
  floatText(e.x, e.y - e.r - 14, fmt(d), blocked ? '#8f88a0' : (heavy ? '#ffd98a' : '#ffffff'), heavy ? 20 : 14, heavy);
  if (heavy) { hitstop(0.05); addShake(5, 0.18); }
  SFX.hit();
  if (e.hp <= 0) killEnemy(e);
}
function killEnemy(e) {
  const p = player;
  if (e.kind === 'knight' && !e.coreDead) {
    e.state = 'dying'; e.deadT = 0.55; e.hp = 0;
    burst(e.x, e.y, 'ash', 10);
    ring(e.x, e.y, 50, 'rgba(208,208,220,0.8)', 3, 0.5);
    SFX.kill();
    return;
  }
  const def = ENEMY_DEF[e.kind];
  const mult = 1 + 0.5 * Math.min(8, p.chain);
  const pts = Math.round(def.score * mult / 5) * 5;
  game.score += pts; scorePop = 0.3;
  p.chain++; p.chainT = 3; p.comboPop = 0.25;
  if (p.flameT <= 0) p.heat = Math.min(100, p.heat + (e.kind === 'wolf' || e.kind === 'bwolf' ? 14 : 8));
  floatText(e.x, e.y - e.r - 30, '+' + fmt(pts), '#f5c04e', 16, true);
  const n = Math.min(6, Math.ceil(def.gold / 2));
  for (let i = 0; i < n; i++) motes.push({ x: e.x, y: e.y, tx: 1226, ty: 96, t: 0, dur: rand(0.5, 0.9), v: def.gold / n });
  burst(e.x, e.y, 'ash', e.kind === 'beetle' ? 8 : 14);
  burst(e.x, e.y, 'ember', 6);
  ring(e.x, e.y, 44, 'rgba(255,176,84,0.7)', 3, 0.35);
  SFX.kill(); hitstop(0.035); addShake(3, 0.15);
  e.dead = true;
}

// ---------------- boss: غاروك، آكل السهول ----------------
const BOSS_HP = 2400, BOSS_SPEED = 120;
function startBoss() {
  game.wave = WAVES.length; game.phase = 'boss'; game.bossTime = 0;
  boss = {
    x: 1420, y: 390, hp: BOSS_HP, maxHp: BOSS_HP, r: 74, state: 'enter', t: 1.7,
    faceAng: Math.PI, hitT: 0, flash: 0, stunT: 0,
    hornA: true, hornB: true, hornWindow: 0, windowDmg: 0, coreExp: 0,
    enraged: false, summonPhase: false, summonT: 4, safeT: 12,
    postClose: 0, postCloseHits: 0, chargeAng: Math.PI,
    slam: null, dead: false, deathT: 0, bob: 0, patchT: 3,
  };
  banner('غاروك، آكل السهول', 'اصطدم به بالأعمدة لنفخ قرنيه!');
  game.tip = 'قرناه ينفخان برتقاليًا بعد الاصطدام بالأعمدة — اركّز هجومك هناك';
  game.tipT = 7;
  bossHintT = 10;
  purpleFlash = 0.7; addShake(14, 0.8);
  SFX.roar();
}
function pickBossAction(b) {
  const p = player, r = Math.random();
  const alive = pillars.filter(pl => pl.alive);
  if (r < 0.42) { b.state = 'slam_tg'; b.t = 0.55; }
  else if (r < 0.78) {
    let tx = p.x, ty = p.y;
    if (alive.length && Math.random() < 0.6) {
      let best = null, bd = 1e9;
      for (const pl of alive) { const d = dist(b.x, b.y, pl.x, pl.y); if (d < bd) { bd = d; best = pl; } }
      if (best && bd < 620) { tx = best.x; ty = best.y; }
    }
    b.chargeAng = angTo(b.x, b.y, tx, ty);
    b.state = 'charge_tg'; b.t = 0.7;
  } else { b.state = 'idle'; b.t = rand(0.5, 0.9); }
}
function hornFlare(dur) {
  if (!boss || boss.dead || (!boss.hornA && !boss.hornB)) return;
  boss.hornWindow = Math.max(boss.hornWindow, dur);
  boss.windowDmg = 0;
  SFX.horn(); boss.flash = 0.3;
  floatText(boss.x, boss.y - 140, 'انفخ القرن!', '#ff8c2f', 18, true);
}
function pillarImpact(pl, b) {
  pl.hp--;
  SFX.pillar(); addShake(11, 0.45);
  burst(pl.x, pl.y, 'dust', 16, 220);
  burst(pl.x, pl.y, 'rubble', 10, 240);
  ring(pl.x, pl.y, 90, 'rgba(200,190,170,0.8)', 5, 0.5);
  if (pl.hp <= 0) {
    pl.alive = false;
    addShake(15, 0.6);
    burst(pl.x, pl.y, 'rubble', 22, 320);
    ring(pl.x, pl.y, 130, 'rgba(177,138,255,0.8)', 6, 0.6);
    SFX.hornBreak();
    floatText(pl.x, pl.y - 110, 'العمود انهار!', '#e8e0d0', 15, true);
  } else {
    floatText(pl.x, pl.y - 110, 'العمود يتصدّع!', '#e8e0d0', 15, true);
  }
  purpleFlash = 0.35;
  hornFlare(3.0);
}
function wallImpact(b) {
  const A = arena();
  b.x = clamp(b.x, A.minX + 72, A.maxX - 72);
  b.y = clamp(b.y, A.minY + 72, A.maxY - 72);
  burst(b.x, b.y, 'dust', 10, 180);
  SFX.pillar(); addShake(8, 0.3);
  hornFlare(1.4);
  b.state = 'rec'; b.t = 0.5;
}
function updateBoss(dt) {
  const b = boss;
  if (!b) return;
  if (b.dead) {
    b.deathT -= dt;
    if (Math.random() < 0.4) burst(b.x + rand(-70, 70), b.y + rand(-50, 50), 'ember', 3, 160);
    if (Math.random() < 0.3) burst(b.x + rand(-70, 70), b.y + rand(-50, 50), 'ash', 3, 120);
    if (b.deathT <= 0) onBossDeath();
    return;
  }
  b.hitT = Math.max(0, b.hitT - dt);
  b.flash = Math.max(0, b.flash - dt);
  b.bob += dt;
  if (b.stunT > 0) { b.stunT -= dt; return; }
  b.t -= dt;
  const p = player, spd = b.enraged ? BOSS_SPEED * 1.3 : BOSS_SPEED;
  const a = angTo(b.x, b.y, p.x, p.y);

  switch (b.state) {
    case 'enter':
      b.x -= 230 * dt;
      if (b.x <= 1000) { b.x = 1000; b.state = 'idle'; b.t = rand(0.6, 1.1); }
      break;
    case 'idle': {
      b.faceAng = a;
      const d = dist(b.x, b.y, p.x, p.y);
      if (d > 150) { b.x += Math.cos(a) * spd * dt; b.y += Math.sin(a) * spd * dt; }
      if (b.t <= 0) pickBossAction(b);
      break;
    }
    case 'slam_tg':
      if (b.t <= 0) { b.state = 'slam'; b.t = 0.55; b.slam = { r: 0, hit: false }; addShake(13, 0.4); SFX.slam(); }
      break;
    case 'slam': {
      b.slam.r += 560 * dt;
      const d = dist(p.x, p.y, b.x, b.y);
      if (!b.slam.hit && d <= b.slam.r && d <= 310) { hurtPlayer(16, b.x, b.y, 260); b.slam.hit = true; }
      if (b.t <= 0) { b.state = 'idle'; b.t = rand(0.5, 1.1); }
      break;
    }
    case 'charge_tg':
      if (b.t <= 0) { b.state = 'charge'; b.t = 1.4; SFX.charge(); }
      break;
    case 'charge': {
      b.x += Math.cos(b.chargeAng) * 950 * dt;
      b.y += Math.sin(b.chargeAng) * 950 * dt;
      for (const pl of pillars) {
        if (!pl.alive) continue;
        const d = dist(b.x, b.y, pl.x, pl.y);
        if (d < pl.r + b.r - 14) {
          pillarImpact(pl, b);
          b.state = 'idle'; b.t = rand(0.7, 1.2);
          break;
        }
      }
      if (b.state === 'charge') {
        if (dist(b.x, b.y, p.x, p.y) < b.r + 14) {
          hurtPlayer(18, b.x, b.y, 300);
          b.state = 'rec'; b.t = 0.5;
          addShake(10, 0.3);
        } else {
          const A = arena();
          if (b.x < A.minX + 70 || b.x > A.maxX - 70 || b.y < A.minY + 70 || b.y > A.maxY - 70) wallImpact(b);
        }
      }
      if (b.t <= 0 && b.state === 'charge') { b.state = 'idle'; b.t = 0.6; }
      break;
    }
    case 'rec':
      if (b.t <= 0) { b.state = 'idle'; b.t = rand(0.4, 1); }
      break;
    case 'summon':
      if (b.t <= 0) {
        for (let i = 0; i < 2; i++) {
          const s = mkEnemy('bwolf', clamp(b.x + rand(-140, 140), 120, 1160), clamp(b.y + rand(-90, 90), 140, 600));
          enemies.push(s);
          ring(s.x, s.y, 40, 'rgba(177,138,255,0.9)', 3, 0.4);
          burst(s.x, s.y, 'ash', 8);
        }
        b.state = 'idle'; b.t = 0.8;
      }
      break;
  }

  // horn window / greed penalty
  if (b.hornWindow > 0) {
    b.hornWindow -= dt;
    if (Math.random() < 0.15) part({ x: b.x - 70 + rand(-10, 10), y: b.y - 44, vx: rand(-20, 20), vy: rand(-70, -20), ttl: 0.5, color: '#ff8c2f', size: 2.5, type: 'ember' });
    if (b.hornWindow <= 0) { b.postClose = 0.5; b.postCloseHits = 0; }
  } else if (b.postClose > 0) b.postClose -= dt;
  if (b.coreExp > 0) b.coreExp -= dt;
  // safety flare so windows always come
  b.safeT -= dt;
  if (b.safeT <= 0 && (b.hornA || b.hornB) && b.hornWindow <= 0 && b.state !== 'enter' && b.state !== 'charge') {
    hornFlare(1.6);
    b.safeT = 12;
  }
  // phase 2: قطيع الرماد
  if (!b.summonPhase && b.hp / b.maxHp < 0.7) { b.summonPhase = true; b.summonT = 3; }
  if (b.summonPhase) {
    b.summonT -= dt;
    if (b.summonT <= 0) {
      let n = 0;
      for (const e of enemies) if (e.kind === 'bwolf') n++;
      if (n < 3) { b.state = 'summon'; b.t = 0.8; b.summonT = 9; }
      else b.summonT = 2;
    }
  }
  // enraged fire patches
  if (b.enraged) {
    b.patchT -= dt;
    if (b.patchT <= 0 && patches.length < 4) {
      b.patchT = 3.2;
      const A = arena();
      for (let k = 0; k < 2; k++) {
        let x, y, tries = 0;
        do { x = rand(A.minX + 80, A.maxX - 80); y = rand(A.minY + 70, A.maxY - 70); }
        while (dist(x, y, p.x, p.y) < 120 && ++tries < 10);
        patches.push({ x, y, r: 64, life: 4 });
        ring(x, y, 80, 'rgba(150,60,255,0.8)', 3, 0.5);
      }
    }
    if (Math.random() < 0.2) part({ x: b.x + rand(-70, 70), y: b.y + rand(-40, 20), vx: rand(-15, 15), vy: rand(-80, -30), ttl: rand(0.3, 0.6), size: rand(2, 4), color: '#ff7a2f', type: 'ember', grav: -30 });
  }
  // contact
  if (p.state === 'alive' && dist(b.x, b.y, p.x, p.y) < b.r + 12) hurtPlayer(12, b.x, b.y, 240);
  // clamp (not during enter — he slides in from off-screen)
  if (b.state !== 'enter') {
    const A = arena();
    b.x = clamp(b.x, A.minX + 80, A.maxX - 80);
    b.y = clamp(b.y, A.minY + 70, A.maxY - 70);
  }
}
function bossHit(dmg, heavy) {
  const b = boss;
  if (!b || b.dead) return;
  let mult = 1;
  if (b.hornWindow > 0) { mult *= 3; b.windowDmg += dmg; }
  if (b.coreExp > 0) mult *= 1.7;
  const d = dmg * mult;
  b.hp -= d; b.hitT = 0.1;
  const hx = b.x + rand(-40, 40), hy = b.y + rand(-50, 10);
  burst(hx, hy, 'spark', heavy ? 12 : 7, 240);
  floatText(hx, hy - 16, fmt(d), mult > 1 ? '#ff8c2f' : '#ffffff', heavy ? 22 : 14, heavy || mult > 1);
  if (mult > 1) hitstop(0.04);
  SFX.hit();
  if (b.hp <= 0) { b.hp = 0; killBoss(); return; }
  if (b.hornWindow > 0 && b.windowDmg >= 45) breakHorn();
  // عقوبة الطمع: الضرب بعد إغلاق النافذة
  if (b.hornWindow <= 0 && b.postClose > 0) {
    b.postCloseHits++;
    if (b.postCloseHits >= 2) {
      b.postClose = 0; b.flash = 0.4;
      SFX.shock();
      ring(b.x, b.y, 190, 'rgba(200,80,255,0.9)', 6, 0.5);
      addShake(9, 0.3);
      floatText(b.x, b.y - 140, 'طامِع!', '#c44dff', 16, true);
      if (dist(player.x, player.y, b.x, b.y) < 200) hurtPlayer(12, b.x, b.y, 260);
    }
  }
}
function breakHorn() {
  const b = boss;
  if (b.hornA) b.hornA = false;
  else if (b.hornB) b.hornB = false;
  else return;
  b.hornWindow = 0; b.windowDmg = 0;
  b.stunT = 1.3; b.coreExp = 4.5;
  const mult = 1 + 0.5 * Math.min(8, player.chain);
  const pts = Math.round(300 * mult / 5) * 5;
  game.score += pts;
  floatText(b.x, b.y - 150, 'انكسر قرن غاروك! +' + fmt(pts), '#ff8c2f', 20, true);
  burst(b.x - 70, b.y - 60, 'rubble', 14, 300);
  burst(b.x, b.y - 60, 'spark', 20, 300, '#ff8c2f');
  ring(b.x, b.y, 150, 'rgba(255,140,47,0.9)', 7, 0.6);
  addShake(13, 0.5); hitstop(0.08);
  SFX.hornBreak(); SFX.roar();
  purpleFlash = 0.4;
  if (!b.hornA && !b.hornB && !b.enraged) {
    b.enraged = true;
    banner('هياج الهاوية', 'الساحة تضيق والنار تشتعل!');
    game.tip = 'الساحة تضيق — احذر برَك النار البنفسجية';
    game.tipT = 6;
    SFX.roar(); purpleFlash = 0.7; addShake(16, 0.7);
  }
}
function killBoss() {
  const b = boss;
  b.dead = true; b.deathT = 1.8;
  game.phase = 'bossdead';
  game.gold += 500; game.shards = 3;
  const mult = 1 + 0.5 * Math.min(8, player.chain);
  const pts = Math.round(2000 * mult / 5) * 5;
  game.score += pts;
  floatText(b.x, b.y - 120, '+' + fmt(pts), '#f5c04e', 26, true);
  ring(b.x, b.y, 300, 'rgba(255,176,84,0.9)', 10, 0.9);
  ring(b.x, b.y, 220, 'rgba(255,255,255,0.8)', 6, 0.7);
  burst(b.x, b.y, 'ember', 50, 320);
  burst(b.x, b.y, 'ash', 30, 260);
  burst(b.x, b.y, 'spark', 24, 380);
  addShake(20, 0.9); hitstop(0.12);
  SFX.bossDeath(); SFX.roar();
  for (const e of enemies) burst(e.x, e.y, 'ash', 10);
  enemies.length = 0;
  projs.length = 0;
}
function calcStars() {
  const t = game.bossTime, d = game.dmgTaken;
  if (t < 80 && d <= 40) return 3;
  if (t < 120 && d <= 70) return 2;
  return 1;
}
function onBossDeath() {
  game.stars = calcStars();
  bank.gold += game.gold;
  bank.shards += game.shards;
  if (!bank.weapon) { bank.weapon = true; game.newWeapon = true; }
  saveBank();
  game.state = 'win';
  endRun();
  fillWin();
  setOverlay('ov-win');
  SFX.win();
}
function onPlayerDeath() {
  game.savedGold = Math.floor(game.gold * 0.5);
  bank.gold += game.savedGold;
  saveBank();
  game.state = 'over';
  endRun();
  fillOver();
  setOverlay('ov-over');
  SFX.lose();
}

// ---------------- projectiles / patches / motes ----------------
function updateProjs(dt) {
  const p = player;
  for (let i = projs.length - 1; i >= 0; i--) {
    const pr = projs[i];
    pr.x += pr.vx * dt; pr.y += pr.vy * dt; pr.life -= dt;
    if (Math.random() < 0.5) part({ x: pr.x, y: pr.y, vx: rand(-10, 10), vy: rand(-10, 10), ttl: 0.25, color: '#8a7f9d', size: 2.5, type: 'ash' });
    const A = arena();
    if (pr.life <= 0 || pr.x < A.minX || pr.x > A.maxX || pr.y < A.minY || pr.y > A.maxY) {
      burst(pr.x, pr.y, 'ash', 4, 80);
      projs.splice(i, 1);
      continue;
    }
    if (p.state === 'alive' && dist(pr.x, pr.y, p.x, p.y) < pr.r + 14) {
      hurtPlayer(pr.dmg, pr.x, pr.y, 120);
      burst(pr.x, pr.y, 'ash', 6, 100);
      projs.splice(i, 1);
    }
  }
}
function updatePatches(dt) {
  const p = player;
  for (let i = patches.length - 1; i >= 0; i--) {
    const f = patches[i];
    f.life -= dt;
    if (f.life <= 0) { patches.splice(i, 1); continue; }
    if (p.state === 'alive' && p.patchCd <= 0 && dist(f.x, f.y, p.x, p.y) < f.r - 8) {
      hurtPlayer(9, f.x, f.y, 120);
      p.patchCd = 0.8;
    }
  }
}
function updateMotes(dt) {
  for (let i = motes.length - 1; i >= 0; i--) {
    const m = motes[i];
    m.t += dt / m.dur;
    if (m.t >= 1) {
      game.gold += m.v; goldPop = 0.3;
      if (i % 2 === 0) SFX.coin();
      motes.splice(i, 1);
    }
  }
}
function drawMotes() {
  for (const m of motes) {
    const t = clamp(m.t, 0, 1), u = 1 - t;
    const cx = (m.x + m.tx) / 2, cy = Math.min(m.y, m.ty) - 90;
    const x = u * u * m.x + 2 * u * t * cx + t * t * m.tx;
    const y = u * u * m.y + 2 * u * t * cy + t * t * m.ty;
    ctx.fillStyle = '#f5c04e';
    ctx.beginPath(); ctx.arc(x, y, 4, 0, TAU); ctx.fill();
    ctx.fillStyle = '#fff3c4';
    ctx.beginPath(); ctx.arc(x - 1, y - 1, 1.6, 0, TAU); ctx.fill();
  }
}
function drawProj(pr) {
  ctx.drawImage(glowPurple, pr.x - 14, pr.y - 14, 28, 28);
  ctx.fillStyle = '#9a86b8';
  ctx.beginPath(); ctx.arc(pr.x, pr.y, pr.r, 0, TAU); ctx.fill();
  ctx.fillStyle = '#d8c8ff';
  ctx.beginPath(); ctx.arc(pr.x - 1.5, pr.y - 1.5, 2.5, 0, TAU); ctx.fill();
}
function drawPatch(f) {
  const a = clamp(f.life, 0, 1);
  const flick = 0.75 + 0.25 * Math.sin(game.time * 24 + f.x);
  ctx.globalAlpha = Math.min(1, a * 2) * flick;
  ctx.drawImage(firePatch, f.x - 80, f.y - 50, 160, 100);
  ctx.globalAlpha = 1;
}

// ---------------- world update ----------------
function stepWorld(dt) {
  game.time += dt;
  updatePlayer(dt);
  for (const e of enemies) updateEnemy(e, dt);
  enemies = enemies.filter(e => !e.dead);
  if (boss) updateBoss(dt);
  updateProjs(dt);
  updatePatches(dt);
  updateMotes(dt);
  updateWaves(dt);
  if (boss && !boss.dead && boss.state !== 'enter') game.bossTime += dt;
  if (boss && boss.enraged && !boss.dead) arenaT = Math.min(1, arenaT + dt / 8);
  if (player.state === 'dead') {
    player.deadT -= dt;
    if (player.deadT <= 0) onPlayerDeath();
  }
  updateParts(dt);
  updateRings(dt);
  updateSlashes(dt);
  updateTexts(dt);
  game.bannerT = Math.max(0, game.bannerT - dt);
  game.tipT = Math.max(0, game.tipT - dt);
  bossHintT = Math.max(0, bossHintT - dt);
}
function update(dt) {
  updateAmbient(dt);
  if (game.state === 'play') stepWorld(dt);
  if (shake.t > 0) shake.t = Math.max(0, shake.t - dt);
  purpleFlash = Math.max(0, purpleFlash - dt);
  goldPop = Math.max(0, goldPop - dt);
  shardPop = Math.max(0, shardPop - dt);
  scorePop = Math.max(0, scorePop - dt);
  if (player) player.hurtFlash = Math.max(0, player.hurtFlash - dt);
}

// ---------------- rendering ----------------
function drawTelegraphs() {
  const t = game.time;
  if (boss && !boss.dead) {
    if (boss.state === 'slam_tg') {
      const k = 1 - boss.t / 0.55;
      ctx.strokeStyle = 'rgba(255,70,60,' + (0.35 + 0.3 * Math.sin(t * 25)) + ')';
      ctx.lineWidth = 3; ctx.setLineDash([10, 8]);
      ctx.beginPath(); ctx.arc(boss.x, boss.y, 290 * k, 0, TAU); ctx.stroke();
      ctx.setLineDash([]);
      ctx.fillStyle = 'rgba(255,70,60,0.08)';
      ctx.beginPath(); ctx.arc(boss.x, boss.y, 290 * k, 0, TAU); ctx.fill();
    }
    if (boss.state === 'charge_tg') {
      ctx.strokeStyle = 'rgba(255,70,60,' + (0.5 + 0.3 * Math.sin(t * 30)) + ')';
      ctx.lineWidth = 5; ctx.setLineDash([16, 12]);
      ctx.beginPath();
      ctx.moveTo(boss.x, boss.y);
      ctx.lineTo(boss.x + Math.cos(boss.chargeAng) * 900, boss.y + Math.sin(boss.chargeAng) * 900);
      ctx.stroke(); ctx.setLineDash([]);
    }
  }
  for (const e of enemies) {
    if ((e.kind === 'wolf' || e.kind === 'bwolf') && e.state === 'tele') {
      ctx.strokeStyle = 'rgba(255,90,80,' + (0.5 + 0.3 * Math.sin(t * 30)) + ')';
      ctx.lineWidth = 3; ctx.setLineDash([8, 8]);
      ctx.beginPath();
      ctx.moveTo(e.x, e.y);
      ctx.lineTo(e.x + Math.cos(e.aimA) * 150, e.y + Math.sin(e.aimA) * 150);
      ctx.stroke(); ctx.setLineDash([]);
    }
  }
}
function drawPillar(pl) {
  ctx.save();
  ctx.translate(pl.x, pl.y);
  ctx.fillStyle = 'rgba(0,0,0,0.3)';
  ctx.beginPath(); ctx.ellipse(0, 6, 44, 14, 0, 0, TAU); ctx.fill();
  ctx.fillStyle = '#6e6558';
  ctx.beginPath(); ctx.ellipse(0, 0, 38, 13, 0, 0, TAU); ctx.fill();
  const h = 140;
  ctx.fillStyle = '#8d8272';
  ctx.beginPath(); ctx.moveTo(-24, 0); ctx.lineTo(-19, -h); ctx.lineTo(19, -h); ctx.lineTo(24, 0); ctx.closePath(); ctx.fill();
  ctx.fillStyle = 'rgba(60,52,44,0.35)';
  ctx.beginPath(); ctx.moveTo(8, 0); ctx.lineTo(12, -h); ctx.lineTo(19, -h); ctx.lineTo(24, 0); ctx.closePath(); ctx.fill();
  ctx.fillStyle = '#7a7062';
  ctx.beginPath(); ctx.ellipse(0, -h, 20, 7, 0, 0, TAU); ctx.fill();
  if (pl.hp === 1) {
    ctx.strokeStyle = 'rgba(30,26,22,0.8)'; ctx.lineWidth = 2.5;
    ctx.beginPath(); ctx.moveTo(-14, -20); ctx.lineTo(-4, -52); ctx.lineTo(-12, -84); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(10, -30); ctx.lineTo(3, -66); ctx.stroke();
  }
  if (boss && boss.state === 'charge_tg' && dist(boss.x, boss.y, pl.x, pl.y) < 620) {
    ctx.strokeStyle = 'rgba(177,138,255,' + (0.4 + 0.3 * Math.sin(game.time * 18)) + ')';
    ctx.lineWidth = 4;
    ctx.beginPath(); ctx.ellipse(0, 0, 46, 16, 0, 0, TAU); ctx.stroke();
  }
  ctx.restore();
}
function drawPlayer() {
  const p = player;
  if (!p) return;
  const bob = p.moving ? Math.sin(game.time * 14) * 2 : Math.sin(game.time * 3) * 1;
  const x = p.x, y = p.y;
  ctx.fillStyle = 'rgba(0,0,0,0.35)';
  ctx.beginPath(); ctx.ellipse(x, y + 16, 18, 6, 0, 0, TAU); ctx.fill();
  if (p.flameT > 0) {
    const s = 130 * (1 + 0.12 * Math.sin(game.time * 20));
    ctx.globalAlpha = 0.55 + 0.2 * Math.sin(game.time * 20);
    ctx.drawImage(glowOrange, x - s / 2, y - s / 2 - 8, s, s);
    ctx.globalAlpha = 1;
  }
  ctx.save();
  ctx.translate(x, y + bob);
  if (p.state === 'dead') {
    ctx.rotate(1.35);
    ctx.globalAlpha = clamp(p.deadT / 1.4, 0, 1);
  } else if (p.iframes > 0 && Math.floor(game.time * 18) % 2 === 0) {
    ctx.globalAlpha = 0.45;
  }
  ctx.scale(p.facing, 1);
  // cape
  const fl = Math.sin(game.time * 10) * 3;
  ctx.fillStyle = '#6e2434';
  ctx.beginPath();
  ctx.moveTo(-4, -14);
  ctx.quadraticCurveTo(-18 - fl, 4, -12 - fl, 14);
  ctx.lineTo(-3, 10);
  ctx.closePath(); ctx.fill();
  // legs
  const run = p.moving ? Math.sin(game.time * 14) : 0;
  ctx.strokeStyle = '#241d30'; ctx.lineWidth = 5; ctx.lineCap = 'round';
  ctx.beginPath(); ctx.moveTo(-3, 8); ctx.lineTo(-3 + run * 5, 16); ctx.stroke();
  ctx.beginPath(); ctx.moveTo(4, 8); ctx.lineTo(4 - run * 5, 16); ctx.stroke();
  // torso
  ctx.fillStyle = '#2f2740'; rr(-9, -13, 18, 21, 5); ctx.fill();
  ctx.fillStyle = '#f5c04e'; ctx.fillRect(-9, -2, 18, 2.5);
  ctx.fillStyle = '#3a3152'; rr(-9, -13, 18, 6, 3); ctx.fill();
  // head + hood + eyes
  ctx.fillStyle = '#3a2f4f';
  ctx.beginPath(); ctx.arc(1, -19, 7.5, 0, TAU); ctx.fill();
  ctx.fillStyle = '#151020';
  ctx.beginPath(); ctx.arc(3, -19, 5, 0, TAU); ctx.fill();
  ctx.fillStyle = '#ffd98a';
  ctx.beginPath(); ctx.arc(4, -20, 1.4, 0, TAU); ctx.fill();
  ctx.beginPath(); ctx.arc(7, -19, 1.4, 0, TAU); ctx.fill();
  // sword
  const attacking = p.attackT > 0;
  const t = attacking ? 1 - p.attackT / 0.15 : 0;
  let swordA;
  if (attacking) {
    const from = p.comboI === 2 ? -2.2 : -0.8;
    const to = p.comboI === 2 ? 2.0 : 1.6;
    swordA = lerp(from, to, easeOut(t));
  } else swordA = -0.9 + Math.sin(game.time * 2.5) * 0.08;
  const hx = 7, hy = -3;
  ctx.strokeStyle = '#241d30'; ctx.lineWidth = 4.5;
  ctx.beginPath(); ctx.moveTo(hx, hy);
  ctx.lineTo(hx + Math.cos(swordA) * 10, hy + Math.sin(swordA) * 10); ctx.stroke();
  const bl = attacking ? 34 : 28, glow = p.flameT > 0;
  ctx.strokeStyle = glow ? '#ffd98a' : '#d8d3e8';
  ctx.lineWidth = glow ? 4 : 3;
  ctx.beginPath();
  ctx.moveTo(hx + Math.cos(swordA) * 8, hy + Math.sin(swordA) * 8);
  ctx.lineTo(hx + Math.cos(swordA) * bl, hy + Math.sin(swordA) * bl);
  ctx.stroke();
  if (glow) {
    ctx.globalAlpha = 0.7;
    ctx.drawImage(glowOrange, hx + Math.cos(swordA) * bl - 14, hy + Math.sin(swordA) * bl - 14, 28, 28);
    ctx.globalAlpha = 1;
  }
  if (p.dashT > 0) {
    ctx.globalAlpha = 0.5;
    ctx.drawImage(glowOrange, -30, -38, 60, 60);
    ctx.globalAlpha = 1;
  }
  ctx.restore();
}
function drawHornShape(hx, hy, alive, vuln) {
  if (!alive) {
    ctx.strokeStyle = '#5a5348'; ctx.lineWidth = 9; ctx.lineCap = 'round';
    ctx.beginPath(); ctx.moveTo(hx, hy); ctx.lineTo(hx - 8, hy - 14); ctx.stroke();
    return;
  }
  if (vuln) {
    ctx.globalAlpha = 0.6 + 0.4 * Math.sin(game.time * 16);
    ctx.drawImage(glowOrange, hx - 34, hy - 58, 70, 80);
    ctx.globalAlpha = 1;
  }
  ctx.strokeStyle = vuln ? '#ff8c2f' : '#b9a98a';
  ctx.lineWidth = 10; ctx.lineCap = 'round';
  ctx.beginPath(); ctx.moveTo(hx, hy);
  ctx.quadraticCurveTo(hx - 18, hy - 34, hx - 34, hy - 44);
  ctx.stroke();
  if (vuln) {
    ctx.strokeStyle = 'rgba(255,220,150,0.9)'; ctx.lineWidth = 3;
    ctx.beginPath(); ctx.moveTo(hx, hy);
    ctx.quadraticCurveTo(hx - 18, hy - 34, hx - 34, hy - 44);
    ctx.stroke();
  }
}
function drawBoss() {
  const b = boss, t = game.time;
  if (b.dead) ctx.globalAlpha = clamp(b.deathT / 1.8, 0, 1);
  const sink = b.dead ? (1.8 - b.deathT) * 40 : 0;
  const bob = Math.sin(b.bob * 3) * 3;
  const dir = Math.cos(b.faceAng) >= 0 ? 1 : -1;
  ctx.save();
  ctx.translate(b.x, b.y + bob + sink);
  ctx.fillStyle = 'rgba(0,0,0,0.4)';
  ctx.beginPath(); ctx.ellipse(0, 62, 95, 20, 0, 0, TAU); ctx.fill();
  ctx.scale(dir, 1);
  // legs
  ctx.fillStyle = '#1d1528';
  for (const [lx, ph] of [[-55, 0], [-25, 2], [25, 4], [55, 1.5]]) {
    const sw = Math.sin(b.bob * 4 + ph) * 3;
    rr(lx - 11 + sw * 0.3, 10, 22, 48, 8);
    ctx.fill();
  }
  // body
  ctx.fillStyle = b.hitT > 0 ? '#3a2c4d' : '#241a30';
  ctx.beginPath(); ctx.ellipse(0, 10, 88, 58, 0, 0, TAU); ctx.fill();
  // corruption veins
  ctx.strokeStyle = b.enraged ? 'rgba(190,80,255,0.85)' : 'rgba(150,60,220,0.5)';
  ctx.lineWidth = 3;
  ctx.beginPath(); ctx.moveTo(-50, -20); ctx.bezierCurveTo(-20, -30, 10, -5, 40, -15); ctx.stroke();
  ctx.beginPath(); ctx.moveTo(-30, 30); ctx.bezierCurveTo(0, 20, 30, 40, 55, 25); ctx.stroke();
  // chest core
  if (b.coreExp > 0) {
    const pulse = 0.6 + 0.4 * Math.sin(t * 10);
    ctx.globalAlpha = pulse;
    ctx.drawImage(glowPurple, -54, -50, 80, 80);
    ctx.globalAlpha = 1;
    ctx.fillStyle = '#d24dff';
    ctx.beginPath(); ctx.arc(-14, -10, 14, 0, TAU); ctx.fill();
    ctx.fillStyle = '#f4c2ff';
    ctx.beginPath(); ctx.arc(-17, -13, 5, 0, TAU); ctx.fill();
  } else {
    ctx.fillStyle = '#120d1c';
    ctx.beginPath(); ctx.arc(-14, -10, 14, 0, TAU); ctx.fill();
    ctx.strokeStyle = 'rgba(150,60,220,0.7)'; ctx.lineWidth = 2.5;
    ctx.beginPath(); ctx.arc(-14, -10, 14, 0, TAU); ctx.stroke();
  }
  // head
  ctx.fillStyle = b.hitT > 0 ? '#3a2c4d' : '#1d1528';
  ctx.beginPath(); ctx.arc(-75, -25, 26, 0, TAU); ctx.fill();
  ctx.beginPath(); ctx.ellipse(-84, -8, 16, 10, 0.3, 0, TAU); ctx.fill();
  ctx.fillStyle = b.enraged ? '#ff2e2e' : '#ff5a3a';
  ctx.beginPath(); ctx.arc(-82, -32, 4.5, 0, TAU); ctx.fill();
  ctx.globalAlpha = 0.6;
  ctx.drawImage(glowRed, -96, -46, 28, 28);
  ctx.globalAlpha = 1;
  // horns
  drawHornShape(-58, -40, b.hornA, b.hornWindow > 0);
  drawHornShape(-92, -30, b.hornB, b.hornWindow > 0);
  // stun stars
  if (b.stunT > 0) {
    for (let k = 0; k < 3; k++) {
      const a = t * 7 + k * 2.1;
      ctx.fillStyle = '#ffd98a';
      ctx.beginPath(); ctx.arc(-70 + Math.cos(a) * 26, -64 + Math.sin(a) * 8, 3, 0, TAU); ctx.fill();
    }
  }
  ctx.restore();
  ctx.globalAlpha = 1;
}
function drawEnemy(e) {
  const t = game.time;
  ctx.save();
  ctx.translate(e.x, e.y);
  const flash = e.flash > 0;
  ctx.fillStyle = 'rgba(0,0,0,0.3)';
  ctx.beginPath(); ctx.ellipse(0, e.r * 0.7, e.r * 1.1, e.r * 0.4, 0, 0, TAU); ctx.fill();

  if (e.kind === 'outcast') {
    const w = e.state === 'walk' ? Math.sin(t * 8 + e.phase) * 3 : 0;
    const lean = e.state === 'windup' ? -3 : (e.state === 'lunge' ? 5 : 0);
    ctx.translate(lean, 0);
    ctx.fillStyle = flash ? '#8a8395' : '#4a4149';
    ctx.beginPath(); ctx.ellipse(0, 0, 13, 11 + (e.state === 'windup' ? Math.sin(t * 40) * 1.5 : 0), 0, 0, TAU); ctx.fill();
    ctx.fillStyle = '#3a333c';
    ctx.beginPath(); ctx.arc(6, -12, 6, 0, TAU); ctx.fill();
    ctx.fillStyle = '#ff4d4d';
    ctx.beginPath(); ctx.arc(8, -13, 1.5, 0, TAU); ctx.fill();
    ctx.beginPath(); ctx.arc(4, -13, 1.5, 0, TAU); ctx.fill();
    ctx.strokeStyle = '#3a333c'; ctx.lineWidth = 4; ctx.lineCap = 'round';
    ctx.beginPath(); ctx.moveTo(-4, 4); ctx.lineTo(-10 + w * 0.3, 12); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(4, 4); ctx.lineTo(10 - w * 0.3, 12); ctx.stroke();
    if (e.state === 'windup') {
      ctx.globalAlpha = 0.5 + 0.3 * Math.sin(t * 30);
      ctx.strokeStyle = '#ff5a5a'; ctx.lineWidth = 2.5;
      ctx.beginPath(); ctx.arc(0, -4, 20, -0.6, 0.6); ctx.stroke();
      ctx.globalAlpha = 1;
    }
  } else if (e.kind === 'wolf' || e.kind === 'bwolf') {
    const s = e.kind === 'bwolf' ? 1.2 : 1;
    ctx.scale(s, s);
    const running = e.state === 'dash' || e.state === 'strafe';
    const run = running ? Math.sin(t * 18 + e.phase) : 0;
    const dir = Math.cos(e.aimA || 0) >= 0 ? 1 : -1;
    ctx.scale(dir, 1);
    ctx.strokeStyle = '#2e2b36'; ctx.lineWidth = 3.5; ctx.lineCap = 'round';
    ctx.beginPath(); ctx.moveTo(-10, -2); ctx.lineTo(-12 + run * 4, 10); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(-4, -2); ctx.lineTo(-6 - run * 4, 10); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(8, -2); ctx.lineTo(10 + run * 4, 10); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(14, -2); ctx.lineTo(16 - run * 4, 10); ctx.stroke();
    ctx.fillStyle = flash ? '#8a8395' : '#413d4a';
    ctx.beginPath(); ctx.ellipse(2, 0, 16, 8, 0, 0, TAU); ctx.fill();
    ctx.strokeStyle = '#35323e'; ctx.lineWidth = 3;
    ctx.beginPath(); ctx.moveTo(-14, -2); ctx.quadraticCurveTo(-22, -8, -24, -2 + Math.sin(t * 6) * 2); ctx.stroke();
    ctx.fillStyle = flash ? '#8a8395' : '#4a4654';
    ctx.beginPath(); ctx.arc(18, -6, 6, 0, TAU); ctx.fill();
    ctx.beginPath(); ctx.moveTo(22, -6); ctx.lineTo(28, -4); ctx.lineTo(22, -2); ctx.closePath(); ctx.fill();
    ctx.fillStyle = e.state === 'tele' ? '#ff4d4d' : '#c9b8ff';
    ctx.beginPath(); ctx.arc(19, -8, 1.4, 0, TAU); ctx.fill();
    if (e.state === 'stagger') {
      for (let k = 0; k < 3; k++) {
        const a = t * 6 + k * 2.1;
        ctx.fillStyle = '#c9b8ff';
        ctx.beginPath(); ctx.arc(16 + Math.cos(a) * 8, -16 + Math.sin(a) * 3, 1.8, 0, TAU); ctx.fill();
      }
    }
  } else if (e.kind === 'thrower') {
    ctx.fillStyle = flash ? '#8a7f9d' : '#574a6e';
    ctx.beginPath(); ctx.moveTo(-9, 14); ctx.quadraticCurveTo(0, -16, 9, 14); ctx.closePath(); ctx.fill();
    ctx.fillStyle = '#3d3450';
    ctx.beginPath(); ctx.arc(0, -13, 6.5, 0, TAU); ctx.fill();
    ctx.fillStyle = '#151020';
    ctx.beginPath(); ctx.arc(0, -13, 4, 0, TAU); ctx.fill();
    ctx.fillStyle = '#c9b8ff';
    ctx.beginPath(); ctx.arc(-1.5, -13.5, 1.2, 0, TAU); ctx.fill();
    ctx.beginPath(); ctx.arc(1.5, -13.5, 1.2, 0, TAU); ctx.fill();
    if (e.state === 'windup') {
      const k = 1 - e.t / 0.65;
      ctx.globalAlpha = 0.8;
      ctx.drawImage(glowPurple, 8 - 16 * k, -6 - 16 * k, 32 * (0.4 + 0.6 * k), 32 * (0.4 + 0.6 * k));
      ctx.globalAlpha = 1;
      ctx.fillStyle = '#8a7f9d';
      ctx.beginPath(); ctx.arc(8, -6, 4 + 3 * k, 0, TAU); ctx.fill();
    }
  } else if (e.kind === 'guard') {
    ctx.fillStyle = flash ? '#8a8395' : '#4e463a';
    rr(-12, -14, 24, 26, 5); ctx.fill();
    ctx.fillStyle = '#3a3428';
    ctx.beginPath(); ctx.arc(0, -18, 6.5, 0, TAU); ctx.fill();
    ctx.fillStyle = '#ff8c5a';
    ctx.beginPath(); ctx.arc(0, -19, 1.6, 0, TAU); ctx.fill();
    ctx.save();
    ctx.rotate(e.faceAng);
    ctx.fillStyle = '#6a5c40';
    ctx.beginPath(); ctx.arc(16, 0, 13, -1.2, 1.2); ctx.arc(12, 0, 7, 1.2, -1.2, true); ctx.closePath(); ctx.fill();
    ctx.strokeStyle = '#f5c04e'; ctx.lineWidth = 2;
    ctx.beginPath(); ctx.arc(14, 0, 12, -1.1, 1.1); ctx.stroke();
    ctx.restore();
    if (e.state === 'windup') {
      ctx.globalAlpha = 0.5 + 0.3 * Math.sin(t * 30);
      ctx.strokeStyle = '#ff5a5a'; ctx.lineWidth = 2.5;
      ctx.beginPath(); ctx.arc(0, -4, 24, -0.6, 0.6); ctx.stroke();
      ctx.globalAlpha = 1;
    }
  } else if (e.kind === 'beetle') {
    ctx.save();
    ctx.rotate(Math.sin(e.phase) * 0.25);
    ctx.fillStyle = flash ? '#9a7f95' : '#5d2c4c';
    ctx.beginPath();
    for (let k = 0; k < 6; k++) {
      const a = k / 6 * TAU, px = Math.cos(a) * 9, py = Math.sin(a) * 7;
      if (k === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
    }
    ctx.closePath(); ctx.fill();
    ctx.strokeStyle = 'rgba(200,120,255,0.5)'; ctx.lineWidth = 1.5;
    ctx.beginPath(); ctx.moveTo(-6, 0); ctx.lineTo(6, 0); ctx.stroke();
    ctx.strokeStyle = '#3a1f33'; ctx.lineWidth = 1.5;
    for (let k = 0; k < 3; k++) {
      const a = (k / 3 - 0.33) * TAU;
      ctx.beginPath(); ctx.moveTo(Math.cos(a) * 8, Math.sin(a) * 6); ctx.lineTo(Math.cos(a) * 13, Math.sin(a) * 10); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(-Math.cos(a) * 8, -Math.sin(a) * 6); ctx.lineTo(-Math.cos(a) * 13, -Math.sin(a) * 10); ctx.stroke();
    }
    ctx.restore();
  } else if (e.kind === 'knight') {
    const rising = e.state === 'rising';
    if (rising || e.state === 'dying') ctx.globalAlpha = 0.55 + 0.2 * Math.sin(t * 10);
    const run = e.state !== 'lunge' && e.state === 'walk' ? Math.sin(t * 10 + e.phase) : 0;
    ctx.strokeStyle = '#8f8878'; ctx.lineWidth = 3.5; ctx.lineCap = 'round';
    ctx.beginPath(); ctx.moveTo(-12, -2); ctx.lineTo(-14 + run * 5, 12); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(-6, -2); ctx.lineTo(-8 - run * 5, 12); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(8, -2); ctx.lineTo(10 + run * 5, 12); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(14, -2); ctx.lineTo(16 - run * 5, 12); ctx.stroke();
    ctx.fillStyle = flash ? '#ffffff' : '#d8d0c0';
    ctx.beginPath(); ctx.ellipse(0, 0, 20, 10, 0, 0, TAU); ctx.fill();
    ctx.fillStyle = '#cfc6b4';
    ctx.beginPath(); ctx.arc(20, -14, 7, 0, TAU); ctx.fill();
    ctx.fillStyle = '#241d30';
    ctx.beginPath(); ctx.arc(22, -15, 1.8, 0, TAU); ctx.fill();
    ctx.strokeStyle = '#8f8878'; ctx.lineWidth = 2;
    ctx.beginPath(); ctx.moveTo(14, -20); ctx.lineTo(10, -26); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(18, -19); ctx.lineTo(16, -26); ctx.stroke();
    ctx.fillStyle = '#3a3348';
    rr(-8, -30, 12, 14, 4); ctx.fill();
    ctx.fillStyle = '#574a6e';
    ctx.beginPath(); ctx.arc(-2, -33, 5, 0, TAU); ctx.fill();
    ctx.fillStyle = '#ff4d4d';
    ctx.fillRect(-4, -40, 3, 6);
    if (!e.coreDead) {
      const pulse = 0.6 + 0.4 * Math.sin(t * 6);
      const ga = ctx.globalAlpha;
      ctx.globalAlpha = pulse;
      ctx.drawImage(glowPurple, -14, -44, 28, 28);
      ctx.globalAlpha = ga;
      ctx.fillStyle = '#35c8ff';
      ctx.beginPath(); ctx.arc(0, -30, 5, 0, TAU); ctx.fill();
      ctx.fillStyle = '#bff0ff';
      ctx.beginPath(); ctx.arc(-1, -31, 2, 0, TAU); ctx.fill();
    } else {
      ctx.fillStyle = 'rgba(40,36,50,0.9)';
      ctx.beginPath(); ctx.arc(0, -30, 5, 0, TAU); ctx.fill();
    }
  }
  ctx.restore();
}
function drawTints() {
  ctx.drawImage(vignette, 0, 0);
  const p = player;
  if (p && p.hurtFlash > 0) {
    const g = ctx.createRadialGradient(640, 360, 240, 640, 360, 700);
    g.addColorStop(0, 'rgba(255,40,40,0)');
    g.addColorStop(1, 'rgba(255,30,30,' + (p.hurtFlash * 0.5) + ')');
    ctx.fillStyle = g; ctx.fillRect(0, 0, DW, DH);
  }
  if (p && p.flameT > 0) {
    const a = 0.10 + 0.05 * Math.sin(game.time * 12);
    const g = ctx.createRadialGradient(640, 360, 300, 640, 360, 720);
    g.addColorStop(0, 'rgba(255,140,40,0)');
    g.addColorStop(1, 'rgba(255,120,30,' + a + ')');
    ctx.fillStyle = g; ctx.fillRect(0, 0, DW, DH);
  }
  if (purpleFlash > 0) {
    ctx.fillStyle = 'rgba(120,50,220,' + (purpleFlash * 0.35) + ')';
    ctx.fillRect(0, 0, DW, DH);
  }
  if (boss && boss.enraged && !boss.dead) {
    const a = 0.05 + 0.03 * Math.sin(game.time * 4);
    const g = ctx.createRadialGradient(640, 360, 320, 640, 360, 720);
    g.addColorStop(0, 'rgba(80,20,140,0)');
    g.addColorStop(1, 'rgba(90,30,170,' + a + ')');
    ctx.fillStyle = g; ctx.fillRect(0, 0, DW, DH);
  }
}
function drawWorld() {
  ctx.drawImage(bgCanvas, 0, 0);
  drawAmbient();
  for (const f of patches) drawPatch(f);
  drawRings();
  drawTelegraphs();
  const list = [];
  for (const pl of pillars) if (pl.alive) list.push({ y: pl.y, f: () => drawPillar(pl) });
  for (const e of enemies) list.push({ y: e.y, f: () => drawEnemy(e) });
  if (boss) list.push({ y: boss.y + 40, f: drawBoss });
  list.push({ y: player.y, f: drawPlayer });
  list.sort((a, b) => a.y - b.y);
  for (const o of list) o.f();
  drawMotes();
  for (const pr of projs) drawProj(pr);
  drawParts();
  drawSlashes();
  drawTexts();
  drawTints();
}

// ---------------- HUD ----------------
const FONT = 'Cairo, Tahoma, sans-serif';
function bar(x, y, w, h, v, c1, c2) {
  v = clamp(v, 0, 1);
  ctx.fillStyle = '#1a1226';
  rr(x, y, w, h, h / 2); ctx.fill();
  if (v > 0.01) {
    const g = ctx.createLinearGradient(x, y, x, y + h);
    g.addColorStop(0, c1); g.addColorStop(1, c2);
    ctx.fillStyle = g;
    rr(x, y, Math.max(h, w * v), h, h / 2); ctx.fill();
  }
  ctx.strokeStyle = 'rgba(255,255,255,0.15)'; ctx.lineWidth = 1;
  rr(x, y, w, h, h / 2); ctx.stroke();
}
function hornIcon(x, y, alive, vuln) {
  ctx.save();
  ctx.translate(x, y);
  if (!alive) {
    ctx.strokeStyle = '#4a4356'; ctx.lineWidth = 5; ctx.lineCap = 'round';
    ctx.beginPath(); ctx.moveTo(0, 4); ctx.lineTo(-4, -4); ctx.stroke();
  } else {
    if (vuln) {
      ctx.globalAlpha = 0.5 + 0.4 * Math.sin(game.time * 16);
      ctx.drawImage(glowOrange, -18, -26, 36, 44);
      ctx.globalAlpha = 1;
    }
    ctx.strokeStyle = vuln ? '#ff8c2f' : '#b9a98a';
    ctx.lineWidth = 5; ctx.lineCap = 'round';
    ctx.beginPath(); ctx.moveTo(0, 6); ctx.quadraticCurveTo(-6, -4, -12, -10); ctx.stroke();
  }
  ctx.restore();
}
function cdIcon(x, y, r, kind, ratio) {
  ratio = clamp(ratio, 0, 1);
  ctx.save();
  ctx.translate(x, y);
  ctx.fillStyle = 'rgba(21,14,32,0.85)';
  ctx.beginPath(); ctx.arc(0, 0, r, 0, TAU); ctx.fill();
  ctx.strokeStyle = ratio > 0 ? 'rgba(139,70,255,0.4)' : 'rgba(245,192,78,0.8)';
  ctx.lineWidth = 2;
  ctx.beginPath(); ctx.arc(0, 0, r, 0, TAU); ctx.stroke();
  if (kind === 'dash') {
    ctx.strokeStyle = ratio > 0 ? '#6a5f80' : '#ffd98a';
    ctx.lineWidth = 3; ctx.lineCap = 'round';
    ctx.beginPath(); ctx.moveTo(-7, -7); ctx.lineTo(-1, 0); ctx.lineTo(-7, 7); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(0, -7); ctx.lineTo(6, 0); ctx.lineTo(0, 7); ctx.stroke();
  } else {
    ctx.fillStyle = ratio > 0 ? '#6a5f80' : '#ffb054';
    ctx.beginPath(); ctx.moveTo(0, -9); ctx.bezierCurveTo(7, -2, 5, 7, 0, 9); ctx.bezierCurveTo(-5, 7, -7, -2, 0, -9); ctx.fill();
    ctx.fillStyle = ratio > 0 ? '#4a4060' : '#fff3c4';
    ctx.beginPath(); ctx.moveTo(0, -3); ctx.bezierCurveTo(3, 1, 2, 5, 0, 6); ctx.bezierCurveTo(-2, 5, -3, 1, 0, -3); ctx.fill();
  }
  if (ratio > 0) {
    ctx.fillStyle = 'rgba(7,5,12,0.65)';
    ctx.beginPath(); ctx.moveTo(0, 0); ctx.arc(0, 0, r, -Math.PI / 2, -Math.PI / 2 + ratio * TAU); ctx.closePath(); ctx.fill();
  }
  ctx.restore();
}
function drawHUD() {
  if (game.state === 'menu' || !player) return;
  const p = player;
  ctx.textBaseline = 'middle';
  const rx = 1252;
  // HP
  ctx.textAlign = 'right';
  ctx.font = '700 12px ' + FONT; ctx.fillStyle = '#b9a8d9';
  ctx.fillText('الصحة', rx, 26);
  bar(rx - 250, 32, 250, 14, p.hp / p.maxHp, '#e23b4e', '#5c1620');
  ctx.font = '800 11px ' + FONT; ctx.fillStyle = '#fff'; ctx.textAlign = 'center';
  ctx.fillText(fmt(Math.max(0, p.hp)), rx - 125, 39);
  // heat
  const hv = p.flameT > 0 ? p.flameT / 6 : p.heat / 100;
  ctx.textAlign = 'right'; ctx.font = '700 12px ' + FONT;
  ctx.fillStyle = p.flameT > 0 ? '#ffd98a' : '#b9a8d9';
  ctx.fillText(p.flameT > 0 ? 'اللهب المتوج!' : 'حرارة اللهب', rx, 58);
  bar(rx - 250, 64, 250, 12, hv, '#ff8c2f', '#4a2410');
  if (hv > 0.97) {
    ctx.strokeStyle = 'rgba(255,255,255,' + (0.4 + 0.3 * Math.sin(game.time * 14)) + ')';
    ctx.lineWidth = 2;
    rr(rx - 250, 64, 250, 12, 6); ctx.stroke();
  }
  // gold
  const gs = 1 + goldPop * 0.5;
  ctx.save(); ctx.translate(rx, 92); ctx.scale(gs, gs);
  ctx.fillStyle = '#f5c04e'; ctx.beginPath(); ctx.arc(0, 0, 8, 0, TAU); ctx.fill();
  ctx.fillStyle = '#b98a2f'; ctx.beginPath(); ctx.arc(0, 0, 5, 0, TAU); ctx.fill();
  ctx.fillStyle = '#fff3c4'; ctx.beginPath(); ctx.arc(-2, -2, 1.8, 0, TAU); ctx.fill();
  ctx.restore();
  ctx.textAlign = 'right'; ctx.font = '800 15px ' + FONT; ctx.fillStyle = '#f5c04e';
  ctx.fillText(fmt(game.gold), rx - 16, 93);
  // spirit shards
  ctx.save(); ctx.translate(rx - 2, 116);
  ctx.fillStyle = '#b18aff';
  ctx.beginPath(); ctx.moveTo(0, -9); ctx.lineTo(6, 0); ctx.lineTo(0, 9); ctx.lineTo(-6, 0); ctx.closePath(); ctx.fill();
  ctx.fillStyle = '#e4d2ff';
  ctx.beginPath(); ctx.moveTo(0, -5); ctx.lineTo(3, 0); ctx.lineTo(0, 5); ctx.closePath(); ctx.fill();
  ctx.restore();
  ctx.font = '800 15px ' + FONT; ctx.fillStyle = '#b18aff';
  ctx.fillText(fmt(game.shards), rx - 16, 117);
  // score + combo (left)
  const ss = 1 + scorePop * 0.4;
  ctx.textAlign = 'left';
  ctx.font = '700 12px ' + FONT; ctx.fillStyle = '#b9a8d9';
  ctx.fillText('النقاط', 24, 26);
  ctx.save(); ctx.translate(24, 52); ctx.scale(ss, ss);
  ctx.font = '900 26px ' + FONT; ctx.fillStyle = '#f5c04e';
  ctx.fillText(fmt(game.score), 0, 0);
  ctx.restore();
  if (p.chain >= 2) {
    const mult = (1 + 0.5 * Math.min(8, p.chain)).toFixed(1);
    const cp = 1 + p.comboPop * 1.2;
    ctx.save(); ctx.translate(24, 86); ctx.scale(cp, cp);
    ctx.font = '900 20px ' + FONT; ctx.fillStyle = '#ff8c2f';
    ctx.fillText('سلسلة ×' + mult, 0, 0);
    ctx.restore();
  }
  // banner
  if (game.bannerT > 0) {
    const tt = game.bannerT;
    const a = clamp(Math.min((3.5 - tt) / 0.3, tt / 0.5), 0, 1);
    const sc = 1 + 0.12 * Math.max(0, (3.5 - tt - 0.25) / 0.25);
    ctx.save();
    ctx.translate(640, 150); ctx.scale(sc, sc); ctx.globalAlpha = a;
    ctx.textAlign = 'center';
    ctx.font = '900 34px ' + FONT;
    ctx.lineWidth = 6; ctx.strokeStyle = 'rgba(10,6,16,0.85)';
    ctx.strokeText(game.bannerTitle, 0, 0);
    ctx.fillStyle = '#f5c04e'; ctx.fillText(game.bannerTitle, 0, 0);
    if (game.bannerSub) {
      ctx.font = '700 16px ' + FONT;
      ctx.lineWidth = 4;
      ctx.strokeText(game.bannerSub, 0, 34);
      ctx.fillStyle = '#cbb8ff'; ctx.fillText(game.bannerSub, 0, 34);
    }
    ctx.restore();
  }
  // tip
  if (game.tipT > 0) {
    ctx.globalAlpha = clamp(game.tipT / 0.5, 0, 1);
    ctx.textAlign = 'center';
    ctx.font = '700 14px ' + FONT;
    ctx.fillStyle = '#ffe9c0';
    ctx.fillText(game.tip, 640, 660);
    ctx.globalAlpha = 1;
  }
  // boss bar
  if (boss && !boss.dead) {
    const w = 600, x = 640 - w / 2, y = 684;
    ctx.textAlign = 'center';
    ctx.font = '800 14px ' + FONT; ctx.fillStyle = '#d9c8ff';
    ctx.fillText('غاروك، آكل السهول' + (boss.enraged ? ' — هائج!' : ''), 640, y - 14);
    ctx.fillStyle = '#1a1226'; rr(x, y, w, 12, 6); ctx.fill();
    ctx.strokeStyle = '#3a2a55'; ctx.lineWidth = 1.5; rr(x, y, w, 12, 6); ctx.stroke();
    const hw = w * clamp(boss.hp / boss.maxHp, 0, 1);
    if (hw > 6) {
      ctx.fillStyle = boss.enraged ? '#c44dff' : '#7b2ff7';
      rr(x, y, Math.max(12, hw), 12, 6); ctx.fill();
    }
    hornIcon(x - 24, y + 6, boss.hornA, boss.hornWindow > 0);
    hornIcon(x + w + 24, y + 6, boss.hornB, boss.hornWindow > 0);
    if (boss.hornWindow > 0) {
      ctx.globalAlpha = 0.5 + 0.4 * Math.sin(game.time * 16);
      ctx.font = '900 15px ' + FONT; ctx.fillStyle = '#ff8c2f';
      ctx.fillText('نافذة الضعف — اضرب!', 640, y - 32);
      ctx.globalAlpha = 1;
    } else if (bossHintT > 0 && game.tipT <= 0) {
      ctx.globalAlpha = clamp(bossHintT / 0.5, 0, 1) * 0.85;
      ctx.font = '700 14px ' + FONT; ctx.fillStyle = '#ffe9c0';
      ctx.fillText('اصطدم غاروك بالأعمدة — اضربه أثناء تألق قرنه البرتقالي', 640, y - 32);
      ctx.globalAlpha = 1;
    }
  }
  // cooldown icons
  cdIcon(40, 640, 19, 'dash', p.dashCd / 1.1);
  cdIcon(82, 640, 19, 'phx', p.phCd / 14);
  ctx.textAlign = 'left';
}
function render() {
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  ctx.fillStyle = '#07050c';
  ctx.fillRect(0, 0, cssW, cssH);
  const [sx, sy] = shakeOff();
  ctx.save();
  ctx.translate(ox + sx * scale, oy + sy * scale);
  ctx.scale(scale, scale);
  ctx.beginPath(); ctx.rect(-4, -4, DW + 8, DH + 8); ctx.clip();
  drawWorld();
  ctx.restore();
  ctx.save();
  ctx.translate(ox, oy);
  ctx.scale(scale, scale);
  drawHUD();
  ctx.restore();
}

// ---------------- state machine / overlays ----------------
function setOverlay(name) {
  for (const id of ['ov-start', 'ov-pause', 'ov-over', 'ov-win'])
    $(id).classList.toggle('hidden', id !== name);
  $('pause-btn').classList.toggle('hidden', !(game.state === 'play' || game.state === 'pause'));
  if (isTouch) $('touch').classList.toggle('on', game.state === 'play' || game.state === 'pause');
}
function toMenu() {
  resetRun();
  game.state = 'menu';
  renderStart();
  setOverlay('ov-start');
  SFX.ui();
}
function startRun() {
  SFX.ensure();
  resetRun();
  game.state = 'play';
  setOverlay(null);
  startWave(0);
}
function togglePause() {
  if (game.state === 'play') { game.state = 'pause'; setOverlay('ov-pause'); SFX.ui(); }
  else if (game.state === 'pause') { game.state = 'play'; setOverlay(null); SFX.ui(); }
}
function endRun() {
  if (game.scored) return;
  game.scored = true;
  const list = loadScores();
  const entry = { s: game.score, st: game.state === 'win' ? game.stars : 0, w: game.wave, d: new Date().toLocaleDateString('ar-EG') };
  list.push(entry);
  list.sort((a, b) => b.s - a.s);
  const top = list.slice(0, 5);
  saveScores(top);
  game.inTop5 = top.includes(entry);
  if (game.state === 'win' && entry.s > 0) $('win-new').classList.toggle('show', game.inTop5);
}
function fillOver() {
  $('over-score').textContent = fmt(game.score);
  $('over-wave').textContent = game.wave >= WAVES.length ? 'مواجهة غاروك' : ('الموجة ' + (game.wave + 1));
  const top = loadScores()[0];
  $('over-best').textContent = fmt(top ? top.s : 0);
  $('over-saved').innerHTML = 'أُنقذت نصف غنائمك: <b>' + fmt(game.savedGold) + ' ذهب</b> (تُضاف إلى المخزن)';
}
function fillWin() {
  $('win-score').textContent = fmt(game.score);
  const list = loadScores();
  $('win-best').textContent = fmt(list.length ? list[0].s : 0);
  const stars = $('win-stars').children;
  for (let i = 0; i < 3; i++) if (stars[i]) stars[i].classList.toggle('lit', i < game.stars);
  const rows = [];
  rows.push('<div class="rw">+' + fmt(game.gold) + ' ذهب</div>');
  rows.push('<div class="rw shard">+' + game.shards + ' شظايا روح</div>');
  if (game.newWeapon) rows.push('<div class="rw new">سلاح جديد: ناب السهل!</div>');
  $('win-rewards').innerHTML = rows.join('');
}
function renderStart() {
  const list = loadScores();
  const el = $('hs-list');
  if (!list.length) {
    el.innerHTML = '<div class="hs-empty">لا نتائج بعد — كن أول من يواجه غاروك.</div>';
  } else {
    el.innerHTML = list.map((s, i) =>
      '<div class="hs-row"><span class="rank">' + (i + 1) + '</span><span class="s">' + fmt(s.s) + '</span>' +
      '<span class="st">' + '★'.repeat(s.st || 0) + '☆'.repeat(3 - (s.st || 0)) + '</span>' +
      '<span>' + (s.w >= WAVES.length ? 'غاروك' : 'موجة ' + (s.w + 1)) + '</span>' +
      '<span class="d">' + (s.d || '') + '</span></div>'
    ).join('');
  }
  const b = bank;
  $('bank-line').innerHTML = (b.gold > 0 || b.shards > 0 || b.weapon)
    ? 'المخزن: <b>' + fmt(b.gold) + ' ذهب</b> · <span class="shard">' + b.shards + ' شظية</span>' + (b.weapon ? ' · <b>ناب السهل</b> ✓' : '')
    : '';
}
function setMute(m) { const el = $('mute-label'); if (el) el.textContent = m ? 'مكتوم' : 'مفعّل'; }

// DOM wiring
$('btn-start').addEventListener('click', () => { SFX.ensure(); startRun(); });
$('btn-resume').addEventListener('click', () => togglePause());
$('btn-restart-p').addEventListener('click', () => startRun());
$('btn-menu-p').addEventListener('click', () => toMenu());
$('btn-mute').addEventListener('click', () => setMute(SFX.toggle()));
$('btn-restart').addEventListener('click', () => startRun());
$('btn-menu-o').addEventListener('click', () => toMenu());
$('btn-again').addEventListener('click', () => startRun());
$('btn-menu-w').addEventListener('click', () => toMenu());
$('pause-btn').addEventListener('click', () => togglePause());
document.addEventListener('visibilitychange', () => { if (document.hidden && game.state === 'play') togglePause(); });

// ---------------- main loop ----------------
let last = performance.now(), acc = 0;
const STEP = 1 / 60;
function frame(now) {
  requestAnimationFrame(frame);
  let dt = (now - last) / 1000;
  last = now;
  if (dt > 0.1) dt = 0.1;
  if (hitstopT > 0) hitstopT -= dt;
  else {
    acc += dt;
    let n = 0;
    while (acc >= STEP && n < 5) { update(STEP); acc -= STEP; n++; }
    if (n === 5) acc = 0;
  }
  render();
}

// ---------------- debug / test hook ----------------
window.__debug = {
  startRun, toMenu, togglePause,
  get state() { return game.state; },
  get score() { return game.score; },
  get gold() { return game.gold; },
  get hp() { return player ? player.hp : 0; },
  setHP: v => { if (player) { player.hp = clamp(v, 1, player.maxHp); player.state = 'alive'; } },
  clearIframes: () => { if (player) player.iframes = 0; },
  input,
  spawn: (k, n = 1) => { for (let i = 0; i < n; i++) spawnEnemy(k); },
  killNearest: () => {
    let best = null, bd = 1e9;
    for (const e of enemies) {
      if (e.dead || e.state === 'dying' || e.state === 'rising') continue;
      const d = dist(e.x, e.y, player.x, player.y);
      if (d < bd) { bd = d; best = e; }
    }
    if (!best) return;
    if (best.kind === 'knight' && !best.coreDead) { best.coreDead = true; best.coreHp = 0; }
    hitEnemy(best, 99999, true);
  },
  hurtPlayer,
  startBoss,
  setBossHP: v => { if (boss) boss.hp = v; },
  nearBoss: () => { if (boss) { player.x = clamp(boss.x - 120, 100, 1180); player.y = boss.y; player.iframes = 0; } },
  get boss() { return boss; },
  get enemies() { return enemies; },
  get pending() { return game.pending.length; },
  get pillars() { return pillars; },
  get arenaT() { return arenaT; },
  get patches() { return patches; },
  get px() { return player ? player.x : 0; },
  get py() { return player ? player.y : 0; },
  setBossPos: (x, y) => { if (boss) { boss.x = x; boss.y = y; } },
  scores: loadScores,
  get bank() { return bank; },
};

// ---------------- boot ----------------
buildStatic();
initAmbient();
resetRun();
game.state = 'menu';
renderStart();
setOverlay('ov-start');
setMute(SFX.muted);
requestAnimationFrame(frame);
