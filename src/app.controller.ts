import { Controller, Get, Header } from '@nestjs/common';
import { AppService } from './app.service';
import * as fs from 'fs';
import * as path from 'path';

@Controller()
export class AppController {
  private cachedPrivacyHtml: string | null = null;

  constructor(private readonly appService: AppService) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('privacy')
  @Header('Content-Type', 'text/html')
  getPrivacyPolicy(): string {
    if (this.cachedPrivacyHtml) {
      return this.cachedPrivacyHtml;
    }

    const possiblePaths = [
      path.join(process.cwd(), 'dashboard', 'public', 'privacy.html'),
      path.join(__dirname, '..', 'dashboard', 'public', 'privacy.html'),
      path.join(__dirname, '..', '..', 'dashboard', 'public', 'privacy.html'),
    ];

    for (const filePath of possiblePaths) {
      try {
        if (fs.existsSync(filePath)) {
          this.cachedPrivacyHtml = fs.readFileSync(filePath, 'utf8');
          return this.cachedPrivacyHtml;
        }
      } catch (err) {
        // Fall through to next path or default copy
      }
    }

    // Direct fallback inline HTML to guarantee the page always loads
    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>QueueCare - Privacy Policy</title>
  <style>
    body { background: #020617; color: #cbd5e1; font-family: sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
    .card { background: #0f172a; padding: 2rem; border-radius: 12px; border: 1px solid #1e293b; max-width: 600px; text-align: center; }
    h1 { color: #fff; margin-top: 0; }
    a { color: #2dd4bf; text-decoration: none; }
  </style>
</head>
<body>
  <div class="card">
    <h1>QueueCare Privacy Policy</h1>
    <p>We are updating our policies. Please contact <a href="mailto:support@queuecare.app">support@queuecare.app</a> for details or try again shortly.</p>
  </div>
</body>
</html>`;
  }
}

