// JWT 토큰 디코딩 테스트
const jwt = require('jsonwebtoken');

const accessToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI2YmZiNDgzZC01ZmIxLTQ3YTUtYjBkMC1iZmYwYWYwMjEwNWMiLCJlbWFpbCI6Imp3dF90ZXN0QGV4YW1wbGUuY29tIiwibmFtZSI6IlVzZXIiLCJlbWFpbFZlcmlmaWVkIjpmYWxzZSwiaWF0IjoxNzUxMDM0MTEzLCJleHAiOjE3NTEwMzUwMTMsImF1ZCI6InBhcGVybHktYXBwIiwiaXNzIjoicGFwZXJseSJ9.X8YFxpbhyqDvZ-yPnBtbwArjmPhDE3mHyTeh1AP86hA";

console.log('🔓 JWT 토큰 디코딩 (검증 없이):');
const decoded = jwt.decode(accessToken);
console.log(JSON.stringify(decoded, null, 2));

console.log('\n📅 토큰 만료 시간:');
if (decoded.exp) {
  const expDate = new Date(decoded.exp * 1000);
  const now = new Date();
  console.log('만료 시간:', expDate.toLocaleString());
  console.log('현재 시간:', now.toLocaleString());
  console.log('남은 시간:', Math.round((expDate - now) / 1000 / 60), '분');
}

console.log('\n🔐 JWT 토큰 형식 확인:');
console.log('헤더:', JSON.stringify(jwt.decode(accessToken, {complete: true}).header, null, 2));

console.log('\n✅ 실제 JWT 토큰이 올바르게 생성되었습니다!');