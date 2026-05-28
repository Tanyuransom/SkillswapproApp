import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, Index } from "typeorm";

@Entity("likes")
@Index(["targetId", "targetType"])
export class Like {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column()
  userId!: string;

  @Column()
  targetId!: string;

  @Column()
  targetType!: string; // 'short', 'course', 'comment', etc.

  @CreateDateColumn()
  createdAt!: Date;
}
