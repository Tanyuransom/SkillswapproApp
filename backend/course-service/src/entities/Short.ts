import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from "typeorm";

@Entity("shorts")
export class Short {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column()
  tutorId!: string;

  @Column()
  tutorName!: string;

  @Column()
  courseName!: string;

  @Column("text")
  description!: string;

  @Column()
  videoUrl!: string;

  @Column({ nullable: true })
  tutorAvatarUrl?: string;

  @Column({ default: 0 })
  likes!: number;

  @Column({ default: 0 })
  comments!: number;

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}
