import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from "typeorm";

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

  @Column({ type: "int", default: 1 })
  level!: number;

  @Column({ nullable: true })
  specialty?: string; // ICT, ISN, CS, SEN, CYS

  @Column({ nullable: true })
  categoryId?: string;

  @Column({ default: 0 })
  likes!: number;

  @Column({ type: "jsonb", nullable: true })
  likedBy!: string[];

  @Column({ default: 0 })
  comments!: number;

  @Index()
  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}
