/**
 * CategoryId.ts
 * 
 * 카테고리 ID를 나타내는 Value Object
 */

import { ValidationError } from '../../shared/errors/index';

export class CategoryId {
  private readonly value: number;

  private constructor(id: number) {
    this.value = id;
  }

  public static create(id: number): CategoryId {
    if (!id || id <= 0) {
      throw new ValidationError('Invalid category ID');
    }

    return new CategoryId(id);
  }

  public toNumber(): number {
    return this.value;
  }

  public toString(): string {
    return this.value.toString();
  }

  public equals(other: CategoryId): boolean {
    return this.value === other.value;
  }
}
