import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from "typeorm";

@Entity("verifications")
export class Verification {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column()
  tutorId!: string;

  @Column({ default: "pending" })
  status!: string;

  @Column({ nullable: true })
  idNumber?: string;

  @Column({ nullable: true })
  specialization?: string;

  @Column({ type: "int", default: 0 })
  score!: number;

  @Column({ type: "int", default: 5 })
  totalQuestions!: number;

  @CreateDateColumn()
  createdAt!: Date;
}
