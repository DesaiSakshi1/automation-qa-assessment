// What a real user sees when the API fails in the two ways found by curl:
//  (a) Settings: change email to one that is already taken  -> API 500 (raw Prisma text)
//  (b) Logged out in another tab, then press Publish          -> API 401
//   node task1-qa-report/scripts/bug-ui-misleading-errors.mjs
import { chromium } from 'playwright';
import { writeFileSync } from 'node:fs';
const WEB = 'http://localhost:8080', API = 'http://localhost:3000/api';
const EV = new URL('../evidence/', import.meta.url);
const reg = async (u) => (await fetch(`${API}/users`, { method: 'POST', headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ user: { username: u, email: `${u}@qa.localhost`, password: 'Passw0rd!123' } }) }).then((r) => r.json())).user;
const id = Date.now(); const me = await reg(`ivy${id}`); const other = await reg(`jay${id}`);
const out = [`# ${new Date().toISOString()}`];
const b = await chromium.launch(); const p = await (await b.newContext()).newPage();
p.on('response', (r) => r.url().startsWith(API) && r.request().method() !== 'GET' && out.push(`API ${r.request().method()} ${r.url()} -> ${r.status()}`));
await p.goto(WEB); await p.evaluate((t) => localStorage.setItem('jwtToken', t), me.token);

// (a)
await p.goto(`${WEB}/settings`); await p.waitForTimeout(800);
await p.getByPlaceholder('Email').fill(other.email);
await p.getByRole('button', { name: /update settings/i }).click(); await p.waitForTimeout(1500);
out.push(`(a) UI shows: "${await p.locator('.error-messages').innerText().catch(() => '<nothing>')}"  url=${p.url()}`);
await p.screenshot({ path: new URL('ui-email-taken.png', EV).pathname.slice(1) });

// (b)
await p.goto(`${WEB}/editor`); await p.waitForTimeout(500);
await p.evaluate(() => localStorage.removeItem('jwtToken')); // exactly what "Log out" in another tab does
await p.getByPlaceholder('Article Title').fill('x'); await p.getByPlaceholder("What's this article about?").fill('d');
await p.getByPlaceholder('Write your article (in markdown)').fill('b');
await p.getByRole('button', { name: /publish/i }).click(); await p.waitForTimeout(1500);
out.push(`(b) UI shows: "${await p.locator('.error-messages').innerText().catch(() => '<nothing>')}"  header: ${(await p.locator('nav').innerText()).replace(/\s+/g, ' ')}`);
await b.close();
writeFileSync(new URL('bug-ui-misleading-errors.txt', EV), out.join('\n')); console.log(out.join('\n'));
