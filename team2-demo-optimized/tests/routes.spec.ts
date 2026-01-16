/*
 * Route and pod health smoke tests for Team2 demo.
 * Run with: npm install && npm run test:routes
 */

import { execFile } from 'node:child_process';
import { promisify } from 'node:util';

const exec = promisify(execFile);
const namespace = 'team2-demo';

const GREEN = '\u001b[32m';
const RED = '\u001b[31m';
const YELLOW = '\u001b[33m';
const RESET = '\u001b[0m';

const ok = (msg: string) => `${GREEN}${msg}${RESET}`;
const warn = (msg: string) => `${YELLOW}${msg}${RESET}`;
const err = (msg: string) => `${RED}${msg}${RESET}`;

async function run(cmd: string, args: string[], ignoreError = false) {
  try {
    const { stdout } = await exec(cmd, args, { maxBuffer: 1024 * 1024 });
    return stdout.trim();
  } catch (e) {
    if (ignoreError) return '';
    throw e;
  }
}

async function fetchWithTimeout(url: string, init: RequestInit & { timeoutMs?: number } = {}) {
  const { timeoutMs = 5000, ...rest } = init;
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    return await fetch(url, { ...rest, signal: ctrl.signal });
  } finally {
    clearTimeout(t);
  }
}

async function preflight() {
  process.stdout.write('🔍 Pre-flight checks... ');
  await run('kubectl', ['cluster-info']);
  await run('kubectl', ['get', 'namespace', namespace]);
  console.log(ok('OK'));
}

async function getRoutes() {
  const getHost = async (name: string) =>
    run('kubectl', ['get', 'route', name, '-n', namespace, '-o', "jsonpath={.spec.host}"], true);

  const frontend = await getHost('team2-frontend');
  if (!frontend) throw new Error('Routes not found; deploy first (./dev.sh)');
  const api = await getHost('team2-api');
  const backend = await getHost('team2-backend');

  console.log('📍 Routes:');
  console.log(`  Frontend: http://${frontend}`);
  console.log(`  API:      http://${api}`);
  console.log(`  Backend:  http://${backend}`);
  console.log('');

  return { frontend, api, backend };
}

async function getEndpoints() {
  const getIps = async (svc: string) =>
    run('kubectl', ['get', 'endpoints', svc, '-n', namespace, '-o', "jsonpath={.subsets[*].addresses[*].ip}"], true);
  const gatewayIps = await getIps('gateway-team2');
  const backendIps = await getIps('backend-team2');
  console.log('🔍 Service Endpoints:');
  console.log(`  Gateway endpoints: ${gatewayIps || 'none'}`);
  console.log(`  Backend endpoints: ${backendIps || 'none'}`);
  if (!gatewayIps || !backendIps) console.log(warn('  Pods may not be ready yet'));
  console.log('');
  return { gatewayIps, backendIps };
}

async function assert(condition: boolean, message: string) {
  if (!condition) throw new Error(message);
}

async function main() {
  console.log('🧪 Testing Team2 Demo Routes');
  console.log('==============================\n');

  await preflight();
  const routes = await getRoutes();
  await getEndpoints();

  const tests: Array<{ name: string; fn: () => Promise<void> }> = [
    {
      name: 'Root returns 404 (no default redirect)',
      fn: async () => {
        const res = await fetchWithTimeout(`http://${routes.frontend}/`, { redirect: 'manual', timeoutMs: 5000 });
        await assert(res.status === 404, `Expected 404, got ${res.status}`);
      },
    },
    {
      name: 'Frontend accessible at /app1',
      fn: async () => {
        const res = await fetchWithTimeout(`http://${routes.frontend}/app1`, { redirect: 'manual' });
        await assert([200, 301].includes(res.status), `Status ${res.status}`);
      },
    },
    {
      name: 'Redirect does not expose internal port',
      fn: async () => {
        const res = await fetchWithTimeout(`http://${routes.frontend}/app1`, { redirect: 'manual' });
        const location = res.headers.get('location') || '';
        await assert(!location.includes(':8080'), `Location header exposes port: ${location}`);
        await assert(location.includes('/app1/'), `Location should redirect to /app1/: ${location}`);
      },
    },
    {
      name: 'Frontend HTML has base href',
      fn: async () => {
        const html = await (await fetchWithTimeout(`http://${routes.frontend}/app1/`)).text();
        await assert(html.includes('<base href="/app1/">'), 'Missing base href');
      },
    },
    {
      name: 'Frontend static assets load',
      fn: async () => {
        const html = await (await fetchWithTimeout(`http://${routes.frontend}/app1/`)).text();
        const match = html.match(/main\.[a-z0-9]*\.js/);
        await assert(!!match, 'main.*.js not found');
        const res = await fetchWithTimeout(`http://${routes.frontend}/app1/${match[0]}`);
        await assert(res.status === 200, `Status ${res.status}`);
      },
    },
    {
      name: 'API via frontend route',
      fn: async () => {
        const body = await (await fetchWithTimeout(`http://${routes.frontend}/api/hello`)).text();
        await assert(body.includes('Hello'), `Body: ${body}`);
      },
    },
    {
      name: 'API via API route',
      fn: async () => {
        const body = await (await fetchWithTimeout(`http://${routes.api}/api/hello`)).text();
        await assert(body.includes('Hello'), `Body: ${body}`);
      },
    },
    {
      name: 'API via backend route',
      fn: async () => {
        const body = await (await fetchWithTimeout(`http://${routes.backend}/api/hello`)).text();
        await assert(body.includes('Hello'), `Body: ${body}`);
      },
    },
    {
      name: 'Security headers present on frontend',
      fn: async () => {
        const res = await fetchWithTimeout(`http://${routes.frontend}/app1/`, { method: 'HEAD' });
        await assert(res.headers.has('x-frame-options'), 'x-frame-options missing');
        await assert(res.headers.has('x-content-type-options'), 'x-content-type-options missing');
      },
    },
    {
      name: 'Unknown paths return 404',
      fn: async () => {
        const res = await fetchWithTimeout(`http://${routes.frontend}/nonexistent/path`, { redirect: 'manual' });
        await assert(res.status === 404, `Status ${res.status}`);
      },
    },
    {
      name: 'Pods are ready',
      fn: async () => {
        const backendReady = await run('kubectl', ['get', 'pods', '-n', namespace, '-l', 'app=backend-team2', '-o', "jsonpath={.items[0].status.containerStatuses[0].ready}"]); 
        const gatewayReady = await run('kubectl', ['get', 'pods', '-n', namespace, '-l', 'app=gateway-team2', '-o', "jsonpath={.items[0].status.containerStatuses[0].ready}"]);
        await assert(backendReady === 'true' && gatewayReady === 'true', `backend:${backendReady} gateway:${gatewayReady}`);
      },
    },
  ];

  let failures = 0;
  for (const test of tests) {
    process.stdout.write(`• ${test.name} ... `);
    try {
      await test.fn();
      console.log(ok('PASS'));
    } catch (e: any) {
      failures += 1;
      console.log(err('FAIL'));
      console.log(`  ${e.message ?? e}`);
    }
  }

  console.log('\n==============================');
  if (failures === 0) {
    console.log(ok('✓ All critical tests passed!'));
    console.log('\n🌐 Access the application:');
    console.log(`   Frontend: http://${routes.frontend}/app1`);
    console.log(`   API:      http://${routes.frontend}/api/hello`);
    process.exit(0);
  } else {
    console.log(err(`✗ ${failures} test(s) failed`));
    console.log('\n🔍 Troubleshooting:');
    console.log('   kubectl get pods -n team2-demo');
    console.log('   kubectl logs -n team2-demo deployment/gateway-team2');
    console.log('   kubectl logs -n team2-demo deployment/backend-team2');
    process.exit(1);
  }
}

main().catch((e) => {
  console.error(err('Unexpected error:'));
  console.error(e);
  process.exit(1);
});
