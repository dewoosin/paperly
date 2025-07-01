/**
 * ArticleId.ts
 * 
 * 기사 ID를 나타내는 Value Object
 */

import { ValidationError } from '../../shared/errors/index';

export class ArticleId {
  private readonly value: number;

  private constructor(id: number) {
    this.value = id;
  }

  public static create(id: number): ArticleId {
    if (!id || id <= 0) {
      throw new ValidationError('Invalid article ID');
    }

    return new ArticleId(id);
  }

  public static generate(): ArticleId {
    return new ArticleId(0);
  }

  public toNumber(): number {
    return this.value;
  }

  public toString(): string {
    return this.value.toString();
  }

  public equals(other: ArticleId): boolean {
    return this.value === other.value;
  }

  public isNew(): boolean {
    return this.value === 0;
  }
}
