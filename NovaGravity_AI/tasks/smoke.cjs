/* Standalone smoke test for the dashboard (fake DOM) - run: node tasks/smoke.js */
const fs = require("fs"), vm = require("vm");
const html = fs.readFileSync(__dirname + "/../Dashboard/novagravity_dashboard.html", "utf8");
const js = html.substring(html.indexOf("<script>") + 8, html.lastIndexOf("</script>"));

function ctxProxy() {
  return new Proxy({}, {
    get(o, k) {
      if (k === "canvas") return { width: 800, height: 400 };
      if (typeof k === "symbol") return undefined;
      if (k in o) return o[k];
      return (...a) => {};
    },
    set(o, k, v) { o[k] = v; return true; }
  });
}
function el(tag) {
  return {
    tag, children: [], style: {}, dataset: {}, value: "", textContent: "", className: "", innerHTML: "",
    width: 0, height: 0, checked: false, disabled: false, files: [],
    appendChild() {}, querySelector() { return el("div"); }, querySelectorAll() { return []; },
    addEventListener() {}, removeEventListener() {}, setAttribute() {}, getAttribute() { return null; },
    getContext() { return ctxProxy(); },
    getBoundingClientRect() { return { width: 800, height: 430, left: 0, top: 0 }; },
    click() {}, focus() {}, toBlob(cb) { cb && cb(Buffer.from("x")); },
    set onclick(f) {}, set onmousemove(f) {}, set onmouseleave(f) {}, set onchange(f) {},
    set oninput(f) {}, set ondragover(f) {}, set ondragleave(f) {}, set ondrop(f) {}
  };
}
const ids = {};
const doc = {
  getElementById(id) { if (!ids[id]) ids[id] = el("div"); return ids[id]; },
  createElement(t) { return el(t); },
  querySelector() { return el("div"); },
  querySelectorAll() { return []; },
  body: el("body")
};
const store = {};
const context = {
  console, Math, JSON, Date, Object, Array, String, Number, parseInt, parseFloat, isNaN,
  alert: () => {}, confirm: () => false, setTimeout, clearTimeout, setInterval: () => 0, clearInterval,
  requestAnimationFrame: () => 0, cancelAnimationFrame: () => {},
  Blob: function () {}, URL: { createObjectURL: () => "", revokeObjectURL: () => {} },
  localStorage: { getItem: k => store[k] || null, setItem: (k, v) => store[k] = v, removeItem: k => delete store[k] },
  document: doc, window: { addEventListener() {}, innerWidth: 1200, innerHeight: 800, devicePixelRatio: 1 },
  addEventListener() {}, devicePixelRatio: 1, innerWidth: 1200, innerHeight: 800,
  FileReader: function () {},
  fetch: async () => ({ ok: false, status: 0, json: async () => ({}) }),
  DOMParser: function () { return { parseFromString: () => ({ querySelectorAll: () => [], body: { innerText: "" } }) }; },
  performance: { now: () => 0 }
};
context.globalThis = context;
vm.createContext(context);
try {
  vm.runInContext(js, context, { timeout: 20000 });
  console.log("BOOT: no exceptions");
  vm.runInContext("for(let i=0;i<400;i++)step();", context, { timeout: 60000 });
  console.log("STEP x400 OK — sim trades:", vm.runInContext("Object.values(market).reduce((s,st)=>s+st.trades.length,0)", context));

  // inject 80-trade report and run new analytics
  vm.runInContext(`REPORTS.length=0; (()=>{const rows=[];const t0=Date.parse('2025-08-01T00:00:00Z');
    for(let i=0;i<80;i++){rows.push({sym:'XAUUSD',tf:'H1',dir:i%2?'buy':'sell',open:2600+i,close:2600+i+(i%5<3?1:-1)*8,
      openTime:t0+i*86400000,closeTime:t0+i*86400000+86400000,size:0.1,commission:0,swap:0,
      profit:(i%5<3?1:-1)*(8+(i%3)*3),openSlippage:1,closeSlippage:1});}
    const r={name:'XAUUSD H1 TEST',symbol:'XAUUSD',period:'H1',rows};finalizeReport(r);REPORTS.push(r);})()`,
    context);
  const m = vm.runInContext(`(()=>{const r=REPORTS[0];const em=extraMetrics(r);const of=overfitCheck(r);
    runMonteCarlo();
    return {sortino:em.sortino.toFixed(2),kellyPct:(em.kelly*100).toFixed(1),maxConsec:em.maxConsec,
      ofCls:of?of.cls:'none',ofPfA:of?of.A.pf.toFixed(2):'',ofPfB:of?of.B.pf.toFixed(2):'',
      mcMed:mcCache.med.toFixed(0),dd95:mcCache.dd95.toFixed(1),ruin:mcCache.ruin.toFixed(2)};})()`, context);
  console.log("ANALYTICS TEST:", JSON.stringify(m));

  // parser test with realistic MT5-style HTML
  const rep = vm.runInContext(`
    (()=>{const html='<html><body><table><tr><td>Total Net Profit</td><td>1 234.50</td></tr></table>'+
    '<table><tr><th>Ticket</th><th>Open Time</th><th>Type</th><th>Size</th><th>Item</th><th>Price</th><th>S</th><th>Close Time</th><th>Price</th><th>S</th><th>Commission</th><th>Swap</th><th>Profit</th><th>Balance</th></tr>'+
    '<tr><td>1</td><td>2025.08.25 12:30</td><td>buy</td><td>0.10</td><td>XAUUSD</td><td>2651.20</td><td>1</td><td>2025.08.26 09:10</td><td>2669.50</td><td>2</td><td>0.00</td><td>0.15</td><td>182.30</td><td>10182.30</td></tr></table></body></html>';
    const r=parseReportHTML(html,'test.html');
    return {n:r.rows.length,pf:r.pf,o1:r.rows[0].open,c1:r.rows[0].close,s1:r.rows[0].openSlippage};})()`, context);
  console.log("PARSER TEST:", JSON.stringify(rep));
  process.exit(0);
} catch (e) {
  console.log("ERROR:", e.message);
  console.log((e.stack || "").split("\n").slice(0, 5).join("\n"));
  process.exit(1);
}
