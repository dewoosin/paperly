/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000',
    NEXT_PUBLIC_WEBSOCKET_URL: process.env.NEXT_PUBLIC_WEBSOCKET_URL || 'ws://localhost:3000',
  },
  async redirects() {
    return [
      {
        source: '/',
        destination: '/dashboard',
        permanent: false,
      },
    ]
  },
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000'}/api/:path*`,
      },
    ]
  },
}

module.exports = nextConfig