'use strict';
/* ============================================================
   smoke.js — اختبار دخان عبر Node: يشغّل اللعبة بلا متصفح
   (DOM/Canvas محاكاة) ثم يدفع أطرًا ويختبر الحالات الحدّية.
   التشغيل: node smoke.js
   ============================================================ */
const fs = require('fs'), path = require('path');
const code = fs.readFileSync(path.join(__dirname, 'game.js'), 'utf8');

// ---- fake canvas 2d context (Proxy: every method no-ops) ----
function makeCtx() {
  const target = {};
  return new Proxy(target, {
    get(t, p) {
      if (p === 'canvas') return { width: 1280, height: 720 };
      if (p === 'measureText') return () => ({ width: 10 });
      if (p === 'createLinearGradient' || p === 'createRadialGradient')
        return () => ({ addColorStop() {} });
      if (p === 'createImageData')
        return (w, h) => ({ data: new Uint8ClampedArray(w * h * 4), width: w, height: h });
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
    id, style: {}, children: [], _handlers: {},
    classList: {
      _s: new Set(),
      add(c) { this._s.add(c); },
      remove(c) { this._s.delete(c); },
      toggle(c, f) { f ? this._s.add(c) : this._s.delete(c); },
      contains(c) { return this._s.has(c); },
    },
    addEventListener(ev, fn) { (this._handlers[ev] = this._handlers[ev] || []).push(fn); },
    removeEventListener() {}, setAttribute() {},
    appendChild(c) { this.children.push(c); return c; }, removeChild() {},
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
global.addEventListener = () => {};
global.removeEventListener = () => {};
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
  createElement(tag) {
    const el = makeEl(tag === 'canvas' ? 'cv' + Math.random() : 'div');
    if (tag === 'canvas') el.getContext = () => makeCtx();
    return el;
  },
  addEventListener() {}, removeEventListener() {},
  hidden: false,
};
global.matchMedia = () => ({ matches: false });

// ---- load game ----
(0, eval)(code);
const D = global.__debug;

function pump(frames) {
  for (let i = 0; i < frames; i++) {
    nowMs += 16.7;
    const cb = rafCb; rafCb = null;
    if (cb) cb(nowMs);
  }
}
let pass = 0, fail = 0;
function check(name, cond) {
  if (cond) { pass++; console.log('  ok   - ' + name); }
  else { fail++; console.log('  FAIL - ' + name); }
}

console.log('smoke: boot');
check('debug handle exists', !!D);
check('initial state = menu', D.state === 'menu');
pump(12);

console.log('smoke: start run');
D.startRun();
pump(30);
check('state = play after start', D.state === 'play');
pump(60);
check('wave 1 spawned enemies', D.enemies.length >= 1);

console.log('smoke: all enemy kinds spawn & die');
for (const k of ['outcast', 'wolf', 'thrower', 'guard', 'beetle', 'knight']) D.spawn(k, 1);
check('6 extra kinds on field', D.enemies.length >= 6);
let guard = 0;
while (guard++ < 600) {
  if (D.enemies.length === 0 && D.pending === 0) break; // wave 1 fully cleared
  D.setHP(100); // keep the dummy player alive (simulates dodging)
  D.killNearest();
  pump(5); // let hit-stop + corpse filter settle
}
pump(60);
check('field cleared (incl. knight core-kill)', D.enemies.length === 0);
check('score > 0', D.score > 0);
check('gold motes converted to gold', D.gold > 0);

console.log('smoke: damage & i-frames');
pump(20); // let any i-frames from combat expire (no enemies left)
const hpBefore = D.hp;
D.hurtPlayer(20, 640, 360);
pump(2);
const hpAfter1 = D.hp;
D.hurtPlayer(20, 640, 360);
pump(2);
const hpAfter2 = D.hp;
check('first hit lands', hpAfter1 < hpBefore);
check('i-frames block second hit', hpAfter2 === hpAfter1);

console.log('smoke: death -> game over -> save');
D.setHP(1);
D.clearIframes();
D.hurtPlayer(999, 640, 360);
pump(150);
check('state = over after death', D.state === 'over');
check('high score saved', D.scores().length >= 1);
check('half gold banked', D.bank.gold > 0);

console.log('smoke: instant restart');
D.startRun();
pump(10);
check('restart returns to play', D.state === 'play');

console.log('smoke: pause / resume');
D.togglePause();
pump(5);
check('state = pause', D.state === 'pause');
D.togglePause();
pump(5);
check('state = play after resume', D.state === 'play');

console.log('smoke: boss fight -> victory');
D.startBoss();
pump(120);
check('boss exists and alive', !!D.boss && !D.boss.dead);
D.nearBoss();
D.setBossHP(1);
D.input.attackHeld = true;
for (let i = 0; i < 8 && D.state === 'play'; i++) { D.setHP(100); pump(30); }
D.input.attackHeld = false;
check('boss defeated -> state win', D.state === 'win');
check('victory stars assigned (1-3)', D.scores().length >= 2);
check('bank weapon unlocked', D.bank.weapon === true);
check('shards banked', D.bank.shards >= 3);

console.log('smoke: menu round-trip');
D.toMenu();
pump(5);
check('back to menu', D.state === 'menu');

console.log('smoke: skill tree (GDD §7)');
D.bank.shards = 10;
check('unlock fire node 1 (spark)', D.unlock('spark') === true);
check('spark registered', D.has('spark'));
check('cost deducted (10 -> 9)', D.bank.shards === 9);
check('unlock ash node 1 (skin)', D.unlock('skin') === true);
check('cannot skip: blade node 2 blocked', D.unlock('edge') === false);
check('can unlock blade node 1', D.unlock('step') === true);
D.startRun();
pump(10);
check('skin raises max HP to 125', D.maxHp === 125);
check('spark/heart burn fields exist on enemies', (() => { D.spawn('outcast', 1); const e = D.enemies.find(x => x.kind === 'outcast'); return e && typeof e.burn === 'number' && typeof e.slowT === 'number'; })());
check('skills persisted in store', D.skills.unlocked.includes('spark') && D.skills.unlocked.includes('skin') && D.skills.unlocked.includes('step'));
D.toMenu();
pump(5);

console.log('\n' + pass + ' passed, ' + fail + ' failed');
process.exit(fail ? 1 : 0);
