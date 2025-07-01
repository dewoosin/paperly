import { Pool } from 'pg';
import * as dotenv from 'dotenv';

// Load environment variables
dotenv.config();

async function getTestData() {
  const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    database: process.env.DB_NAME || 'paperly_db',
    user: process.env.DB_USER || 'paperly_user',
    password: process.env.DB_PASSWORD || 'paperly_dev_password',
  });

  try {
    console.log('🔍 Retrieving test data from paperly database...\n');

    // Test connection
    await pool.query('SELECT NOW()');
    console.log('✅ Database connection successful\n');

    // Set search path
    await pool.query('SET search_path TO paperly, public');
    console.log('✅ Search path set to paperly schema\n');

    // Get a test user
    console.log('👤 Getting test user data...');
    const userResult = await pool.query(`
      SELECT id, email, name, email_verified 
      FROM users 
      WHERE email_verified = true 
      LIMIT 1
    `);
    console.log('User data:', userResult.rows[0]);
    console.log('');

    // Get a test article (first check table structure)
    console.log('📰 Getting articles table structure...');
    const columnsResult = await pool.query(`
      SELECT column_name, data_type
      FROM information_schema.columns 
      WHERE table_schema = 'paperly' AND table_name = 'articles'
      ORDER BY ordinal_position
    `);
    console.log('Articles table columns:', columnsResult.rows.map(r => r.column_name));
    console.log('');

    console.log('📰 Getting test article data...');
    const articleResult = await pool.query(`
      SELECT id, title, author_id, status, published_at, created_at
      FROM articles 
      WHERE status = 'published' 
      ORDER BY created_at DESC 
      LIMIT 1
    `);
    console.log('Article data:', articleResult.rows[0]);
    console.log('');

    // Check if article_likes table exists
    console.log('💖 Checking article_likes table...');
    const tableExistsResult = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'paperly' AND table_name = 'article_likes'
      );
    `);
    console.log('Table exists:', tableExistsResult.rows[0].exists);

    if (tableExistsResult.rows[0].exists) {
      const likesCountResult = await pool.query('SELECT COUNT(*) FROM article_likes');
      console.log('Current likes count:', likesCountResult.rows[0].count);
      
      // Get table structure
      const structureResult = await pool.query(`
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns 
        WHERE table_schema = 'paperly' AND table_name = 'article_likes'
        ORDER BY ordinal_position
      `);
      console.log('Table structure:', structureResult.rows);
    }
    console.log('');

    // Check article_stats table
    console.log('📊 Checking article_stats table...');
    const statsExistsResult = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'paperly' AND table_name = 'article_stats'
      );
    `);
    console.log('Table exists:', statsExistsResult.rows[0].exists);

    if (statsExistsResult.rows[0].exists) {
      const statsCountResult = await pool.query('SELECT COUNT(*) FROM article_stats');
      console.log('Current stats records:', statsCountResult.rows[0].count);

      if (parseInt(statsCountResult.rows[0].count) > 0) {
        const statsDataResult = await pool.query('SELECT * FROM article_stats LIMIT 3');
        console.log('Sample stats data:', statsDataResult.rows);
      }
    }
    console.log('');

    // Generate test summary
    const testUser = userResult.rows[0];
    const testArticle = articleResult.rows[0];

    console.log('🎯 TEST DATA SUMMARY');
    console.log('===================');
    console.log(`Test User ID: ${testUser?.id}`);
    console.log(`Test User Email: ${testUser?.email}`);
    console.log(`Test User Name: ${testUser?.name}`);
    console.log('');
    console.log(`Test Article ID: ${testArticle?.id}`);
    console.log(`Test Article Title: ${testArticle?.title}`);
    console.log(`Test Article Status: ${testArticle?.status}`);
    console.log(`Test Article Author ID: ${testArticle?.author_id}`);
    console.log('');
    console.log('Tables Status:');
    console.log(`- article_likes table exists: ${tableExistsResult.rows[0].exists}`);
    console.log(`- article_stats table exists: ${statsExistsResult.rows[0].exists}`);

  } catch (error) {
    console.error('❌ Error retrieving test data:', error);
  } finally {
    await pool.end();
  }
}

getTestData();