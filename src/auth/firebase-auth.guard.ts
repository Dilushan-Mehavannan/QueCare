import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

interface DecodedToken {
  uid: string;
  email?: string;
  name?: string;
  role?: string;
}

interface CustomRequest {
  headers: {
    authorization?: string;
  };
  user?: {
    uid: string;
    email: string;
    name: string;
    role: string;
  };
}

@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  private firebaseInitialized = false;

  constructor(private configService: ConfigService) {
    const projectId = this.configService.get<string>('FIREBASE_PROJECT_ID');
    const clientEmail = this.configService.get<string>('FIREBASE_CLIENT_EMAIL');
    const privateKey = this.configService.get<string>('FIREBASE_PRIVATE_KEY');

    if (projectId && clientEmail && privateKey) {
      try {
        if (admin.apps.length === 0) {
          admin.initializeApp({
            credential: admin.credential.cert({
              projectId,
              clientEmail,
              privateKey: privateKey.replace(/\\n/g, '\n'),
            }),
          });
        }
        this.firebaseInitialized = true;
        console.log('Firebase Admin initialized successfully.');
      } catch (error) {
        console.error('Failed to initialize Firebase Admin:', error);
      }
    } else {
      console.warn(
        'Firebase Admin credentials not fully configured. Running in Development / Mock Mode.',
      );
    }
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<CustomRequest>();
    const authHeader = request.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException(
        'Authorization header with Bearer token is required',
      );
    }

    const token = authHeader.split(' ')[1];

    try {
      let decodedToken: DecodedToken | null = null;

      if (this.firebaseInitialized) {
        decodedToken = await admin.auth().verifyIdToken(token);
      } else {
        // Development / Mock verification fallback
        try {
          const parts = token.split('.');
          if (parts.length !== 3) {
            // Treat non-JWT bearer tokens as direct mock UIDs for manual curl/testing convenience
            decodedToken = {
              uid: token,
              email: `${token}@example.com`,
              name: `Mock User (${token})`,
            };
          } else {
            const payloadBase64 = parts[1];
            const payloadString = Buffer.from(payloadBase64, 'base64').toString(
              'utf-8',
            );
            decodedToken = JSON.parse(payloadString) as DecodedToken;
          }
        } catch {
          throw new UnauthorizedException('Invalid token format in mock mode');
        }
      }

      if (!decodedToken || !decodedToken.uid) {
        throw new UnauthorizedException('Invalid token payload: uid missing');
      }

      // Map properties to standardized request.user
      request.user = {
        uid: decodedToken.uid,
        email: decodedToken.email || '',
        name: decodedToken.name || decodedToken.email || 'User',
        role: decodedToken.role || 'patient',
      };

      return true;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      throw new UnauthorizedException(`Unauthorized: ${message}`);
    }
  }
}
