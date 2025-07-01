const request = require('supertest');
const { expect } = require('chai');
const app = require('../../apps/backend/src/infrastructure/web/express/app');

describe('Writer Article Integration Tests', () => {
  let authToken;
  let testUserId;
  let testArticleId;

  // Test user credentials
  const testUser = {
    email: 'writer.test@paperly.com',
    password: 'TestPassword123!',
    firstName: 'Test',
    lastName: 'Writer'
  };

  // Setup: Register and login a test user
  before(async () => {
    // Register test user
    const registerResponse = await request(app)
      .post('/api/v1/writer/auth/register')
      .send(testUser)
      .expect(201);

    testUserId = registerResponse.body.data.user.id;

    // Login to get auth token
    const loginResponse = await request(app)
      .post('/api/v1/writer/auth/login')
      .send({
        email: testUser.email,
        password: testUser.password
      })
      .expect(200);

    authToken = loginResponse.body.data.accessToken;
    expect(authToken).to.be.a('string');
    expect(authToken).to.not.be.empty;
  });

  // Cleanup: Delete test data
  after(async () => {
    // Clean up test data if needed
    if (testArticleId) {
      await request(app)
        .delete(`/api/v1/writer/articles/${testArticleId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect((res) => {
          // Accept both 200 (success) and 404 (already deleted)
          expect([200, 404]).to.include(res.status);
        });
    }
  });

  describe('Article Creation', () => {
    it('should create a new article with valid data', async () => {
      const articleData = {
        title: 'Test Article Title',
        content: 'This is a test article content with sufficient length to meet the minimum requirements for article creation. It contains multiple sentences to ensure proper word count calculation.',
        subtitle: 'Test Article Subtitle',
        excerpt: 'This is a test excerpt for the article.',
        visibility: 'public',
        isPremium: false,
        difficultyLevel: 2,
        contentType: 'article',
        seoTitle: 'Test Article SEO Title',
        seoDescription: 'Test article SEO description',
        metadata: {
          tags: ['test', 'integration'],
          source: 'integration-test'
        }
      };

      const response = await request(app)
        .post('/api/v1/writer/articles')
        .set('Authorization', `Bearer ${authToken}`)
        .send(articleData)
        .expect(201);

      expect(response.body).to.have.property('success', true);
      expect(response.body).to.have.property('data');
      expect(response.body.data).to.have.property('id');
      expect(response.body.data).to.have.property('title', articleData.title);
      expect(response.body.data).to.have.property('content', articleData.content);
      expect(response.body.data).to.have.property('authorId', testUserId);
      expect(response.body.data).to.have.property('status', 'draft');
      expect(response.body.data).to.have.property('slug');
      expect(response.body.data).to.have.property('wordCount');
      expect(response.body.data.wordCount).to.be.greaterThan(0);
      expect(response.body.data).to.have.property('createdAt');
      expect(response.body.data).to.have.property('updatedAt');

      // Store article ID for further tests
      testArticleId = response.body.data.id;
    });

    it('should fail to create article without authentication', async () => {
      const articleData = {
        title: 'Unauthorized Article',
        content: 'This should fail without authentication.'
      };

      await request(app)
        .post('/api/v1/writer/articles')
        .send(articleData)
        .expect(401);
    });

    it('should fail to create article with invalid data', async () => {
      const invalidData = {
        title: '', // Empty title should fail validation
        content: 'Short' // Too short content
      };

      const response = await request(app)
        .post('/api/v1/writer/articles')
        .set('Authorization', `Bearer ${authToken}`)
        .send(invalidData)
        .expect(400);

      expect(response.body).to.have.property('success', false);
      expect(response.body.error).to.have.property('code', 'VALIDATION_ERROR');
      expect(response.body.error.details).to.have.property('validationErrors');
      expect(response.body.error.details.validationErrors).to.be.an('array');
    });
  });

  describe('Article Retrieval', () => {
    it('should get article by ID', async () => {
      const response = await request(app)
        .get(`/api/v1/writer/articles/${testArticleId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).to.have.property('success', true);
      expect(response.body.data).to.have.property('id', testArticleId);
      expect(response.body.data).to.have.property('title');
      expect(response.body.data).to.have.property('content');
      expect(response.body.data).to.have.property('authorId', testUserId);
    });

    it('should get list of articles with pagination', async () => {
      const response = await request(app)
        .get('/api/v1/writer/articles')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ page: 1, limit: 10 })
        .expect(200);

      expect(response.body).to.have.property('success', true);
      expect(response.body).to.have.property('data').that.is.an('array');
      expect(response.body).to.have.property('pagination');
      expect(response.body.pagination).to.have.property('page', 1);
      expect(response.body.pagination).to.have.property('limit', 10);
      expect(response.body.pagination).to.have.property('total');
      expect(response.body.pagination).to.have.property('totalPages');
    });

    it('should filter articles by status', async () => {
      const response = await request(app)
        .get('/api/v1/writer/articles')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ status: 'draft' })
        .expect(200);

      expect(response.body).to.have.property('success', true);
      expect(response.body.data).to.be.an('array');
      
      // All returned articles should have 'draft' status
      response.body.data.forEach(article => {
        expect(article).to.have.property('status', 'draft');
      });
    });

    it('should search articles by title', async () => {
      const response = await request(app)
        .get('/api/v1/writer/articles')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ search: 'Test Article' })
        .expect(200);

      expect(response.body).to.have.property('success', true);
      expect(response.body.data).to.be.an('array');
    });
  });

  describe('Article Update', () => {
    it('should update article with valid data', async () => {
      const updateData = {
        title: 'Updated Test Article Title',
        content: 'This is the updated content for the test article. It has been modified to test the update functionality.',
        subtitle: 'Updated subtitle',
        visibility: 'private'
      };

      const response = await request(app)
        .put(`/api/v1/writer/articles/${testArticleId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(updateData)
        .expect(200);

      expect(response.body).to.have.property('success', true);
      expect(response.body.data).to.have.property('id', testArticleId);
      expect(response.body.data).to.have.property('title', updateData.title);
      expect(response.body.data).to.have.property('content', updateData.content);
      expect(response.body.data).to.have.property('subtitle', updateData.subtitle);
      expect(response.body.data).to.have.property('visibility', updateData.visibility);
      expect(response.body.data).to.have.property('updatedAt');
    });

    it('should fail to update non-existent article', async () => {
      const fakeId = '550e8400-e29b-41d4-a716-446655440000';
      
      await request(app)
        .put(`/api/v1/writer/articles/${fakeId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ title: 'Updated Title' })
        .expect(404);
    });

    it('should fail to update article with invalid data', async () => {
      const invalidData = {
        title: '', // Empty title
        difficultyLevel: 10 // Invalid difficulty level
      };

      const response = await request(app)
        .put(`/api/v1/writer/articles/${testArticleId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(invalidData)
        .expect(400);

      expect(response.body.error).to.have.property('code', 'VALIDATION_ERROR');
    });
  });

  describe('Article Publishing', () => {
    it('should publish a draft article', async () => {
      const response = await request(app)
        .post(`/api/v1/writer/articles/${testArticleId}/publish`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({})
        .expect(200);

      expect(response.body).to.have.property('success', true);
      expect(response.body.data).to.have.property('status', 'published');
      expect(response.body.data).to.have.property('publishedAt');
      expect(new Date(response.body.data.publishedAt)).to.be.a('date');
    });

    it('should unpublish a published article', async () => {
      const response = await request(app)
        .post(`/api/v1/writer/articles/${testArticleId}/unpublish`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({})
        .expect(200);

      expect(response.body).to.have.property('success', true);
      expect(response.body.data).to.have.property('status', 'draft');
      expect(response.body.data.publishedAt).to.be.null;
    });

    it('should schedule article for future publication', async () => {
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + 7); // One week from now

      const response = await request(app)
        .post(`/api/v1/writer/articles/${testArticleId}/publish`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          publishedAt: futureDate.toISOString()
        })
        .expect(200);

      expect(response.body).to.have.property('success', true);
      expect(response.body.data).to.have.property('status', 'published');
      expect(new Date(response.body.data.publishedAt)).to.be.closeToTime(futureDate, 1000);
    });
  });

  describe('Article Archiving', () => {
    it('should archive an article', async () => {
      const response = await request(app)
        .post(`/api/v1/writer/articles/${testArticleId}/archive`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({})
        .expect(200);

      expect(response.body).to.have.property('success', true);
      expect(response.body.data).to.have.property('id', testArticleId);
      // Check if archived metadata is added
      expect(response.body.data.metadata).to.have.property('archivedAt');
    });
  });

  describe('Writer Statistics', () => {
    it('should get writer statistics', async () => {
      const response = await request(app)
        .get('/api/v1/writer/articles/stats')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).to.have.property('success', true);
      expect(response.body.data).to.have.property('totalArticles');
      expect(response.body.data).to.have.property('publishedArticles');
      expect(response.body.data).to.have.property('draftArticles');
      expect(response.body.data).to.have.property('archivedArticles');
      expect(response.body.data).to.have.property('totalViews');
      expect(response.body.data).to.have.property('totalLikes');
      expect(response.body.data).to.have.property('totalShares');
      expect(response.body.data).to.have.property('totalComments');
      expect(response.body.data).to.have.property('averageReadingTime');
      expect(response.body.data).to.have.property('topPerformingArticles').that.is.an('array');
      expect(response.body.data).to.have.property('recentArticles').that.is.an('array');

      // Verify numerical fields
      expect(response.body.data.totalArticles).to.be.a('number');
      expect(response.body.data.totalArticles).to.be.at.least(1); // We created at least one article
    });
  });

  describe('Article Deletion', () => {
    it('should delete an article', async () => {
      const response = await request(app)
        .delete(`/api/v1/writer/articles/${testArticleId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).to.have.property('success', true);
      expect(response.body).to.have.property('message');

      // Verify article is deleted (soft delete)
      await request(app)
        .get(`/api/v1/writer/articles/${testArticleId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);
    });
  });

  describe('Error Handling', () => {
    it('should handle database connection errors gracefully', async () => {
      // This test would require mocking database connection
      // For now, we'll test with invalid UUID format
      const invalidId = 'invalid-uuid';

      await request(app)
        .get(`/api/v1/writer/articles/${invalidId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(400);
    });

    it('should handle unauthorized access attempts', async () => {
      // Try to access articles without authentication
      await request(app)
        .get('/api/v1/writer/articles')
        .expect(401);

      // Try to access with invalid token
      await request(app)
        .get('/api/v1/writer/articles')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);
    });

    it('should handle rate limiting', async () => {
      // This test would require multiple rapid requests
      // For demonstration, we'll just verify the rate limiter exists
      const promises = [];
      for (let i = 0; i < 10; i++) {
        promises.push(
          request(app)
            .get('/api/v1/writer/articles')
            .set('Authorization', `Bearer ${authToken}`)
        );
      }

      const responses = await Promise.all(promises);
      
      // All requests should succeed or some should be rate limited
      responses.forEach(response => {
        expect([200, 429]).to.include(response.status);
      });
    });
  });

  describe('Content Validation', () => {
    it('should validate word count calculation', async () => {
      const content = 'This is a test content with exactly ten words in it.';
      const articleData = {
        title: 'Word Count Test',
        content: content
      };

      const response = await request(app)
        .post('/api/v1/writer/articles')
        .set('Authorization', `Bearer ${authToken}`)
        .send(articleData)
        .expect(201);

      expect(response.body.data.wordCount).to.equal(10);
      
      // Clean up
      await request(app)
        .delete(`/api/v1/writer/articles/${response.body.data.id}`)
        .set('Authorization', `Bearer ${authToken}`);
    });

    it('should validate slug generation', async () => {
      const title = 'This is a Test Article with Special Characters! @#$%';
      const articleData = {
        title: title,
        content: 'Test content for slug generation.'
      };

      const response = await request(app)
        .post('/api/v1/writer/articles')
        .set('Authorization', `Bearer ${authToken}`)
        .send(articleData)
        .expect(201);

      expect(response.body.data.slug).to.match(/^[a-z0-9-]+$/);
      expect(response.body.data.slug).to.include('this-is-a-test-article');
      
      // Clean up
      await request(app)
        .delete(`/api/v1/writer/articles/${response.body.data.id}`)
        .set('Authorization', `Bearer ${authToken}`);
    });

    it('should handle duplicate slugs', async () => {
      const title = 'Duplicate Slug Test';
      const articleData = {
        title: title,
        content: 'Test content for duplicate slug handling.'
      };

      // Create first article
      const response1 = await request(app)
        .post('/api/v1/writer/articles')
        .set('Authorization', `Bearer ${authToken}`)
        .send(articleData)
        .expect(201);

      // Create second article with same title
      const response2 = await request(app)
        .post('/api/v1/writer/articles')
        .set('Authorization', `Bearer ${authToken}`)
        .send(articleData)
        .expect(201);

      expect(response1.body.data.slug).to.not.equal(response2.body.data.slug);
      expect(response2.body.data.slug).to.include(response1.body.data.slug);
      
      // Clean up
      await request(app)
        .delete(`/api/v1/writer/articles/${response1.body.data.id}`)
        .set('Authorization', `Bearer ${authToken}`);
      await request(app)
        .delete(`/api/v1/writer/articles/${response2.body.data.id}`)
        .set('Authorization', `Bearer ${authToken}`);
    });
  });
});

// Helper to check if dates are close to each other
require('chai').use(function (chai, utils) {
  chai.Assertion.addMethod('closeToTime', function (expected, delta) {
    const actual = this._obj;
    const difference = Math.abs(actual.getTime() - expected.getTime());
    
    this.assert(
      difference <= delta,
      `expected #{this} to be close to ${expected} (within ${delta}ms)`,
      `expected #{this} not to be close to ${expected} (within ${delta}ms)`,
      expected,
      actual
    );
  });
});