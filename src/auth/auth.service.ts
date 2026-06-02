import { ConflictException, Injectable } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { RegisterDto } from './dto/register.dto';
import { User } from '../users/entities/user.entity';

@Injectable()
export class AuthService {
  constructor(private usersService: UsersService) {}

  async register(uid: string, registerDto: RegisterDto): Promise<User> {
    const existingUser = await this.usersService.findById(uid);
    if (existingUser) {
      throw new ConflictException('User already registered in the system');
    }

    return this.usersService.create({
      id: uid,
      email: registerDto.email,
      name: registerDto.name,
      role: registerDto.role || 'patient',
    });
  }
}
