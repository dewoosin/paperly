import { injectable, inject } from 'tsyringe';
import { Pool } from 'pg';
import { v4 as uuidv4 } from 'uuid';
import { Logger } from '../logging/Logger';

const logger = new Logger('CategoryRepository');

export interface Category {
  id: string;
  name: string;
  slug: string;
  description?: string;
  parent_id?: string;
  icon_name?: string;
  color_code?: string;
  order_index: number;
  is_active: boolean;
  ai_keywords?: any;
  metadata?: any;
  created_at: Date;
  updated_at: Date;
}

export interface ICategoryRepository {
  findAll(): Promise<Category[]>;
  findById(id: string): Promise<Category | null>;
  findBySlug(slug: string): Promise<Category | null>;
  create(data: Partial<Category>): Promise<Category>;
  update(id: string, data: Partial<Category>): Promise<Category | null>;
  delete(id: string): Promise<boolean>;
  findWithArticleCount(): Promise<any[]>;
}

@injectable()
export class CategoryRepository implements ICategoryRepository {
  constructor(
    @inject('DatabasePool') private readonly pool: Pool
  ) {}

  async findAll(): Promise<Category[]> {
    try {
      const query = `
        SELECT * FROM paperly.categories 
        WHERE is_active = true 
        ORDER BY order_index ASC, name ASC
      `;
      const result = await this.pool.query(query);
      return result.rows;
    } catch (error) {
      logger.error('Error finding all categories:', error);
      throw error;
    }
  }

  async findById(id: string): Promise<Category | null> {
    try {
      const query = 'SELECT * FROM paperly.categories WHERE id = $1';
      const result = await this.pool.query(query, [id]);
      return result.rows.length > 0 ? result.rows[0] : null;
    } catch (error) {
      logger.error('Error finding category by id:', error);
      throw error;
    }
  }

  async findBySlug(slug: string): Promise<Category | null> {
    try {
      const query = 'SELECT * FROM paperly.categories WHERE slug = $1';
      const result = await this.pool.query(query, [slug]);
      return result.rows.length > 0 ? result.rows[0] : null;
    } catch (error) {
      logger.error('Error finding category by slug:', error);
      throw error;
    }
  }

  async create(data: Partial<Category>): Promise<Category> {
    try {
      const id = uuidv4();
      const now = new Date();
      
      const query = `
        INSERT INTO paperly.categories (
          id, name, slug, description, parent_id, icon_name, 
          color_code, order_index, is_active, ai_keywords, 
          metadata, created_at, updated_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
        RETURNING *
      `;
      
      const values = [
        id,
        data.name,
        data.slug,
        data.description || null,
        data.parent_id || null,
        data.icon_name || null,
        data.color_code || null,
        data.order_index || 0,
        data.is_active !== undefined ? data.is_active : true,
        data.ai_keywords ? JSON.stringify(data.ai_keywords) : null,
        data.metadata ? JSON.stringify(data.metadata) : null,
        now,
        now
      ];
      
      const result = await this.pool.query(query, values);
      return result.rows[0];
    } catch (error) {
      logger.error('Error creating category:', error);
      throw error;
    }
  }

  async update(id: string, data: Partial<Category>): Promise<Category | null> {
    try {
      const now = new Date();
      
      const query = `
        UPDATE paperly.categories SET
          name = COALESCE($2, name),
          slug = COALESCE($3, slug),
          description = COALESCE($4, description),
          parent_id = COALESCE($5, parent_id),
          icon_name = COALESCE($6, icon_name),
          color_code = COALESCE($7, color_code),
          order_index = COALESCE($8, order_index),
          is_active = COALESCE($9, is_active),
          ai_keywords = COALESCE($10, ai_keywords),
          metadata = COALESCE($11, metadata),
          updated_at = $12
        WHERE id = $1
        RETURNING *
      `;
      
      const values = [
        id,
        data.name || null,
        data.slug || null,
        data.description || null,
        data.parent_id || null,
        data.icon_name || null,
        data.color_code || null,
        data.order_index || null,
        data.is_active !== undefined ? data.is_active : null,
        data.ai_keywords ? JSON.stringify(data.ai_keywords) : null,
        data.metadata ? JSON.stringify(data.metadata) : null,
        now
      ];
      
      const result = await this.pool.query(query, values);
      return result.rows.length > 0 ? result.rows[0] : null;
    } catch (error) {
      logger.error('Error updating category:', error);
      throw error;
    }
  }

  async delete(id: string): Promise<boolean> {
    try {
      const query = 'DELETE FROM paperly.categories WHERE id = $1';
      const result = await this.pool.query(query, [id]);
      return result.rowCount > 0;
    } catch (error) {
      logger.error('Error deleting category:', error);
      throw error;
    }
  }

  async findWithArticleCount(): Promise<any[]> {
    try {
      const query = `
        SELECT 
          c.id,
          c.name,
          c.slug,
          c.description,
          c.icon_name,
          c.color_code,
          c.parent_id,
          COUNT(DISTINCT a.id) as article_count
        FROM paperly.categories c
        LEFT JOIN paperly.articles a ON c.id = a.category_id AND a.status = 'published'
        WHERE c.is_active = true
        GROUP BY c.id, c.name, c.slug, c.description, c.icon_name, c.color_code, c.parent_id
        ORDER BY c.order_index ASC, c.name ASC
      `;
      
      const result = await this.pool.query(query);
      return result.rows;
    } catch (error) {
      logger.error('Error finding categories with article count:', error);
      throw error;
    }
  }
}