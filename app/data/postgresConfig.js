var dotenv = require('dotenv');
dotenv.config();

module.exports = {
  user: process.env.PGUSER,
  password: process.env.PGPASSWORD,
  database: process.env.PGDATABASE,
  host: process.env.PGHOST || 'localhost',
  port: process.env.PGPORT || 5432,
  max: 10, // max number of clients in the pool
  idleTimeoutMillis: 30000, // how long a client is allowed to remain idle before being closed
};
