'use strict';
/* ============================================================
   fullrun.cjs — محاكاة لعب كاملة (headless) للفصل الأول:
   4 موجات → غاروك → اصطدام عمود → كسر القرنين → الهياج → النصر.
   التشغيل: node fullrun.cjs
   ============================================================ */
const fs = require('fs');
const code = fs.readFileSync('/home/user/opencode-antigravity-auth/game/game.js', 'utf8');

// ---- same headless DOM/canvas stubs as smoke.cjs ----
function makeCtx() {
  const t = {};
  return new Proxy(t, {
    get(t, p) {
      if (p === 'canvas') return { width: 1280, height: 720 };
      if (p === 'createLinearGradient' || p === 'createRadialGradient') return () => ({ addColorStop() {} });
      if (p in t) return t[p];
      return () => undefined;
    },
    set(t, p, v) { t[p] = v; return true; },
  });
}
const mainCtx = makeCtx();
const elCache = {};
function makeEl(id) {
  const el = {
    id, style: {}, children: [],
    classList: { _s: new Set(), add(c) { this._s.add(c); }, remove(c) { this._s.delete(c); }, toggle(c, f) { f ? this._s.add(c) : this._s.delete(c); }, contains(c) { return this._s.has(c); } },
    addEventListener() {}, removeEventListener() {}, setAttribute() {},
    appendChild(c) { return c; }, removeChild() {},
    textContent: '', innerHTML: '',
    querySelector() { return makeEl('q'); },
    getBoundingClientRect() { return { left: 0, top: 0, width: 1280, height: 720 }; },
  };
  if (id === 'game') { el.width = 0; el.height = 0; el.getContext = () => mainCtx; }
  return el;
}
const getEl = id => elCache[id] || (elCache[id] = makeEl(id));
let nowMs = 0, rafCb = null;
global.window = global;
global.innerWidth = 1280; global.innerHeight = 720; global.devicePixelRatio = 1;
global.addEventListener = () => {}; global.removeEventListener = () => {};
global.performance = { now: () => nowMs };
global.requestAnimationFrame = cb => { rafCb = cb; return 1; };
global.localStorage = {
  _d: {},
  getItem(k) { return k in this._d ? this._d[k] : null; },
  setItem(k, v) { this._d[k] = String(v); },
  removeItem(k) { delete this._d[k]; },
};
global.document = {
  getElementById: getEl,
  createElement(tag) { const el = makeEl(tag === 'canvas' ? 'cv' + Math.random() : 'div'); if (tag === 'canvas') el.getContext = () => makeCtx(); return el; },
  addEventListener() {}, removeEventListener() {},
  hidden: false,
};
global.matchMedia = () => ({ matches: false });

(0, eval)(code);
const D = global.__debug;

function pump(f) { for (let i = 0; i < f; i++) { nowMs += 16.7; const cb = rafCb; rafCb = null; if (cb) cb(nowMs); } }
function keepAlive() { D.setHP(100); D.clearIframes(); }
let pass = 0, fail = 0;
function check(name, cond) { if (cond) { pass++; console.log('  ok   - ' + name); } else { fail++; console.log('  FAIL - ' + name); } }

console.log('fullrun: waves 1-4');
D.startRun();
pump(30);
for (let w = 0; w < 4; w++) {
  let guard = 0;
  while (guard++ < 900) {
    if (D.enemies.length === 0 && D.pending === 0 && !D.boss) break;
    keepAlive();
    D.killNearest();
    pump(5);
  }
  for (let i = 0; i < 18; i++) { keepAlive(); pump(10); } // wait for next wave / boss intro
}
check('boss engaged after 4 waves', !!D.boss);
pump(150);
check('boss entered arena', D.boss && D.boss.state !== 'enter');

function pickLivePillar(minX) {
  const alive = D.pillars.filter(p => p.alive && p.x >= minX);
  if (!alive.length) return null;
  return alive.sort((a, b) => Math.abs(a.x - 640) - Math.abs(b.x - 640))[0]; // most central first
}

console.log('fullrun: forced pillar impact -> horn window');
{
  const b = D.boss;
  const pl = pickLivePillar(500) || pickLivePillar(0);
  const hpBefore = pl.hp;
  D.setBossPos(pl.x - 250, pl.y);
  b.state = 'charge_tg'; b.t = 0.7; b.chargeAng = 0; // charge east into the pillar
  let hit = false;
  for (let i = 0; i < 90 && !hit; i++) { keepAlive(); pump(5); hit = pl.hp < hpBefore || !pl.alive; }
  check('pillar took damage from boss charge', hit);
  check('horn window opened by impact flare', b.hornWindow > 0);
}

function attackDuringWindow() {
  const b = D.boss;
  let guard = 0;
  while (guard++ < 400 && b.hornWindow > 0) {
    keepAlive();
    const dx = b.x - D.px, dy = b.y - D.py, d = Math.hypot(dx, dy) || 1;
    D.input.mx = d > 110 ? dx / d : 0;
    D.input.my = d > 110 ? dy / d : 0;
    D.input.attackHeld = true;
    pump(4);
  }
  D.input.attackHeld = false;
  D.input.mx = 0; D.input.my = 0;
}

console.log('fullrun: break horn A');
{
  const b = D.boss;
  if (b.hornWindow <= 0) { // safety: trigger a flare if window already closed
    b.hornWindow = 3; b.windowDmg = 0;
  }
  attackDuringWindow();
  check('horn A broken', b.hornA === false);
  check('stun + core exposure after break', b.coreExp > 0 || b.stunT > 0 || b.hornB === false);
  pump(60);
}

console.log('fullrun: forced second impact -> horn B -> enrage');
{
  const b = D.boss;
  const pl = D.pillars.filter(p => p.alive).sort((a, c) => Math.abs(a.x - 640) - Math.abs(c.x - 640))[0];
  const hpBefore = pl ? pl.hp : 0;
  if (pl) {
    D.setBossPos(pl.x + 250, pl.y);
    b.state = 'charge_tg'; b.t = 0.7; b.chargeAng = Math.PI; // charge west into the pillar
    for (let i = 0; i < 90 && !(pl.hp < hpBefore || !pl.alive); i++) { keepAlive(); pump(5); }
  }
  if (b.hornWindow > 0) attackDuringWindow();
  else {
    // if no live pillar remained (all shattered by the boss), use a fresh flare
    // to verify the break pipeline (flare->window->break->enrage)
    if (b.hornB) { b.hornWindow = 3; b.windowDmg = 0; attackDuringWindow(); }
  }
  check('horn B broken', b.hornB === false);
  check('enraged after both horns', b.enraged === true);
}

console.log('fullrun: enrage effects (arena shrink + fire patches)');
for (let i = 0; i < 60; i++) { keepAlive(); pump(10); }
check('arena shrinking started', D.arenaT > 0);
check('fire patches spawning', D.patches.length > 0);

console.log('fullrun: finish boss -> victory');
D.setBossHP(1);
let guard = 0;
while (guard++ < 300 && D.state === 'play') {
  keepAlive();
  const b = D.boss;
  if (b && !b.dead) {
    const dx = b.x - D.px, dy = b.y - D.py, d = Math.hypot(dx, dy) || 1;
    D.input.mx = d > 110 ? dx / d : 0;
    D.input.my = d > 110 ? dy / d : 0;
  }
  D.input.attackHeld = true;
  pump(5);
}
D.input.attackHeld = false;
check('boss defeated -> win', D.state === 'win');
check('victory score > 0', D.score > 0);

console.log('\n' + pass + ' passed, ' + fail + ' failed');
process.exit(fail ? 1 : 0);
