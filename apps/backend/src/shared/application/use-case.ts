// UseCase 인터페이스
export interface UseCase<Input, Output> {
  execute(input: Input): Promise<Output>;
}
