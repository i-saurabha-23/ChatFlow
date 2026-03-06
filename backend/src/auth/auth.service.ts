import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { OAuth2Client } from 'google-auth-library';
import { CryptoService } from '../common/crypto/crypto.service';
import { UsersService } from '../users/users.service';
import { GoogleLoginDto } from './google-login.dto';
import { LoginDto } from './login.dto';
import { RegisterDto } from './register.dto';

@Injectable()
export class AuthService {
  private readonly googleAuthClient = new OAuth2Client();

  constructor(
    private readonly usersService: UsersService,
    private readonly cryptoService: CryptoService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async register(registerDto: RegisterDto) {
    const createdUser = await this.usersService.create(registerDto);
    const token = await this.signToken(createdUser.id, createdUser.email);

    return {
      token,
      user: createdUser,
    };
  }

  async login(loginDto: LoginDto) {
    const user = await this.usersService.findRawByEmail(loginDto.email);

    if (!user) {
      throw new UnauthorizedException('Invalid email or password.');
    }

    if (!user.passwordHash || !user.passwordSalt) {
      throw new UnauthorizedException(
        'This account uses Google sign-in. Continue with Google.',
      );
    }

    const incomingHash = this.cryptoService.hashPassword(
      loginDto.password,
      user.passwordSalt,
    );

    if (incomingHash !== user.passwordHash) {
      throw new UnauthorizedException('Invalid email or password.');
    }

    const token = await this.signToken(user.id, user.email);
    const safeUser = await this.usersService.findById(user.id);

    return {
      token,
      user: safeUser,
    };
  }

  async googleLogin(googleLoginDto: GoogleLoginDto) {
    const audiences = this.googleAudiences();

    if (audiences.length === 0) {
      throw new BadRequestException(
        'Google sign-in is not configured on server. Missing GOOGLE_CLIENT_IDS.',
      );
    }

    try {
      const ticket = await this.googleAuthClient.verifyIdToken({
        idToken: googleLoginDto.idToken,
        audience: audiences,
      });

      const payload = ticket.getPayload();

      if (!payload || !payload.sub || !payload.email) {
        throw new UnauthorizedException('Invalid Google account payload.');
      }

      if (payload.email_verified === false) {
        throw new UnauthorizedException('Google email is not verified.');
      }

      const safeUser = await this.usersService.upsertGoogleUser({
        googleSub: payload.sub,
        email: payload.email,
        fullName: payload.name ?? payload.email.split('@')[0],
      });

      const token = await this.signToken(safeUser.id, safeUser.email);

      return {
        token,
        user: safeUser,
      };
    } catch (error) {
      if (error instanceof BadRequestException) {
        throw error;
      }
      if (error instanceof UnauthorizedException) {
        throw error;
      }
      throw new UnauthorizedException('Invalid Google token.');
    }
  }

  async validateSession(authHeader?: string) {
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing bearer token.');
    }

    const token = authHeader.replace('Bearer ', '').trim();

    try {
      const payload = await this.jwtService.verifyAsync<{
        sub: string;
        email: string;
      }>(token);

      const user = await this.usersService.findById(payload.sub);

      return {
        valid: true,
        user,
      };
    } catch (error) {
      throw new BadRequestException('Invalid or expired token.');
    }
  }

  private async signToken(userId: string, email: string): Promise<string> {
    return this.jwtService.signAsync({ sub: userId, email });
  }

  private googleAudiences(): string[] {
    const raw = this.configService.get<string>('GOOGLE_CLIENT_IDS') ?? '';
    return raw
      .split(',')
      .map((value) => value.trim())
      .filter((value) => value.length > 0);
  }
}
