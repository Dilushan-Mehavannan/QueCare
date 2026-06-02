import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { FirebaseAuthGuard } from './firebase-auth.guard';
import { GetUser } from './get-user.decorator';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('register')
  @UseGuards(FirebaseAuthGuard)
  async register(
    @GetUser('uid') uid: string,
    @Body() registerDto: RegisterDto,
  ) {
    return this.authService.register(uid, registerDto);
  }
}
