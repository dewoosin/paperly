// apps/backend/src/shared/domain/entity.ts

import { v4 as uuidv4 } from 'uuid';

/**
 * 도메인 엔티티 기본 클래스
 * 
 * DDD의 Entity 패턴을 구현하는 추상 클래스
 * 모든 도메인 엔티티는 이 클래스를 상속받아야 합니다.
 */
export abstract class Entity<T> {
  protected _id: string;
  protected props: T;

  constructor(props: T, id?: string) {
    this._id = id || uuidv4();
    this.props = props;
  }

  /**
   * 엔티티 ID 반환
   */
  get id(): string {
    return this._id;
  }

  /**
   * 엔티티 동등성 비교
   * 
   * @param entity - 비교할 엔티티
   * @returns 동일한 엔티티 여부
   */
  equals(entity?: Entity<T>): boolean {
    if (!entity) {
      return false;
    }

    if (!(entity instanceof Entity)) {
      return false;
    }

    return this._id === entity._id;
  }

  /**
   * 엔티티를 영속성 계층에 저장하기 위한 순수 객체로 변환
   * 
   * @returns 순수 객체
   */
  toPersistence(): any {
    const props = { ...this.props } as any;
    
    // Value Object들을 primitive 타입으로 변환
    Object.keys(props).forEach(key => {
      const value = props[key];
      
      if (value && typeof value === 'object' && 'value' in value) {
        // Value Object인 경우 value 속성 추출
        props[key] = value.value;
      } else if (value && typeof value === 'object' && 'toPersistence' in value) {
        // toPersistence 메서드가 있는 경우 호출
        props[key] = value.toPersistence();
      }
    });

    return {
      id: this._id,
      ...props
    };
  }
}

/**
 * 집합 루트(Aggregate Root) 마커 인터페이스
 * 
 * DDD의 Aggregate Root를 표시하기 위한 인터페이스
 */
export interface AggregateRoot {
  // 마커 인터페이스이므로 메서드 정의 없음
}

/**
 * 도메인 이벤트 기본 인터페이스
 */
export interface DomainEvent {
  aggregateId: string;
  eventVersion: number;
  occurredAt: Date;
}