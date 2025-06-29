import { injectable, inject } from 'tsyringe';
import { Pool } from 'pg';
import { v4 as uuidv4 } from 'uuid';
import { Logger } from '../logging/Logger';

const logger = new Logger('TagRepository');

export interface Tag {
  id: string;
  name: string;
  display_name: string;
  description?: string;
  usage_count: number;
  is_active: boolean;
  is_trending: boolean;
  trending_score?: number;
  ai_metadata?: any;
  created_at: Date;
  updated_at: Date;
}

export interface ITagRepository {
  findAll(): Promise<Tag[]>;
  findById(id: string): Promise<Tag | null>;
  findByName(name: string): Promise<Tag | null>;
  search(query?: string): Promise<Tag[]>;
  create(data: Partial<Tag>): Promise<Tag>;
  update(id: string, data: Partial<Tag>): Promise<Tag | null>;
  delete(id: string): Promise<boolean>;
  findOrCreate(names: string[]): Promise<Tag[]>;
  incrementUsageCount(id: string): Promise<void>;
}

@injectable()
export class TagRepository implements ITagRepository {
  constructor(
    @inject('DatabasePool') private readonly pool: Pool
  ) {}

  async findAll(): Promise<Tag[]> {
    try {
      const query = `
        SELECT * FROM paperly.tags 
        WHERE is_active = true 
        ORDER BY usage_count DESC, name ASC
      `;
      const result = await this.pool.query(query);
      return result.rows;
    } catch (error) {
      logger.error('Error finding all tags:', error);
      throw error;
    }
  }

  async findById(id: string): Promise<Tag | null> {
    try {
      const query = 'SELECT * FROM paperly.tags WHERE id = $1';
      const result = await this.pool.query(query, [id]);
      return result.rows.length > 0 ? result.rows[0] : null;
    } catch (error) {
      logger.error('Error finding tag by id:', error);
      throw error;
    }
  }

  async findByName(name: string): Promise<Tag | null> {
    try {
      const query = 'SELECT * FROM paperly.tags WHERE name = $1';
      const result = await this.pool.query(query, [name.toLowerCase()]);
      return result.rows.length > 0 ? result.rows[0] : null;
    } catch (error) {
      logger.error('Error finding tag by name:', error);
      throw error;
    }
  }

  async search(query?: string): Promise<Tag[]> {
    try {
      if (!query) {
        return await this.findAll();
      }

      const searchQuery = `%${query.toLowerCase()}%`;
      const sql = `
        SELECT * FROM paperly.tags 
        WHERE is_active = true 
        AND (LOWER(name) LIKE $1 OR LOWER(display_name) LIKE $1)
        ORDER BY usage_count DESC
        LIMIT 20
      `;
      const result = await this.pool.query(sql, [searchQuery]);
      return result.rows;
    } catch (error) {
      logger.error('Error searching tags:', error);
      throw error;
    }
  }

  async create(data: Partial<Tag>): Promise<Tag> {
    try {
      const id = uuidv4();
      const now = new Date();
      
      const query = `
        INSERT INTO paperly.tags (
          id, name, display_name, description, usage_count, 
          is_active, is_trending, trending_score, ai_metadata, 
          created_at, updated_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
        RETURNING *
      `;
      
      const values = [
        id,
        data.name?.toLowerCase(),
        data.display_name || data.name,
        data.description || null,
        data.usage_count || 0,
        data.is_active !== undefined ? data.is_active : true,
        data.is_trending || false,
        data.trending_score || null,
        data.ai_metadata ? JSON.stringify(data.ai_metadata) : null,
        now,
        now
      ];
      
      const result = await this.pool.query(query, values);
      return result.rows[0];
    } catch (error) {
      logger.error('Error creating tag:', error);
      throw error;
    }
  }

  async update(id: string, data: Partial<Tag>): Promise<Tag | null> {
    try {
      const now = new Date();
      
      const query = `
        UPDATE paperly.tags SET
          name = COALESCE($2, name),
          display_name = COALESCE($3, display_name),
          description = COALESCE($4, description),
          usage_count = COALESCE($5, usage_count),
          is_active = COALESCE($6, is_active),
          is_trending = COALESCE($7, is_trending),
          trending_score = COALESCE($8, trending_score),
          ai_metadata = COALESCE($9, ai_metadata),
          updated_at = $10
        WHERE id = $1
        RETURNING *
      `;
      
      const values = [
        id,
        data.name?.toLowerCase() || null,
        data.display_name || null,
        data.description || null,
        data.usage_count || null,
        data.is_active !== undefined ? data.is_active : null,
        data.is_trending !== undefined ? data.is_trending : null,
        data.trending_score || null,
        data.ai_metadata ? JSON.stringify(data.ai_metadata) : null,
        now
      ];
      
      const result = await this.pool.query(query, values);
      return result.rows.length > 0 ? result.rows[0] : null;
    } catch (error) {
      logger.error('Error updating tag:', error);
      throw error;
    }
  }

  async delete(id: string): Promise<boolean> {
    try {
      const query = 'DELETE FROM paperly.tags WHERE id = $1';
      const result = await this.pool.query(query, [id]);
      return result.rowCount > 0;
    } catch (error) {
      logger.error('Error deleting tag:', error);
      throw error;
    }
  }

  async findOrCreate(names: string[]): Promise<Tag[]> {
    const tags: Tag[] = [];
    
    for (const name of names) {
      const normalizedName = name.toLowerCase().trim();
      let tag = await this.findByName(normalizedName);
      
      if (!tag) {
        tag = await this.create({
          name: normalizedName,
          display_name: name.trim(),
          usage_count: 0,
          is_active: true
        });
      }
      
      tags.push(tag);
    }
    
    return tags;
  }

  async incrementUsageCount(id: string): Promise<void> {
    try {
      const query = `
        UPDATE paperly.tags SET
          usage_count = usage_count + 1,
          updated_at = $2
        WHERE id = $1
      `;
      await this.pool.query(query, [id, new Date()]);
    } catch (error) {
      logger.error('Error incrementing usage count:', error);
      throw error;
    }
  }
}