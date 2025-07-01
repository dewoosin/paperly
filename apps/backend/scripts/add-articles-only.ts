import { Pool } from 'pg';
import * as dotenv from 'dotenv';
import { v4 as uuidv4 } from 'uuid';

// Load environment variables
dotenv.config();

const categories = [
  'technology', 'business', 'science', 'learning', 'lifestyle', 
  'startup', 'programming', 'data-science', 'creative', 'investment'
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
  'The Psychology of Sports Performance',
  'Building Resilient Communities',
  'The Art of Effective Communication',
  'Sustainable Energy Solutions',
  'Digital Privacy in Modern Times',
  'The Future of Remote Work',
  'Healthy Cooking on a Budget',
  'Space Exploration and Discovery',
  'The Impact of Social Media',
  'Creative Problem Solving',
  'Personal Finance for Beginners'
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

  `Building resilient communities is essential for facing the challenges of our rapidly changing world. From climate change to economic uncertainty, communities that can adapt and thrive in the face of adversity are those that invest in social connections, infrastructure, and local resources.

Community resilience starts with strong social networks. When neighbors know and trust each other, they're more likely to come together during times of crisis. This social capital can be built through regular community events, volunteer opportunities, and shared spaces where people can gather and connect.

Economic resilience is equally important. Communities that support local businesses, develop diverse economic opportunities, and invest in skills training are better positioned to weather economic storms. Local food systems, renewable energy projects, and cooperative businesses all contribute to this resilience.

Finally, environmental resilience requires communities to work with nature rather than against it. This might mean restoring natural habitats, implementing sustainable water management systems, or designing green infrastructure that can handle extreme weather events.`
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
  return Math.ceil(wordCount / 200);
}

function getRandomElement<T>(array: T[]): T {
  return array[Math.floor(Math.random() * array.length)];
}

function getRandomNumber(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

async function addArticles() {
  const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    database: process.env.DB_NAME || 'paperly_db',
    user: process.env.DB_USER || 'paperly_user',
    password: process.env.DB_PASSWORD || 'paperly_dev_password',
  });

  try {
    console.log('🔄 Adding articles to existing writers...\n');

    await pool.query('SET search_path TO paperly, public');

    // Get existing writers
    const writersResult = await pool.query(`
      SELECT id, email, name 
      FROM users 
      WHERE user_type = 'writer' OR email LIKE '%writer%'
      ORDER BY created_at DESC
    `);

    if (writersResult.rows.length === 0) {
      console.log('❌ No writers found in database');
      return;
    }

    const writers = writersResult.rows;
    console.log(`✅ Found ${writers.length} existing writers`);

    // Get categories
    const categoriesResult = await pool.query('SELECT id, slug FROM categories');
    const categoryMap = new Map<string, string>();
    categoriesResult.rows.forEach(row => {
      categoryMap.set(row.slug, row.id);
    });

    console.log(`✅ Found ${categoryMap.size} categories\n`);

    // Begin transaction
    await pool.query('BEGIN');

    // Add articles for each writer
    let totalArticles = 0;
    const articlesPerWriter = Math.ceil(50 / writers.length);

    for (const writer of writers) {
      console.log(`📝 Adding ${articlesPerWriter} articles for ${writer.name}...`);
      
      for (let i = 0; i < articlesPerWriter && totalArticles < 50; i++) {
        const titleIndex = (totalArticles) % sampleTitles.length;
        const contentIndex = i % sampleContent.length;
        
        const baseTitle = sampleTitles[titleIndex];
        const title = `${baseTitle} - ${writer.name} Edition`;
        const content = sampleContent[contentIndex];
        const summary = content.substring(0, 150) + '...';
        const slug = `${generateSlug(baseTitle)}-${writer.name.toLowerCase().replace(/\s+/g, '-')}-${Date.now()}-${i}`;
        const wordCount = calculateWordCount(content);
        const readingTime = calculateReadingTime(wordCount);
        const category = getRandomElement(categories);
        let categoryId = categoryMap.get(category);
        
        // Fallback to first available category if mapping fails
        if (!categoryId && categoryMap.size > 0) {
          categoryId = categoryMap.values().next().value;
        }

        await pool.query(
          `INSERT INTO articles (
            id, title, slug, content, summary, author_id, author_name, category_id,
            status, word_count, estimated_reading_time,
            difficulty_level, content_type, language, target_audience,
            is_premium, is_featured, published_at, created_at, updated_at
          ) VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8, 'published', $9, $10, 1, 'article', 'ko', $11,
            false, $12,
            NOW() - INTERVAL '${getRandomNumber(1, 30)} days', 
            NOW() - INTERVAL '${getRandomNumber(1, 30)} days', 
            NOW()
          )`,
          [
            uuidv4(), title, slug, content, summary,
            writer.id, writer.name, categoryId,
            wordCount, readingTime, 
            JSON.stringify(['general']), // target_audience as JSON array
            getRandomNumber(1, 10) === 1 // 10% chance of being featured
          ]
        );

        totalArticles++;
      }
    }

    await pool.query('COMMIT');
    console.log(`\n✅ Successfully added ${totalArticles} articles\n`);

    // Verification
    const articleCount = await pool.query('SELECT COUNT(*) FROM articles WHERE status = \'published\'');
    console.log(`📊 Total published articles in database: ${articleCount.rows[0].count}`);

    // Show sample articles
    const sampleArticles = await pool.query(`
      SELECT a.title, a.word_count, u.name as author_name, c.name as category_name
      FROM articles a
      LEFT JOIN users u ON a.author_id = u.id
      LEFT JOIN categories c ON a.category_id = c.id
      WHERE a.status = 'published'
      ORDER BY a.created_at DESC
      LIMIT 10
    `);

    console.log('\n📋 Sample articles:');
    sampleArticles.rows.forEach(article => {
      console.log(`  - "${article.title}" by ${article.author_name} (${article.word_count} words, ${article.category_name || 'No category'})`);
    });

    console.log('\n✅ Articles added successfully!');

  } catch (error) {
    await pool.query('ROLLBACK');
    console.error('❌ Error adding articles:', error);
    throw error;
  } finally {
    await pool.end();
  }
}

addArticles().catch(console.error);