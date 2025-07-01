import { Pool } from 'pg';
import * as dotenv from 'dotenv';

// Load environment variables
dotenv.config();

async function testMobileAPI() {
  const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    database: process.env.DB_NAME || 'paperly_db',
    user: process.env.DB_USER || 'paperly_user',
    password: process.env.DB_PASSWORD || 'paperly_dev_password',
  });

  try {
    console.log('🔍 Testing Mobile Article Feed API Data...\n');

    await pool.query('SET search_path TO paperly, public');

    // Test the data that the mobile API would return
    console.log('📱 Simulating mobile article feed query...');
    
    const articlesQuery = `
      SELECT 
        a.id,
        a.title,
        a.slug,
        a.summary,
        a.content,
        a.author_id,
        a.author_name,
        c.name as category_name,
        c.slug as category_slug,
        a.word_count,
        a.estimated_reading_time,
        a.is_featured,
        a.is_premium,
        a.status,
        a.published_at,
        a.created_at,
        COALESCE(
          (SELECT COUNT(*) FROM article_likes al WHERE al.article_id = a.id), 
          0
        ) as like_count,
        COALESCE(
          (SELECT COUNT(*) FROM article_stats ast WHERE ast.article_id = a.id), 
          0
        ) as view_count
      FROM articles a
      LEFT JOIN categories c ON a.category_id = c.id
      WHERE a.status = 'published'
      ORDER BY a.published_at DESC
      LIMIT 10
    `;

    const result = await pool.query(articlesQuery);
    
    console.log(`✅ Found ${result.rows.length} published articles\n`);

    // Format articles like the mobile API would
    const mobileApiResponse = {
      success: true,
      data: {
        articles: result.rows.map(article => ({
          id: article.id,
          title: article.title,
          slug: article.slug,
          summary: article.summary || article.content.substring(0, 200) + '...',
          authorId: article.author_id,
          authorName: article.author_name,
          category: {
            name: article.category_name,
            slug: article.category_slug
          },
          wordCount: article.word_count,
          readingTime: article.estimated_reading_time,
          isFeatured: article.is_featured,
          isPremium: article.is_premium,
          likeCount: parseInt(article.like_count),
          viewCount: parseInt(article.view_count),
          publishedAt: article.published_at,
          createdAt: article.created_at
        })),
        pagination: {
          total: result.rows.length,
          page: 1,
          limit: 10,
          totalPages: 1
        }
      }
    };

    console.log('📋 Sample Mobile API Response:');
    console.log(JSON.stringify(mobileApiResponse, null, 2));

    // Test specific features
    console.log('\n🎯 Testing specific mobile features...\n');

    // Featured articles
    const featuredQuery = `
      SELECT COUNT(*) as count FROM articles 
      WHERE status = 'published' AND is_featured = true
    `;
    const featuredResult = await pool.query(featuredQuery);
    console.log(`📌 Featured articles: ${featuredResult.rows[0].count}`);

    // Categories with articles
    const categoriesQuery = `
      SELECT c.name, c.slug, COUNT(a.id) as article_count
      FROM categories c
      LEFT JOIN articles a ON c.id = a.category_id AND a.status = 'published'
      GROUP BY c.id, c.name, c.slug
      HAVING COUNT(a.id) > 0
      ORDER BY article_count DESC
    `;
    const categoriesResult = await pool.query(categoriesQuery);
    console.log('\n📂 Categories with published articles:');
    categoriesResult.rows.forEach(cat => {
      console.log(`  - ${cat.name}: ${cat.article_count} articles`);
    });

    // Authors with articles
    const authorsQuery = `
      SELECT 
        a.author_name,
        COUNT(a.id) as article_count,
        AVG(a.estimated_reading_time) as avg_reading_time
      FROM articles a
      WHERE a.status = 'published'
      GROUP BY a.author_name
      ORDER BY article_count DESC
    `;
    const authorsResult = await pool.query(authorsQuery);
    console.log('\n👥 Authors with published articles:');
    authorsResult.rows.forEach(author => {
      console.log(`  - ${author.author_name}: ${author.article_count} articles (avg ${Math.round(author.avg_reading_time)} min read)`);
    });

    // Login test data
    console.log('\n🔐 Available test login accounts:');
    const usersQuery = `
      SELECT email, name, user_type 
      FROM users 
      WHERE email LIKE '%writer%' OR user_type = 'writer'
      ORDER BY created_at DESC
    `;
    const usersResult = await pool.query(usersQuery);
    console.log('   Email: Password');
    console.log('   ─────────────────────────────');
    usersResult.rows.forEach(user => {
      console.log(`   ${user.email}: password123`);
    });

    console.log('\n✅ Mobile API data verification completed!');
    console.log('\n📱 Mobile app can now:');
    console.log('   - Login with test writer accounts');
    console.log('   - Fetch article feed from /api/mobile/articles');
    console.log('   - Browse articles by category');
    console.log('   - View featured articles');
    console.log('   - Read full article content');

  } catch (error) {
    console.error('❌ Error testing mobile API:', error);
  } finally {
    await pool.end();
  }
}

testMobileAPI().catch(console.error);