import { Pool } from 'pg';
import * as dotenv from 'dotenv';
import * as bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';

// Load environment variables
dotenv.config();

interface Writer {
  id: string;
  email: string;
  name: string;
  nickname: string;
  passwordHash: string;
}

interface Article {
  id: string;
  title: string;
  slug: string;
  content: string;
  excerpt: string;
  authorId: string;
  categoryId: string | null;
  status: string;
  wordCount: number;
  readingTimeMinutes: number;
  viewCount: number;
  likeCount: number;
}

const categories = [
  'tech', 'travel', 'health', 'education', 'lifestyle', 
  'food', 'business', 'science', 'art', 'sports'
];

const sampleTitles = [
  'The Future of Artificial Intelligence in Healthcare',
  'Sustainable Travel: A Guide to Eco-Friendly Adventures',
  'Mental Health and Wellness in the Digital Age',
  'Online Learning: Revolutionizing Education',
  'Minimalist Living: Finding Joy in Simplicity',
  'Street Food Culture Around the World',
  'Entrepreneurship in the Digital Economy',
  'Climate Change and Scientific Innovation',
  'Contemporary Art and Social Commentary',
  'The Psychology of Sports Performance'
];

const sampleContent = [
  `Artificial intelligence is transforming healthcare in unprecedented ways. From diagnostic imaging to personalized treatment plans, AI is enabling doctors to provide more accurate and efficient care. This article explores the current state of AI in healthcare and its promising future applications.

The integration of machine learning algorithms in medical imaging has dramatically improved the accuracy of diagnoses. Radiologists can now detect anomalies in X-rays, MRIs, and CT scans with greater precision, leading to earlier interventions and better patient outcomes.

Moreover, AI-powered drug discovery is accelerating the development of new medications. By analyzing vast datasets of molecular structures and biological interactions, researchers can identify potential drug candidates much faster than traditional methods.

As we look to the future, the possibilities are endless. From robotic surgery to AI-assisted mental health therapy, technology continues to push the boundaries of what's possible in medicine.`,

  `Sustainable travel has become more than just a trend—it's a necessity for preserving our planet's natural beauty for future generations. This comprehensive guide will help you plan eco-friendly adventures that minimize your environmental impact while maximizing your travel experiences.

The key to sustainable travel lies in making conscious choices about transportation, accommodation, and activities. Consider taking trains instead of planes for shorter distances, choosing eco-certified hotels, and supporting local businesses that prioritize environmental responsibility.

One of the most rewarding aspects of sustainable travel is the deeper connection you develop with local communities. By choosing locally-owned accommodations and restaurants, you contribute directly to the local economy while experiencing authentic culture.

Remember, every small action counts. From bringing a reusable water bottle to respecting wildlife and natural habitats, your choices as a traveler can make a significant difference.`,

  `In our increasingly connected world, maintaining mental health and wellness has become more challenging yet more important than ever. The digital age brings both opportunities and threats to our psychological well-being.

Social media, while connecting us globally, can also contribute to anxiety, depression, and feelings of inadequacy. The constant comparison with others' curated online lives can negatively impact self-esteem and mental health.

However, technology also offers unprecedented access to mental health resources. From meditation apps to online therapy platforms, digital tools can provide support and guidance for those seeking to improve their mental well-being.

The key is finding balance. Setting boundaries with technology, practicing digital detox, and using technology mindfully can help harness its benefits while minimizing its negative impact on mental health.`,

  `The landscape of education is undergoing a radical transformation, with online learning at the forefront of this revolution. The COVID-19 pandemic accelerated the adoption of digital learning platforms, fundamentally changing how we approach education.

Online learning offers unprecedented flexibility and accessibility. Students can access world-class education from anywhere, at any time, breaking down geographical and socioeconomic barriers to learning.

Interactive technologies, virtual reality, and AI-powered personalized learning are creating more engaging and effective educational experiences. These tools adapt to individual learning styles and paces, ensuring that every student can reach their full potential.

However, the digital divide remains a significant challenge. Ensuring equal access to technology and internet connectivity is crucial for making online education truly inclusive and equitable.`,

  `Minimalist living is not about deprivation—it's about intentionality. In a world overwhelmed by consumer culture and material excess, minimalism offers a path to greater clarity, purpose, and joy.

The philosophy of minimalism encourages us to focus on what truly matters, eliminating the unnecessary to make room for the essential. This applies not just to physical possessions, but to commitments, relationships, and daily activities.

Starting your minimalist journey doesn't require dramatic changes overnight. Begin by decluttering one room, practicing mindful consumption, and regularly evaluating what adds value to your life versus what merely takes up space.

The benefits of minimalist living extend far beyond a tidy home. Many practitioners report reduced stress, increased focus, better financial health, and a greater appreciation for experiences over material possessions.`
];

function generateSlug(title: string): string {
  return title
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .trim();
}

function calculateWordCount(content: string): number {
  return content.split(/\s+/).filter(word => word.length > 0).length;
}

function calculateReadingTime(wordCount: number): number {
  // Average reading speed is 200 words per minute
  return Math.ceil(wordCount / 200);
}

function getRandomElement<T>(array: T[]): T {
  return array[Math.floor(Math.random() * array.length)];
}

function getRandomNumber(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

async function insertTestData() {
  const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    database: process.env.DB_NAME || 'paperly_db',
    user: process.env.DB_USER || 'paperly_user',
    password: process.env.DB_PASSWORD || 'paperly_dev_password',
  });

  try {
    console.log('🔄 Starting test data insertion...\n');

    // Test connection
    await pool.query('SELECT NOW()');
    console.log('✅ Database connection successful\n');

    // Set search path
    await pool.query('SET search_path TO paperly, public');
    console.log('✅ Search path set to paperly schema\n');

    // Begin transaction
    await pool.query('BEGIN');

    // Create 10 writers
    console.log('👥 Creating 10 test writers...');
    const writers: Writer[] = [];
    const saltRounds = 10;
    const defaultPassword = await bcrypt.hash('password123', saltRounds);

    for (let i = 1; i <= 10; i++) {
      const writerId = uuidv4();
      const writer: Writer = {
        id: writerId,
        email: `writer${i}@paperly.com`,
        name: `Writer ${i}`,
        nickname: `writer${i}`,
        passwordHash: defaultPassword
      };

      // First check if user already exists
      const existingUser = await pool.query(
        'SELECT id FROM paperly.users WHERE email = $1',
        [writer.email]
      );

      if (existingUser.rows.length === 0) {
        await pool.query(
          `INSERT INTO paperly.users (
            id, email, password_hash, name, nickname, 
            email_verified, phone_verified, status, user_type, user_code,
            created_at, updated_at
          ) VALUES ($1, $2, $3, $4, $5, true, false, 'active', 'writer', $6, NOW(), NOW())`,
          [writerId, writer.email, writer.passwordHash, writer.name, writer.nickname, `W${i.toString().padStart(3, '0')}`]
        );
        
        // Try to assign writer role if roles exist
        try {
          const writerRole = await pool.query(
            'SELECT id FROM paperly.roles WHERE name = $1 LIMIT 1',
            ['writer']
          );
          
          if (writerRole.rows.length > 0) {
            await pool.query(
              `INSERT INTO paperly.user_role_assignments (user_id, role_id, assigned_at, is_active)
               VALUES ($1, $2, NOW(), true)
               ON CONFLICT (user_id, role_id) DO NOTHING`,
              [writerId, writerRole.rows[0].id]
            );
          }
        } catch (roleError) {
          console.warn(`⚠️  Could not assign role to user ${writer.email}:`, roleError.message);
        }
      } else {
        // Update existing user and use existing ID
        writer.id = existingUser.rows[0].id;
        await pool.query(
          `UPDATE paperly.users SET 
           name = $1, nickname = $2, updated_at = NOW() 
           WHERE id = $3`,
          [writer.name, writer.nickname, writer.id]
        );
      }

      writers.push(writer);
    }
    console.log(`✅ Created ${writers.length} writers\n`);

    // Create categories if they don't exist
    console.log('📂 Ensuring categories exist...');
    for (const category of categories) {
      await pool.query(
        `INSERT INTO paperly.categories (id, name, slug, description, created_at, updated_at)
         VALUES ($1, $2, $3, $4, NOW(), NOW())
         ON CONFLICT (slug) DO NOTHING`,
        [uuidv4(), category.charAt(0).toUpperCase() + category.slice(1), category, `Articles about ${category}`]
      );
    }
    console.log('✅ Categories ready\n');

    // Get category IDs
    const categoryResult = await pool.query('SELECT id, slug FROM paperly.categories');
    const categoryMap = new Map<string, string>();
    categoryResult.rows.forEach(row => {
      categoryMap.set(row.slug, row.id);
    });

    // Create 50 articles (5 per writer)
    console.log('📰 Creating 50 test articles...');
    const articles: Article[] = [];

    for (let writerIndex = 0; writerIndex < writers.length; writerIndex++) {
      const writer = writers[writerIndex];
      
      for (let articleIndex = 0; articleIndex < 5; articleIndex++) {
        const titleIndex = (writerIndex * 5 + articleIndex) % sampleTitles.length;
        const contentIndex = articleIndex % sampleContent.length;
        
        const title = `${sampleTitles[titleIndex]} - ${writer.name} Edition`;
        const content = sampleContent[contentIndex];
        const excerpt = content.substring(0, 150) + '...';
        const slug = generateSlug(title);
        const wordCount = calculateWordCount(content);
        const readingTime = calculateReadingTime(wordCount);
        const category = getRandomElement(categories);
        const categoryId = categoryMap.get(category) || null;
        
        const article: Article = {
          id: uuidv4(),
          title,
          slug: `${slug}-${Date.now()}-${articleIndex}`, // Ensure uniqueness
          content,
          excerpt,
          authorId: writer.id,
          categoryId,
          status: 'published',
          wordCount,
          readingTimeMinutes: readingTime,
          viewCount: getRandomNumber(50, 1000),
          likeCount: getRandomNumber(5, 100)
        };

        await pool.query(
          `INSERT INTO paperly.articles (
            id, title, slug, content, summary, author_id, author_name, category_id,
            status, word_count, estimated_reading_time,
            difficulty_level, content_type, language, target_audience,
            is_premium, is_featured, published_at, created_at, updated_at
          ) VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, 'ko', 'general',
            false, false,
            NOW() - INTERVAL '${getRandomNumber(1, 30)} days', 
            NOW() - INTERVAL '${getRandomNumber(1, 30)} days', 
            NOW()
          )`,
          [
            article.id, article.title, article.slug, article.content, article.excerpt,
            article.authorId, writer.name, article.categoryId, article.status,
            article.wordCount, article.readingTimeMinutes, 1, 'article'
          ]
        );

        articles.push(article);
      }
    }
    console.log(`✅ Created ${articles.length} articles\n`);

    // Create some article stats if the table exists
    console.log('📊 Checking article_stats table...');
    const statsTableExists = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'paperly' AND table_name = 'article_stats'
      );
    `);

    if (statsTableExists.rows[0].exists) {
      console.log('📊 Creating article stats...');
      for (const article of articles) {
        await pool.query(
          `INSERT INTO paperly.article_stats (
            article_id, view_count, like_count, share_count, comment_count,
            created_at, updated_at
          ) VALUES ($1, $2, $3, $4, $5, NOW(), NOW())
          ON CONFLICT (article_id) DO UPDATE SET
            view_count = EXCLUDED.view_count,
            like_count = EXCLUDED.like_count,
            share_count = EXCLUDED.share_count,
            comment_count = EXCLUDED.comment_count,
            updated_at = NOW()`,
          [
            article.id, article.viewCount, article.likeCount,
            getRandomNumber(0, 20), getRandomNumber(0, 15)
          ]
        );
      }
      console.log('✅ Article stats created\n');
    }

    // Commit transaction
    await pool.query('COMMIT');

    // Verification queries
    console.log('🔍 Verifying inserted data...\n');

    const userCount = await pool.query('SELECT COUNT(*) FROM paperly.users WHERE user_type = \'writer\'');
    console.log(`👥 Writers in database: ${userCount.rows[0].count}`);

    const articleCount = await pool.query('SELECT COUNT(*) FROM paperly.articles WHERE status = \'published\'');
    console.log(`📰 Published articles: ${articleCount.rows[0].count}`);

    const categoryCount = await pool.query('SELECT COUNT(*) FROM paperly.categories');
    console.log(`📂 Categories: ${categoryCount.rows[0].count}`);

    // Show sample data
    console.log('\n📋 Sample writers:');
    const sampleWriters = await pool.query(`
      SELECT email, name, nickname FROM paperly.users 
      WHERE user_type = 'writer' 
      ORDER BY created_at DESC 
      LIMIT 3
    `);
    sampleWriters.rows.forEach(writer => {
      console.log(`  - ${writer.name} (${writer.email})`);
    });

    console.log('\n📋 Sample articles:');
    const sampleArticles = await pool.query(`
      SELECT a.title, a.view_count, a.like_count, u.name as author_name
      FROM paperly.articles a
      JOIN paperly.users u ON a.author_id = u.id
      WHERE a.status = 'published'
      ORDER BY a.created_at DESC
      LIMIT 5
    `);
    sampleArticles.rows.forEach(article => {
      console.log(`  - "${article.title}" by ${article.author_name} (${article.view_count} views, ${article.like_count} likes)`);
    });

    console.log('\n✅ Test data insertion completed successfully!');
    console.log('\n📝 Login credentials for all writers:');
    console.log('   Email: writer1@paperly.com to writer10@paperly.com');
    console.log('   Password: password123');

  } catch (error) {
    await pool.query('ROLLBACK');
    console.error('❌ Error inserting test data:', error);
    throw error;
  } finally {
    await pool.end();
  }
}

// Run the script
insertTestData().catch(console.error);