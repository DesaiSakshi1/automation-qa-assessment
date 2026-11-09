// Screenshots of the n8n canvases and one successful execution (local n8n only).
//   node task2-n8n-workflow/screenshots.mjs
import { chromium } from 'playwright';
import { readFileSync } from 'node:fs';
const env = Object.fromEntries(readFileSync(new URL('../.env', import.meta.url), 'utf8').split(/\r?\n/).filter((l) => l.includes('=')).map((l) => [l.slice(0, l.indexOf('=')), l.slice(l.indexOf('=') + 1)]));
const N8N = 'http://localhost:5678';
const out = (p) => new URL(`../${p}`, import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');

const b = await chromium.launch();
const page = await b.newPage({ viewport: { width: 1700, height: 900 }, deviceScaleFactor: 1 });
await page.goto(`${N8N}/signin`);
await page.locator('input[type=email], input[name=emailOrLdapLoginId], input[name=email]').first().fill(env.N8N_OWNER_EMAIL);
await page.locator('input[type=password]').first().fill(env.N8N_OWNER_PASSWORD);
await page.keyboard.press('Enter');
await page.waitForURL((u) => !u.pathname.includes('signin'), { timeout: 20000 });

async function settle() { await page.waitForTimeout(2500); for (let i = 0; i < 3; i++) await page.keyboard.press('Escape'); await page.waitForTimeout(500); }

for (const [id, file] of [['mbMorningBrief01', 'task2-n8n-workflow/screenshots/canvas.png'],
                          ['mbErrorHandler01', 'task2-n8n-workflow/screenshots/error-handler-canvas.png'],
                          ['mbUptimeMonitor1', 'bonus-uptime-monitor/screenshots/canvas.png']]) {
  await page.goto(`${N8N}/workflow/${id}`); await settle();
  await page.keyboard.press('Shift+1'); await page.waitForTimeout(800); // zoom to fit
  await page.screenshot({ path: out(file) }); console.log('saved', file);
}

// Latest execution of the Morning Brief (opened from the Executions tab), with "Build digest" output open.
await page.goto(`${N8N}/workflow/mbMorningBrief01/executions`); await settle();
await page.screenshot({ path: out('task2-n8n-workflow/screenshots/executions-list.png') });
// The execution preview is an iframe; open its Logs panel and select the "Build digest" step.
const view = (await page.locator('iframe').count()) ? page.frameLocator('iframe').first() : page;
await view.getByText('Logs', { exact: true }).last().click({ timeout: 10000 }).catch((e) => console.log('logs:', e.message));
await page.waitForTimeout(1500);
await view.getByText('Build digest', { exact: true }).last().click({ timeout: 10000 }).catch((e) => console.log('row:', e.message));
await page.waitForTimeout(2000);
await page.screenshot({ path: out('task2-n8n-workflow/screenshots/successful-execution.png') });
console.log('saved successful-execution.png (latest execution, url:', page.url(), ')');
await b.close();
