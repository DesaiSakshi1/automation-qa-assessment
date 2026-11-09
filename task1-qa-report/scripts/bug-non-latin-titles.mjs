// Hypothesis: slugs drop non-Latin characters, so a user can publish only ONE article
// whose title is fully non-Latin (Hindi, Chinese, emoji...). The 2nd one is rejected as "not unique".
//   node task1-qa-report/scripts/bug-non-latin-titles.mjs
import { writeFileSync } from 'node:fs';
const API = process.env.API || 'http://localhost:3000/api';
const out = [`# ${new Date().toISOString()}`];
const call = async (method, path, body, token) => {
  const r = await fetch(API + path, { method, headers: { 'Content-Type': 'application/json', ...(token && { Authorization: `Token ${token}` }) }, body: body && JSON.stringify(body) });
  const text = (await r.text()).replace(/"token":"[^"]+"/g, '"token":"<jwt redacted>"');
  out.push(`> ${method} ${API}${path}`, body ? `> body: ${JSON.stringify(body)}` : '', text, `HTTP ${r.status}`, '');
  return JSON.parse(text);
};
const u = 'nonlatin' + Date.now();
const { user } = await fetch(API + '/users', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ user: { username: u, email: `${u}@qa.localhost`, password: 'Passw0rd!123' } }) }).then((r) => r.json());
out.push('## Mixed title keeps its text (works)');
await call('POST', '/articles', { article: { title: `Café 🚀 ${u}`, description: 'd', body: 'b' } }, user.token);
out.push('## First fully Hindi title -> slug loses every character');
await call('POST', '/articles', { article: { title: 'नमस्ते दुनिया', description: 'd', body: 'b' } }, user.token);
out.push('## Second, different Hindi title -> expected 201, gets 422 "must be unique"');
await call('POST', '/articles', { article: { title: 'मेरा दूसरा लेख', description: 'd', body: 'b' } }, user.token);
out.push('## Different Chinese title -> same rejection');
await call('POST', '/articles', { article: { title: '测试', description: 'd', body: 'b' } }, user.token);
writeFileSync(new URL('../evidence/bug-non-latin-titles.txt', import.meta.url), out.join('\n'));
console.log(out.join('\n'));
