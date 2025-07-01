/// Paperly Backend - Value Objects Index
/// 
/// 이 파일은 모든 Value Object를 중앙에서 관리하고 export하는 인덱스 파일입니다.
/// Value Object는 도메인의 핵심 개념을 나타내는 불변 객체들입니다.

// 기본 Value Objects
export { Email } from './email.vo';
export { Password } from './password.vo';
export { UserId } from './user-id.vo';

// 기타 Value Objects (레거시 파일들도 포함)
export { ArticleId } from './ArticleId';
export { CategoryId } from './CategoryId';

// 인증 관련 Value Objects
export * from './auth.value-objects';