const assert = require('assert');
const app = require('./app');

assert.ok(app, 'Express application should be created');

const rootRoute = app._router.stack.find(
  layer => layer.route && layer.route.path === '/'
);

assert.ok(rootRoute, 'Root route should exist');
assert.strictEqual(rootRoute.route.path, '/');

console.log('Unit tests passed successfully.');
