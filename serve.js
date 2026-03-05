const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3000;
const ROOT = __dirname;

const MIME = {
  '.html': 'text/html',
  '.css':  'text/css',
  '.js':   'text/javascript',
  '.png':  'image/png',
  '.jpg':  'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg':  'image/svg+xml',
  '.ico':  'image/x-icon',
  '.webp': 'image/webp',
};

http.createServer(function (req, res) {
  let urlPath = req.url.split('?')[0];
  if (urlPath === '/') urlPath = '/index.html';

  // Allow requests for assets one level up (../Google business photos/, ../archive/)
  const safePath = path.normalize(path.join(ROOT, urlPath));
  const projectRoot = path.resolve(ROOT, '..');

  if (!safePath.startsWith(projectRoot)) {
    res.writeHead(403); res.end('Forbidden'); return;
  }

  fs.readFile(safePath, function (err, data) {
    if (err) {
      res.writeHead(404); res.end('Not found: ' + urlPath); return;
    }
    const ext  = path.extname(safePath).toLowerCase();
    const mime = MIME[ext] || 'application/octet-stream';
    res.writeHead(200, { 'Content-Type': mime });
    res.end(data);
  });
}).listen(PORT, function () {
  console.log('Lagom Næring dev server running at http://localhost:' + PORT);
});
