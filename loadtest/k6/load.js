// k6 load test through the Gateway.
// Run from the Mac:  kubectl -n ems port-forward svc/<gateway> 18080:80
//                    k6 run -e BASE=http://127.0.0.1:18080 loadtest/k6/load.js
// Stages ramp up enough traffic to trigger the HPA, and every POST /employee publishes an
// employee.created event, which fills the RabbitMQ queue that KEDA scales department-service on.
import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE = __ENV.BASE || 'http://127.0.0.1:18080';
const DEPTS = ['ENG', 'OPS', 'FIN'];

export const options = {
  // PROFILE=drill: short and lab-sized (used by deploy/drills/section-e.sh); default: heavier.
  stages: __ENV.PROFILE === 'drill'
    ? [{ duration: '20s', target: 4 }, { duration: '100s', target: 8 }, { duration: '10s', target: 0 }]
    : [{ duration: '30s', target: 5 }, { duration: '2m', target: 20 }, { duration: '30s', target: 0 }],
  thresholds: {
    http_req_failed: ['rate<0.02'],
    http_req_duration: ['p(95)<800'],
  },
};

export function setup() {
  for (const code of DEPTS) {
    http.post(`${BASE}/api/v1/department-controller`, JSON.stringify({
      departmentName: code, departmentDescription: `${code} department`, departmentCode: code,
    }), { headers: { 'Content-Type': 'application/json' } });
  }
}

export default function () {
  const code = DEPTS[Math.floor(Math.random() * DEPTS.length)];
  const email = `u${__VU}-${__ITER}-${Date.now()}@example.test`;
  const created = http.post(`${BASE}/api/v1/employee-service`, JSON.stringify({
    firstName: 'Load', lastName: 'Test', email, departmentCode: code,
    position: 'Engineer', salary: 1000, hireDate: '2026-01-01',
  }), { headers: { 'Content-Type': 'application/json' } });
  check(created, { 'employee created': (r) => r.status === 201 });

  if (created.status === 201) {
    const id = created.json('id');
    const got = http.get(`${BASE}/api/v1/employee-service/${id}`);
    check(got, { 'employee read': (r) => r.status === 200 });
  }
  http.get(`${BASE}/api/v1/department-controller/${code}`); // served from Redis after the first hit
  sleep(0.5);
}
