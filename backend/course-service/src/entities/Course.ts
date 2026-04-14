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
  categoryId?: string;

  @Column({ nullable: true })
  imageUrl?: string;

  @Column({ default: "active" })
  status!: string; // active, draft, archived

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}
