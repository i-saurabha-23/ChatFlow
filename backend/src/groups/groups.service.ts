import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { isValidObjectId, Model, Types } from 'mongoose';
import { User, UserDocument } from '../users/user.schema';
import { CreateGroupDto } from './create-group.dto';
import { Group, GroupDocument } from './group.schema';

@Injectable()
export class GroupsService {
  constructor(
    @InjectModel(Group.name) private readonly groupModel: Model<GroupDocument>,
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
  ) {}

  async create(createGroupDto: CreateGroupDto) {
    if (!isValidObjectId(createGroupDto.adminId)) {
      throw new BadRequestException('Invalid adminId.');
    }

    const adminUser = await this.userModel.findById(createGroupDto.adminId);

    if (!adminUser) {
      throw new NotFoundException('Admin user not found.');
    }

    const uniqueMemberIds = Array.from(new Set([...createGroupDto.memberIds, createGroupDto.adminId]));

    const membersCount = await this.userModel.countDocuments({
      _id: { $in: uniqueMemberIds.map((id) => new Types.ObjectId(id)) },
    });

    if (membersCount !== uniqueMemberIds.length) {
      throw new BadRequestException('One or more memberIds are invalid.');
    }

    const group = await this.groupModel.create({
      name: createGroupDto.name,
      description: createGroupDto.description,
      adminId: new Types.ObjectId(createGroupDto.adminId),
      memberIds: uniqueMemberIds.map((id) => new Types.ObjectId(id)),
    });

    return {
      id: group.id,
      name: group.name,
      description: group.description,
      adminId: group.adminId,
      memberIds: group.memberIds,
      createdAt: group.createdAt,
    };
  }

  async findById(groupId: string) {
    const group = await this.groupModel.findById(groupId);

    if (!group) {
      throw new NotFoundException('Group not found.');
    }

    return {
      id: group.id,
      name: group.name,
      description: group.description,
      adminId: group.adminId,
      memberIds: group.memberIds,
      createdAt: group.createdAt,
    };
  }

  async findForMember(memberId?: string) {
    if (!memberId) {
      return [];
    }

    if (!isValidObjectId(memberId)) {
      throw new BadRequestException('Invalid memberId.');
    }

    const groups = await this.groupModel
      .find({ memberIds: new Types.ObjectId(memberId) })
      .sort({ createdAt: -1 });

    return groups.map((group) => ({
      id: group.id,
      name: group.name,
      description: group.description,
      adminId: group.adminId,
      memberIds: group.memberIds,
      createdAt: group.createdAt,
    }));
  }
}
