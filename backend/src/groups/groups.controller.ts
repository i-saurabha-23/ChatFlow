import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { CreateGroupDto } from './create-group.dto';
import { GroupsService } from './groups.service';

@Controller('groups')
export class GroupsController {
  constructor(private readonly groupsService: GroupsService) {}

  @Post()
  async create(@Body() createGroupDto: CreateGroupDto) {
    return this.groupsService.create(createGroupDto);
  }

  @Get()
  async findForMember(@Query('memberId') memberId?: string) {
    return this.groupsService.findForMember(memberId);
  }

  @Get(':id')
  async findById(@Param('id') id: string) {
    return this.groupsService.findById(id);
  }
}
