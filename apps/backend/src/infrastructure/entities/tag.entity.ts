import { Entity, Column, PrimaryColumn, CreateDateColumn, UpdateDateColumn, ManyToMany } from 'typeorm';
import { ArticleEntity } from './article.entity';

@Entity({ name: 'tags', schema: 'paperly' })
export class TagEntity {
  @PrimaryColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 50, unique: true })
  name: string;

  @Column({ type: 'varchar', length: 50 })
  display_name: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'int', default: 0 })
  usage_count: number;

  @Column({ type: 'boolean', default: true })
  is_active: boolean;

  @Column({ type: 'boolean', default: false })
  is_trending: boolean;

  @Column({ type: 'float', nullable: true })
  trending_score: number;

  @Column({ type: 'jsonb', nullable: true })
  ai_metadata: any;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;

  // Relations
  @ManyToMany(() => ArticleEntity, (article) => article.tags)
  articles: ArticleEntity[];
}