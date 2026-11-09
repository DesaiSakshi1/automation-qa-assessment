// Headless UI walk-through of every core flow + UI-level edge cases.
// Writes screenshots and a JSON log to ../evidence. Target: local app only.
//   node task1-qa-report/scripts/ui-flows.mjs
import { chromium } from 'playwright';
import AxeBuilder from '@axe-core/playwright';
import { writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const WEB = process.env.WEB || 'http://localhost:8080';
const EV = fileURLToPath(new URL('../evidence/', import.meta.url));
const id = Date.now().toString(36);
const log = { date: new Date().toISOString(), web: WEB, steps: [] };
const step = (name, data = {}) => { log.steps.push({ name, ...data }); console.log('✔', name, JSON.stringify(data)); };
const shot = (page, f) => page.screenshot({ path: EV + f, fullPage: true });

const browser = await chromium.launch();
log.browser = `Chromium ${browser.version()}`;
const ctx = await browser.newContext({ viewport: { width: 1280, height: 800 } });
const page = await ctx.newPage();
const consoleMsgs = [];
page.on('console', (m) => consoleMsgs.push(`${m.type()}: ${m.text()}`));
page.on('dialog', (d) => { consoleMsgs.push(`DIALOG: ${d.message()}`); d.accept(); });

// --- Sign up
await page.goto(`${WEB}/register`);
await page.getByPlaceholder('Username').fill(`ui_${id}`);
await page.getByPlaceholder('Email').fill(`ui_${id}@qa.localhost`);
await page.getByPlaceholder('Password').fill('Passw0rd!123');
await page.getByRole('button', { name: /sign up/i }).click();
await page.waitForURL(`${WEB}/`);
const token = await page.evaluate(() => localStorage.getItem('jwtToken'));
step('sign-up', { tokenInLocalStorage: !!token, cookies: (await ctx.cookies()).length });

// --- Create article with an XSS probe in the body (harmless console.log)
await page.goto(`${WEB}/editor`);
await page.getByPlaceholder('Article Title').fill(`UI article ${id}`);
await page.getByPlaceholder("What's this article about?").fill('desc');
await page.getByPlaceholder('Write your article (in markdown)').fill(
  '# Hello\n\n<img src=x onerror="console.log(\'XSS-FIRED-body\')">\n\n[click](javascript:console.log(\'XSS-FIRED-link\'))');
await page.getByPlaceholder('Enter tags').fill('uitag');
await page.keyboard.press('Enter');
await page.getByRole('button', { name: /publish/i }).click();
await page.waitForURL(/\/article\//);
await page.waitForTimeout(800);
const articleUrl = page.url();
const linkHref = await page.locator('.article-content a').first().getAttribute('href').catch(() => null);
step('create article', { url: articleUrl, xssFired: consoleMsgs.some((m) => m.includes('XSS-FIRED')), sanitizedLinkHref: linkHref });
await shot(page, 'ui-article-created.png');

// --- Edit article
await page.getByRole('link', { name: /edit article/i }).first().click();
await page.getByPlaceholder('Write your article (in markdown)').fill('Edited body');
await page.getByRole('button', { name: /publish/i }).click();
await page.waitForURL(/\/article\//);
step('edit article', { tagsAfterEdit: await page.locator('.tag-list li').allInnerTexts() });

// --- Comment: double-click "Post Comment"
await page.getByPlaceholder('Write a comment...').fill(`double click ${id}`);
await page.getByRole('button', { name: 'Post Comment' }).dblclick();
await page.waitForTimeout(1500);
await page.reload(); await page.waitForTimeout(1000);
const dupes = await page.locator('.card .card-text', { hasText: `double click ${id}` }).count();
step('comment double-click', { commentsCreated: dupes });
await shot(page, 'ui-double-comment.png');

// --- Favorite (authors get no favorite button on their own article page; use the heart in the home list)
await page.goto(WEB); await page.waitForTimeout(1000);
const favBtn = page.locator('.article-preview button').first();
const before = (await favBtn.innerText()).trim();
await favBtn.click(); await page.waitForTimeout(800);
step('favorite', { countBefore: before, countAfter: (await favBtn.innerText()).trim() });

// --- Accessibility (axe) on main pages
const a11y = {};
for (const [name, url] of [['home', '/'], ['article', new URL(articleUrl).pathname], ['editor', '/editor'], ['settings', '/settings']]) {
  await page.goto(WEB + url); await page.waitForTimeout(800);
  const r = await new AxeBuilder({ page }).analyze();
  a11y[name] = r.violations.map((v) => ({ id: v.id, impact: v.impact, nodes: v.nodes.length, help: v.help }));
}
writeFileSync(EV + 'axe-results.json', JSON.stringify(a11y, null, 2));
step('axe', Object.fromEntries(Object.entries(a11y).map(([k, v]) => [k, v.map((x) => `${x.id}(${x.impact},${x.nodes})`)])));

// --- Keyboard: does Tab show a visible focus indicator on the editor's first field?
await page.goto(`${WEB}/editor`); await page.waitForTimeout(500);
await page.keyboard.press('Tab');
const focused = await page.evaluate(() => { const e = document.activeElement; const s = getComputedStyle(e); return { tag: e.tagName, text: e.innerText?.slice(0, 30), outline: s.outlineStyle + ' ' + s.outlineWidth }; });
step('keyboard first tab stop', focused);

// --- Log out, then reuse the old token directly against the API
await page.goto(`${WEB}/settings`);
await page.getByRole('button', { name: /logout/i }).click();
await page.waitForTimeout(800);
const after = await page.evaluate(() => localStorage.getItem('jwtToken'));
const reuse = await page.evaluate(async (t) => (await fetch('http://localhost:3000/api/user', { headers: { Authorization: `Token ${t}` } })).status, token);
step('logout', { tokenStillInStorage: !!after, oldTokenApiStatus: reuse });
await shot(page, 'ui-after-logout.png');

// --- Two tabs: log out in tab 1, tab 2 still acts as logged in
const ctx2 = await browser.newContext();
const t1 = await ctx2.newPage(); const t2 = await ctx2.newPage();
await t1.goto(`${WEB}/login`);
await t1.getByPlaceholder('Email').fill(`ui_${id}@qa.localhost`);
await t1.getByPlaceholder('Password').fill('Passw0rd!123');
await t1.getByRole('button', { name: /sign in/i }).click(); await t1.waitForURL(`${WEB}/`);
await t2.goto(`${WEB}/editor`); await t2.waitForTimeout(500);
await t1.goto(`${WEB}/settings`); await t1.getByRole('button', { name: /logout/i }).click(); await t1.waitForTimeout(500);
await t2.getByPlaceholder('Article Title').fill(`tab2 ${id}`);
await t2.getByPlaceholder("What's this article about?").fill('d');
await t2.getByPlaceholder('Write your article (in markdown)').fill('b');
await t2.getByRole('button', { name: /publish/i }).click(); await t2.waitForTimeout(1500);
step('logout in tab 1, publish in tab 2', { tab2Url: t2.url(), tab2Header: (await t2.locator('nav').innerText()).replace(/\s+/g, ' ') });
await t2.screenshot({ path: EV + 'ui-two-tabs.png' });
await ctx2.close();

// --- API down: block all API calls and load the home page
const ctx3 = await browser.newContext();
const p3 = await ctx3.newPage();
await p3.route('http://localhost:3000/**', (r) => r.abort('connectionrefused'));
await p3.goto(WEB); await p3.waitForTimeout(2500);
step('API down', { visibleText: (await p3.locator('body').innerText()).replace(/\s+/g, ' ').slice(0, 300) });
await p3.screenshot({ path: EV + 'ui-api-down.png', fullPage: true });

// --- Slow 3G: time to first article preview on home
const p4 = await ctx3.newPage();
const cdp = await ctx3.newCDPSession(p4);
await cdp.send('Network.emulateNetworkConditions', { offline: false, latency: 400, downloadThroughput: 50000, uploadThroughput: 50000 });
const t0 = Date.now();
await p4.goto(WEB, { waitUntil: 'load', timeout: 120000 });
const loadMs = Date.now() - t0;
await p4.waitForTimeout(3000);
step('slow 3G home', { loadEventMs: loadMs, text: (await p4.locator('body').innerText()).replace(/\s+/g, ' ').slice(0, 160) });
await p4.screenshot({ path: EV + 'ui-slow3g.png' });

log.console = consoleMsgs;
writeFileSync(EV + 'ui-flows-log.json', JSON.stringify(log, null, 2));
await browser.close();
