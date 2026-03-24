require('dotenv').config();

const http = require('http');
const route = require('./router');

const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
    route(req, res);
});

server.listen(PORT, () => {
    console.log(`Sidequest API running on port ${PORT}`);
});
