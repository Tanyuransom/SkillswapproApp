import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from "typeorm";
import { Course } from "./Course";

@Entity("course_reviews")
export class CourseReview {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column()
  courseId!: string;

  @Column()
  userId!: string;

  @Column()
  userName!: string;

  @Column("int")
  rating!: number; // 1 to 5

  @Column("text")
  comment!: string;

  @CreateDateColumn()
  createdAt!: Date;

  @ManyToOne(() => Course)
  @JoinColumn({ name: "courseId" })
  course!: Course;
}
