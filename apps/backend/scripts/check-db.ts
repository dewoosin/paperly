/**
 * Database connection test script
 * 
 * Tests database connectivity and displays connection information
 */

import { Client } from 'pg';
import { config } from '../src/infrastructure/config/env.config';
import { getPlatformConfig } from '../src/infrastructure/config/platform.config';

async function checkDatabaseConnection() {
  console.log('\n🔍 Checking database connection...\n');

  // Display platform information
  const platformConfig = getPlatformConfig();
  console.log('📍 Platform Configuration:');
  console.log(`  - Platform: ${platformConfig.isWSL ? 'WSL' : platformConfig.isMacOS ? 'macOS' : 'Linux'}`);
  console.log(`  - Database Host: ${config.DB_HOST}`);
  console.log(`  - Redis Host: ${config.REDIS_HOST}`);
  console.log();

  // Test database connection
  const client = new Client({
    host: config.DB_HOST,
    port: config.DB_PORT,
    database: config.DB_NAME,
    user: config.DB_USER,
    password: config.DB_PASSWORD,
  });

  try {
    console.log(`🔗 Connecting to PostgreSQL at ${config.DB_HOST}:${config.DB_PORT}...`);
    await client.connect();
    
    console.log('✅ Database connection successful!');
    
    // Get PostgreSQL version
    const result = await client.query('SELECT version()');
    console.log(`📊 PostgreSQL Version: ${result.rows[0].version}`);
    
    // Check if tables exist
    const tablesResult = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name
    `);
    
    console.log(`\n📋 Tables in database:`);
    if (tablesResult.rows.length === 0) {
      console.log('  - No tables found (database is empty)');
    } else {
      tablesResult.rows.forEach(row => {
        console.log(`  - ${row.table_name}`);
      });
    }
    
  } catch (error) {
    console.error('❌ Database connection failed!');
    console.error(`Error: ${error.message}`);
    
    if (error.code === 'ECONNREFUSED') {
      console.log('\n💡 Troubleshooting tips:');
      console.log('  1. Check if PostgreSQL is running in Docker');
      console.log('  2. Verify Docker is running and accessible');
      console.log('  3. Check if the port 5432 is exposed');
      if (platformConfig.isWSL) {
        console.log('  4. For WSL: Make sure Docker Desktop is running on Windows');
        console.log('  5. Try manually setting DB_HOST_OVERRIDE in .env.local');
      }
    }
    
    process.exit(1);
  } finally {
    await client.end();
  }
  
  console.log('\n✨ All checks passed!\n');
}

// Run the check
checkDatabaseConnection().catch(console.error);