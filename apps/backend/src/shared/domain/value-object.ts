// Value Object 베이스 클래스
export abstract class ValueObject<T> {
  protected readonly value: T;

  protected constructor(value: T) {
    this.value = Object.freeze(value);
  }

  equals(vo?: ValueObject<T>): boolean {
    if (vo === null || vo === undefined) {
      return false;
    }
    return JSON.stringify(this.value) === JSON.stringify(vo.value);
  }
}
