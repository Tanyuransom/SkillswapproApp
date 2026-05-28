import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, Unique } from "typeorm";

@Entity("follows")
@Unique(["followerId", "tutorId"])
export class Follow {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column()
  followerId!: string;

  @Column()
  tutorId!: string;

  @CreateDateColumn()
  createdAt!: Date;
}
