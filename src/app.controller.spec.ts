import { Test, TestingModule } from '@nestjs/testing';
import { AppController } from './app.controller';
import { AppService } from './app.service';

describe('AppController', () => {
  let appController: AppController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [AppService],
    }).compile();

    appController = app.get<AppController>(AppController);
  });

  describe('root', () => {
    it('should return "Hello World!"', () => {
      expect(appController.getHello()).toBe('Hello World!');
    });
  });

  describe('privacy', () => {
    it('should return Privacy Policy HTML string', () => {
      const html = appController.getPrivacyPolicy();
      expect(html).toContain('<!DOCTYPE html>');
      expect(html).toContain('Privacy Policy');
      expect(html).toContain('QueueCare');
    });
  });
});

