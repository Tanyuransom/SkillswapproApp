import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from "typeorm";

@Entity("enrollments")
export class Enrollment {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column()
  studentId!: string;

  @Column()
  courseId!: string;

  @Column()
  instructorId!: string; // Added to make querying per-tutor easier

  @Column({ default: "active" })
  status!: string;

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}
