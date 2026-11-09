// HTML -> PDF with headless Chromium.   npm run pdf
import { chromium } from 'playwright';
import { fileURLToPath } from 'node:url';
const src = new URL('../report-source/report.html', import.meta.url).href;
const out = fileURLToPath(new URL('../Task1_QA_Report_SakshiDesai.pdf', import.meta.url));
const b = await chromium.launch();
const p = await b.newPage();
await p.goto(src, { waitUntil: 'networkidle' });
const broken = await p.$$eval('img', (imgs) => imgs.filter((i) => !i.complete || i.naturalWidth === 0).map((i) => i.src));
if (broken.length) throw new Error('Broken images: ' + broken.join(', '));
await p.pdf({ path: out, format: 'A4', printBackground: true, displayHeaderFooter: true,
  headerTemplate: '<span></span>',
  footerTemplate: '<div style="font-size:8px;width:100%;text-align:center;color:#888">Task 1 QA Report – Sakshi Desai – page <span class="pageNumber"></span>/<span class="totalPages"></span></div>',
  margin: { top: '14mm', bottom: '16mm', left: '12mm', right: '12mm' } });
await b.close();
console.log('wrote', out);
