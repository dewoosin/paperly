/**
 * Email sending test script
 * 
 * Tests the email service functionality
 */

import { RealEmailService } from '../src/infrastructure/email/real-email.service';

async function testEmailService() {
  console.log('\n📧 Testing Email Service...\n');

  const emailService = new RealEmailService();
  
  // Wait a bit for initialization
  await new Promise(resolve => setTimeout(resolve, 2000));

  try {
    console.log('🧪 Testing verification email...');
    await emailService.sendVerificationEmail(
      'test@example.com',
      'Test User',
      'test_verification_token_123'
    );
    console.log('✅ Verification email sent successfully!\n');

    console.log('🧪 Testing welcome email...');
    await emailService.sendWelcomeEmail(
      'test@example.com',
      'Test User'
    );
    console.log('✅ Welcome email sent successfully!\n');

    console.log('🧪 Testing password reset email...');
    await emailService.sendPasswordResetEmail(
      'test@example.com',
      'Test User',
      'test_reset_token_456'
    );
    console.log('✅ Password reset email sent successfully!\n');

    console.log('🎉 All email tests passed!');
    
  } catch (error) {
    console.error('❌ Email test failed:', error);
    process.exit(1);
  }
}

// Run the test
testEmailService().catch(console.error);