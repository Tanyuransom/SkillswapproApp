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

  @CreateDateColumn()
  createdAt!: Date;
}
