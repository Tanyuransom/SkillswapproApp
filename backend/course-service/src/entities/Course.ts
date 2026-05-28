import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from "typeorm";

@Entity("courses")
export class Course {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column()
  title!: string;

  @Column("text")
  description!: string;

  @Column("decimal", { precision: 10, scale: 2 })
  price!: number;

  @Column()
  instructorId!: string; // Reference to User.id from auth-service

  @Column({ nullable: true })
  instructorName?: string;

  @Column({ nullable: true })
  instructorAvatarUrl?: string;

  @Column()
  categoryId!: string;

  @Column({ type: "int", default: 1 })
  level!: number;

  @Column({ nullable: true })
  specialty?: string; // ICT, ISN, CS, SEN, CYS

  @Column({ nullable: true })
  imageUrl?: string;

  @Column({ nullable: true })
  semester?: string;

  @Column({ type: "jsonb", nullable: true })
  materials?: any[];

  @Column({ default: "active" })
  status!: string; // active, draft, archived

  @Column({ default: 0 })
  viewsCount!: number;

  @Column("decimal", { precision: 3, scale: 2, default: 0 })
  averageRating!: number;

  @Column({ default: 0 })
  reviewCount!: number;

  @CreateDateColumn()

  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}
