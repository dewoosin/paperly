/**
 * Platform-specific configuration
 * 
 * Automatically detects the environment (WSL, macOS, Linux) and
 * provides appropriate database host configuration
 */

import { execSync } from 'child_process';
import os from 'os';

export interface PlatformConfig {
  isWSL: boolean;
  isMacOS: boolean;
  isLinux: boolean;
  databaseHost: string;
  redisHost: string;
}

/**
 * Detects if running in WSL environment
 */
function isWSL(): boolean {
  try {
    const osRelease = execSync('cat /proc/version', { encoding: 'utf8' });
    return osRelease.toLowerCase().includes('microsoft');
  } catch {
    return false;
  }
}

/**
 * Gets the host IP address for WSL to connect to Windows Docker
 */
function getWSLHostIP(): string {
  try {
    const hostIP = execSync("ip route | grep default | awk '{print $3}'", { 
      encoding: 'utf8' 
    }).trim();
    return hostIP || '172.28.144.1'; // fallback to your current WSL IP
  } catch {
    return '172.28.144.1';
  }
}

/**
 * Gets platform-specific configuration
 */
export function getPlatformConfig(): PlatformConfig {
  const platform = os.platform();
  const wsl = isWSL();
  const macOS = platform === 'darwin';
  const linux = platform === 'linux' && !wsl;

  let databaseHost: string;
  let redisHost: string;

  if (wsl) {
    // WSL: Use Windows host IP
    const hostIP = getWSLHostIP();
    databaseHost = hostIP;
    redisHost = hostIP;
    console.log(`🐧 WSL detected, using Windows host IP: ${hostIP}`);
  } else if (macOS) {
    // macOS: Use localhost (Docker Desktop forwards ports)
    databaseHost = 'localhost';
    redisHost = 'localhost';
    console.log('🍎 macOS detected, using localhost');
  } else {
    // Linux or other: Use localhost
    databaseHost = 'localhost';
    redisHost = 'localhost';
    console.log('🐧 Linux detected, using localhost');
  }

  // Allow environment variable override
  if (process.env.DB_HOST_OVERRIDE) {
    databaseHost = process.env.DB_HOST_OVERRIDE;
    console.log(`⚙️  Database host overridden: ${databaseHost}`);
  }
  if (process.env.REDIS_HOST_OVERRIDE) {
    redisHost = process.env.REDIS_HOST_OVERRIDE;
    console.log(`⚙️  Redis host overridden: ${redisHost}`);
  }

  return {
    isWSL: wsl,
    isMacOS: macOS,
    isLinux: linux,
    databaseHost,
    redisHost
  };
}