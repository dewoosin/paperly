import { NextRequest, NextResponse } from 'next/server'

/**
 * 관리자 로그인 API 라우트
 * 
 * Next.js API Routes를 통해 백엔드 관리자 인증 API와 통신합니다.
 * 프록시 역할을 하여 클라이언트의 요청을 백엔드로 전달합니다.
 */

// 백엔드 API 기본 URL
const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:3001'
const API_VERSION = process.env.API_VERSION || 'v1'

export async function POST(request: NextRequest) {
  try {
    // 요청 본문 파싱
    const body = await request.json()
    
    // 기본 검증
    if (!body.email || !body.password) {
      return NextResponse.json(
        {
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: '이메일과 비밀번호는 필수입니다'
          }
        },
        { status: 400 }
      )
    }

    // 클라이언트 정보 수집
    const clientIP = request.headers.get('x-forwarded-for') || 
                     request.headers.get('x-real-ip') || 
                     'unknown'
    const userAgent = request.headers.get('user-agent') || 'unknown'
    const deviceId = request.headers.get('x-device-id')

    // 백엔드 API 요청 준비
    const backendURL = `${BACKEND_URL}/api/${API_VERSION}/admin/auth/login`
    
    const requestBody = {
      email: body.email,
      password: body.password
    }

    const requestHeaders: Record<string, string> = {
      'Content-Type': 'application/json',
      'User-Agent': userAgent,
      'X-Forwarded-For': clientIP,
      'X-Real-IP': clientIP
    }

    if (deviceId) {
      requestHeaders['X-Device-ID'] = deviceId
    }

    // 백엔드 API 호출
    const backendResponse = await fetch(backendURL, {
      method: 'POST',
      headers: requestHeaders,
      body: JSON.stringify(requestBody),
    })

    const responseData = await backendResponse.json()

    // 응답 처리
    if (!backendResponse.ok) {
      // 백엔드 에러를 그대로 전달
      return NextResponse.json(responseData, { 
        status: backendResponse.status 
      })
    }

    // 성공 응답 처리
    const response = NextResponse.json(responseData)

    // Refresh 토큰을 쿠키로 설정 (백엔드에서 Set-Cookie 헤더가 있는 경우)
    const setCookieHeader = backendResponse.headers.get('set-cookie')
    if (setCookieHeader) {
      response.headers.set('Set-Cookie', setCookieHeader)
    }

    return response

  } catch (error) {
    console.error('관리자 로그인 API 오류:', error)

    // 네트워크 오류 또는 백엔드 연결 실패
    if (error instanceof TypeError && error.message.includes('fetch')) {
      return NextResponse.json(
        {
          success: false,
          error: {
            code: 'BACKEND_CONNECTION_ERROR',
            message: '백엔드 서버에 연결할 수 없습니다. 잠시 후 다시 시도해주세요.'
          }
        },
        { status: 503 }
      )
    }

    // 기타 서버 오류
    return NextResponse.json(
      {
        success: false,
        error: {
          code: 'INTERNAL_SERVER_ERROR',
          message: '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.'
        }
      },
      { status: 500 }
    )
  }
}

// OPTIONS 메서드 처리 (CORS Preflight)
export async function OPTIONS(request: NextRequest) {
  return new NextResponse(null, {
    status: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Device-ID',
    },
  })
}