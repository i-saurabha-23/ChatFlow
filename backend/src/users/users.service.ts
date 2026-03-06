import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { isValidObjectId, Model } from 'mongoose';
import { CryptoService } from '../common/crypto/crypto.service';
import { CreateUserDto } from './create-user.dto';
import { User, UserDocument } from './user.schema';

@Injectable()
export class UsersService {
  constructor(
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    private readonly cryptoService: CryptoService,
  ) {}

  async create(createUserDto: CreateUserDto) {
    const existingUser = await this.userModel.findOne({
      email: createUserDto.email.toLowerCase(),
    });

    if (existingUser) {
      throw new BadRequestException('Email is already registered.');
    }

    const passwordSalt = this.cryptoService.generatePasswordSalt();
    const passwordHash = this.cryptoService.hashPassword(
      createUserDto.password,
      passwordSalt,
    );

    let phoneCipherText: string | undefined;
    let phoneIv: string | undefined;
    let phoneAuthTag: string | undefined;

    if (createUserDto.phoneNumber) {
      const encryptedPhone = this.cryptoService.encryptText(createUserDto.phoneNumber);
      phoneCipherText = encryptedPhone.cipherText;
      phoneIv = encryptedPhone.iv;
      phoneAuthTag = encryptedPhone.authTag;
    }

    const createdUser = await this.userModel.create({
      fullName: createUserDto.fullName,
      email: createUserDto.email.toLowerCase(),
      passwordHash,
      passwordSalt,
      authProvider: 'local',
      phoneCipherText,
      phoneIv,
      phoneAuthTag,
    });

    return this.toSafeUser(createdUser);
  }

  async findRawByEmail(email: string) {
    return this.userModel.findOne({ email: email.toLowerCase() });
  }

  async findRawByGoogleSub(googleSub: string) {
    return this.userModel.findOne({ googleSub });
  }

  async upsertGoogleUser(params: {
    googleSub: string;
    email: string;
    fullName: string;
  }) {
    const normalizedEmail = params.email.toLowerCase();

    let user = await this.findRawByGoogleSub(params.googleSub);
    if (!user) {
      user = await this.findRawByEmail(normalizedEmail);
    }

    if (user) {
      const update: Record<string, unknown> = {};

      if (!user.googleSub) {
        update.googleSub = params.googleSub;
      }

      if (params.fullName.trim().length > 0 && user.fullName !== params.fullName) {
        update.fullName = params.fullName;
      }

      if (user.authProvider !== 'google') {
        update.authProvider = 'google';
      }

      if (Object.keys(update).length > 0) {
        const updated = await this.userModel.findByIdAndUpdate(user.id, update, {
          new: true,
        });
        if (updated) {
          user = updated;
        }
      }

      return this.toSafeUser(user);
    }

    const createdUser = await this.userModel.create({
      fullName: params.fullName,
      email: normalizedEmail,
      authProvider: 'google',
      googleSub: params.googleSub,
    });

    return this.toSafeUser(createdUser);
  }

  async findById(userId: string) {
    const user = await this.userModel.findById(userId);

    if (!user) {
      throw new NotFoundException('User not found.');
    }

    return this.toSafeUser(user);
  }

  async findAll(excludeId?: string) {
    if (excludeId && !isValidObjectId(excludeId)) {
      throw new BadRequestException('Invalid excludeId.');
    }

    const query = excludeId ? { _id: { $ne: excludeId } } : {};
    const users = await this.userModel.find(query).sort({ fullName: 1 });

    return users.map((user) => this.toSafeUser(user));
  }

  private toSafeUser(user: UserDocument) {
    return {
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      phoneNumber:
        user.phoneCipherText && user.phoneIv && user.phoneAuthTag
          ? this.cryptoService.decryptText({
              cipherText: user.phoneCipherText,
              iv: user.phoneIv,
              authTag: user.phoneAuthTag,
            })
          : null,
      createdAt: (user as any).createdAt,
    };
  }
}
